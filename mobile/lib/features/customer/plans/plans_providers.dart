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

/// Active access_plans with their included-item count. Fetched as two
/// queries (plans, then all their access_plan_items) and joined in Dart —
/// same pattern used for sessions/wristbands elsewhere in the app, since
/// PostgREST's embedded-count syntax is finicky through join tables with a
/// composite key.
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
      .select('access_plan_id')
      .inFilter('access_plan_id', planIds);
  final countByPlanId = <String, int>{};
  for (final row in itemRows) {
    final planId = row['access_plan_id'] as String;
    countByPlanId[planId] = (countByPlanId[planId] ?? 0) + 1;
  }

  return planRows
      .map(
        (r) => AccessPlan.fromJson(
          r,
          includedItemCount: countByPlanId[r['id']] ?? 0,
        ),
      )
      .toList();
});

/// Active packages currently within their availability window (or with no
/// window set at all, meaning always available).
final packagesProvider = FutureProvider<List<PackageOffer>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final rows = await client
      .from('packages')
      .select()
      .eq('is_active', true)
      .order('price');
  final now = DateTime.now();
  return rows
      .map(PackageOffer.fromJson)
      .where(
        (p) =>
            p.availabilityStart == null || p.availabilityStart!.isBefore(now),
      )
      .where(
        (p) => p.availabilityEnd == null || p.availabilityEnd!.isAfter(now),
      )
      .toList();
});
