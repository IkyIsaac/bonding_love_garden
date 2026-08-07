import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/branded_app_bar.dart';
import 'staff_home_providers.dart';

class StaffHomeScreen extends ConsumerWidget {
  const StaffHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    final firstName = (profile.value?.fullName ?? '').trim().isEmpty
        ? 'there'
        : profile.value!.fullName.trim().split(RegExp(r'\s+')).first;

    return Scaffold(
      appBar: const BrandedAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(staffHomeStatsProvider);
          ref.invalidate(staffRecentActivityProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(
              'Good to see you, $firstName',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              "Here's what's happening at the park.",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const _StatsRow(),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.base),
            ElevatedButton.icon(
              onPressed: () => context.go('/staff/scanner'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.qr_code_scanner_outlined),
              label: const Text('Scan QR Code'),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.base),
            const _RecentActivityList(),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends ConsumerWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(staffHomeStatsProvider);
    return stats.when(
      data: (s) => Row(
        children: [
          Expanded(
            child: _StatTile(
              label: 'ACTIVE VISITORS',
              value: '${s.activeGuestCount}',
              background: AppColors.primary,
              foreground: AppColors.onPrimary,
            ),
          ),
          const SizedBox(width: AppSpacing.base),
          Expanded(
            child: _StatTile(
              label: 'EXPIRING SOON',
              value: '${s.expiringSoonCount}',
              background: s.expiringSoonCount > 0
                  ? AppColors.tertiary
                  : AppColors.surfaceVariant,
              foreground: s.expiringSoonCount > 0
                  ? Colors.white
                  : AppColors.onSurface,
            ),
          ),
        ],
      ),
      loading: () => const SizedBox(
        height: 90,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Text(
        "Couldn't load park stats.",
        style: TextStyle(color: AppColors.error),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.background,
    required this.foreground,
  });

  final String label;
  final String value;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.large),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: foreground.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: foreground,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentActivityList extends ConsumerWidget {
  const _RecentActivityList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = ref.watch(staffRecentActivityProvider);
    return activity.when(
      data: (items) {
        if (items.isEmpty) {
          return Text(
            'No check-ins yet today.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
          );
        }
        return Column(
          children: items
              .map(
                (item) => Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.base),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.primaryContainer,
                      child: Icon(
                        Icons.check,
                        color: AppColors.onPrimaryContainer,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      'Admitted ${item.beneficiaryName}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: Text(
                      _relativeTime(item.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (_, __) => Text(
        "Couldn't load recent activity.",
        style: TextStyle(color: AppColors.error),
      ),
    );
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
