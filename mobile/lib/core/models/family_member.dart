import 'package:freezed_annotation/freezed_annotation.dart';

part 'family_member.freezed.dart';

enum FamilyMemberKind { child, dependentAdult }

FamilyMemberKind _kindFromString(String value) {
  return value == 'dependent_adult' ? FamilyMemberKind.dependentAdult : FamilyMemberKind.child;
}

String kindToColumnValue(FamilyMemberKind kind) {
  return kind == FamilyMemberKind.dependentAdult ? 'dependent_adult' : 'child';
}

/// 1:1 with the `family_members` table. Deliberately no delete support in
/// this app — family_members_delete is admin-only by design (RLS), so the
/// customer app only ever adds or edits.
@freezed
abstract class FamilyMember with _$FamilyMember {
  const factory FamilyMember({
    required String id,
    required String fullName,
    required FamilyMemberKind kind,
    int? age,
    String? gender,
    String? allergiesNotes,
    String? generalNotes,
    required bool isPrimaryChild,
  }) = _FamilyMember;

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      kind: _kindFromString(json['kind'] as String),
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      allergiesNotes: json['allergies_notes'] as String?,
      generalNotes: json['general_notes'] as String?,
      isPrimaryChild: json['is_primary_child'] as bool? ?? false,
    );
  }
}
