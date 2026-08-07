import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription_summary.freezed.dart';

/// `subscriptions` joined with its access_plans.name — a customer's own
/// purchased memberships/passes, distinct from Plans (the browsable
/// catalog) and Checkout (buying a new one).
@freezed
abstract class SubscriptionSummary with _$SubscriptionSummary {
  const factory SubscriptionSummary({
    required String id,
    required String accessPlanId,
    required String planName,
    required String status,
    required DateTime startsAt,
    required DateTime endsAt,
    int? visitsRemaining,
  }) = _SubscriptionSummary;
}
