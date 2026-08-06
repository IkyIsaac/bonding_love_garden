import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/family/current_family_provider.dart';
import '../../../core/models/family_member.dart';

final familyMembersProvider = FutureProvider<List<FamilyMember>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final familyId = await ref.watch(currentFamilyIdProvider.future);
  final rows = await client
      .from('family_members')
      .select()
      .eq('family_id', familyId)
      .order('created_at');
  return rows.map(FamilyMember.fromJson).toList();
});

class FamilyController {
  FamilyController(this.ref);

  final Ref ref;

  Future<void> addMember({
    required String fullName,
    required FamilyMemberKind kind,
    int? age,
    String? gender,
    String? allergiesNotes,
    String? generalNotes,
  }) async {
    final client = ref.read(supabaseClientProvider);
    final familyId = await ref.read(currentFamilyIdProvider.future);
    await client.from('family_members').insert({
      'family_id': familyId,
      'full_name': fullName,
      'kind': kindToColumnValue(kind),
      'age': age,
      'gender': gender,
      'allergies_notes': allergiesNotes,
      'general_notes': generalNotes,
    });
    ref.invalidate(familyMembersProvider);
  }

  Future<void> updateMember({
    required String id,
    required String fullName,
    required FamilyMemberKind kind,
    int? age,
    String? gender,
    String? allergiesNotes,
    String? generalNotes,
  }) async {
    final client = ref.read(supabaseClientProvider);
    await client
        .from('family_members')
        .update({
          'full_name': fullName,
          'kind': kindToColumnValue(kind),
          'age': age,
          'gender': gender,
          'allergies_notes': allergiesNotes,
          'general_notes': generalNotes,
        })
        .eq('id', id);
    ref.invalidate(familyMembersProvider);
  }
}

final familyControllerProvider = Provider<FamilyController>(
  (ref) => FamilyController(ref),
);
