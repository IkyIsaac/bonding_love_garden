import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/customer/notifications/notifications_providers.dart';
import '../auth/auth_providers.dart';
import '../auth/otp_controller.dart';
import '../models/profile.dart';
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
        child: InkWell(
          onTap: () => _showAccountSheet(context, ref, profile.value),
          customBorder: const CircleBorder(),
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
      ),
      title: Text(venue.value?.parkName ?? 'Bonding Love Garden'),
      actions: [_NotificationsBell(profile: profile)],
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

/// Customer-only: BrandedAppBar is shared with the staff shell too, and
/// there's no staff notifications inbox screen to send a tap to (staff's own
/// purchase-alert notifications, written via notifySupervisorsOfPurchase,
/// aren't surfaced anywhere in the app yet) — so non-customer roles just get
/// the plain inert bell this widget always showed before.
class _NotificationsBell extends ConsumerWidget {
  const _NotificationsBell({required this.profile});

  final AsyncValue<Profile?> profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (profile.value?.role != ProfileRole.customer) {
      return IconButton(
        icon: const Icon(Icons.notifications_outlined),
        onPressed: () {},
      );
    }

    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return IconButton(
      icon: Badge(
        isLabelVisible: unreadCount > 0,
        label: Text('$unreadCount'),
        child: const Icon(Icons.notifications_outlined),
      ),
      onPressed: () => context.push('/customer/notifications'),
    );
  }
}

/// Tapping the avatar (the one element present on every screen, customer and
/// staff alike) is the account entry point — there was previously no sign-out
/// affordance anywhere in the mobile app at all.
void _showAccountSheet(BuildContext context, WidgetRef ref, Profile? profile) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Container(
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  profile?.fullName.isNotEmpty == true
                      ? profile!.fullName
                      : 'My Account',
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(sheetContext).pop(),
              ),
            ],
          ),
          if (profile != null) ...[
            Text(
              profile.phone,
              style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            Text(
              _roleLabel(profile.role),
              style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(sheetContext).pop();
              ref.read(authRepositoryProvider).signOut();
              // otpControllerProvider isn't scoped to the auth session — its
              // state (which step, the phone number, and critically a
              // deliberately-never-cleared `loading: true` left over from
              // the *last successful verify*) otherwise survives sign-out
              // untouched. Without this, landing back on /login re-renders
              // that stale post-verify state instead of a fresh phone-entry
              // screen — the login form appears permanently stuck on
              // "Verifying…" even though nothing is actually in flight.
              ref.invalidate(otpControllerProvider);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
            ),
            icon: const Icon(Icons.logout),
            label: const Text('Sign Out'),
          ),
        ],
      ),
    ),
  );
}

String _roleLabel(ProfileRole role) {
  switch (role) {
    case ProfileRole.customer:
      return 'Customer';
    case ProfileRole.cashier:
      return 'Cashier';
    case ProfileRole.attendant:
      return 'Attendant';
    case ProfileRole.supervisor:
      return 'Supervisor';
    case ProfileRole.admin:
      return 'Admin';
  }
}
