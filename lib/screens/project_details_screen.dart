import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../domain/app_enums.dart';
import '../domain/froyo_rules.dart';
import '../engines/revenue_engine.dart';
import '../models/campaign_model.dart';
import '../models/project_model.dart';
import '../providers/campaign_provider.dart';
import '../providers/project_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common/ui_kit.dart';
import '../widgets/project/campaign_widgets.dart';
import '../widgets/project/project_dialogs.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final String projectId;

  const ProjectDetailsScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CampaignProvider>().setProjectScope(widget.projectId);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final project = context.select<ProjectProvider, Project?>(
      (p) => p.projectById(widget.projectId),
    );

    final campaigns = context.select<CampaignProvider, List<Campaign>>(
      (c) => c.campaignsForProject(widget.projectId),
    );

    if (project == null) return _notFound(context);

    final stats = RevenueEngine.calculateProgress(campaigns);
    final bool isLocked =
        project.status == ProjectStatus.completed ||
        project.status == ProjectStatus.archived;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5FA),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(
              context,
              project,
              stats,
              context.read<ProjectProvider>(),
              campaigns,
            ),
            const SizedBox(height: 24),
            _buildHorizontalFinancialPanel(project, campaigns, stats),
            const SizedBox(height: 28),
            _buildCampaignHeader(
              context,
              project,
              context.read<CampaignProvider>(),
              isLocked,
            ),
            const SizedBox(height: 16),
            getCampaignsListView(campaigns, isLocked, project),
          ],
        ),
      ),
    );
  }

  Widget getCampaignsListView(
    List<Campaign> campaigns,
    bool isLocked,
    Project project,
  ) {
    return Expanded(
      child: campaigns.isEmpty
          ? _emptyCampaigns()
          : CampaignList(
              campaigns: campaigns,
              project: project,
              campaignProv: context.read<CampaignProvider>(),
              isLocked: isLocked,
            ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    Project project,
    ProjectProgressStats stats,
    ProjectProvider prov,
    List<Campaign> campaigns,
  ) {
    final bool isOverdue =
        project.deadline.isBefore(DateTime.now()) &&
        project.status == ProjectStatus.active;

    return Row(
      children: [
        IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppTheme.primaryDark,
          ),
          onPressed: () => context.go('/projects'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Project Details: ${project.projectName}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.primaryDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (project.leadName.isNotEmpty)
                Text(
                  'Project Lead: ${project.leadName}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
        if (project.isRetainer)
          DreamStatusChip(
            label:
                'Retainer: ${stats.completedCampaigns} / ${project.durationMonths} months',
            customColor: AppTheme.primaryPurple,
          ),
        const SizedBox(width: 10),
        DreamStatusChip(label: project.status.value),
        const SizedBox(width: 12),
        _DeadlineIndicator(deadline: project.deadline, isOverdue: isOverdue),
        if (project.status == ProjectStatus.active) ...[
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: () =>
                _attemptToArchive(context, project, campaigns, prov),
            icon: const Icon(Icons.check_circle_rounded, size: 16),
            label: const Text('Complete Project'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHorizontalFinancialPanel(
    Project project,
    List<Campaign> campaigns,
    ProjectProgressStats stats,
  ) {
    final logistics = RevenueEngine.calculateProjectLogistics(
      project,
      campaigns,
    );
    final fmt = NumberFormat('#,##0', 'en_IN');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          DreamLedgerCard(
            title: 'Client Billing',
            row1Label: 'Effective Budget',
            row1Value: '₹${fmt.format(project.effectiveBudget)}',
            row2Label: 'Advance Collected',
            row2Value: '₹${fmt.format(project.advanceReceived)}',
            totalLabel: 'Outstanding Balance',
            totalValue: '₹${fmt.format(project.balanceDue)}',
            themeColor: Colors.green,
          ),
          Container(width: 1, height: 64, color: Colors.grey.shade200),
          DreamLedgerCard(
            title: 'Creator Payouts',
            row1Label: 'Total Agreed',
            row1Value: '₹${fmt.format(stats.totalPayouts)}',
            row2Label: 'Advances Paid Out',
            row2Value: '₹${fmt.format(stats.totalAdvances)}',
            totalLabel: 'Balance Owed',
            totalValue: '₹${fmt.format(stats.pendingPayouts)}',
            themeColor: Colors.orange,
          ),
          Container(width: 1, height: 64, color: Colors.grey.shade200),
          DreamLedgerCard(
            title: 'Product Inventory',
            row1Label: 'Product Budget',
            row1Value: '₹${fmt.format(logistics.totalGmvBudget)}',
            row2Label: 'Sent to Creators',
            row2Value: '₹${fmt.format(logistics.totalDistributedGmv)}',
            totalLabel: 'In Stock',
            totalValue: '₹${fmt.format(logistics.retainedGmv)}',
            themeColor: Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignHeader(
    BuildContext context,
    Project project,
    CampaignProvider prov,
    bool isLocked,
  ) {
    return Row(
      children: [
        const Text(
          'Campaign Cycles',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryDark,
          ),
        ),
        const Spacer(),
        if (!isLocked)
          ElevatedButton.icon(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => AddCampaignDialog(
                project: project,
                onAdd: (c) => prov.addCampaign(c),
              ),
            ),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Add Campaign'),
          ),
      ],
    );
  }

  void _attemptToArchive(
    BuildContext context,
    Project project,
    List<Campaign> campaigns,
    ProjectProvider prov,
  ) async {
    final audit = FroyoRules.canArchiveProject(project, campaigns);

    if (!audit.isValid) {
      _showSimpleAlert(
        context,
        'Cannot Complete Yet',
        audit.message,
        icon: Icons.warning_amber_rounded,
        iconColor: Colors.orange,
      );
      return;
    }

    final confirmed = await showDreamConfirm(
      context,
      title: 'Archive Project?',
      body:
          'This will archive ${project.projectName} and prevent further changes.',
      confirmText: 'Archive Project',
    );

    if (confirmed == true) {
      if (!mounted) return;
      try {
        await prov.completeProject(project.id, campaigns: campaigns);
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${project.projectName} finalized successfully.'),
            backgroundColor: AppTheme.success,
          ),
        );
        context.pop();
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete project: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _showSimpleAlert(
    BuildContext context,
    String title,
    String body, {
    IconData icon = Icons.info_outline,
    Color iconColor = Colors.blue,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 10),
            Text(title),
          ],
        ),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _notFound(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Project not found.')));

  Widget _emptyCampaigns() => const Center(
    child: Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Text(
        'No campaigns added to this project.',
        style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
      ),
    ),
  );
}

class _DeadlineIndicator extends StatelessWidget {
  final DateTime deadline;
  final bool isOverdue;

  const _DeadlineIndicator({required this.deadline, required this.isOverdue});

  @override
  Widget build(BuildContext context) {
    final color = isOverdue ? Colors.red : Colors.grey.shade600;
    return Row(
      children: [
        Icon(Icons.calendar_today_outlined, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          DateFormat('dd MMM yyyy').format(deadline),
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: isOverdue ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
