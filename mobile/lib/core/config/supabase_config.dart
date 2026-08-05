import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads Supabase project connection details passed at build time, e.g.:
///   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_PUBLISHABLE_KEY=...
/// Never commit real project credentials — these are public (publishable
/// key + RLS-protected), but still environment-specific (local/staging/prod).
class SupabaseConfig {
  SupabaseConfig._();

  static const url = String.fromEnvironment('SUPABASE_URL');
  static const publishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static Future<void> initialize() {
    return Supabase.initialize(url: url, publishableKey: publishableKey);
  }
}
