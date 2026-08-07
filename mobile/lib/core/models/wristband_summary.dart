import 'package:freezed_annotation/freezed_annotation.dart';

part 'wristband_summary.freezed.dart';

/// Derived from `wristband_live_status` (view) joined in Dart with
/// family_members/profiles for a display name — same hand-join pattern used
/// elsewhere in this app (home_providers.dart) rather than relying on
/// PostgREST embedding through a view.
@freezed
abstract class WristbandSummary with _$WristbandSummary {
  const factory WristbandSummary({
    required String id,
    required String wristbandNumber,
    required String qrCodeValue,
    required String liveStatus,
    required DateTime expiresAt,
    DateTime? lastScannedAt,
    required String beneficiaryName,
    required bool isAccountOwner,
  }) = _WristbandSummary;
}
