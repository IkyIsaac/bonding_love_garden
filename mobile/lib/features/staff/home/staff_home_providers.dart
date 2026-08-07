import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';

class StaffHomeStats {
  const StaffHomeStats({
    required this.activeGuestCount,
    required this.expiringSoonCount,
  });

  final int activeGuestCount;
  final int expiringSoonCount;
}

/// Park-wide (not family-scoped) counts from session_live_status — visible
/// to any staff role via the sessions_select RLS policy (owns_wristband OR
/// is_staff() OR is_admin()).
final staffHomeStatsProvider = FutureProvider<StaffHomeStats>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final rows = await client
      .from('session_live_status')
      .select('status')
      .inFilter('status', ['active', 'expiring_soon']);
  final expiringSoon = rows.where((r) => r['status'] == 'expiring_soon').length;
  return StaffHomeStats(
    activeGuestCount: rows.length,
    expiringSoonCount: expiringSoon,
  );
});

class StaffActivityItem {
  const StaffActivityItem({
    required this.beneficiaryName,
    required this.createdAt,
  });

  final String beneficiaryName;
  final DateTime createdAt;
}

/// Park-wide recent admissions, sourced from `sessions` rather than
/// audit_log — audit_log_select's RLS is deliberately admin-only ("confirmed:
/// no supervisor visibility", per its migration comment), so a staff session
/// can't read it at all. `sessions` (via sessions_select) is staff-readable,
/// and every successful scan-admission creates exactly one session row, so
/// "recently started sessions" is a faithful proxy for "recent check-ins"
/// without needing any RLS change. Denied scans never reach here — the
/// Scanner screen already shows that outcome immediately at scan time.
final staffRecentActivityProvider = FutureProvider<List<StaffActivityItem>>((
  ref,
) async {
  final client = ref.watch(supabaseClientProvider);
  final sessionRows = await client
      .from('sessions')
      .select('wristband_id, started_at')
      .order('started_at', ascending: false)
      .limit(10);
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

  return sessionRows.map((r) {
    final wristbandId = r['wristband_id'] as String;
    final wristband = wristbandById[wristbandId];
    final memberId = wristband?['family_member_id'] as String?;
    final familyId = wristband?['family_id'] as String?;
    final beneficiaryName = memberId != null
        ? (memberNameById[memberId] ?? 'Unknown guest')
        : (ownerNameByFamilyId[familyId] ?? 'Unknown guest');
    return StaffActivityItem(
      beneficiaryName: beneficiaryName,
      createdAt: DateTime.parse(r['started_at'] as String),
    );
  }).toList();
});
