import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/family_member.dart';
import '../../../core/models/subscription_summary.dart';
import '../../../core/models/wristband_summary.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/branded_app_bar.dart';
import 'customer_detail_providers.dart';
import 'customer_search_providers.dart';

/// A read-only staff lookup of one family's members, memberships, and
/// wristbands — the "staff Memberships" capability from
/// docs/ARCHITECTURE_PLAN.md §5, and the entry point into Sell (staff needs
/// to identify who they're selling to before picking a plan).
class CustomerDetailScreen extends ConsumerWidget {
  const CustomerDetailScreen({super.key, required this.customer});

  final CustomerMatch customer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(
      familyMembersByFamilyIdProvider(customer.familyId),
    );
    final subscriptions = ref.watch(
      subscriptionsByFamilyIdProvider(customer.familyId),
    );
    final wristbands = ref.watch(
      wristbandsByFamilyIdProvider(customer.familyId),
    );

    return Scaffold(
      appBar: const BrandedAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(familyMembersByFamilyIdProvider(customer.familyId));
          ref.invalidate(subscriptionsByFamilyIdProvider(customer.familyId));
          ref.invalidate(wristbandsByFamilyIdProvider(customer.familyId));
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(
              customer.fullName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              customer.phone,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ElevatedButton.icon(
              onPressed: () => context.push('/staff/sell', extra: customer),
              icon: const Icon(Icons.point_of_sale_outlined),
              label: const Text('Sell Access Plan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.onSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Family Members',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.base),
            members.when(
              data: (list) => _FamilyMembersList(members: list),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Text(
                "Couldn't load family members.",
                style: TextStyle(color: AppColors.error),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Memberships', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.base),
            subscriptions.when(
              data: (list) => _SubscriptionsList(subscriptions: list),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Text(
                "Couldn't load memberships.",
                style: TextStyle(color: AppColors.error),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Wristbands', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.base),
            wristbands.when(
              data: (list) => _WristbandsList(wristbands: list),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Text(
                "Couldn't load wristbands.",
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FamilyMembersList extends StatelessWidget {
  const _FamilyMembersList({required this.members});

  final List<FamilyMember> members;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return Text(
        'No family members added.',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
      );
    }
    return Column(
      children: members
          .map(
            (m) => Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.base),
              child: ListTile(
                title: Text(m.fullName),
                subtitle: Text(
                  m.kind == FamilyMemberKind.child
                      ? 'Child${m.age != null ? ' · ${m.age} years old' : ''}'
                      : 'Dependent adult',
                ),
                trailing:
                    m.allergiesNotes != null && m.allergiesNotes!.isNotEmpty
                    ? const Icon(
                        Icons.warning_amber_outlined,
                        color: AppColors.tertiary,
                      )
                    : null,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _SubscriptionsList extends StatelessWidget {
  const _SubscriptionsList({required this.subscriptions});

  final List<SubscriptionSummary> subscriptions;

  @override
  Widget build(BuildContext context) {
    if (subscriptions.isEmpty) {
      return Text(
        'No memberships yet.',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
      );
    }
    return Column(
      children: subscriptions
          .map(
            (s) => Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.base),
              child: ListTile(
                title: Text(s.planName),
                subtitle: Text(
                  '${s.status.replaceAll('_', ' ')} · valid until ${_formatDate(s.endsAt)}',
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  String _formatDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';
}

class _WristbandsList extends StatelessWidget {
  const _WristbandsList({required this.wristbands});

  final List<WristbandSummary> wristbands;

  @override
  Widget build(BuildContext context) {
    if (wristbands.isEmpty) {
      return Text(
        'No wristbands issued.',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
      );
    }
    return Column(
      children: wristbands
          .map(
            (w) => Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.base),
              child: ListTile(
                title: Text(w.beneficiaryName),
                subtitle: Text('${w.wristbandNumber} · ${w.liveStatus}'),
              ),
            ),
          )
          .toList(),
    );
  }
}
