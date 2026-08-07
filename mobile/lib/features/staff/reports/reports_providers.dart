import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';

class RevenueStats {
  const RevenueStats({
    required this.today,
    required this.thisWeek,
    required this.thisMonth,
  });

  final double today;
  final double thisWeek;
  final double thisMonth;
}

class AcquisitionStats {
  const AcquisitionStats({
    required this.newToday,
    required this.newThisWeek,
    required this.newThisMonth,
    required this.pendingApproval,
  });

  final int newToday;
  final int newThisWeek;
  final int newThisMonth;
  final int pendingApproval;
}

class PlanSales {
  const PlanSales({
    required this.name,
    required this.quantitySold,
    required this.revenue,
  });

  final String name;
  final int quantitySold;
  final double revenue;
}

class GamePopularity {
  const GamePopularity({required this.name, required this.sessionCount});

  final String name;
  final int sessionCount;
}

class FamilyFrequency {
  const FamilyFrequency({required this.familyName, required this.visitCount});

  final String familyName;
  final int visitCount;
}

class StaffReportsSummary {
  const StaffReportsSummary({
    required this.revenue,
    required this.acquisition,
    required this.sessionsToday,
    required this.sessionsThisWeek,
    required this.topPlans,
    required this.popularGames,
    required this.topFamiliesThisMonth,
  });

  final RevenueStats revenue;
  final AcquisitionStats acquisition;
  final int sessionsToday;
  final int sessionsThisWeek;
  final List<PlanSales> topPlans;
  final List<GamePopularity> popularGames;
  final List<FamilyFrequency> topFamiliesThisMonth;
}

/// Aggregated client-side over a handful of raw queries, same deliberate
/// first-pass shortcut the web admin's own Reports page takes (its own
/// comment: pure aggregation belongs in a Postgres view/RPC once order
/// volume justifies it — not worth it yet at this data size). Revenue,
/// acquisition, and session counts are date-scoped (today/week/month);
/// Top Plans and Popular Games are all-time, matching the web admin's
/// existing report exactly; Top Families is scoped to "this month" to match
/// the Stitch mockup's own wording ("18 visits this month").
final staffReportsProvider = FutureProvider<StaffReportsSummary>((ref) async {
  final client = ref.watch(supabaseClientProvider);

  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);
  final startOfWeek = startOfToday.subtract(
    Duration(days: startOfToday.weekday % 7),
  );
  final startOfMonth = DateTime(now.year, now.month, 1);

  final paidOrdersFuture = client
      .from('orders')
      .select('id, total_amount, created_at')
      .eq('status', 'paid');
  final accessPlansFuture = client.from('access_plans').select('id, name');
  final sessionsFuture = client
      .from('sessions')
      .select('id, wristband_id, catalog_item_id, started_at');
  final catalogItemsFuture = client.from('catalog_items').select('id, name');
  final customerProfilesFuture = client
      .from('profiles')
      .select('id, created_at, approval_status')
      .eq('role', 'customer');

  final paidOrders = await paidOrdersFuture;
  final accessPlans = await accessPlansFuture;
  final sessions = await sessionsFuture;
  final catalogItems = await catalogItemsFuture;
  final customerProfiles = await customerProfilesFuture;

  final paidOrderIds = paidOrders.map((o) => o['id'] as String).toList();
  final orderItems = paidOrderIds.isEmpty
      ? <Map<String, dynamic>>[]
      : await client
            .from('order_items')
            .select('reference_id, quantity, line_total')
            .eq('item_type', 'access_plan')
            .inFilter('order_id', paidOrderIds);

  // Revenue
  double sumSince(DateTime since) => paidOrders
      .where((o) => !DateTime.parse(o['created_at'] as String).isBefore(since))
      .fold(0.0, (sum, o) => sum + (o['total_amount'] as num).toDouble());
  final revenue = RevenueStats(
    today: sumSince(startOfToday),
    thisWeek: sumSince(startOfWeek),
    thisMonth: sumSince(startOfMonth),
  );

  // Acquisition
  int countSince(DateTime since) => customerProfiles
      .where((p) => !DateTime.parse(p['created_at'] as String).isBefore(since))
      .length;
  final acquisition = AcquisitionStats(
    newToday: countSince(startOfToday),
    newThisWeek: countSince(startOfWeek),
    newThisMonth: countSince(startOfMonth),
    pendingApproval: customerProfiles
        .where((p) => p['approval_status'] == 'pending')
        .length,
  );

  // Sessions today/this week
  int sessionsSince(DateTime since) => sessions
      .where((s) => !DateTime.parse(s['started_at'] as String).isBefore(since))
      .length;
  final sessionsToday = sessionsSince(startOfToday);
  final sessionsThisWeek = sessionsSince(startOfWeek);

  // Top plans by revenue (all-time), matching the web admin's own report
  final planNameById = {
    for (final p in accessPlans) p['id'] as String: p['name'] as String,
  };
  final planSales = <String, PlanSales>{};
  for (final item in orderItems) {
    final referenceId = item['reference_id'] as String?;
    if (referenceId == null) continue;
    final name = planNameById[referenceId] ?? 'Unknown plan';
    final existing = planSales[referenceId];
    planSales[referenceId] = PlanSales(
      name: name,
      quantitySold: (existing?.quantitySold ?? 0) + (item['quantity'] as int),
      revenue:
          (existing?.revenue ?? 0) + (item['line_total'] as num).toDouble(),
    );
  }
  final topPlans = planSales.values.toList()
    ..sort((a, b) => b.revenue.compareTo(a.revenue));

  // Popular games (all-time), matching the web admin's own report
  final catalogNameById = {
    for (final c in catalogItems) c['id'] as String: c['name'] as String,
  };
  final gameCounts = <String, int>{};
  for (final s in sessions) {
    final catalogItemId = s['catalog_item_id'] as String?;
    if (catalogItemId == null) continue;
    gameCounts[catalogItemId] = (gameCounts[catalogItemId] ?? 0) + 1;
  }
  final popularGames =
      gameCounts.entries
          .map(
            (e) => GamePopularity(
              name: catalogNameById[e.key] ?? 'Unknown',
              sessionCount: e.value,
            ),
          )
          .toList()
        ..sort((a, b) => b.sessionCount.compareTo(a.sessionCount));

  // Top families by visit frequency this month — sessions -> wristbands ->
  // families, the same hand-join pattern used throughout the staff feature.
  final sessionsThisMonth = sessions
      .where(
        (s) =>
            !DateTime.parse(s['started_at'] as String).isBefore(startOfMonth),
      )
      .toList();
  final wristbandIds = sessionsThisMonth
      .map((s) => s['wristband_id'] as String)
      .toSet()
      .toList();
  final wristbandRows = wristbandIds.isEmpty
      ? <Map<String, dynamic>>[]
      : await client
            .from('wristbands')
            .select('id, family_id')
            .inFilter('id', wristbandIds);
  final familyIdByWristbandId = {
    for (final w in wristbandRows) w['id'] as String: w['family_id'] as String,
  };

  final familyIds = familyIdByWristbandId.values.toSet().toList();
  final familyRows = familyIds.isEmpty
      ? <Map<String, dynamic>>[]
      : await client
            .from('families')
            .select('id, display_name, owner_profile_id')
            .inFilter('id', familyIds);
  final ownerProfileIds = familyRows
      .where((f) => f['display_name'] == null)
      .map((f) => f['owner_profile_id'] as String)
      .toList();
  final ownerNameRows = ownerProfileIds.isEmpty
      ? <Map<String, dynamic>>[]
      : await client
            .from('profiles')
            .select('id, full_name')
            .inFilter('id', ownerProfileIds);
  final ownerNameByProfileId = {
    for (final p in ownerNameRows) p['id'] as String: p['full_name'] as String,
  };
  final familyNameById = {
    for (final f in familyRows)
      f['id'] as String:
          (f['display_name'] as String?) ??
          ownerNameByProfileId[f['owner_profile_id']] ??
          'Unknown family',
  };

  final visitCountByFamilyId = <String, int>{};
  for (final s in sessionsThisMonth) {
    final familyId = familyIdByWristbandId[s['wristband_id'] as String];
    if (familyId == null) continue;
    visitCountByFamilyId[familyId] = (visitCountByFamilyId[familyId] ?? 0) + 1;
  }
  final topFamilies =
      visitCountByFamilyId.entries
          .map(
            (e) => FamilyFrequency(
              familyName: familyNameById[e.key] ?? 'Unknown family',
              visitCount: e.value,
            ),
          )
          .toList()
        ..sort((a, b) => b.visitCount.compareTo(a.visitCount));

  return StaffReportsSummary(
    revenue: revenue,
    acquisition: acquisition,
    sessionsToday: sessionsToday,
    sessionsThisWeek: sessionsThisWeek,
    topPlans: topPlans.take(5).toList(),
    popularGames: popularGames.take(5).toList(),
    topFamiliesThisMonth: topFamilies.take(5).toList(),
  );
});
