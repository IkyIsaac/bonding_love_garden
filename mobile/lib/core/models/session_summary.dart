import 'package:freezed_annotation/freezed_annotation.dart';

part 'session_summary.freezed.dart';

/// Derived from `session_live_status` (view) joined in Dart with
/// wristbands/family_members/catalog_items for display — same hand-join
/// pattern used by WristbandSummary rather than relying on PostgREST
/// embedding through the view.
@freezed
abstract class SessionSummary with _$SessionSummary {
  const factory SessionSummary({
    required String id,
    required String wristbandId,
    required String beneficiaryName,
    String? catalogItemName,
    required DateTime startedAt,
    required DateTime plannedEndAt,
    required String status,
    required int extendedMinutesTotal,
  }) = _SessionSummary;
}
