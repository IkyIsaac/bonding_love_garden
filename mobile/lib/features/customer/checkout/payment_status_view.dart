import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import 'checkout_providers.dart';

/// Shared "waiting for Selcom -> success/failed" flow, used by both plan
/// checkout and reservation-fee payment — same order-watching pattern
/// either way, only the copy differs. Watches orderStatusProvider itself so
/// callers just drop this in once a CheckoutResult exists.
class PaymentStatusView extends ConsumerWidget {
  const PaymentStatusView({
    super.key,
    required this.checkout,
    required this.successMessage,
    required this.doneLabel,
    required this.onDone,
    required this.onRetry,
  });

  final CheckoutResult checkout;
  final String successMessage;
  final String doneLabel;
  final VoidCallback onDone;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(orderStatusProvider(checkout.orderId));

    return status.when(
      data: (s) {
        return switch (s) {
          'paid' => _SuccessView(
            message: successMessage,
            doneLabel: doneLabel,
            onDone: onDone,
          ),
          'failed' => _FailedView(onRetry: onRetry),
          _ => _WaitingView(redirectUrl: checkout.redirectUrl),
        };
      },
      loading: () => _WaitingView(redirectUrl: checkout.redirectUrl),
      error: (_, __) => _FailedView(onRetry: onRetry),
    );
  }
}

class _WaitingView extends StatelessWidget {
  const _WaitingView({this.redirectUrl});

  final String? redirectUrl;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Waiting for payment confirmation…',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              'In production you\'d be redirected to Selcom\'s hosted payment page now. This app updates automatically the moment Selcom confirms the payment.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (redirectUrl != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              redirectUrl!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({
    required this.message,
    required this.doneLabel,
    required this.onDone,
  });

  final String message;
  final String doneLabel;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: AppColors.primary, size: 64),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Payment successful!',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton(onPressed: onDone, child: Text(doneLabel)),
        ],
      ),
    );
  }
}

class _FailedView extends StatelessWidget {
  const _FailedView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 64),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Payment failed',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'The payment wasn\'t completed. No charge was made.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}
