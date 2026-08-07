import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/family/current_family_provider.dart';
import '../../../core/models/reservation.dart';
import '../../../core/models/subscription_summary.dart';

final familySubscriptionsProvider = FutureProvider<List<SubscriptionSummary>>((
  ref,
) async {
  final client = ref.watch(supabaseClientProvider);
  final familyId = await ref.watch(currentFamilyIdProvider.future);

  final rows = await client
      .from('subscriptions')
      .select(
        'id, access_plan_id, status, starts_at, ends_at, visits_remaining, access_plans(name)',
      )
      .eq('family_id', familyId)
      .order('ends_at', ascending: false);

  return rows.map((r) {
    final plan = r['access_plans'] as Map<String, dynamic>?;
    return SubscriptionSummary(
      id: r['id'] as String,
      accessPlanId: r['access_plan_id'] as String,
      planName: plan?['name'] as String? ?? 'Unknown plan',
      status: r['status'] as String,
      startsAt: DateTime.parse(r['starts_at'] as String),
      endsAt: DateTime.parse(r['ends_at'] as String),
      visitsRemaining: r['visits_remaining'] as int?,
    );
  }).toList();
});

class ReservableItem {
  const ReservableItem({required this.id, required this.name});

  final String id;
  final String name;
}

/// Games/services a subscription's plan actually includes — reservations
/// can only be booked for one of these (reservations-book enforces the
/// same rule server-side via access_plan_items).
final reservableItemsProvider =
    FutureProvider.family<List<ReservableItem>, String>((
      ref,
      accessPlanId,
    ) async {
      final client = ref.watch(supabaseClientProvider);
      final itemRows = await client
          .from('access_plan_items')
          .select('catalog_item_id')
          .eq('access_plan_id', accessPlanId);
      final catalogItemIds = itemRows
          .map((r) => r['catalog_item_id'] as String)
          .toList();
      if (catalogItemIds.isEmpty) return [];

      final catalogRows = await client
          .from('catalog_items')
          .select('id, name')
          .inFilter('id', catalogItemIds)
          .eq('is_active', true);
      return catalogRows
          .map(
            (r) => ReservableItem(
              id: r['id'] as String,
              name: r['name'] as String,
            ),
          )
          .toList();
    });

class ReservationSettings {
  const ReservationSettings({
    required this.maxAdvanceDays,
    required this.defaultFee,
  });

  final int maxAdvanceDays;
  final double defaultFee;
}

final reservationSettingsProvider = FutureProvider<ReservationSettings>((
  ref,
) async {
  final client = ref.watch(supabaseClientProvider);
  final row = await client
      .from('reservation_settings')
      .select('max_advance_days, default_fee')
      .single();
  return ReservationSettings(
    maxAdvanceDays: row['max_advance_days'] as int,
    defaultFee: (row['default_fee'] as num).toDouble(),
  );
});

/// All of the family's reservations across every subscription, most recent
/// slot first — reservations doesn't carry family_id directly, so this
/// fetches subscription ids for the family first (mirrors the pattern used
/// for liveSessionProvider's wristband-id lookup in home_providers.dart).
final familyReservationsProvider = FutureProvider<List<Reservation>>((
  ref,
) async {
  final client = ref.watch(supabaseClientProvider);
  final familyId = await ref.watch(currentFamilyIdProvider.future);

  final subRows = await client
      .from('subscriptions')
      .select('id')
      .eq('family_id', familyId);
  final subscriptionIds = subRows.map((r) => r['id'] as String).toList();
  if (subscriptionIds.isEmpty) return [];

  final rows = await client
      .from('reservations')
      .select(
        'id, subscription_id, catalog_item_id, slot_start, slot_end, fee, status, catalog_items(name)',
      )
      .inFilter('subscription_id', subscriptionIds)
      .order('slot_start', ascending: false);

  return rows.map((r) {
    final item = r['catalog_items'] as Map<String, dynamic>?;
    return Reservation(
      id: r['id'] as String,
      subscriptionId: r['subscription_id'] as String,
      catalogItemName: item?['name'] as String? ?? 'Unknown game',
      slotStart: DateTime.parse(r['slot_start'] as String),
      slotEnd: DateTime.parse(r['slot_end'] as String),
      fee: (r['fee'] as num).toDouble(),
      status: r['status'] as String,
    );
  }).toList();
});

/// Books a slot via reservations-book rather than a raw insert against the
/// customer-writable RLS policy — the Edge Function is what enforces
/// lead-time and per-day-cap rules, which RLS can't express (see that
/// function's own header comment).
class ReservationController {
  ReservationController(this._client);

  final SupabaseClient _client;

  Future<Reservation> book({
    required String subscriptionId,
    required String catalogItemId,
    required String catalogItemName,
    required DateTime slotStart,
    required DateTime slotEnd,
  }) async {
    final response = await _client.functions.invoke(
      'reservations-book',
      body: {
        'channel': 'customer_app',
        'subscriptionId': subscriptionId,
        'catalogItemId': catalogItemId,
        'slotStart': slotStart.toIso8601String(),
        'slotEnd': slotEnd.toIso8601String(),
      },
    );
    final data = response.data as Map<String, dynamic>;
    final r = data['reservation'] as Map<String, dynamic>;
    return Reservation(
      id: r['id'] as String,
      subscriptionId: r['subscription_id'] as String,
      catalogItemName: catalogItemName,
      slotStart: DateTime.parse(r['slot_start'] as String),
      slotEnd: DateTime.parse(r['slot_end'] as String),
      fee: (r['fee'] as num).toDouble(),
      status: r['status'] as String,
    );
  }
}

final reservationControllerProvider = Provider<ReservationController>((ref) {
  return ReservationController(ref.watch(supabaseClientProvider));
});
