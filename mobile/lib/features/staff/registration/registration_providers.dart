import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/auth_providers.dart';

class PendingCustomer {
  const PendingCustomer({
    required this.profileId,
    required this.fullName,
    required this.phone,
    required this.createdAt,
  });

  final String profileId;
  final String fullName;
  final String phone;
  final DateTime createdAt;
}

/// Customers awaiting approval — profiles_select's RLS already lets staff
/// read any customer profile, so this is a direct query. Approving/rejecting
/// itself can't go through a direct client update though (profiles_update's
/// RLS is `id = auth.uid() or is_admin()`, so a staff session has no write
/// path to another profile at all) — that's what staff-approve-customer is for.
final pendingCustomersProvider = FutureProvider<List<PendingCustomer>>((
  ref,
) async {
  final client = ref.watch(supabaseClientProvider);
  final rows = await client
      .from('profiles')
      .select('id, full_name, phone, created_at')
      .eq('role', 'customer')
      .eq('approval_status', 'pending')
      .order('created_at');
  return rows
      .map(
        (r) => PendingCustomer(
          profileId: r['id'] as String,
          fullName: r['full_name'] as String,
          phone: r['phone'] as String,
          createdAt: DateTime.parse(r['created_at'] as String),
        ),
      )
      .toList();
});

class RegistrationController {
  RegistrationController(this._client);

  final SupabaseClient _client;

  Future<void> decide(String profileId, {required bool approve}) async {
    await _client.functions.invoke(
      'staff-approve-customer',
      body: {
        'profileId': profileId,
        'decision': approve ? 'approve' : 'reject',
      },
    );
  }
}

final registrationControllerProvider = Provider<RegistrationController>((ref) {
  return RegistrationController(ref.watch(supabaseClientProvider));
});
