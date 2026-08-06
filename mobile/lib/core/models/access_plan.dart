import 'package:freezed_annotation/freezed_annotation.dart';

part 'access_plan.freezed.dart';

enum AccessPlanType { singleVisit, membership }

AccessPlanType _planTypeFromString(String value) {
  return value == 'membership'
      ? AccessPlanType.membership
      : AccessPlanType.singleVisit;
}

/// 1:1 with `access_plans`, plus includedItemCount which is derived from a
/// separate access_plan_items query (see plans_providers.dart) rather than
/// stored on the row.
@freezed
abstract class AccessPlan with _$AccessPlan {
  const factory AccessPlan({
    required String id,
    required String name,
    required AccessPlanType planType,
    required double price,
    required int validityValue,
    required String validityUnit,
    int? visitLimit,
    String? description,
    required int includedItemCount,
  }) = _AccessPlan;

  factory AccessPlan.fromJson(
    Map<String, dynamic> json, {
    required int includedItemCount,
  }) {
    return AccessPlan(
      id: json['id'] as String,
      name: json['name'] as String,
      planType: _planTypeFromString(json['plan_type'] as String),
      price: (json['price'] as num).toDouble(),
      validityValue: json['validity_value'] as int,
      validityUnit: json['validity_unit'] as String,
      visitLimit: json['visit_limit'] as int?,
      description: json['description'] as String?,
      includedItemCount: includedItemCount,
    );
  }
}
