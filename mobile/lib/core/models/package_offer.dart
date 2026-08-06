import 'package:freezed_annotation/freezed_annotation.dart';

part 'package_offer.freezed.dart';

/// 1:1 with `packages` — the fields the browsing screen shows.
@freezed
abstract class PackageOffer with _$PackageOffer {
  const factory PackageOffer({
    required String id,
    required String name,
    String? description,
    required double price,
    DateTime? availabilityStart,
    DateTime? availabilityEnd,
  }) = _PackageOffer;

  factory PackageOffer.fromJson(Map<String, dynamic> json) {
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
    );
  }
}
