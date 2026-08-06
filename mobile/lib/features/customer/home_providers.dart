import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_providers.dart';

/// Every profile has exactly one family row (even solo customers with zero
/// family_members — see families table comment), so this is always non-null
/// once currentProfileProvider has resolved.
final currentFamilyIdProvider = FutureProvider<String>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final profile = await ref.watch(currentProfileProvider.future);
  final row = await client.from('families').select('id').eq('owner_profile_id', profile!.id).single();
  return row['id'] as String;
});

final familyMemberNamesProvider = FutureProvider<List<String>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final familyId = await ref.watch(currentFamilyIdProvider.future);
  final rows = await client.from('family_members').select('full_name').eq('family_id', familyId).order('created_at');
  return rows.map((r) => r['full_name'] as String).toList();
});

class ActivePlanSummary {
  const ActivePlanSummary({required this.planName, required this.endsAt});

  final String planName;
  final DateTime endsAt;
}

final activeSubscriptionProvider = FutureProvider<ActivePlanSummary?>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final familyId = await ref.watch(currentFamilyIdProvider.future);
  final row = await client
      .from('subscriptions')
      .select('ends_at, access_plans(name)')
      .eq('family_id', familyId)
      .eq('status', 'active')
      .order('ends_at', ascending: false)
      .limit(1)
      .maybeSingle();
  if (row == null) return null;
  final plan = row['access_plans'] as Map<String, dynamic>?;
  if (plan == null) return null;
  return ActivePlanSummary(planName: plan['name'] as String, endsAt: DateTime.parse(row['ends_at'] as String));
});

class LiveSessionSummary {
  const LiveSessionSummary({required this.zoneName, required this.plannedEndAt, required this.startedAt, required this.peopleCount});

  final String zoneName;
  final DateTime plannedEndAt;
  final DateTime startedAt;
  final int peopleCount;
}

/// A family's live session, if anyone is currently playing (status active or
/// expiring_soon — see session_live_status view). Fetched by hand-joining
/// wristbands -> session_live_status -> zones rather than relying on
/// PostgREST's embedded-resource syntax through a view, which is unreliable
/// once the FK-implying columns are selected through `s.*`.
final liveSessionProvider = FutureProvider<LiveSessionSummary?>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final familyId = await ref.watch(currentFamilyIdProvider.future);

  final wristbandRows = await client.from('wristbands').select('id').eq('family_id', familyId);
  final wristbandIds = wristbandRows.map((r) => r['id'] as String).toList();
  if (wristbandIds.isEmpty) return null;

  final sessionRows = await client
      .from('session_live_status')
      .select('zone_id, started_at, planned_end_at')
      .inFilter('wristband_id', wristbandIds)
      .inFilter('status', ['active', 'expiring_soon']);
  if (sessionRows.isEmpty) return null;

  final first = sessionRows.first;
  String zoneName = 'The park';
  final zoneId = first['zone_id'] as String?;
  if (zoneId != null) {
    final zoneRow = await client.from('zones').select('name').eq('id', zoneId).maybeSingle();
    if (zoneRow != null) zoneName = zoneRow['name'] as String;
  }

  return LiveSessionSummary(
    zoneName: zoneName,
    plannedEndAt: DateTime.parse(first['planned_end_at'] as String),
    startedAt: DateTime.parse(first['started_at'] as String),
    peopleCount: sessionRows.length,
  );
});

class ActivityItem {
  const ActivityItem({required this.title, required this.body, required this.createdAt});

  final String title;
  final String? body;
  final DateTime createdAt;
}

final recentActivityProvider = FutureProvider<List<ActivityItem>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile == null) return [];
  final rows = await client
      .from('notifications')
      .select('title, body, created_at')
      .eq('recipient_profile_id', profile.id)
      .order('created_at', ascending: false)
      .limit(3);
  return rows
      .map((r) => ActivityItem(title: r['title'] as String, body: r['body'] as String?, createdAt: DateTime.parse(r['created_at'] as String)))
      .toList();
});
