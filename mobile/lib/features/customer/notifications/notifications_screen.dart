import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/app_notification.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/branded_app_bar.dart';
import 'notifications_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: const BrandedAppBar(),
      body: notifications.when(
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.notifications_none,
                      size: 48,
                      color: AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'No notifications yet.',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            );
          }
          final unreadIds = list
              .where((n) => !n.isRead)
              .map((n) => n.id)
              .toList();
          return Column(
            children: [
              if (unreadIds.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    0,
                  ),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => ref
                          .read(notificationsControllerProvider)
                          .markAllRead(unreadIds),
                      child: const Text('Mark all as read'),
                    ),
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: list.length,
                  itemBuilder: (context, i) =>
                      _NotificationTile(notification: list[i]),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Text(
            "Couldn't load notifications.",
            style: TextStyle(color: AppColors.error),
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.notification});

  final AppNotification notification;

  static const Map<String, IconData> _iconByType = {
    'payment_confirmed': Icons.check_circle_outline,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final icon = _iconByType[notification.type] ?? Icons.notifications_outlined;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.base),
      color: notification.isRead
          ? null
          : AppColors.primaryContainer.withValues(alpha: 0.15),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: notification.isRead
              ? AppColors.surfaceVariant
              : AppColors.primaryContainer,
          child: Icon(
            icon,
            color: notification.isRead
                ? AppColors.onSurfaceVariant
                : AppColors.onPrimaryContainer,
            size: 20,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead
                ? FontWeight.normal
                : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (notification.body != null) Text(notification.body!),
            const SizedBox(height: 4),
            Text(
              _relativeTime(notification.createdAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: notification.isRead
            ? null
            : const Icon(Icons.circle, size: 10, color: AppColors.secondary),
        onTap: notification.isRead
            ? null
            : () => ref
                  .read(notificationsControllerProvider)
                  .markRead(notification.id),
      ),
    );
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
