import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/models/access_plan.dart';
import '../../../core/models/package_offer.dart';

final entryFeeProvider = FutureProvider<double?>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final row = await client
      .from('entry_fee_config')
      .select('amount')
      .isFilter('effective_to', null)
      .maybeSingle();
  if (row == null) return null;
  return (row['amount'] as num).toDouble();
});

/// Active access_plans with the actual names of their included games/
/// services — not just a count — so a customer can see what they'd
/// actually be buying before selecting a plan. Fetched as three queries
/// (plans, their access_plan_items, then those catalog_items) and joined in
/// Dart, same pattern used for sessions/wristbands elsewhere in the app,
/// since PostgREST's embedded-resource syntax is finicky through join
/// tables with a composite key.
final accessPlansProvider = FutureProvider<List<AccessPlan>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final planRows = await client
      .from('access_plans')
      .select()
      .eq('is_active', true)
      .order('price');
  final planIds = planRows.map((r) => r['id'] as String).toList();
  if (planIds.isEmpty) return [];

  final itemRows = await client
      .from('access_plan_items')
      .select('access_plan_id, catalog_item_id')
      .inFilter('access_plan_id', planIds);
  final catalogItemIds = itemRows
      .map((r) => r['catalog_item_id'] as String)
      .toSet()
      .toList();
  final catalogNameById = <String, String>{};
  if (catalogItemIds.isNotEmpty) {
    final catalogRows = await client
        .from('catalog_items')
        .select('id, name')
        .inFilter('id', catalogItemIds);
    for (final c in catalogRows) {
      catalogNameById[c['id'] as String] = c['name'] as String;
    }
  }

  final namesByPlanId = <String, List<String>>{};
  for (final row in itemRows) {
    final planId = row['access_plan_id'] as String;
    final name = catalogNameById[row['catalog_item_id']];
    if (name == null) continue;
    (namesByPlanId[planId] ??= []).add(name);
  }

  return planRows
      .map(
        (r) => AccessPlan.fromJson(
          r,
          includedItemNames: namesByPlanId[r['id']] ?? const [],
        ),
      )
      .toList();
});

/// Active packages currently within their availability window (or with no
/// window set at all, meaning always available), with the quantity-prefixed
/// names of what each one includes (see PackageOffer's own doc comment).
final packagesProvider = FutureProvider<List<PackageOffer>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final packageRows = await client
      .from('packages')
      .select()
      .eq('is_active', true)
      .order('price');
  final now = DateTime.now();
  final activeRows = packageRows.where((r) {
    final start = r['availability_start'] == null
        ? null
        : DateTime.parse(r['availability_start'] as String);
    final end = r['availability_end'] == null
        ? null
        : DateTime.parse(r['availability_end'] as String);
    if (start != null && !start.isBefore(now)) return false;
    if (end != null && !end.isAfter(now)) return false;
    return true;
  }).toList();
  final packageIds = activeRows.map((r) => r['id'] as String).toList();
  if (packageIds.isEmpty) return [];

  final itemRows = await client
      .from('package_items')
      .select('package_id, catalog_item_id, quantity')
      .inFilter('package_id', packageIds);
  final catalogItemIds = itemRows
      .map((r) => r['catalog_item_id'] as String)
      .toSet()
      .toList();
  final catalogNameById = <String, String>{};
  if (catalogItemIds.isNotEmpty) {
    final catalogRows = await client
        .from('catalog_items')
        .select('id, name')
        .inFilter('id', catalogItemIds);
    for (final c in catalogRows) {
      catalogNameById[c['id'] as String] = c['name'] as String;
    }
  }

  final namesByPackageId = <String, List<String>>{};
  for (final row in itemRows) {
    final packageId = row['package_id'] as String;
    final name = catalogNameById[row['catalog_item_id']];
    if (name == null) continue;
    final quantity = row['quantity'] as int;
    (namesByPackageId[packageId] ??= []).add('${quantity}x $name');
  }

  return activeRows
      .map(
        (r) => PackageOffer.fromJson(
          r,
          includedItemNames: namesByPackageId[r['id']] ?? const [],
        ),
      )
      .toList();
});
