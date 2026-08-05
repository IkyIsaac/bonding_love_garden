import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Route tree skeleton. Once core/auth exists, the redirect callback below
/// will branch on the signed-in profile's role: `customer` -> CustomerShell
/// (Home/Family/Plans/Wallet), staff roles -> StaffShell (Home/Scanner/
/// Sessions/Reports), `admin` -> redirect out (web dashboard only, per
/// docs/ARCHITECTURE_PLAN.md §5).
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const _ScaffoldPlaceholder(title: 'Bonding Love Garden'),
    ),
  ],
);

class _ScaffoldPlaceholder extends StatelessWidget {
  const _ScaffoldPlaceholder({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Center(
        child: Text('Scaffold placeholder — not yet implemented.'),
      ),
    );
  }
}
