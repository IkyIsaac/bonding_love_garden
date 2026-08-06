import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile.freezed.dart';

enum ProfileRole { customer, cashier, attendant, supervisor, admin }

ProfileRole profileRoleFromString(String value) {
  return ProfileRole.values.firstWhere(
    (r) => r.name == value,
    orElse: () => ProfileRole.customer,
  );
}

/// 1:1 with the `profiles` table (backend/supabase/migrations/…identity…sql).
/// Only the columns the app actually reads so far — extend as new screens
/// need more (photo_url, timestamps, ...).
@freezed
abstract class Profile with _$Profile {
  const factory Profile({
    required String id,
    required String phone,
    required String fullName,
    required ProfileRole role,
    required String approvalStatus,
  }) = _Profile;

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      phone: json['phone'] as String,
      fullName: json['full_name'] as String? ?? '',
      role: profileRoleFromString(json['role'] as String),
      approvalStatus: json['approval_status'] as String,
    );
  }
}
