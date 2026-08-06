import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/family_member.dart';
import '../../../core/theme/app_theme.dart';
import 'family_providers.dart';

Future<void> showMemberFormSheet(
  BuildContext context, {
  required FamilyMember? existing,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _MemberFormSheet(existing: existing),
  );
}

class _MemberFormSheet extends ConsumerStatefulWidget {
  const _MemberFormSheet({required this.existing});

  final FamilyMember? existing;

  @override
  ConsumerState<_MemberFormSheet> createState() => _MemberFormSheetState();
}

class _MemberFormSheetState extends ConsumerState<_MemberFormSheet> {
  late final _nameController = TextEditingController(
    text: widget.existing?.fullName ?? '',
  );
  late final _ageController = TextEditingController(
    text: widget.existing?.age?.toString() ?? '',
  );
  late final _allergiesController = TextEditingController(
    text: widget.existing?.allergiesNotes ?? '',
  );
  late final _notesController = TextEditingController(
    text: widget.existing?.generalNotes ?? '',
  );
  late FamilyMemberKind _kind = widget.existing?.kind ?? FamilyMemberKind.child;
  String? _gender;

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _gender = widget.existing?.gender;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _allergiesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Full name is required');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final age = int.tryParse(_ageController.text.trim());
    final allergies = _allergiesController.text.trim();
    final notes = _notesController.text.trim();
    try {
      final controller = ref.read(familyControllerProvider);
      if (widget.existing == null) {
        await controller.addMember(
          fullName: name,
          kind: _kind,
          age: age,
          gender: _gender,
          allergiesNotes: allergies.isEmpty ? null : allergies,
          generalNotes: notes.isEmpty ? null : notes,
        );
      } else {
        await controller.updateMember(
          id: widget.existing!.id,
          fullName: name,
          kind: _kind,
          age: age,
          gender: _gender,
          allergiesNotes: allergies.isEmpty ? null : allergies,
          generalNotes: notes.isEmpty ? null : notes,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _saving = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.large),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isEditing ? 'Member Details' : 'Add Family Member',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),
              SegmentedButton<FamilyMemberKind>(
                segments: const [
                  ButtonSegment(
                    value: FamilyMemberKind.child,
                    label: Text('Child'),
                  ),
                  ButtonSegment(
                    value: FamilyMemberKind.dependentAdult,
                    label: Text('Dependent Adult'),
                  ),
                ],
                selected: {_kind},
                onSelectionChanged: (s) => setState(() => _kind = s.first),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        hintText: 'e.g. Leo Jenkins',
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Age',
                        hintText: 'Years',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text('Gender', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: AppSpacing.base),
              Wrap(
                spacing: AppSpacing.base,
                children: [
                  for (final option in const [
                    ('male', 'Male'),
                    ('female', 'Female'),
                    ('other', 'Other'),
                  ])
                    ChoiceChip(
                      label: Text(option.$2),
                      selected: _gender == option.$1,
                      onSelected: (selected) =>
                          setState(() => _gender = selected ? option.$1 : null),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _allergiesController,
                decoration: const InputDecoration(
                  labelText: 'Allergies',
                  hintText: 'e.g. Peanut allergy',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                ),
                maxLines: 2,
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(_error!, style: const TextStyle(color: AppColors.error)),
              ],
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: AppColors.onSecondary,
                      ),
                      child: Text(_saving ? 'Saving…' : 'Save Member'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
