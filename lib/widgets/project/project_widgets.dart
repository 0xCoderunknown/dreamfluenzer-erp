import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../domain/app_enums.dart';
import '../../models/client_model.dart';
import '../../models/project_model.dart';
import '../../providers/campaign_provider.dart';
import '../../providers/project_provider.dart';
import '../../theme/app_theme.dart';
import '../common/ui_kit.dart';

// ===========================================================================
// PROJECTS TABLE
// ===========================================================================
class ProjectTable extends StatelessWidget {
  final List<Project> projects;
  final List<Client> clients;

  const ProjectTable({
    super.key,
    required this.projects,
    required this.clients,
  });

  @override
  Widget build(BuildContext context) {
    final clientMap = {for (var c in clients) c.id: c};

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          const ProjectTableHeader(),
          Expanded(
            child: ListView.separated(
              itemCount: projects.length,
              separatorBuilder: (_, _) =>
                  Divider(height: 1, color: Colors.grey.shade100),
              itemBuilder: (_, i) {
                final p = projects[i];
                final clientName =
                    clientMap[p.clientId]?.businessName ?? 'Unknown Client';
                return ProjectRow(project: p, clientName: clientName);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ProjectTableHeader extends StatelessWidget {
  const ProjectTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    const s = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: Color(0xFF9CA3AF),
      letterSpacing: 0.8,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FF),
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: const Row(
        children: [
          Expanded(flex: 4, child: Text('PROJECT NAME', style: s)),
          Expanded(flex: 2, child: Text('PARTNER CLIENT', style: s)),
          Expanded(flex: 2, child: Text('DEAL TYPE', style: s)),
          Expanded(flex: 2, child: Text('STATUS', style: s)),
          Expanded(flex: 2, child: Text('EFFECTIVE BUDGET', style: s)),
          Expanded(flex: 2, child: Text('ADVANCE PAYMENT', style: s)),
          Expanded(flex: 2, child: Text('TARGET DEADLINE', style: s)),
          SizedBox(width: 80),
        ],
      ),
    );
  }
}

// ===========================================================================
// PROJECT ROW OBJECT
// ===========================================================================
class ProjectRow extends StatefulWidget {
  final Project project;
  final String clientName;

  const ProjectRow({
    super.key,
    required this.project,
    required this.clientName,
  });

  @override
  State<ProjectRow> createState() => _ProjectRowState();
}

class _ProjectRowState extends State<ProjectRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.project;
    final fmt = NumberFormat('#,##0', 'en_IN');

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.go('/projects/${p.id}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          color: _hovered
              ? AppTheme.primaryPurple.withValues(alpha: 0.04)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Row(
            children: [
              _ProjectTableCell(
                flex: 4,
                primaryText: p.displayProjectName,
                primaryColor: AppTheme.primaryDark,
                secondaryText: p.isRetainer
                    ? 'Retainer (${p.durationMonths}mo)'
                    : (p.leadName.isNotEmpty
                          ? 'Lead: ${p.leadName}'
                          : 'One-Off'),
                secondaryColor: p.isRetainer
                    ? AppTheme.primaryPurple
                    : Colors.grey.shade400,
              ),
              Expanded(
                flex: 2,
                child: Text(
                  widget.clientName,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: DreamStatusChip(label: p.dealType.value),
                ),
              ),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: DreamStatusChip(label: p.status.value),
                ),
              ),
              _ProjectTableCell(
                flex: 2,
                primaryText: p.dealType == DealType.prGift
                    ? 'Barter'
                    : '₹${fmt.format(p.effectiveBudget)}',
                primaryColor: AppTheme.primaryDark,
                secondaryText:
                    (p.isGstExclusive && p.dealType != DealType.prGift)
                    ? 'excl. 18% GST'
                    : null,
              ),
              _ProjectTableCell(
                flex: 2,
                primaryText: p.dealType == DealType.prGift
                    ? '—'
                    : '₹${fmt.format(p.advanceReceived)}',
                primaryColor: p.dealType == DealType.prGift
                    ? Colors.grey.shade300
                    : Colors.grey.shade700,
                bottomWidget: p.isPaymentPending
                    ? const DreamMiniBadge(
                        label: 'PAYMENT PENDING',
                        color: Colors.orange,
                      )
                    : null,
              ),

              _ProjectTableCell(
                flex: 2,
                primaryText: DateFormat('dd MMM yyyy').format(p.deadline),
                primaryColor: p.isOverdue
                    ? Colors.red.shade600
                    : Colors.grey.shade600,
                bottomWidget: p.isOverdue
                    ? const DreamMiniBadge(label: 'OVERDUE', color: Colors.red)
                    : null,
              ),
              _buildActions(context, p),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, Project p) {
    return SizedBox(
      width: 80,
      child: Opacity(
        opacity: _hovered ? 1.0 : 0.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: const Icon(
                Icons.history_rounded,
                color: Colors.blueGrey,
                size: 18,
              ),
              tooltip: 'View Audit Logs',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                final logsFuture = context
                    .read<ProjectProvider>()
                    .fetchProjectExecutionLogs(p.id);
                showDialog(
                  context: context,
                  builder: (diagContext) => DreamAuditLogDialog(
                    title: p.projectName,
                    fetchLogs: logsFuture,
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.red,
                size: 18,
              ),
              tooltip: 'Delete Project',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => _confirmDelete(context, p),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Project p) {
    final projectProv = context.read<ProjectProvider>();
    final campaignProv = context.read<CampaignProvider>();
    final campaignsCount = campaignProv.campaignsForProject(p.id).length;

    showDreamConfirm(
      context,
      title: 'Permanently Delete Project?',
      body: campaignsCount > 0
          ? 'Warning: This will delete all $campaignsCount active campaign cycles and related allocations.'
          : 'Are you sure you want to delete ${p.projectName}?',
      confirmText: 'Delete Project',
      isDestructive: true,
    ).then((confirmed) {
      if (confirmed == true) {
        projectProv.deleteProject(p.id);
      }
    });
  }
}

class _ProjectTableCell extends StatelessWidget {
  final int flex;
  final String primaryText;
  final Color primaryColor;
  final FontWeight primaryWeight;
  final String? secondaryText;
  final Color? secondaryColor;
  final Widget? bottomWidget;

  const _ProjectTableCell({
    required this.flex,
    required this.primaryText,
    this.primaryColor = AppTheme.primaryDark,
    this.secondaryText,
    this.secondaryColor,
    this.bottomWidget,
  }) : primaryWeight = FontWeight.w600;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            primaryText,
            style: TextStyle(
              fontWeight: primaryWeight,
              fontSize: 13,
              color: primaryColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (secondaryText != null)
            Text(
              secondaryText!,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: secondaryColor ?? Colors.grey.shade400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ?bottomWidget,
        ],
      ),
    );
  }
}
