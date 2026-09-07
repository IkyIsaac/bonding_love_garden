import 'package:freezed_annotation/freezed_annotation.dart';

part 'package_offer.freezed.dart';

/// 1:1 with `packages`, plus includedItemNames which is derived from a
/// separate package_items -> catalog_items join (see plans_providers.dart)
/// rather than stored on the row — formatted as "4x Bounce Zone" (quantity
/// prefixed) since, unlike an access plan's included games, a package's
/// items carry a meaningful quantity (see backend's game_credit_ledger
/// crediting logic, which sums these same quantities into a credit total).
@freezed
abstract class PackageOffer with _$PackageOffer {
  const factory PackageOffer({
    required String id,
    required String name,
    String? description,
    required double price,
    DateTime? availabilityStart,
    DateTime? availabilityEnd,
    required List<String> includedItemNames,
  }) = _PackageOffer;

  factory PackageOffer.fromJson(
    Map<String, dynamic> json, {
    List<String> includedItemNames = const [],
  }) {
    return PackageOffer(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      availabilityStart: json['availability_start'] == null
          ? null
          : DateTime.parse(json['availability_start'] as String),
      availabilityEnd: json['availability_end'] == null
          ? null
          : DateTime.parse(json['availability_end'] as String),
      includedItemNames: includedItemNames,
    );
  }
}
