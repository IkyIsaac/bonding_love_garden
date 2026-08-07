import 'package:freezed_annotation/freezed_annotation.dart';

part 'cart_pricing.freezed.dart';

/// Mirrors discount-preview / checkout-create-order's response shape
/// (backend/supabase/functions/_shared/cart-pricing.ts) — both share the
/// exact same pricing pipeline, so this model works for either response.
@freezed
abstract class CartPricing with _$CartPricing {
  const factory CartPricing({
    required double subtotal,
    required double discountTotal,
    required double entryFeeTotal,
    required double totalAmount,
  }) = _CartPricing;

  factory CartPricing.fromJson(Map<String, dynamic> json) {
    return CartPricing(
      subtotal: (json['subtotal'] as num).toDouble(),
      discountTotal: (json['discountTotal'] as num).toDouble(),
      entryFeeTotal: (json['entryFeeTotal'] as num).toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
    );
  }
}
