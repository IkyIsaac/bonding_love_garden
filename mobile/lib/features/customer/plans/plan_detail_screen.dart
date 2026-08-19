import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/access_plan.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/branded_app_bar.dart';
import 'plans_providers.dart';

/// Shown between the Plans list and Checkout — lets a customer see exactly
/// what a plan includes before committing to buy it, rather than finding
/// out only after paying. Reached via "View Plan" (not "Buy"/"Select") on
/// the plans list, since this screen itself is the browsing step; the real
/// purchase commitment happens on the button here.
class PlanDetailScreen extends ConsumerWidget {
  const PlanDetailScreen({super.key, required this.plan});

  final AccessPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entryFee = ref.watch(entryFeeProvider);

    return Scaffold(
      appBar: const BrandedAppBar(),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(plan.name, style: Theme.of(context).textTheme.headlineSmall),
          if (plan.description != null && plan.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              plan.description!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Price',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        plan.price.toStringAsFixed(0),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  entryFee.when(
                    data: (fee) => fee != null && fee > 0
                        ? Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '+ ${fee.toStringAsFixed(0)} entry fee applies',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.onSurfaceVariant),
                            ),
                          )
                        : const SizedBox.shrink(),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const Divider(height: AppSpacing.md),
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
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            "What's Included",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.base),
          if (plan.includedItemNames.isEmpty)
            Text(
              'No games or services are bundled with this plan.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            )
          else
            Card(
              child: Column(
                children: plan.includedItemNames
                    .map(
                      (name) => ListTile(
                        leading: const Icon(
                          Icons.check_circle_outline,
                          color: AppColors.primary,
                        ),
                        title: Text(name),
                      ),
                    )
                    .toList(),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton.icon(
            onPressed: () => context.push('/customer/checkout', extra: plan),
            icon: const Icon(Icons.lock_outline),
            label: const Text('Buy This Plan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.onSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
