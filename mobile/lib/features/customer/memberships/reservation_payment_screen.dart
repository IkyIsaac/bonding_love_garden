import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/reservation.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/branded_app_bar.dart';
import '../checkout/checkout_providers.dart';
import '../checkout/payment_status_view.dart';
import 'memberships_providers.dart';

/// Pays a reservation's fee — started automatically right after booking
/// (see reservation_booking_sheet.dart), not something a customer revisits
/// later for an older reservation, since nothing in the schema tracks
/// per-reservation payment status after the fact.
class ReservationPaymentScreen extends ConsumerStatefulWidget {
  const ReservationPaymentScreen({super.key, required this.reservation});

  final Reservation reservation;

  @override
  ConsumerState<ReservationPaymentScreen> createState() =>
      _ReservationPaymentScreenState();
}

class _ReservationPaymentScreenState
    extends ConsumerState<ReservationPaymentScreen> {
  CheckoutResult? _checkout;
  bool _starting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _pay();
  }

  Future<void> _pay() async {
    setState(() {
      _starting = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(checkoutRepositoryProvider)
          .startReservationFeeCheckout(widget.reservation.id);
      setState(() => _checkout = result);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BrandedAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: _checkout == null
            ? _buildStarting(context)
            : _buildPaying(context, _checkout!),
      ),
    );
  }

  Widget _buildStarting(BuildContext context) {
    return Column(
      children: [
        Text(
          'Reservation Fee',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text(
          '${widget.reservation.catalogItemName} · ${widget.reservation.fee.toStringAsFixed(0)}',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.md),
        if (_starting) const Center(child: CircularProgressIndicator()),
        if (_error != null) ...[
          Text(_error!, style: const TextStyle(color: AppColors.error)),
          const SizedBox(height: AppSpacing.sm),
          ElevatedButton(onPressed: _pay, child: const Text('Try again')),
        ],
      ],
    );
  }

  Widget _buildPaying(BuildContext context, CheckoutResult checkout) {
    return PaymentStatusView(
      checkout: checkout,
      successMessage:
          'Your reservation for ${widget.reservation.catalogItemName} is confirmed.',
      doneLabel: 'Done',
      onDone: () {
        ref.invalidate(familyReservationsProvider);
        context.go('/customer/memberships');
      },
      onRetry: () => setState(() => _checkout = null),
    );
  }
}
