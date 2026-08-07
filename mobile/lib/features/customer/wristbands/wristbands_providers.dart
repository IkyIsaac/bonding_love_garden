import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/family/current_family_provider.dart';
import '../../../core/models/wristband_summary.dart';

final familyWristbandsProvider = FutureProvider<List<WristbandSummary>>((
  ref,
) async {
  final client = ref.watch(supabaseClientProvider);
  final familyId = await ref.watch(currentFamilyIdProvider.future);
  final profile = await ref.watch(currentProfileProvider.future);

  final rows = await client
      .from('wristband_live_status')
      .select(
        'id, family_member_id, wristband_number, qr_code_value, live_status, expires_at, last_scanned_at',
      )
      .eq('family_id', familyId)
      .order('issued_at', ascending: false);

  final memberIds = rows
      .map((r) => r['family_member_id'])
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

  return rows.map((r) {
    final memberId = r['family_member_id'] as String?;
    return WristbandSummary(
      id: r['id'] as String,
      wristbandNumber: r['wristband_number'] as String,
      qrCodeValue: r['qr_code_value'] as String,
      liveStatus: r['live_status'] as String,
      expiresAt: DateTime.parse(r['expires_at'] as String),
      lastScannedAt: r['last_scanned_at'] == null
          ? null
          : DateTime.parse(r['last_scanned_at'] as String),
      beneficiaryName: memberId != null
          ? (memberNameById[memberId] ?? 'Unknown')
          : (profile?.fullName ?? 'You'),
      isAccountOwner: memberId == null,
    );
  }).toList();
});
