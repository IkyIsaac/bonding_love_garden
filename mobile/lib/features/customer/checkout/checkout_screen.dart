import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/access_plan.dart';
import '../../../core/models/cart_pricing.dart';
import '../../../core/models/package_offer.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/branded_app_bar.dart';
import '../home_providers.dart';
import '../wallet/wallet_providers.dart';
import 'checkout_providers.dart';
import 'payment_status_view.dart';

/// Handles both an access_plan purchase and a package purchase — the two
/// diverge only in which preview/checkout call fires and what happens on
/// success (a plan activates a subscription; a package credits the wallet,
/// see checkout_providers.dart), so one screen with two optional
/// constructor params is less duplication than two near-identical screens.
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key, this.plan, this.package})
    : assert(
        (plan == null) != (package == null),
        'Provide exactly one of plan or package',
      );

  final AccessPlan? plan;
  final PackageOffer? package;

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  CheckoutResult? _checkout;
  bool _starting = false;
  String? _error;

  String get _itemId => widget.plan?.id ?? widget.package!.id;
  String get _itemName => widget.plan?.name ?? widget.package!.name;
  List<String> get _includedItemNames =>
      widget.plan?.includedItemNames ?? widget.package!.includedItemNames;
  bool get _isPackage => widget.package != null;

  Future<void> _pay() async {
    setState(() {
      _starting = true;
      _error = null;
    });
    try {
      final repository = ref.read(checkoutRepositoryProvider);
      final result = _isPackage
          ? await repository.startPackageCheckout(_itemId)
          : await repository.startCheckout(_itemId);
      setState(() => _checkout = result);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = _isPackage
        ? ref.watch(packageCheckoutPreviewProvider(_itemId))
        : ref.watch(checkoutPreviewProvider(_itemId));

    return Scaffold(
      appBar: const BrandedAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: _checkout == null
            ? _buildPreview(context, preview)
            : PaymentStatusView(
                checkout: _checkout!,
                successMessage: _isPackage
                    ? '$_itemName credits are in your wallet — show your wristband (or get one at the gate) to start playing.'
                    : '$_itemName is now active on your account. Your wristband is ready.',
                doneLabel: 'Back to Home',
                onDone: () {
                  // Home's/Wallet's providers were fetched before this purchase
                  // existed — without invalidating, they'd keep showing stale
                  // data until a manual pull-to-refresh (same fix as the plan
                  // path already needed for activeSubscriptionProvider).
                  if (_isPackage) {
                    ref.invalidate(familyCreditBalanceProvider);
                    ref.invalidate(creditLedgerProvider);
                  } else {
                    ref.invalidate(activeSubscriptionProvider);
                    ref.invalidate(liveSessionProvider);
                  }
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
          _itemName,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
        ),
        if (_includedItemNames.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text('Includes', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Wrap(
            spacing: AppSpacing.base,
            runSpacing: 4,
            children: _includedItemNames
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
        if (_isPackage) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Paid for up front as game credits — spend them on any of the games above, in any mix, next time you visit.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
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
                  _priceRow(context, _itemName, pricing.subtotal),
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
