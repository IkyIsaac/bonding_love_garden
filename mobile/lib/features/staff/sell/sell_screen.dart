import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/access_plan.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/branded_app_bar.dart';
import '../../customer/plans/plans_providers.dart';
import '../customers/customer_search_providers.dart';

/// Plan picker for a staff-assisted sale — same catalog data as the
/// customer app's Plans tab (accessPlansProvider/packagesProvider are
/// world-readable), but every "Sell" action checks out on behalf of
/// [customer] via channel: staff_app rather than the caller's own family.
class SellScreen extends ConsumerStatefulWidget {
  const SellScreen({super.key, required this.customer});

  final CustomerMatch customer;

  @override
  ConsumerState<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends ConsumerState<SellScreen> {
  AccessPlanType _selectedType = AccessPlanType.singleVisit;

  void _showPackagesNotSupported() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Not available yet'),
        content: const Text(
          'Selling a package isn\'t supported yet — packages don\'t issue a subscription/wristband on payment (a known backend gap). Sell an access plan instead.',
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
    final entryFee = ref.watch(entryFeeProvider);

    return Scaffold(
      appBar: const BrandedAppBar(),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(
            'Sell Access Plan',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(
            'Selling to ${widget.customer.fullName} (${widget.customer.phone})',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
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
            onSelectionChanged: (s) => setState(() => _selectedType = s.first),
          ),
          const SizedBox(height: AppSpacing.sm),
          plans.when(
            data: (list) {
              final filtered = list
                  .where((p) => p.planType == _selectedType)
                  .toList();
              if (filtered.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Text(
                    'No plans available right now.',
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
                      (p) => _SellPlanCard(
                        plan: p,
                        entryFee: entryFee.value,
                        onSell: () => context.push(
                          '/staff/sell/checkout',
                          extra: (customer: widget.customer, plan: p),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Text(
              "Couldn't load access plans.",
              style: TextStyle(color: AppColors.error),
            ),
          ),
          const SizedBox(height: AppSpacing.base),
          TextButton(
            onPressed: _showPackagesNotSupported,
            child: const Text('Looking for a package instead?'),
          ),
        ],
      ),
    );
  }
}

class _SellPlanCard extends StatelessWidget {
  const _SellPlanCard({
    required this.plan,
    required this.entryFee,
    required this.onSell,
  });

  final AccessPlan plan;
  final double? entryFee;
  final VoidCallback onSell;

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
            const SizedBox(height: AppSpacing.sm),
            ElevatedButton.icon(
              onPressed: onSell,
              icon: const Icon(Icons.point_of_sale_outlined),
              label: const Text('Sell'),
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
