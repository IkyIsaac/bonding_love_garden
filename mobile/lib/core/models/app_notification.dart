import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_notification.freezed.dart';

/// 1:1 with the `notifications` table. `type` is deliberately unconstrained
/// text server-side (new types don't need a migration) — the UI maps known
/// values to an icon/color and falls back to a generic bell for anything
/// else, rather than assuming the full set is known up front.
@freezed
abstract class AppNotification with _$AppNotification {
  const factory AppNotification({
    required String id,
    required String type,
    required String title,
    String? body,
    required bool isRead,
    required DateTime createdAt,
  }) = _AppNotification;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String?,
      isRead: json['is_read'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
