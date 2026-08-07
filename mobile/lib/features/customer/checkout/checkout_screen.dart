import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/access_plan.dart';
import '../../../core/models/cart_pricing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/branded_app_bar.dart';
import '../home_providers.dart';
import 'checkout_providers.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key, required this.plan});

  final AccessPlan plan;

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  CheckoutResult? _checkout;
  bool _starting = false;
  String? _error;

  Future<void> _pay() async {
    setState(() {
      _starting = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(checkoutRepositoryProvider)
          .startCheckout(widget.plan.id);
      setState(() => _checkout = result);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = ref.watch(checkoutPreviewProvider(widget.plan.id));

    return Scaffold(
      appBar: const BrandedAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: _checkout == null
            ? _buildPreview(context, preview)
            : _buildPaymentStatus(context, _checkout!),
      ),
    );
  }

  Widget _buildPreview(BuildContext context, AsyncValue<CartPricing> preview) {
    return ListView(
      children: [
        Text('Checkout', style: Theme.of(context).textTheme.headlineSmall),
        Text(
          widget.plan.name,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: preview.when(
              data: (pricing) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _priceRow(context, widget.plan.name, pricing.subtotal),
                  if (pricing.discountTotal > 0)
                    _priceRow(
                      context,
                      'Discount',
                      -pricing.discountTotal,
                      color: AppColors.primary,
                    ),
                  if (pricing.entryFeeTotal > 0)
                    _priceRow(context, 'Entry Fee', pricing.entryFeeTotal),
                  const Divider(),
                  _priceRow(context, 'Total', pricing.totalAmount, bold: true),
                ],
              ),
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => Text(
                "Couldn't load pricing.",
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (_error != null) ...[
          Text(_error!, style: const TextStyle(color: AppColors.error)),
          const SizedBox(height: AppSpacing.sm),
        ],
        ElevatedButton.icon(
          onPressed: _starting || !preview.hasValue ? null : _pay,
          icon: _starting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.onSecondary,
                  ),
                )
              : const Icon(Icons.lock_outline),
          label: Text(_starting ? 'Starting checkout…' : 'Pay with Selcom'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: AppColors.onSecondary,
          ),
        ),
      ],
    );
  }

  Widget _priceRow(
    BuildContext context,
    String label,
    double amount, {
    bool bold = false,
    Color? color,
  }) {
    final style = bold
        ? Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
        : Theme.of(context).textTheme.bodyMedium?.copyWith(color: color);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(
            amount < 0
                ? '-${amount.abs().toStringAsFixed(0)}'
                : amount.toStringAsFixed(0),
            style: style,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStatus(BuildContext context, CheckoutResult checkout) {
    final status = ref.watch(orderStatusProvider(checkout.orderId));

    return status.when(
      data: (s) {
        return switch (s) {
          'paid' => _SuccessView(planName: widget.plan.name),
          'failed' => _FailedView(
            onRetry: () => setState(() => _checkout = null),
          ),
          _ => _WaitingView(redirectUrl: checkout.redirectUrl),
        };
      },
      loading: () => _WaitingView(redirectUrl: checkout.redirectUrl),
      error: (_, __) =>
          _FailedView(onRetry: () => setState(() => _checkout = null)),
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

class _SuccessView extends ConsumerWidget {
  const _SuccessView({required this.planName});

  final String planName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            '$planName is now active on your account. Your wristband is ready.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton(
            onPressed: () {
              // Home's providers were fetched before this purchase existed —
              // without invalidating, "Welcome back" would keep showing "No
              // active membership" until a manual pull-to-refresh.
              ref.invalidate(activeSubscriptionProvider);
              ref.invalidate(liveSessionProvider);
              context.go('/customer');
            },
            child: const Text('Back to Home'),
          ),
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
