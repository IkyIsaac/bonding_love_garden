import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/access_plan.dart';
import '../../../core/models/package_offer.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/branded_app_bar.dart';
import 'plans_providers.dart';

class PlansScreen extends ConsumerStatefulWidget {
  const PlansScreen({super.key});

  @override
  ConsumerState<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends ConsumerState<PlansScreen> {
  AccessPlanType _selectedType = AccessPlanType.singleVisit;

  void _showCheckoutComingSoon() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Coming soon'),
        content: const Text(
          'Checkout isn\'t built yet — you can browse plans, but purchasing is a future step.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plans = ref.watch(accessPlansProvider);
    final packages = ref.watch(packagesProvider);
    final entryFee = ref.watch(entryFeeProvider);

    return Scaffold(
      appBar: const BrandedAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(accessPlansProvider);
          ref.invalidate(packagesProvider);
          ref.invalidate(entryFeeProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(
              'Access Plans',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              'Choose your path to fun in the park.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SegmentedButton<AccessPlanType>(
              segments: const [
                ButtonSegment(
                  value: AccessPlanType.singleVisit,
                  label: Text('Single Visit'),
                ),
                ButtonSegment(
                  value: AccessPlanType.membership,
                  label: Text('Memberships'),
                ),
              ],
              selected: {_selectedType},
              onSelectionChanged: (s) =>
                  setState(() => _selectedType = s.first),
            ),
            const SizedBox(height: AppSpacing.sm),
            plans.when(
              data: (list) {
                final filtered = list
                    .where((p) => p.planType == _selectedType)
                    .toList();
                if (filtered.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.lg,
                    ),
                    child: Text(
                      _selectedType == AccessPlanType.singleVisit
                          ? 'No single-visit plans available right now.'
                          : 'No memberships available right now.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return Column(
                  children: filtered
                      .map(
                        (p) => _PlanCard(
                          plan: p,
                          entryFee: entryFee.value,
                          onSelect: () =>
                              context.push('/customer/plans/detail', extra: p),
                        ),
                      )
                      .toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => Text(
                "Couldn't load access plans.",
                style: TextStyle(color: AppColors.error),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Packages & Offers',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.base),
            packages.when(
              data: (list) {
                if (list.isEmpty) {
                  return Text(
                    'No packages available right now.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  );
                }
                return SizedBox(
                  height: 150,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: list.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: AppSpacing.base),
                    itemBuilder: (context, i) => _PackageCard(
                      package: list[i],
                      onSelect: _showCheckoutComingSoon,
                    ),
                  ),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (_, __) => Text(
                "Couldn't load packages.",
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.entryFee,
    required this.onSelect,
  });

  final AccessPlan plan;
  final double? entryFee;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.base),
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
                    plan.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      plan.price.toStringAsFixed(0),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (entryFee != null && entryFee! > 0)
                      const Text(
                        '+ Entry Fee applies',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            if (plan.description != null && plan.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                plan.description!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  'Valid for ${plan.validityValue} ${plan.validityUnit}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.base),
            if (plan.includedItemNames.isEmpty)
              Row(
                children: [
                  const Icon(
                    Icons.sports_esports_outlined,
                    size: 16,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'No games/services bundled',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              )
            else
              Wrap(
                spacing: AppSpacing.base,
                runSpacing: 4,
                children: [
                  ...plan.includedItemNames
                      .take(3)
                      .map((name) => _IncludedItemChip(name: name)),
                  if (plan.includedItemNames.length > 3)
                    _IncludedItemChip(
                      name: '+${plan.includedItemNames.length - 3} more',
                    ),
                ],
              ),
            if (plan.visitLimit != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.confirmation_number_outlined,
                    size: 16,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${plan.visitLimit} visits',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            ElevatedButton.icon(
              onPressed: onSelect,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('View Plan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.onSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IncludedItemChip extends StatelessWidget {
  const _IncludedItemChip({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadii.full),
      ),
      child: Text(name, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({required this.package, required this.onSelect});

  final PackageOffer package;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        child: InkWell(
          onTap: onSelect,
          borderRadius: BorderRadius.circular(AppRadii.large),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (package.availabilityEnd != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(AppRadii.full),
                    ),
                    child: Text(
                      'Ends ${_relativeEnd(package.availabilityEnd!)}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.onSecondaryContainer,
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.base),
                Text(
                  package.name,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (package.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    package.description!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const Spacer(),
                Text(
                  package.price.toStringAsFixed(0),
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: AppColors.secondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _relativeEnd(DateTime end) {
    final days = end.difference(DateTime.now()).inDays;
    if (days <= 0) return 'today';
    if (days == 1) return 'tomorrow';
    return 'in $days days';
  }
}
