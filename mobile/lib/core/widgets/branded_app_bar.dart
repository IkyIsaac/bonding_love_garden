import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import '../theme/app_theme.dart';
import '../venue/venue_providers.dart';

/// The avatar + venue name + notification bell header every customer shell
/// tab shares (see the Stitch mockups — identical across Home/Family/...).
/// Per-screen headings ("My Family", "Today at a glance") live in each
/// screen's body, not here.
class BrandedAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const BrandedAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    final venue = ref.watch(venueSettingsProvider);

    return AppBar(
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: CircleAvatar(
          backgroundColor: AppColors.primaryContainer,
          child: Text(
            _initials(profile.value?.fullName ?? ''),
            style: const TextStyle(
              color: AppColors.onPrimaryContainer,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      title: Text(venue.value?.parkName ?? 'Bonding Love Garden'),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {},
        ),
      ],
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    final first = parts[0][0];
    final second = parts.length > 1 ? parts[1][0] : '';
    return (first + second).toUpperCase();
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
