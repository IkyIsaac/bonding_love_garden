import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/models/family_member.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/branded_app_bar.dart';
import 'family_providers.dart';
import 'member_form_sheet.dart';

class FamilyScreen extends ConsumerWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    final members = ref.watch(familyMembersProvider);

    return Scaffold(
      appBar: const BrandedAppBar(),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(familyMembersProvider),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('My Family', style: Theme.of(context).textTheme.headlineSmall),
                      Text(
                        'Manage your family group and guest profiles.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton.icon(
                  onPressed: () => showMemberFormSheet(context, existing: null),
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.secondary, foregroundColor: AppColors.onSecondary),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _OwnerCard(fullName: profile.value?.fullName ?? '', phone: profile.value?.phone ?? ''),
            const SizedBox(height: AppSpacing.base),
            members.when(
              data: (list) {
                if (list.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: Text(
                      'No family members added yet. Add a child or dependent adult to bring them along on your visits.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return Column(children: list.map((m) => _MemberCard(member: m)).toList());
              },
              loading: () => const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
              error: (_, __) => Text(
                "Couldn't load family members.",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OwnerCard extends StatelessWidget {
  const _OwnerCard({required this.fullName, required this.phone});

  final String fullName;
  final String phone;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primaryContainer,
              child: Text(_initials(fullName), style: const TextStyle(color: AppColors.onPrimaryContainer, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fullName.isEmpty ? 'You' : fullName, style: Theme.of(context).textTheme.titleMedium),
                  Text('Account Owner · $phone', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts[0][0];
    final second = parts.length > 1 ? parts[1][0] : '';
    return (first + second).toUpperCase();
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.member});

  final FamilyMember member;

  @override
  Widget build(BuildContext context) {
    final kindLabel = member.kind == FamilyMemberKind.child ? 'Child' : 'Dependent Adult';
    final ageLabel = member.age != null ? '$kindLabel · ${member.age} Years Old' : kindLabel;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.base),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.surfaceVariant,
              child: Text(member.fullName.isNotEmpty ? member.fullName[0].toUpperCase() : '?'),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(child: Text(member.fullName, style: Theme.of(context).textTheme.titleMedium)),
                      if (member.isPrimaryChild) ...[
                        const SizedBox(width: AppSpacing.base),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(AppRadii.full)),
                          child: const Text('Primary Child', style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    ],
                  ),
                  Text(ageLabel, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant)),
                  if (member.allergiesNotes != null && member.allergiesNotes!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.base),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.errorContainer, borderRadius: BorderRadius.circular(AppRadii.full)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.onErrorContainer),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              member.allergiesNotes!,
                              style: const TextStyle(fontSize: 11, color: AppColors.onErrorContainer),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton(
                    onPressed: () => showMemberFormSheet(context, existing: member),
                    child: Text(member.kind == FamilyMemberKind.child ? 'Edit Child' : 'Edit Profile'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
