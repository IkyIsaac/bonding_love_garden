import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/models/app_notification.dart';

/// Realtime rather than a one-shot fetch — notifications is already in the
/// supabase_realtime publication (added alongside sessions, before orders
/// joined it for checkout), and a live-updating list means a notification
/// that arrives while this screen (or just the bell badge) is open shows up
/// with no manual refresh, same reasoning as orderStatusProvider's stream.
/// Sorted client-side rather than via `.stream().order(...)` to avoid
/// depending on realtime-stream ordering support.
final notificationsProvider = StreamProvider<List<AppNotification>>((
  ref,
) async* {
  final client = ref.watch(supabaseClientProvider);
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile == null) {
    yield [];
    return;
  }
  yield* client
      .from('notifications')
      .stream(primaryKey: ['id'])
      .eq('recipient_profile_id', profile.id)
      .map((rows) {
        final list = rows.map(AppNotification.fromJson).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider);
  return notifications.maybeWhen(
    data: (list) => list.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});

class NotificationsController {
  NotificationsController(this._client);

  final SupabaseClient _client;

  Future<void> markRead(String id) async {
    await _client.from('notifications').update({'is_read': true}).eq('id', id);
  }

  Future<void> markAllRead(List<String> ids) async {
    if (ids.isEmpty) return;
    await _client
        .from('notifications')
        .update({'is_read': true})
        .inFilter('id', ids);
  }
}

final notificationsControllerProvider = Provider<NotificationsController>((
  ref,
) {
  return NotificationsController(ref.watch(supabaseClientProvider));
});
