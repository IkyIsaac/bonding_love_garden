import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/branded_app_bar.dart';
import 'reports_providers.dart';

class StaffReportsScreen extends ConsumerWidget {
  const StaffReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(staffReportsProvider);

    return Scaffold(
      appBar: const BrandedAppBar(),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(staffReportsProvider),
        child: reports.when(
          data: (r) => _ReportsBody(summary: r),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Text('Reports', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: Text(
                  "Couldn't load reports.",
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportsBody extends StatelessWidget {
  const _ReportsBody({required this.summary});

  final StaffReportsSummary summary;

  static String fmt(double v) => v.toStringAsFixed(0);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text('Reports', style: Theme.of(context).textTheme.headlineSmall),
        Text(
          'Revenue, growth, and attendance at a glance.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.md),

        _SectionHeading(icon: Icons.payments_outlined, title: 'Financial'),
        const SizedBox(height: AppSpacing.base),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'TODAY',
                value: fmt(summary.revenue.today),
                background: AppColors.primary,
                foreground: AppColors.onPrimary,
              ),
            ),
            const SizedBox(width: AppSpacing.base),
            Expanded(
              child: _StatTile(
                label: 'THIS WEEK',
                value: fmt(summary.revenue.thisWeek),
                background: AppColors.surfaceVariant,
                foreground: AppColors.onSurface,
              ),
            ),
            const SizedBox(width: AppSpacing.base),
            Expanded(
              child: _StatTile(
                label: 'THIS MONTH',
                value: fmt(summary.revenue.thisMonth),
                background: AppColors.surfaceVariant,
                foreground: AppColors.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        _SectionHeading(
          icon: Icons.person_add_alt_1_outlined,
          title: 'New Customers',
        ),
        const SizedBox(height: AppSpacing.base),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'TODAY',
                value: '${summary.acquisition.newToday}',
                background: AppColors.secondary,
                foreground: AppColors.onSecondary,
              ),
            ),
            const SizedBox(width: AppSpacing.base),
            Expanded(
              child: _StatTile(
                label: 'THIS WEEK',
                value: '${summary.acquisition.newThisWeek}',
                background: AppColors.surfaceVariant,
                foreground: AppColors.onSurface,
              ),
            ),
            const SizedBox(width: AppSpacing.base),
            Expanded(
              child: _StatTile(
                label: 'THIS MONTH',
                value: '${summary.acquisition.newThisMonth}',
                background: AppColors.surfaceVariant,
                foreground: AppColors.onSurface,
              ),
            ),
          ],
        ),
        if (summary.acquisition.pendingApproval > 0) ...[
          const SizedBox(height: AppSpacing.base),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.tertiary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadii.standard),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.hourglass_empty,
                  color: AppColors.tertiary,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.base),
                Expanded(
                  child: Text(
                    '${summary.acquisition.pendingApproval} account${summary.acquisition.pendingApproval == 1 ? '' : 's'} waiting for approval',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),

        _SectionHeading(icon: Icons.repeat, title: 'Frequency & Attendance'),
        const SizedBox(height: AppSpacing.base),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'SESSIONS TODAY',
                value: '${summary.sessionsToday}',
                background: AppColors.surfaceVariant,
                foreground: AppColors.onSurface,
              ),
            ),
            const SizedBox(width: AppSpacing.base),
            Expanded(
              child: _StatTile(
                label: 'SESSIONS THIS WEEK',
                value: '${summary.sessionsThisWeek}',
                background: AppColors.surfaceVariant,
                foreground: AppColors.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.base),
        Text(
          'Top Families This Month',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.base),
        _RankedBarList(
          emptyMessage: 'No visits recorded yet this month.',
          items: summary.topFamiliesThisMonth
              .map(
                (f) => _RankedBarItem(
                  label: f.familyName,
                  value: f.visitCount.toDouble(),
                  valueLabel:
                      '${f.visitCount} visit${f.visitCount == 1 ? '' : 's'}',
                  color: AppColors.secondary,
                ),
              )
              .toList(),
        ),
        const SizedBox(height: AppSpacing.md),

        _SectionHeading(
          icon: Icons.confirmation_number_outlined,
          title: 'Top Plans by Revenue',
        ),
        const SizedBox(height: AppSpacing.base),
        _RankedBarList(
          emptyMessage: 'No plan sales yet.',
          items: summary.topPlans
              .map(
                (p) => _RankedBarItem(
                  label: p.name,
                  value: p.revenue,
                  valueLabel: p.revenue.toStringAsFixed(0),
                  color: AppColors.primary,
                ),
              )
              .toList(),
        ),
        const SizedBox(height: AppSpacing.md),

        _SectionHeading(
          icon: Icons.sports_esports_outlined,
          title: 'Most Popular Games',
        ),
        const SizedBox(height: AppSpacing.base),
        _RankedBarList(
          emptyMessage: 'No sessions recorded yet.',
          items: summary.popularGames
              .map(
                (g) => _RankedBarItem(
                  label: g.name,
                  value: g.sessionCount.toDouble(),
                  valueLabel:
                      '${g.sessionCount} session${g.sessionCount == 1 ? '' : 's'}',
                  color: AppColors.primary,
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: AppSpacing.base),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
      ],
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
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: foreground,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _RankedBarItem {
  const _RankedBarItem({
    required this.label,
    required this.value,
    required this.valueLabel,
    required this.color,
  });

  final String label;
  final double value;
  final String valueLabel;
  final Color color;
}

/// A ranked, proportional-bar list — the mobile equivalent of the web
/// admin's Reports DataTable rows (same visual language: label + thin
/// progress bar sized relative to the top value + a trailing number).
class _RankedBarList extends StatelessWidget {
  const _RankedBarList({required this.items, required this.emptyMessage});

  final List<_RankedBarItem> items;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text(
        emptyMessage,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
      );
    }
    final maxValue = items.map((i) => i.value).reduce((a, b) => a > b ? a : b);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          children: items
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.label,
                              style: Theme.of(context).textTheme.bodyMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.base),
                          Text(
                            item.valueLabel,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadii.full),
                        child: LinearProgressIndicator(
                          value: maxValue <= 0 ? 0 : item.value / maxValue,
                          minHeight: 5,
                          backgroundColor: AppColors.surfaceVariant,
                          valueColor: AlwaysStoppedAnimation(item.color),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
