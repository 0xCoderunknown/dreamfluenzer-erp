import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../config/agency_config.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common/shell_widgets.dart';

class ShellScreen extends StatelessWidget {
  final Widget child;

  const ShellScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Row(
        children: [
          const _SideNav(),
          Container(width: 1, color: Colors.grey.shade200),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _SideNav extends StatelessWidget {
  const _SideNav();

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    return Container(
      width: 240,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const NavBranding(),
          const Divider(height: 1),
          const SizedBox(height: 12),

          _sectionLabel('MAIN MENU'),
          NavItem(
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard_rounded,
            label: 'Dashboard',
            route: '/dashboard',
            isActive: location.startsWith('/dashboard'),
          ),
          NavItem(
            icon: Icons.pause_presentation,
            activeIcon: Icons.pause_presentation,
            label: 'Leads',
            route: '/leads',
            isActive:
                location.startsWith('/leads') ||
                location.startsWith('/proposal_engine'),
          ),
          NavItem(
            icon: Icons.people_outline_rounded,
            activeIcon: Icons.people_rounded,
            label: 'Creators',
            route: '/creators',
            isActive: location.startsWith('/creators'),
          ),
          NavItem(
            icon: Icons.business_outlined,
            activeIcon: Icons.business_rounded,
            label: 'Clients',
            route: '/clients',
            isActive: location.startsWith('/clients'),
          ),
          NavItem(
            icon: Icons.folder_outlined,
            activeIcon: Icons.folder_rounded,
            label: 'Projects',
            route: '/projects',
            isActive: location.startsWith('/projects'),
          ),
          NavItem(
            icon: Icons.receipt_long_outlined,
            activeIcon: Icons.receipt_long_rounded,
            label: 'Invoices',
            route: '/invoices',
            isActive: location.startsWith('/invoices'),
          ),
          NavItem(
            icon: Icons.account_balance_wallet_outlined,
            activeIcon: Icons.account_balance_wallet_rounded,
            label: 'Ledger',
            route: '/ledger',
            isActive: location.startsWith('/ledger'),
          ),

          const SizedBox(height: 8),
          _sectionLabel('COMING SOON', color: Colors.grey.shade300),
          const NavItem(
            icon: Icons.bar_chart_rounded,
            activeIcon: Icons.bar_chart_rounded,
            label: 'Analytics',
            route: '/analytics',
            isActive: false,
            disabled: true,
          ),

          const Spacer(),
          const Divider(height: 1),

          _buildUserSignOutAction(context),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color ?? Colors.grey.shade400,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildUserSignOutAction(BuildContext context) {
    if (!AgencyConfig.loginRequired) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: NavUserSection(),
      );
    }

    final authProv = context.watch<AppAuthProvider>();

    return Tooltip(
      message: 'Logged in as ${authProv.userEmail}',
      child: InkWell(
        onTap: () => _showLogoutConfirmation(context),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Expanded(child: NavUserSection()),
              Icon(Icons.logout_rounded, size: 18, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out?'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AppAuthProvider>().logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
