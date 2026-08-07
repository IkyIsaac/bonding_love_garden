import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/access_plan.dart';
import '../../../core/models/cart_pricing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/branded_app_bar.dart';
import '../../customer/checkout/checkout_providers.dart';
import '../../customer/checkout/payment_status_view.dart';
import '../customers/customer_detail_providers.dart';
import '../customers/customer_search_providers.dart';
import 'sell_checkout_providers.dart';

class SellCheckoutScreen extends ConsumerStatefulWidget {
  const SellCheckoutScreen({
    super.key,
    required this.customer,
    required this.plan,
  });

  final CustomerMatch customer;
  final AccessPlan plan;

  @override
  ConsumerState<SellCheckoutScreen> createState() => _SellCheckoutScreenState();
}

class _SellCheckoutScreenState extends ConsumerState<SellCheckoutScreen> {
  CheckoutResult? _checkout;
  bool _starting = false;
  String? _error;

  Future<void> _charge() async {
    setState(() {
      _starting = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(sellCheckoutRepositoryProvider)
          .startPlanSale(
            familyId: widget.customer.familyId,
            accessPlanId: widget.plan.id,
          );
      setState(() => _checkout = result);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = ref.watch(
      sellPreviewProvider((
        familyId: widget.customer.familyId,
        accessPlanId: widget.plan.id,
      )),
    );

    return Scaffold(
      appBar: const BrandedAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: _checkout == null
            ? _buildPreview(context, preview)
            : PaymentStatusView(
                checkout: _checkout!,
                successMessage:
                    '${widget.plan.name} is now active for ${widget.customer.fullName}. Their wristband is ready.',
                doneLabel: 'Done',
                onDone: () {
                  ref.invalidate(
                    subscriptionsByFamilyIdProvider(widget.customer.familyId),
                  );
                  ref.invalidate(
                    wristbandsByFamilyIdProvider(widget.customer.familyId),
                  );
                  context.pop();
                  context.pop();
                },
                onRetry: () => setState(() => _checkout = null),
              ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context, AsyncValue<CartPricing> preview) {
    return ListView(
      children: [
        Text('Confirm Sale', style: Theme.of(context).textTheme.headlineSmall),
        Text(
          '${widget.plan.name} for ${widget.customer.fullName}',
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
        Text(
          'The customer completes payment on their own phone (Selcom) — this starts that request.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_error != null) ...[
          Text(_error!, style: const TextStyle(color: AppColors.error)),
          const SizedBox(height: AppSpacing.sm),
        ],
        ElevatedButton.icon(
          onPressed: _starting || !preview.hasValue ? null : _charge,
          icon: _starting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.onSecondary,
                  ),
                )
              : const Icon(Icons.point_of_sale_outlined),
          label: Text(_starting ? 'Starting…' : 'Charge with Selcom'),
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
