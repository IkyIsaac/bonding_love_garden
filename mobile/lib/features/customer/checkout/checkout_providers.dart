import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/models/cart_pricing.dart';

/// Read-only price preview for a single access_plan purchase, via
/// discount-preview (backend/supabase/functions/discount-preview) — same
/// pricing pipeline checkout-create-order uses, just without persisting an
/// order. familyId is omitted: for the customer_app channel the backend
/// resolves it from the caller's own session, never from client input.
final checkoutPreviewProvider = FutureProvider.family<CartPricing, String>((
  ref,
  accessPlanId,
) async {
  final client = ref.watch(supabaseClientProvider);
  final response = await client.functions.invoke(
    'discount-preview',
    body: {
      'channel': 'customer_app',
      'includeEntryFee': true,
      'items': [
        {'itemType': 'access_plan', 'accessPlanId': accessPlanId},
      ],
    },
  );
  return CartPricing.fromJson(response.data as Map<String, dynamic>);
});

class CheckoutResult {
  const CheckoutResult({
    required this.orderId,
    required this.paymentId,
    this.redirectUrl,
  });

  final String orderId;
  final String paymentId;
  final String? redirectUrl;
}

/// Orchestrates checkout-create-order -> payments-initiate, mirroring
/// exactly what a real payment flow does: create a pending order, then ask
/// the chosen provider (Selcom) to start a transaction against it. What
/// happens after — the customer completing payment on Selcom's own hosted
/// page, and Selcom calling back via payments-webhook-selcom — happens
/// outside this app entirely; CheckoutScreen watches the order's status via
/// Realtime rather than polling for a result here.
class CheckoutRepository {
  CheckoutRepository(this._client);

  final SupabaseClient _client;

  Future<CheckoutResult> startCheckout(String accessPlanId) {
    return _createOrderAndInitiate(
      items: [
        {'itemType': 'access_plan', 'accessPlanId': accessPlanId},
      ],
      includeEntryFee: true,
    );
  }

  /// Reservation fees aren't part of the discount engine's composition (see
  /// cart-pricing.ts's computeCartPricing — only access_plan/package lines
  /// feed evaluateDiscounts), and the customer already has an active
  /// subscription by the time they're booking a reservation, so this never
  /// re-charges the entry fee.
  Future<CheckoutResult> startReservationFeeCheckout(String reservationId) {
    return _createOrderAndInitiate(
      items: [
        {'itemType': 'reservation_fee', 'reservationId': reservationId},
      ],
      includeEntryFee: false,
    );
  }

  Future<CheckoutResult> _createOrderAndInitiate({
    required List<Map<String, Object?>> items,
    required bool includeEntryFee,
  }) async {
    final orderResponse = await _client.functions.invoke(
      'checkout-create-order',
      body: {
        'channel': 'customer_app',
        'includeEntryFee': includeEntryFee,
        'items': items,
      },
    );
    final orderData = orderResponse.data as Map<String, dynamic>;
    final order = orderData['order'] as Map<String, dynamic>;
    final orderId = order['id'] as String;

    final paymentResponse = await _client.functions.invoke(
      'payments-initiate',
      body: {'orderId': orderId, 'providerCode': 'selcom'},
    );
    final paymentData = paymentResponse.data as Map<String, dynamic>;

    return CheckoutResult(
      orderId: orderId,
      paymentId: paymentData['paymentId'] as String,
      redirectUrl: paymentData['redirectUrl'] as String?,
    );
  }
}

final checkoutRepositoryProvider = Provider<CheckoutRepository>((ref) {
  return CheckoutRepository(ref.watch(supabaseClientProvider));
});

/// Live order status ('pending' -> 'paid' | 'failed'), via Realtime rather
/// than polling — orders_select's RLS (owns_family) applies to the stream
/// the same as any other query.
final orderStatusProvider = StreamProvider.family<String, String>((
  ref,
  orderId,
) {
  final client = ref.watch(supabaseClientProvider);
  return client.from('orders').stream(primaryKey: ['id']).eq('id', orderId).map(
    (rows) {
      if (rows.isEmpty) return 'pending';
      return rows.first['status'] as String;
    },
  );
});
