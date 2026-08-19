import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/access_plan.dart';
import '../../../core/models/cart_pricing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/branded_app_bar.dart';
import '../home_providers.dart';
import 'checkout_providers.dart';
import 'payment_status_view.dart';

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
            : PaymentStatusView(
                checkout: _checkout!,
                successMessage:
                    '${widget.plan.name} is now active on your account. Your wristband is ready.',
                doneLabel: 'Back to Home',
                onDone: () {
                  // Home's providers were fetched before this purchase existed —
                  // without invalidating, "Welcome back" would keep showing "No
                  // active membership" until a manual pull-to-refresh.
                  ref.invalidate(activeSubscriptionProvider);
                  ref.invalidate(liveSessionProvider);
                  context.go('/customer');
                },
                onRetry: () => setState(() => _checkout = null),
              ),
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
        if (widget.plan.includedItemNames.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text('Includes', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Wrap(
            spacing: AppSpacing.base,
            runSpacing: 4,
            children: widget.plan.includedItemNames
                .map(
                  (name) => Chip(
                    label: Text(name),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: AppColors.surfaceVariant,
                  ),
                )
                .toList(),
          ),
        ],
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
}
