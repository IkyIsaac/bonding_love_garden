import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';

/// Bottom-nav shell for the customer experience: Home / Family / Plans /
/// Wallet, per docs/ARCHITECTURE_PLAN.md §5 and the customer_app_home_dashboard
/// mockup. Each tab keeps its own navigation stack (StatefulShellRoute).
class CustomerShell extends StatelessWidget {
  const CustomerShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        indicatorColor: AppColors.secondary,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppColors.onSecondary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups, color: AppColors.onSecondary),
            label: 'Family',
          ),
          NavigationDestination(
            icon: Icon(Icons.confirmation_number_outlined),
            selectedIcon: Icon(
              Icons.confirmation_number,
              color: AppColors.onSecondary,
            ),
            label: 'Plans',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(
              Icons.account_balance_wallet,
              color: AppColors.onSecondary,
            ),
            label: 'Wallet',
          ),
        ],
      ),
    );
  }
}
