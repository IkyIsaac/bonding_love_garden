import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_providers.dart';
import '../models/profile.dart';
import '../../features/customer/customer_home_screen.dart';
import '../../features/customer/customer_shell.dart';
import '../../features/customer/family/family_screen.dart';
import '../../features/customer/plans/plans_screen.dart';
import '../../features/shared/login_screen.dart';

/// Role gate (post sign-in, from `profiles.role`), per
/// docs/ARCHITECTURE_PLAN.md §5:
/// - customer -> CustomerShell (Home/Family/Plans/Wallet)
/// - cashier/attendant/supervisor -> StaffShell (Home/Scanner/Sessions/Reports)
/// - admin -> not expected to auth here; shown a "use the web dashboard" screen
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(
      ref.watch(authRepositoryProvider).onAuthStateChange,
    ),
    redirect: (context, state) async {
      final loggingIn = state.matchedLocation == '/login';
      final session = ref.read(authRepositoryProvider).currentSession;

      if (session == null) {
        return loggingIn ? null : '/login';
      }

      final profile = await ref.read(currentProfileProvider.future);
      if (profile == null) {
        // profiles row not visible yet (handle_new_user hasn't landed) —
        // refreshListenable re-runs this once currentProfileProvider settles.
        return null;
      }

      if (!loggingIn) return null;

      return switch (profile.role) {
        ProfileRole.customer => '/customer',
        ProfileRole.admin => '/admin-only',
        ProfileRole.cashier ||
        ProfileRole.attendant ||
        ProfileRole.supervisor => '/staff',
      };
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/admin-only',
        builder: (context, state) => const _AdminOnlyScreen(),
      ),
      GoRoute(
        path: '/staff',
        builder: (context, state) =>
            const _NotYetBuiltScreen(title: 'Staff app'),
      ),
      GoRoute(
        path: '/customer/wristbands',
        builder: (context, state) =>
            const _NotYetBuiltScreen(title: 'Wristbands'),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            CustomerShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/customer',
                builder: (context, state) => const CustomerHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/customer/family',
                builder: (context, state) => const FamilyScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/customer/plans',
                builder: (context, state) => const PlansScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/customer/wallet',
                builder: (context, state) =>
                    const _NotYetBuiltScreen(title: 'Wallet'),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class _AdminOnlyScreen extends ConsumerWidget {
  const _AdminOnlyScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Admin accounts use the web dashboard, not this app.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => ref.read(authRepositoryProvider).signOut(),
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotYetBuiltScreen extends StatelessWidget {
  const _NotYetBuiltScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title — not yet implemented.')),
    );
  }
}

/// Converts a Stream into a Listenable so go_router's `refreshListenable`
/// re-evaluates `redirect` on every auth state change.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
