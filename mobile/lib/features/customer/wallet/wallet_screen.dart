import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/credit_ledger_entry.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/branded_app_bar.dart';
import 'wallet_providers.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(familyCreditBalanceProvider);
    final ledger = ref.watch(creditLedgerProvider);

    return Scaffold(
      appBar: const BrandedAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(familyCreditBalanceProvider);
          ref.invalidate(creditLedgerProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text('Wallet', style: Theme.of(context).textTheme.headlineSmall),
            Text(
              'Your game credit balance and history.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadii.large),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Game Credit Balance',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: AppSpacing.base),
                  balance.when(
                    data: (b) => Text(
                      '$b',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    loading: () => const SizedBox(
                      height: 48,
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                    error: (_, __) => const Text(
                      '—',
                      style: TextStyle(color: Colors.white, fontSize: 48),
                    ),
                  ),
                  const Text(
                    'credits',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Redeem credits with staff at any game station — this app shows your balance and history, not a redeem button.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('History', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.base),
            ledger.when(
              data: (entries) {
                if (entries.isEmpty) {
                  return Text(
                    'No credit activity yet.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  );
                }
                return Column(
                  children: entries.map((e) => _LedgerTile(entry: e)).toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => Text(
                "Couldn't load history.",
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LedgerTile extends StatelessWidget {
  const _LedgerTile({required this.entry});

  final CreditLedgerEntry entry;

  @override
  Widget build(BuildContext context) {
    final isPositive =
        entry.direction == CreditDirection.earned ||
        (entry.direction == CreditDirection.adjusted && entry.amount > 0);
    final icon = switch (entry.direction) {
      CreditDirection.earned => Icons.add_circle_outline,
      CreditDirection.redeemed => Icons.remove_circle_outline,
      CreditDirection.adjusted => Icons.tune,
    };
    final label = switch (entry.direction) {
      CreditDirection.earned => 'Earned',
      CreditDirection.redeemed => 'Redeemed',
      CreditDirection.adjusted => 'Adjusted',
    };
    final color = isPositive ? AppColors.primary : AppColors.secondary;
    final amountLabel = '${isPositive ? '+' : '-'}${entry.amount.abs()}';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.base),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(label),
        subtitle: entry.reason != null
            ? Text(entry.reason!)
            : Text(_formatDate(entry.createdAt)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              amountLabel,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
            if (entry.reason != null)
              Text(
                _formatDate(entry.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';
}
