import 'package:freezed_annotation/freezed_annotation.dart';

part 'reservation.freezed.dart';

/// `reservations` joined with catalog_items.name for display — a booked
/// time slot within an already-active subscription (reservations-book).
@freezed
abstract class Reservation with _$Reservation {
  const factory Reservation({
    required String id,
    required String subscriptionId,
    required String catalogItemName,
    required DateTime slotStart,
    required DateTime slotEnd,
    required double fee,
    required String status,
  }) = _Reservation;
}
