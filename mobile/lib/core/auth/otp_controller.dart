import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_providers.dart';

enum LoginStep { phone, otp }

class LoginState {
  const LoginState({this.step = LoginStep.phone, this.phone = '', this.loading = false, this.error});

  final LoginStep step;
  final String phone;
  final bool loading;
  final String? error;

  LoginState copyWith({LoginStep? step, String? phone, bool? loading, String? error}) {
    return LoginState(
      step: step ?? this.step,
      phone: phone ?? this.phone,
      loading: loading ?? this.loading,
      // Explicitly nulled out on every successful transition rather than
      // sticking around from the previous attempt.
      error: error,
    );
  }
}

/// Drives the two-step phone -> OTP login screen. Verification success
/// itself doesn't need to be represented here — authStateChangesProvider
/// picks up the new session and the router redirects away from /login.
class OtpController extends Notifier<LoginState> {
  @override
  LoginState build() => const LoginState();

  Future<void> sendOtp(String phone) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await ref.read(authRepositoryProvider).sendOtp(phone);
      state = state.copyWith(step: LoginStep.otp, phone: phone, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: _messageFor(e));
    }
  }

  Future<void> verifyOtp(String token) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await ref.read(authRepositoryProvider).verifyOtp(phone: state.phone, token: token);
      // Loading is left true deliberately through the redirect — the OTP
      // screen would otherwise flash back to an idle state for a frame
      // before the router navigates away.
    } catch (e) {
      state = state.copyWith(loading: false, error: _messageFor(e));
    }
  }

  void backToPhoneStep() {
    state = state.copyWith(step: LoginStep.phone, error: null);
  }

  String _messageFor(Object e) => e.toString().replaceFirst('AuthException: ', '');
}

final otpControllerProvider = NotifierProvider<OtpController, LoginState>(OtpController.new);
