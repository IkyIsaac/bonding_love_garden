import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import '../models/venue_settings.dart';

/// World-readable (incl. anon — see venue_settings_select RLS policy), so
/// this is safe to fetch before the user has signed in.
final venueSettingsProvider = FutureProvider<VenueSettings>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final row = await client.from('venue_settings').select('park_name, logo_url').single();
  return VenueSettings.fromJson(row);
});
