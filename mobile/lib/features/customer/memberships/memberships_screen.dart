import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/reservation.dart';
import '../../../core/models/subscription_summary.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/branded_app_bar.dart';
import 'memberships_providers.dart';
import 'reservation_booking_sheet.dart';

class MembershipsScreen extends ConsumerWidget {
  const MembershipsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptions = ref.watch(familySubscriptionsProvider);
    final reservations = ref.watch(familyReservationsProvider);

    return Scaffold(
      appBar: const BrandedAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(familySubscriptionsProvider);
          ref.invalidate(familyReservationsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(
              'My Memberships',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              'Your purchased plans and passes.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            subscriptions.when(
              data: (list) {
                if (list.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.lg,
                    ),
                    child: Text(
                      'No memberships yet. Buy an access plan to get started.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return Column(
                  children: list
                      .map(
                        (s) => _SubscriptionCard(
                          subscription: s,
                          onReserve: s.status == 'active'
                              ? () async {
                                  final reservation =
                                      await showReservationBookingSheet(
                                        context,
                                        subscription: s,
                                      );
                                  if (reservation != null && context.mounted) {
                                    handlePostBookingPayment(
                                      context,
                                      reservation,
                                    );
                                  }
                                }
                              : null,
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
                "Couldn't load memberships.",
                style: TextStyle(color: AppColors.error),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'My Reservations',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.base),
            reservations.when(
              data: (list) {
                if (list.isEmpty) {
                  return Text(
                    'No reservations booked yet.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  );
                }
                return Column(
                  children: list
                      .map((r) => _ReservationTile(reservation: r))
                      .toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => Text(
                "Couldn't load reservations.",
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({required this.subscription, this.onReserve});

  final SubscriptionSummary subscription;
  final VoidCallback? onReserve;

  static const Map<String, Color> _statusColor = {
    'active': AppColors.primary,
    'expired': AppColors.onSurfaceVariant,
    'cancelled': AppColors.error,
    'suspended': AppColors.tertiary,
    'pending_payment': AppColors.tertiary,
  };

  @override
  Widget build(BuildContext context) {
    final color =
        _statusColor[subscription.status] ?? AppColors.onSurfaceVariant;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.base),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    subscription.planName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadii.full),
                  ),
                  child: Text(
                    subscription.status.replaceAll('_', ' '),
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.base),
            Text(
              'Valid ${_formatDate(subscription.startsAt)} → ${_formatDate(subscription.endsAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (subscription.visitsRemaining != null) ...[
              const SizedBox(height: 4),
              Text(
                '${subscription.visitsRemaining} visits remaining',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (onReserve != null) ...[
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: onReserve,
                icon: const Icon(Icons.event_available_outlined),
                label: const Text('Reserve a Game'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';
}

class _ReservationTile extends StatelessWidget {
  const _ReservationTile({required this.reservation});

  final Reservation reservation;

  static const Map<String, Color> _statusColor = {
    'booked': AppColors.primary,
    'checked_in': AppColors.primary,
    'cancelled': AppColors.error,
    'no_show': AppColors.error,
  };

  @override
  Widget build(BuildContext context) {
    final color =
        _statusColor[reservation.status] ?? AppColors.onSurfaceVariant;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.base),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(Icons.event_outlined, color: color, size: 20),
        ),
        title: Text(reservation.catalogItemName),
        subtitle: Text(
          '${_formatDateTime(reservation.slotStart)} · Fee: ${reservation.fee.toStringAsFixed(0)}',
        ),
        trailing: Text(
          reservation.status.replaceAll('_', ' '),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
