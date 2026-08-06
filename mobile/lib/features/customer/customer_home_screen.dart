import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/branded_app_bar.dart';
import 'family/family_providers.dart';
import 'home_providers.dart';

class CustomerHomeScreen extends ConsumerWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);

    return Scaffold(
      appBar: const BrandedAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(currentProfileProvider);
          ref.invalidate(familyMembersProvider);
          ref.invalidate(activeSubscriptionProvider);
          ref.invalidate(liveSessionProvider);
          ref.invalidate(recentActivityProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _WelcomeCard(fullName: profile.value?.fullName ?? ''),
            const SizedBox(height: AppSpacing.sm),
            const _LiveSessionCard(),
            const SizedBox(height: AppSpacing.sm),
            _QuickActionTile(
              icon: Icons.confirmation_number_outlined,
              title: 'Buy Access Plan',
              subtitle: 'Top up or renew passes',
              onTap: () => context.go('/customer/plans'),
            ),
            const SizedBox(height: AppSpacing.base),
            _QuickActionTile(
              icon: Icons.auto_awesome_outlined,
              title: 'My Wristbands',
              subtitle: 'Manage device linkages',
              onTap: () => context.push('/customer/wristbands'),
            ),
            const SizedBox(height: AppSpacing.base),
            _QuickActionTile(
              icon: Icons.groups_outlined,
              title: 'My Family',
              subtitle: 'Add members or guests',
              onTap: () => context.go('/customer/family'),
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

class _WelcomeCard extends ConsumerWidget {
  const _WelcomeCard({required this.fullName});

  final String fullName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(activeSubscriptionProvider);
    final familyNames = ref.watch(
      familyMembersProvider.select(
        (v) => v.whenData((m) => m.map((e) => e.fullName).toList()),
      ),
    );
    final firstName = fullName.trim().isEmpty
        ? 'there'
        : fullName.trim().split(RegExp(r'\s+')).first;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    'Welcome back,\n$firstName',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppRadii.base),
                  ),
                  child: const Icon(Icons.eco_outlined, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              plan.when(
                data: (p) => p == null
                    ? 'No active membership'
                    : 'Membership: ${p.planName}',
                loading: () => ' ',
                error: (_, __) => 'No active membership',
              ),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            familyNames.when(
              data: (names) {
                if (names.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.base),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppRadii.standard),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.groups,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppSpacing.base),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Family Managed',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                '${names.join(' & ')} ${names.length == 1 ? 'is' : 'are'} with you',
                                style: Theme.of(context).textTheme.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go('/customer/family'),
                          child: const Text('Manage'),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveSessionCard extends ConsumerWidget {
  const _LiveSessionCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(liveSessionProvider);
    return session.when(
      data: (s) => s == null
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.only(bottom: 0),
              child: _LiveSessionContent(session: s),
            ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _LiveSessionContent extends StatefulWidget {
  const _LiveSessionContent({required this.session});

  final LiveSessionSummary session;

  @override
  State<_LiveSessionContent> createState() => _LiveSessionContentState();
}

class _LiveSessionContentState extends State<_LiveSessionContent> {
  late Timer _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = widget.session.plannedEndAt.difference(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(
        () =>
            _remaining = widget.session.plannedEndAt.difference(DateTime.now()),
      );
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.session.plannedEndAt
        .difference(widget.session.startedAt)
        .inSeconds;
    final elapsed = DateTime.now()
        .difference(widget.session.startedAt)
        .inSeconds;
    final progress = total <= 0 ? 1.0 : (elapsed / total).clamp(0.0, 1.0);
    final isOver = _remaining.isNegative;
    final clamped = isOver ? Duration.zero : _remaining;
    final minutes = clamped.inMinutes.toString().padLeft(2, '0');
    final seconds = (clamped.inSeconds % 60).toString().padLeft(2, '0');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(AppRadii.large),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppRadii.full),
            ),
            child: const Text(
              'LIVE PLAYING SESSION',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text('Time Remaining', style: TextStyle(color: Colors.white70)),
          Text(
            '$minutes:$seconds',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.base),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.full),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 4),
              Text(
                widget.session.zoneName,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(Icons.groups_outlined, size: 16, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                '${widget.session.peopleCount} People',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.large),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppRadii.base),
                ),
                child: Icon(icon, size: 22),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentActivityList extends ConsumerWidget {
  const _RecentActivityList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = ref.watch(recentActivityProvider);
    return activity.when(
      data: (items) {
        if (items.isEmpty) {
          return Text(
            'No recent activity yet.',
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
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: item.body != null ? Text(item.body!) : null,
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
        'Couldn\'t load recent activity.',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.error),
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
