import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/models/cart_pricing.dart';
import '../../customer/checkout/checkout_providers.dart';

/// Staff-initiated twin of the customer app's checkoutPreviewProvider/
/// CheckoutRepository — same discount-preview / checkout-create-order /
/// payments-initiate pipeline, just with channel: 'staff_app' and an
/// explicit familyId (resolveFamilyId requires it for that channel, since
/// staff act on behalf of a family rather than their own). The customer
/// still pays with their own phone at the counter — this reuses the real
/// online-gateway flow rather than inventing a separate cash-settlement
/// path, per the same Selcom pipeline already proven for customer checkout.
final sellPreviewProvider =
    FutureProvider.family<
      CartPricing,
      ({String familyId, String accessPlanId})
    >((ref, params) async {
      final client = ref.watch(supabaseClientProvider);
      final response = await client.functions.invoke(
        'discount-preview',
        body: {
          'channel': 'staff_app',
          'familyId': params.familyId,
          'includeEntryFee': true,
          'items': [
            {'itemType': 'access_plan', 'accessPlanId': params.accessPlanId},
          ],
        },
      );
      return CartPricing.fromJson(response.data as Map<String, dynamic>);
    });

class SellCheckoutRepository {
  SellCheckoutRepository(this._client);

  final SupabaseClient _client;

  Future<CheckoutResult> startPlanSale({
    required String familyId,
    required String accessPlanId,
  }) async {
    final orderResponse = await _client.functions.invoke(
      'checkout-create-order',
      body: {
        'channel': 'staff_app',
        'familyId': familyId,
        'includeEntryFee': true,
        'items': [
          {'itemType': 'access_plan', 'accessPlanId': accessPlanId},
        ],
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

final sellCheckoutRepositoryProvider = Provider<SellCheckoutRepository>((ref) {
  return SellCheckoutRepository(ref.watch(supabaseClientProvider));
});
