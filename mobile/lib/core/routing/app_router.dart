import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_providers.dart';
import '../models/access_plan.dart';
import '../models/profile.dart';
import '../models/reservation.dart';
import '../../features/customer/checkout/checkout_screen.dart';
import '../../features/customer/customer_home_screen.dart';
import '../../features/customer/customer_shell.dart';
import '../../features/customer/family/family_screen.dart';
import '../../features/customer/memberships/memberships_screen.dart';
import '../../features/customer/memberships/reservation_payment_screen.dart';
import '../../features/customer/notifications/notifications_screen.dart';
import '../../features/customer/plans/plans_screen.dart';
import '../../features/customer/wallet/wallet_screen.dart';
import '../../features/customer/wristbands/wristbands_screen.dart';
import '../../features/shared/login_screen.dart';
import '../../features/staff/customers/customer_detail_screen.dart';
import '../../features/staff/customers/customer_lookup_screen.dart';
import '../../features/staff/customers/customer_search_providers.dart';
import '../../features/staff/home/staff_home_screen.dart';
import '../../features/staff/registration/registration_screen.dart';
import '../../features/staff/reports/staff_reports_screen.dart';
import '../../features/staff/scanner/scanner_screen.dart';
import '../../features/staff/sell/sell_checkout_screen.dart';
import '../../features/staff/sell/sell_screen.dart';
import '../../features/staff/sessions/sessions_screen.dart';
import '../../features/staff/staff_shell.dart';

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
        path: '/customer/wristbands',
        builder: (context, state) => const WristbandsScreen(),
      ),
      GoRoute(
        path: '/customer/checkout',
        builder: (context, state) =>
            CheckoutScreen(plan: state.extra as AccessPlan),
      ),
      GoRoute(
        path: '/customer/memberships',
        builder: (context, state) => const MembershipsScreen(),
      ),
      GoRoute(
        path: '/customer/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/customer/reservations/pay',
        builder: (context, state) =>
            ReservationPaymentScreen(reservation: state.extra as Reservation),
      ),
      GoRoute(
        path: '/staff/registration',
        builder: (context, state) => const RegistrationScreen(),
      ),
      GoRoute(
        path: '/staff/customers',
        builder: (context, state) => const CustomerLookupScreen(),
      ),
      GoRoute(
        path: '/staff/customers/detail',
        builder: (context, state) =>
            CustomerDetailScreen(customer: state.extra as CustomerMatch),
      ),
      GoRoute(
        path: '/staff/sell',
        builder: (context, state) =>
            SellScreen(customer: state.extra as CustomerMatch),
      ),
      GoRoute(
        path: '/staff/sell/checkout',
        builder: (context, state) {
          final args =
              state.extra as ({CustomerMatch customer, AccessPlan plan});
          return SellCheckoutScreen(customer: args.customer, plan: args.plan);
        },
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
                builder: (context, state) => const WalletScreen(),
              ),
            ],
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            StaffShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/staff',
                builder: (context, state) => const StaffHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/staff/scanner',
                builder: (context, state) => const ScannerScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/staff/sessions',
                builder: (context, state) => const SessionsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/staff/reports',
                builder: (context, state) => const StaffReportsScreen(),
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
