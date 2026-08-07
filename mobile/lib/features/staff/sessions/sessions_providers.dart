import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/models/session_summary.dart';

/// Every currently open session (not yet explicitly ended by staff), park-
/// wide — not scoped to a family (sessions_select's RLS lets any staff role
/// see all of them, per docs/ARCHITECTURE_PLAN.md §4.11's "Active Sessions"
/// screen). Includes 'expired' (time ran out but nobody hit "End" yet) since
/// that's exactly the case staff need this screen to surface and close out.
final activeSessionsProvider = FutureProvider<List<SessionSummary>>((
  ref,
) async {
  final client = ref.watch(supabaseClientProvider);

  final sessionRows = await client
      .from('session_live_status')
      .select(
        'id, wristband_id, catalog_item_id, started_at, planned_end_at, status, extended_minutes_total',
      )
      .neq('status', 'ended')
      .order('planned_end_at');
  if (sessionRows.isEmpty) return [];

  final wristbandIds = sessionRows
      .map((r) => r['wristband_id'] as String)
      .toSet()
      .toList();
  final wristbandRows = await client
      .from('wristbands')
      .select('id, family_id, family_member_id')
      .inFilter('id', wristbandIds);
  final wristbandById = {for (final w in wristbandRows) w['id'] as String: w};

  final memberIds = wristbandRows
      .map((w) => w['family_member_id'])
      .whereType<String>()
      .toSet()
      .toList();
  final memberNameById = <String, String>{};
  if (memberIds.isNotEmpty) {
    final memberRows = await client
        .from('family_members')
        .select('id, full_name')
        .inFilter('id', memberIds);
    for (final m in memberRows) {
      memberNameById[m['id'] as String] = m['full_name'] as String;
    }
  }

  final ownerFamilyIds = wristbandRows
      .where((w) => w['family_member_id'] == null)
      .map((w) => w['family_id'] as String)
      .toSet()
      .toList();
  final ownerNameByFamilyId = <String, String>{};
  if (ownerFamilyIds.isNotEmpty) {
    final familyRows = await client
        .from('families')
        .select('id, owner_profile_id')
        .inFilter('id', ownerFamilyIds);
    final ownerProfileIds = familyRows
        .map((f) => f['owner_profile_id'] as String)
        .toSet()
        .toList();
    final profileRows = await client
        .from('profiles')
        .select('id, full_name')
        .inFilter('id', ownerProfileIds);
    final nameByProfileId = {
      for (final p in profileRows) p['id'] as String: p['full_name'] as String,
    };
    for (final f in familyRows) {
      final name = nameByProfileId[f['owner_profile_id']];
      if (name != null) ownerNameByFamilyId[f['id'] as String] = name;
    }
  }

  final catalogItemIds = sessionRows
      .map((r) => r['catalog_item_id'])
      .whereType<String>()
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

  return sessionRows.map((r) {
    final wristbandId = r['wristband_id'] as String;
    final wristband = wristbandById[wristbandId];
    final memberId = wristband?['family_member_id'] as String?;
    final familyId = wristband?['family_id'] as String?;
    final beneficiaryName = memberId != null
        ? (memberNameById[memberId] ?? 'Unknown guest')
        : (ownerNameByFamilyId[familyId] ?? 'Unknown guest');
    final catalogItemId = r['catalog_item_id'] as String?;

    return SessionSummary(
      id: r['id'] as String,
      wristbandId: wristbandId,
      beneficiaryName: beneficiaryName,
      catalogItemName: catalogItemId != null
          ? catalogNameById[catalogItemId]
          : null,
      startedAt: DateTime.parse(r['started_at'] as String),
      plannedEndAt: DateTime.parse(r['planned_end_at'] as String),
      status: r['status'] as String,
      extendedMinutesTotal: r['extended_minutes_total'] as int,
    );
  }).toList();
});

/// Extend/end a session via sessions-manage — supervisor/admin only,
/// server-enforced (matches the sessions_update RLS policy, which a direct
/// client update would also be bound by).
class SessionActionsController {
  SessionActionsController(this._client);

  final SupabaseClient _client;

  Future<void> extend(String sessionId, int minutes) async {
    await _client.functions.invoke(
      'sessions-manage',
      body: {
        'sessionId': sessionId,
        'action': 'extend',
        'extendMinutes': minutes,
      },
    );
  }

  Future<void> end(String sessionId) async {
    await _client.functions.invoke(
      'sessions-manage',
      body: {'sessionId': sessionId, 'action': 'end'},
    );
  }
}

final sessionActionsControllerProvider = Provider<SessionActionsController>((
  ref,
) {
  return SessionActionsController(ref.watch(supabaseClientProvider));
});
