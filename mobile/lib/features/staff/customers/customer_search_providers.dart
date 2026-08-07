import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';

class CustomerMatch {
  const CustomerMatch({
    required this.profileId,
    required this.familyId,
    required this.fullName,
    required this.phone,
  });

  final String profileId;
  final String familyId;
  final String fullName;
  final String phone;
}

/// Phone-number search across customer profiles, joined in Dart to each
/// profile's family (every profile gets a families row via handle_new_user,
/// so a match with no family row is an anomaly, not a normal empty state —
/// silently dropped rather than shown as a dead-end result). profiles_select
/// RLS already lets staff read any customer profile
/// (`is_staff() and role = 'customer'`), so this is a direct client query,
/// no Edge Function needed.
final customerSearchProvider =
    FutureProvider.family<List<CustomerMatch>, String>((ref, query) async {
      final trimmed = query.trim();
      if (trimmed.length < 3) return [];

      final client = ref.watch(supabaseClientProvider);
      final profileRows = await client
          .from('profiles')
          .select('id, full_name, phone')
          .eq('role', 'customer')
          .ilike('phone', '%$trimmed%')
          .limit(20);
      if (profileRows.isEmpty) return [];

      final profileIds = profileRows.map((r) => r['id'] as String).toList();
      final familyRows = await client
          .from('families')
          .select('id, owner_profile_id')
          .inFilter('owner_profile_id', profileIds);
      final familyIdByOwner = {
        for (final f in familyRows)
          f['owner_profile_id'] as String: f['id'] as String,
      };

      return profileRows
          .where((r) => familyIdByOwner.containsKey(r['id']))
          .map(
            (r) => CustomerMatch(
              profileId: r['id'] as String,
              familyId: familyIdByOwner[r['id']]!,
              fullName: r['full_name'] as String,
              phone: r['phone'] as String,
            ),
          )
          .toList();
    });
