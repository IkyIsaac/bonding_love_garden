import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/otp_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/venue/venue_providers.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loginState = ref.watch(otpControllerProvider);
    final venue = ref.watch(venueSettingsProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppRadii.large),
                  ),
                  child: const Icon(Icons.eco, color: AppColors.onPrimary, size: 36),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: venue.when(
                  data: (v) => Text(
                    v.parkName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.primary),
                    textAlign: TextAlign.center,
                  ),
                  loading: () => const SizedBox(height: 32),
                  error: (_, __) => Text(
                    'Bonding Love Garden',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.primary),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                loginState.step == LoginStep.phone
                    ? 'Enter your phone number to begin your journey.'
                    : 'Enter the code sent to ${loginState.phone}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              if (loginState.step == LoginStep.phone) const _PhoneStep() else const _OtpStep(),
              if (loginState.error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  loginState.error!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PhoneStep extends ConsumerStatefulWidget {
  const _PhoneStep();

  @override
  ConsumerState<_PhoneStep> createState() => _PhoneStepState();
}

class _PhoneStepState extends ConsumerState<_PhoneStep> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(otpControllerProvider).loading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          keyboardType: TextInputType.phone,
          autofocus: true,
          decoration: const InputDecoration(hintText: '+255700000000', prefixIcon: Icon(Icons.phone_outlined)),
        ),
        const SizedBox(height: AppSpacing.sm),
        ElevatedButton.icon(
          onPressed: loading ? null : () => ref.read(otpControllerProvider.notifier).sendOtp(_controller.text.trim()),
          icon: loading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onSecondary))
              : const Icon(Icons.arrow_forward),
          label: Text(loading ? 'Sending…' : 'Continue'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, foregroundColor: AppColors.onSecondary),
        ),
      ],
    );
  }
}

class _OtpStep extends ConsumerStatefulWidget {
  const _OtpStep();

  @override
  ConsumerState<_OtpStep> createState() => _OtpStepState();
}

class _OtpStepState extends ConsumerState<_OtpStep> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(otpControllerProvider).loading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          keyboardType: TextInputType.number,
          maxLength: 6,
          autofocus: true,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, letterSpacing: 8),
          decoration: const InputDecoration(counterText: '', hintText: '123456'),
        ),
        const SizedBox(height: AppSpacing.sm),
        ElevatedButton.icon(
          onPressed: loading ? null : () => ref.read(otpControllerProvider.notifier).verifyOtp(_controller.text.trim()),
          icon: loading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onSecondary))
              : const Icon(Icons.check),
          label: Text(loading ? 'Verifying…' : 'Verify'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, foregroundColor: AppColors.onSecondary),
        ),
        TextButton(
          onPressed: loading ? null : () => ref.read(otpControllerProvider.notifier).backToPhoneStep(),
          child: const Text('Use a different number'),
        ),
      ],
    );
  }
}
