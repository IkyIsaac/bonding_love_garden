import 'package:freezed_annotation/freezed_annotation.dart';

part 'venue_settings.freezed.dart';

/// 1:1 with the `venue_settings` singleton row — deliberately not
/// hardcoding the venue name/logo anywhere in the app (brief §1); this is
/// the one runtime-configurable branding surface for app chrome.
@freezed
abstract class VenueSettings with _$VenueSettings {
  const factory VenueSettings({required String parkName, String? logoUrl}) = _VenueSettings;

  factory VenueSettings.fromJson(Map<String, dynamic> json) {
    return VenueSettings(parkName: json['park_name'] as String, logoUrl: json['logo_url'] as String?);
  }
}
