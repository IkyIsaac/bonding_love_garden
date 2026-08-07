import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/models/family_member.dart';
import '../../../core/models/subscription_summary.dart';
import '../../../core/models/wristband_summary.dart';

/// Staff-lookup twins of the customer app's own family_members/
/// subscriptions/wristbands providers — same queries, parameterized by an
/// arbitrary familyId instead of currentFamilyIdProvider, since staff are
/// looking up someone else's family rather than their own. All three tables
/// grant staff SELECT via `is_staff()` in their RLS policies.
final familyMembersByFamilyIdProvider =
    FutureProvider.family<List<FamilyMember>, String>((ref, familyId) async {
      final client = ref.watch(supabaseClientProvider);
      final rows = await client
          .from('family_members')
          .select()
          .eq('family_id', familyId)
          .order('created_at');
      return rows.map(FamilyMember.fromJson).toList();
    });

final subscriptionsByFamilyIdProvider =
    FutureProvider.family<List<SubscriptionSummary>, String>((
      ref,
      familyId,
    ) async {
      final client = ref.watch(supabaseClientProvider);
      final rows = await client
          .from('subscriptions')
          .select(
            'id, access_plan_id, status, starts_at, ends_at, visits_remaining, access_plans(name)',
          )
          .eq('family_id', familyId)
          .order('ends_at', ascending: false);

      return rows.map((r) {
        final plan = r['access_plans'] as Map<String, dynamic>?;
        return SubscriptionSummary(
          id: r['id'] as String,
          accessPlanId: r['access_plan_id'] as String,
          planName: plan?['name'] as String? ?? 'Unknown plan',
          status: r['status'] as String,
          startsAt: DateTime.parse(r['starts_at'] as String),
          endsAt: DateTime.parse(r['ends_at'] as String),
          visitsRemaining: r['visits_remaining'] as int?,
        );
      }).toList();
    });

final wristbandsByFamilyIdProvider =
    FutureProvider.family<List<WristbandSummary>, String>((
      ref,
      familyId,
    ) async {
      final client = ref.watch(supabaseClientProvider);
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

      String ownerName = 'Account owner';
      if (rows.any((r) => r['family_member_id'] == null)) {
        final familyRow = await client
            .from('families')
            .select('owner_profile_id')
            .eq('id', familyId)
            .maybeSingle();
        final ownerProfileId = familyRow?['owner_profile_id'] as String?;
        if (ownerProfileId != null) {
          final profileRow = await client
              .from('profiles')
              .select('full_name')
              .eq('id', ownerProfileId)
              .maybeSingle();
          ownerName = profileRow?['full_name'] as String? ?? ownerName;
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
              : ownerName,
          isAccountOwner: memberId == null,
        );
      }).toList();
    });
