import 'package:freezed_annotation/freezed_annotation.dart';

part 'credit_ledger_entry.freezed.dart';

enum CreditDirection { earned, redeemed, adjusted }

CreditDirection _directionFromString(String value) {
  return CreditDirection.values.firstWhere(
    (d) => d.name == value,
    orElse: () => CreditDirection.adjusted,
  );
}

/// 1:1 with `game_credit_ledger` — append-only, so this is purely a read
/// model. Customers can only view; redemption is a staff-only action at a
/// physical game station (see wallet-redeem Edge Function), and "earning"
/// credits from a purchase isn't built yet (the conversion rule is
/// genuinely ambiguous — see that function's own header comment).
@freezed
abstract class CreditLedgerEntry with _$CreditLedgerEntry {
  const factory CreditLedgerEntry({
    required String id,
    required CreditDirection direction,
    required int amount,
    String? reason,
    required DateTime createdAt,
  }) = _CreditLedgerEntry;

  factory CreditLedgerEntry.fromJson(Map<String, dynamic> json) {
    return CreditLedgerEntry(
      id: json['id'] as String,
      direction: _directionFromString(json['direction'] as String),
      amount: json['amount'] as int,
      reason: json['reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
