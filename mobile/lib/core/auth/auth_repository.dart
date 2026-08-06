import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';

/// Thin wrapper over supabase_flutter's phone-OTP auth — mirrors the web
/// admin's login flow (web/app/login/page.tsx) exactly: phone in, OTP in,
/// no password/email anywhere in this app.
class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  Session? get currentSession => _client.auth.currentSession;

  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  Future<void> sendOtp(String phone) {
    return _client.auth.signInWithOtp(phone: phone);
  }

  Future<void> verifyOtp({required String phone, required String token}) async {
    await _client.auth.verifyOTP(phone: phone, token: token, type: OtpType.sms);
  }

  Future<void> signOut() {
    return _client.auth.signOut();
  }

  /// Null if there's no signed-in user, or the profile row hasn't been
  /// created yet (handle_new_user runs on the trigger's own transaction,
  /// so in practice this is available immediately after verifyOtp).
  Future<Profile?> fetchCurrentProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    final row = await _client.from('profiles').select().eq('id', userId).maybeSingle();
    if (row == null) return null;
    return Profile.fromJson(row);
  }
}
