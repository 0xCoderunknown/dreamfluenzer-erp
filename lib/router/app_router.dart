import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/agency_config.dart';
import '../models/lead_model.dart';
import '../models/proposal_model.dart';
import '../providers/auth_provider.dart';
import '../screens/clients_screen.dart';
import '../screens/creators_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/invoices_screen.dart';
import '../screens/leads_screen.dart';
import '../screens/ledger_screen.dart';
import '../screens/login_screen.dart';
import '../screens/project_details_screen.dart';
import '../screens/projects_screen.dart';
import '../screens/proposal_screen.dart';
import '../screens/shell_screen.dart';

abstract class AppRouter {
  static GoRouter createRouter(AppAuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/dashboard',
      refreshListenable: authProvider,
      // Authentication Guard Redirect:
      // - If auth state is not yet initialized, suspend redirection to avoid flashing the login screen.
      // - If the user is logged out and not on login page, force redirect to /login.
      // - If the user is logged in and tries to access /login, redirect to /dashboard.
      redirect: (BuildContext context, GoRouterState state) {
        if (!AgencyConfig.loginRequired) {
          if (state.matchedLocation == '/login') {
            return '/dashboard';
          }
          return null;
        }

        if (!authProvider.isInitialized) {
          return null;
        }

        final bool loggedIn = authProvider.isAuthenticated;
        final bool loggingIn = state.matchedLocation == '/login';

        if (!loggedIn && !loggingIn) {
          return '/login';
        }

        if (loggedIn && loggingIn) {
          return '/dashboard';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: LoginScreen()),
        ),

        ShellRoute(
          builder: (context, state, child) => ShellScreen(child: child),
          routes: [
            GoRoute(
              path: '/dashboard',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: DashboardScreen()),
            ),
            GoRoute(
              path: '/creators',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: CreatorRosterScreen()),
            ),
            GoRoute(
              path: '/clients',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: ClientsScreen()),
            ),
            GoRoute(
              path: '/projects',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: ProjectsScreen()),
            ),
            GoRoute(
              path: '/projects/:id',
              pageBuilder: (context, state) {
                final id = state.pathParameters['id']!;
                return NoTransitionPage(
                  child: ProjectDetailsScreen(projectId: id),
                );
              },
            ),
            GoRoute(
              path: '/invoices',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: InvoicesScreen()),
            ),
            GoRoute(
              path: '/ledger',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: FinancialLedgerScreen()),
            ),
            GoRoute(
              path: '/leads',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: LeadsScreen()),
            ),
            GoRoute(
              path: '/proposal_engine',
              pageBuilder: (context, state) {
                if (state.extra == null) {
                  return const NoTransitionPage(child: LeadsScreen());
                }
                if (state.extra is Map<String, dynamic>) {
                  final map = state.extra as Map<String, dynamic>;
                  return NoTransitionPage(
                    child: ProposalEngineScreen(
                      lead: map['lead'] as Lead,
                      existingProposal: map['proposal'] as Proposal?,
                    ),
                  );
                } else if (state.extra is Lead) {
                  final lead = state.extra as Lead;
                  return NoTransitionPage(
                    child: ProposalEngineScreen(lead: lead),
                  );
                }
                return const NoTransitionPage(child: LeadsScreen());
              },
            ),
          ],
        ),
      ],
    );
  }
}
