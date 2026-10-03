import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';
import '../domain/app_enums.dart';
import '../models/campaign_model.dart';
import '../models/creator_model.dart';
import '../models/project_model.dart';

class DashboardAction {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String targetRoute;

  DashboardAction({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.targetRoute,
  });
}

class DashboardAuditor {
  final int activeCreatorsCount;
  final List<Project> liveProjects;
  final double pendingClientDues;
  final double pendingCreatorPayouts;
  final int stuckClientAssetsCount;

  final List<DashboardAction> financialActions;
  final List<DashboardAction> logisticsActions;
  final List<DashboardAction> pipelineActions;

  DashboardAuditor({
    required this.activeCreatorsCount,
    required this.liveProjects,
    required this.pendingClientDues,
    required this.pendingCreatorPayouts,
    required this.stuckClientAssetsCount,
    required this.financialActions,
    required this.logisticsActions,
    required this.pipelineActions,
  });

  static DashboardAuditor process(
    List<Project> projects,
    List<Campaign> campaigns,
    List<Creator> creators,
  ) {
    double clientDues = 0.0;
    double creatorDues = 0.0;
    int stuckClientAssetsCount = 0;

    List<DashboardAction> finActions = [];
    List<DashboardAction> logActions = [];
    List<DashboardAction> pipeActions = [];

    final today = DateTime.now();
    final fmt = NumberFormat('#,##0', 'en_IN');

    // 1. Unified creator Check: Counts both active and training trials natively
    final activeCount = creators
        .where(
          (c) =>
              c.status == CreatorStatus.active ||
              c.status == CreatorStatus.trial,
        )
        .length;

    // 2. Active Projects Board Sorting (Unified Pipeline Entry)
    final live = projects
        .where((p) => p.status == ProjectStatus.active)
        .toList();

    for (var p in projects) {
      if (p.status == ProjectStatus.dropped ||
          p.status == ProjectStatus.archived) {
        continue;
      }

      if (p.dealType != DealType.prGift) {
        final due = p.effectiveBudget - p.advanceReceived;
        if (due > 0) clientDues += due;
      }

      if (p.status == ProjectStatus.active && p.deadline.isBefore(today)) {
        finActions.add(
          DashboardAction(
            icon: Icons.timer_off_rounded,
            color: Colors.red,
            title: 'Overdue Project: ${p.projectName}',
            subtitle: 'Deadline was ${DateFormat('dd MMM').format(p.deadline)}',
            targetRoute: '/projects/${p.id}',
          ),
        );
      }
    }

    final Set<String> loggedLogisticsKeys = {};

    // 3. Campaigns Processing (The Unified Engine)
    for (var camp in campaigns) {
      final parent = projects.firstWhere(
        (p) => p.id == camp.projectId,
        orElse: () => Project(
          id: '',
          clientId: '',
          projectName: 'Unknown',
          leadName: '',
          dealType: DealType.prGift,
          status: ProjectStatus.dropped,
          deadline: today,
          billingModel: BillingModel.oneOff,
          durationMonths: 1,
          baseBudget: 0,
          isGstExclusive: false,
          advanceReceived: 0,
          createdAt: today,
        ),
      );

      if (parent.id.isEmpty ||
          parent.status == ProjectStatus.dropped ||
          parent.status == ProjectStatus.archived) {
        continue;
      }

      for (var ac in camp.assignedCreators) {
        if (ac.pipelineStatus == PipelineStatus.dropped) continue;

        final creator = creators.firstWhere(
          (c) => c.id == ac.creatorId,
          orElse: () => Creator(
            id: '',
            fullName: ac.creatorName,
            handle: '',
            phoneNumber: '',
            status: CreatorStatus.trial,
            type: CreatorType.sandboxTrainee,
            primaryCategory: PrimaryCategory.generalUgc,
            secondaryNiche: '',
            baseRate: 0,
            followerCount: 0,
            upiId: '',
            location: '',
            notes: '',
            rating: 5,
          ),
        );

        if (ac.pipelineStatus == PipelineStatus.awaitingClientSignoff) {
          final difference = today.difference(ac.individualDeadline);
          if (difference.inHours > 48) {
            stuckClientAssetsCount++;
          }
        }

        // ─── TRIAGE 1: FINANCE ───
        // ─── TRIAGE 1: FINANCE ───
        if (!ac.isPaid && ac.agreedPayout > 0) {
          creatorDues += ac.agreedPayout;
          if (ac.pipelineStatus == PipelineStatus.postedLive ||
              parent.status == ProjectStatus.completed) {
            final isTrainee = creator.type == CreatorType.sandboxTrainee;

            finActions.add(
              DashboardAction(
                icon: isTrainee
                    ? Icons.school_rounded
                    : Icons.money_off_rounded,
                color: isTrainee ? Colors.blueGrey : AppTheme.primaryPurple,
                title: isTrainee
                    ? 'Disburse Trainee Stipend: ${creator.fullName}'
                    : 'Pay creator: ${creator.fullName}',
                subtitle:
                    '₹${fmt.format(ac.agreedPayout - ac.advancePaid)} pending for ${camp.title}',
                targetRoute: '/projects/${parent.id}',
              ),
            );
          }
        }

        // ─── TRIAGE 2: PIPELINE & CONTENT PRODUCTION ───
        if (ac.pipelineStatus == PipelineStatus.draftRequested &&
            ac.individualDeadline.isBefore(today)) {
          final isTrainee = creator.type == CreatorType.sandboxTrainee;

          pipeActions.add(
            DashboardAction(
              icon: Icons.warning_amber_rounded,
              color: isTrainee ? Colors.amber.shade600 : Colors.orange.shade800,
              title: isTrainee
                  ? 'Sandbox Blocked: ${creator.fullName}'
                  : 'Late Content: ${creator.fullName}',
              subtitle: isTrainee
                  ? 'Training assignment pending for ${camp.title}'
                  : 'Past due for ${camp.title}',
              targetRoute: '/projects/${parent.id}',
            ),
          );
        }

        if (ac.pipelineStatus == PipelineStatus.reviewing) {
          pipeActions.add(
            DashboardAction(
              icon: Icons.preview_rounded,
              color: Colors.blue,
              title: 'Review Needed: ${creator.fullName}',
              subtitle: 'Draft submitted for ${camp.title}',
              targetRoute: '/projects/${parent.id}',
            ),
          );
        }

        // ─── TRIAGE 3: LOGISTICS (The Polythin Bags) ───
        for (var item in ac.allocatedItems) {
          final logUniqueKey =
              '${ac.creatorId}_${item.inventoryId}_${item.status.name}';
          if (loggedLogisticsKeys.contains(logUniqueKey)) continue;

          if (item.status == AllocationStatus.pending) {
            logActions.add(
              DashboardAction(
                icon: Icons.inventory_2,
                color: Colors.orange,
                title: 'Ship Item to ${creator.fullName}',
                subtitle:
                    '${item.quantity}x ${item.itemName} for ${camp.title}',
                targetRoute: '/projects/${parent.id}',
              ),
            );
            loggedLogisticsKeys.add(logUniqueKey);
          }

          if (item.status == AllocationStatus.received) {
            final poolItem = camp.inventoryPool
                .whereType<CampaignInventory>()
                .firstWhere(
                  (p) => p.id == item.inventoryId,
                  orElse: () => const CampaignInventory(
                    id: '',
                    itemName: '',
                    totalQuantity: 0,
                    gmvPerUnit: 0,
                    isReturnable: false,
                  ),
                );

            if (poolItem.id.isNotEmpty &&
                poolItem.isReturnable &&
                ac.pipelineStatus == PipelineStatus.postedLive) {
              logActions.add(
                DashboardAction(
                  icon: Icons.assignment_return_rounded,
                  color: Colors.red,
                  title: 'Retrieve Item: ${creator.fullName}',
                  subtitle: '${poolItem.itemName} must be returned to Office!',
                  targetRoute: '/projects/${parent.id}',
                ),
              );
              loggedLogisticsKeys.add(logUniqueKey);
            }
          }
        }
      }
    }

    return DashboardAuditor(
      activeCreatorsCount: activeCount,
      liveProjects: live,
      pendingClientDues: clientDues,
      pendingCreatorPayouts: creatorDues,
      stuckClientAssetsCount: stuckClientAssetsCount,
      financialActions: finActions,
      logisticsActions: logActions,
      pipelineActions: pipeActions,
    );
  }
}
