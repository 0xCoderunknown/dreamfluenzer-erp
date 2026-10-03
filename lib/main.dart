import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/agency_config.dart';
import 'config/app_config.dart';
import 'engines/dashboard_auditor.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/campaign_provider.dart';
import 'providers/client_provider.dart';
import 'providers/creator_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/lead_provider.dart';
import 'providers/project_provider.dart';
import 'providers/proposal_provider.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load dual-tier configuration (private local config with demo fallback)
  await AppConfig.load();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint(
      '⚠️ Firebase init note: $e\n'
      'App is operating in ${AppConfig.isDemoMode ? "DEMO" : "LOCAL"} mode.',
    );
  }

  // Initialize Auth Provider outside so we can safely pass it to the router
  final authProvider = AppAuthProvider();

  runApp(
    MultiProvider(
      providers: [
        // ─── AUTHENTICATION PROVIDER INJECTION ───
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => CampaignProvider(), lazy: false),
        ChangeNotifierProvider(create: (_) => CreatorProvider(), lazy: false),
        ChangeNotifierProvider(create: (_) => ClientProvider(), lazy: false),
        ChangeNotifierProvider(create: (_) => ProjectProvider(), lazy: false),
        ChangeNotifierProvider(create: (_) => LeadProvider(), lazy: false),
        ChangeNotifierProvider(create: (_) => ProposalProvider(), lazy: false),

        // ─── CACHED DASHBOARD PROVIDER ───
        ChangeNotifierProxyProvider3<
          ProjectProvider,
          CampaignProvider,
          CreatorProvider,
          DashboardProvider
        >(
          create: (_) => DashboardProvider(),
          update: (context, projProv, campProv, creatProv, dashProv) {
            // Natively utilizes your existing internal caching guard safely
            return dashProv!..updateData(
              projects: projProv.projects,
              campaigns: campProv.campaigns,
              creators: creatProv.creators,
            );
          },
        ),

        // ─── READ-ONLY DASHBOARD AUDITOR EXTENSION ───
        // Allows down-tree UI components to listen directly to DashboardAuditor changes
        ProxyProvider<DashboardProvider, DashboardAuditor?>(
          update: (context, dashProv, previousAuditor) => dashProv.auditor,
        ),
      ],
      child: DreamFluenzerApp(authProvider: authProvider),
    ),
  );
}

class DreamFluenzerApp extends StatelessWidget {
  final AppAuthProvider authProvider;

  const DreamFluenzerApp({super.key, required this.authProvider});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: authProvider,
      builder: (context, _) {
        if (AgencyConfig.loginRequired && !authProvider.isInitialized) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              backgroundColor: Color(0xFFF0F2FF), // AppTheme.backgroundLight
              body: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
                ),
              ),
            ),
          );
        }

        return MaterialApp.router(
          title: AgencyConfig.portalTitle,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          routerConfig: AppRouter.createRouter(authProvider),
        );
      },
    );
  }
}
