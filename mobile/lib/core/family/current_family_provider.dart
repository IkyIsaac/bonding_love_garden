import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';

/// Every profile has exactly one family row (even solo customers with zero
/// family_members — see families table comment), so this is always non-null
/// once currentProfileProvider has resolved. Shared across every customer
/// feature that needs to scope a query to "my family" (Home, Family, Plans,
/// Wallet, ...).
final currentFamilyIdProvider = FutureProvider<String>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final profile = await ref.watch(currentProfileProvider.future);
  final row = await client
      .from('families')
      .select('id')
      .eq('owner_profile_id', profile!.id)
      .single();
  return row['id'] as String;
});
