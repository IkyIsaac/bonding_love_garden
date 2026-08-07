import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/models/profile.dart';
import '../../../core/models/session_summary.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/branded_app_bar.dart';
import 'sessions_providers.dart';

class SessionsScreen extends ConsumerWidget {
  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(activeSessionsProvider);
    final profile = ref.watch(currentProfileProvider);
    final canManage =
        profile.value?.role == ProfileRole.supervisor ||
        profile.value?.role == ProfileRole.admin;

    return Scaffold(
      appBar: const BrandedAppBar(),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(activeSessionsProvider),
        child: sessions.when(
          data: (list) {
            if (list.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  Text(
                    'Active Sessions',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'No one is currently playing.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: list.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Text(
                      'Active Sessions',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  );
                }
                final session = list[index - 1];
                return _SessionCard(session: session, canManage: canManage);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(
            child: Text(
              "Couldn't load active sessions.",
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ),
      ),
    );
  }
}

class _SessionCard extends ConsumerStatefulWidget {
  const _SessionCard({required this.session, required this.canManage});

  final SessionSummary session;
  final bool canManage;

  @override
  ConsumerState<_SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends ConsumerState<_SessionCard> {
  late Timer _timer;
  late Duration _remaining;
  bool _busy = false;

  static const Map<String, Color> _statusColor = {
    'active': AppColors.primary,
    'expiring_soon': AppColors.statusOrange,
    'expired': AppColors.error,
  };

  @override
  void initState() {
    super.initState();
    _remaining = widget.session.plannedEndAt.difference(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      setState(
        () =>
            _remaining = widget.session.plannedEndAt.difference(DateTime.now()),
      );
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _extend() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(sessionActionsControllerProvider)
          .extend(widget.session.id, 15);
      ref.invalidate(activeSessionsProvider);
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _end() async {
    setState(() => _busy = true);
    try {
      await ref.read(sessionActionsControllerProvider).end(widget.session.id);
      ref.invalidate(activeSessionsProvider);
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(String message) {
    // A Dialog, not a SnackBar — ScaffoldMessenger bubbles up to the shell's
    // outer Scaffold inside a StatefulShellRoute branch and would render
    // clipped behind the bottom nav.
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Action failed'),
        content: Text(message),
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
    final session = widget.session;
    final color = _statusColor[session.status] ?? AppColors.onSurfaceVariant;
    final isOver = _remaining.isNegative;
    final clamped = isOver ? -_remaining : _remaining;
    final hours = clamped.inHours;
    final minutes = (clamped.inMinutes % 60);
    final timeLabel = hours > 0
        ? '${isOver ? '-' : ''}${hours}h ${minutes}m'
        : '${isOver ? '-' : ''}${minutes}m';

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
                    session.beneficiaryName,
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
                    session.status.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              session.catalogItemName ?? 'General admission',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(Icons.timer_outlined, size: 18, color: color),
                const SizedBox(width: 6),
                Text(
                  timeLabel,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (widget.canManage) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy ? null : _extend,
                      child: const Text('Extend +15m'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.base),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _busy ? null : _end,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: AppColors.onError,
                      ),
                      child: const Text('End'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
