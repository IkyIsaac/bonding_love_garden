import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/reservation.dart';
import '../../../core/models/subscription_summary.dart';
import '../../../core/theme/app_theme.dart';
import 'memberships_providers.dart';

/// Returns the booked Reservation on success, or null if the sheet was
/// dismissed without booking.
Future<Reservation?> showReservationBookingSheet(
  BuildContext context, {
  required SubscriptionSummary subscription,
}) {
  return showModalBottomSheet<Reservation?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _ReservationBookingSheet(subscription: subscription),
  );
}

class _ReservationBookingSheet extends ConsumerStatefulWidget {
  const _ReservationBookingSheet({required this.subscription});

  final SubscriptionSummary subscription;

  @override
  ConsumerState<_ReservationBookingSheet> createState() =>
      _ReservationBookingSheetState();
}

class _ReservationBookingSheetState
    extends ConsumerState<_ReservationBookingSheet> {
  ReservableItem? _selectedItem;
  DateTime? _slotStart;
  bool _booking = false;
  String? _error;

  static const _slotDuration = Duration(hours: 1);

  Future<void> _pickSlot(int maxAdvanceDays) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(Duration(days: maxAdvanceDays)),
      initialDate: now.add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (time == null) return;
    setState(
      () => _slotStart = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ),
    );
  }

  Future<void> _book() async {
    if (_selectedItem == null || _slotStart == null) {
      setState(() => _error = 'Pick a game and a time slot.');
      return;
    }
    setState(() {
      _booking = true;
      _error = null;
    });
    try {
      final reservation = await ref
          .read(reservationControllerProvider)
          .book(
            subscriptionId: widget.subscription.id,
            catalogItemId: _selectedItem!.id,
            catalogItemName: _selectedItem!.name,
            slotStart: _slotStart!,
            slotEnd: _slotStart!.add(_slotDuration),
          );
      if (!mounted) return;
      Navigator.of(context).pop(reservation);
    } catch (e) {
      setState(() {
        _booking = false;
        _error = e
            .toString()
            .replaceFirst('FunctionsHttpException(status: 409, details: ', '')
            .replaceFirst(RegExp(r'\)$'), '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(
      reservableItemsProvider(widget.subscription.accessPlanId),
    );
    final settings = ref.watch(reservationSettingsProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Reserve a Game',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Text(
                widget.subscription.planName,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),
              items.when(
                data: (list) {
                  if (list.isEmpty) {
                    return Text(
                      'This plan doesn\'t include any reservable games.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    );
                  }
                  return DropdownButtonFormField<ReservableItem>(
                    initialValue: _selectedItem,
                    decoration: const InputDecoration(labelText: 'Game'),
                    items: list
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(item.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedItem = v),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Text(
                  "Couldn't load games.",
                  style: TextStyle(color: AppColors.error),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              settings.when(
                data: (s) => OutlinedButton.icon(
                  onPressed: () => _pickSlot(s.maxAdvanceDays),
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(
                    _slotStart == null
                        ? 'Choose date & time (up to ${s.maxAdvanceDays} days ahead)'
                        : '${_slotStart!.day}/${_slotStart!.month}/${_slotStart!.year} at ${_slotStart!.hour.toString().padLeft(2, '0')}:${_slotStart!.minute.toString().padLeft(2, '0')}',
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: AppSpacing.sm),
              settings.when(
                data: (s) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Reservation fee',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      s.defaultFee > 0
                          ? s.defaultFee.toStringAsFixed(0)
                          : 'Free',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              Text(
                'This is on top of your membership — booking a specific time slot is a paid convenience, not included in the plan price.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(_error!, style: const TextStyle(color: AppColors.error)),
              ],
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: _booking ? null : _book,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.onSecondary,
                ),
                child: Text(_booking ? 'Booking…' : 'Book Reservation'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Called right after a successful booking — pays the fee inline (same
/// booking session, not a separate "pay later" revisit) via the same
/// checkout pipeline used for plans, or skips straight to a confirmation if
/// the fee is zero.
void handlePostBookingPayment(BuildContext context, Reservation reservation) {
  if (reservation.fee <= 0) {
    // A Dialog rather than a SnackBar — ScaffoldMessenger.of(context) inside
    // a StatefulShellRoute branch bubbles up to the shell's outer Scaffold
    // and renders clipped behind the bottom nav (see checkout's own note on
    // this same issue).
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reserved'),
        content: Text('${reservation.catalogItemName} is booked — no fee due.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    return;
  }
  context.push('/customer/reservations/pay', extra: reservation);
}
