import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../domain/app_enums.dart';
import '../config/agency_config.dart';
import '../engines/dashboard_auditor.dart';
import '../models/project_model.dart';
import '../providers/dashboard_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/dashboard/dashboard_widgets.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static final _currencyFmt = NumberFormat('#,##0', 'en_IN');
  static final _dateFmt = DateFormat('dd MMM');

  String _calculateGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final auditor = context.watch<DashboardProvider>().auditor;
    final currentGreeting = _calculateGreeting();

    if (auditor == null) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryPurple),
          ),
        ),
      );
    }

    final displayProjects = auditor.liveProjects.take(5).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, currentGreeting),
              const SizedBox(height: 32),
              _buildStatGrid(context, auditor),
              const SizedBox(height: 32),

              LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth > 1100;

                  if (isDesktop) {
                    return Row(
                      key: const ValueKey('DesktopDashboardLayout'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildActionCenter(
                            context,
                            'Logistics Bay',
                            auditor.logisticsActions,
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _buildActionCenter(
                            context,
                            'Content & Pipeline',
                            auditor.pipelineActions,
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _buildActionCenter(
                            context,
                            'Financial Tracking',
                            auditor.financialActions,
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      key: const ValueKey('MobileDashboardLayout'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildActionCenter(
                          context,
                          'Logistics Bay',
                          auditor.logisticsActions,
                        ),
                        const SizedBox(height: 24),
                        _buildActionCenter(
                          context,
                          'Content & Pipeline',
                          auditor.pipelineActions,
                        ),
                        const SizedBox(height: 24),
                        _buildActionCenter(
                          context,
                          'Financial Tracking',
                          auditor.financialActions,
                        ),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 32),
              _buildPipeline(context, displayProjects),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String greeting) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting, ${AgencyConfig.adminGreetingName} 👋',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppTheme.primaryDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Here is your agency's unified pulse for today.",
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildStatGrid(BuildContext context, DashboardAuditor auditor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth > 900 ? 4 : 2;
        return GridView.count(
          crossAxisCount: cols,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: constraints.maxWidth > 1200 ? 2.2 : 1.6,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            DashboardStatCard(
              label: 'Creators Managed',
              value: auditor.activeCreatorsCount.toString(),
              icon: Icons.people_rounded,
              color: AppTheme.info,
            ),
            DashboardStatCard(
              label: 'Live Projects',
              value: auditor.liveProjects.length.toString(),
              icon: Icons.rocket_launch_rounded,
              color: const Color(0xFFFF6584),
            ),
            DashboardStatCard(
              label: 'Outstanding Invoices',
              value: '₹${_currencyFmt.format(auditor.pendingClientDues)}',
              icon: Icons.arrow_circle_down_rounded,
              color: auditor.pendingClientDues > 0
                  ? Colors.orange
                  : AppTheme.success,
            ),
            DashboardStatCard(
              label: 'Pending Payouts',
              value: '₹${_currencyFmt.format(auditor.pendingCreatorPayouts)}',
              icon: Icons.arrow_circle_up_rounded,
              color: AppTheme.primaryPurple,
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionCenter(
    BuildContext context,
    String title,
    List<DashboardAction> actions,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryDark,
          ),
        ),
        const SizedBox(height: 12),
        if (actions.isEmpty)
          _buildAllClear()
        else
          ...actions.map(
            (action) => DashboardActionTile(
              icon: action.icon,
              color: action.color,
              title: action.title,
              subtitle: action.subtitle,
              onTap: () => context.go(action.targetRoute),
            ),
          ),
      ],
    );
  }

  Widget _buildPipeline(BuildContext context, List<Project> displayProjects) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Active Projects',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryDark,
          ),
        ),
        const SizedBox(height: 16),
        Material(
          color: Colors.white,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: displayProjects.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    'No active projects yet.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : Column(
                  children: List.generate(displayProjects.length, (index) {
                    final p = displayProjects[index];
                    final isGift = p.dealType == DealType.prGift;

                    return Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 4,
                          ),
                          title: Text(
                            p.projectName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            'Due: ${_dateFmt.format(p.deadline)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Text(
                            isGift
                                ? 'Barter / Internal'
                                : '₹${_currencyFmt.format(p.effectiveBudget)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isGift
                                  ? Colors.blueGrey
                                  : AppTheme.success,
                            ),
                          ),
                          onTap: () => context.go('/projects/${p.id}'),
                        ),
                        if (index < displayProjects.length - 1)
                          Divider(height: 1, color: Colors.grey.shade100),
                      ],
                    );
                  }),
                ),
        ),
      ],
    );
  }

  Widget _buildAllClear() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 20),
          SizedBox(width: 12),
          Text(
            'All clear — nothing pending.',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
