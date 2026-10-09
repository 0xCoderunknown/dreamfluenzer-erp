import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../domain/app_enums.dart';
import '../../models/campaign_model.dart';
import '../../providers/project_provider.dart';
import '../../theme/app_theme.dart';
import '../common/ui_kit.dart';

/// Stat KPI tile for Creator Profile View
class ProfileStatKpi extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const ProfileStatKpi({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: valueColor ?? AppTheme.primaryDark,
          ),
        ),
      ],
    );
  }
}

/// Tracking column for Active & Completed Campaigns in Creator Profile
class CampaignTrackingColumn extends StatelessWidget {
  final String title;
  final List<Campaign> campaigns;
  final String creatorId;
  final NumberFormat fmt;
  final ProjectProvider projectProv;

  const CampaignTrackingColumn({
    super.key,
    required this.title,
    required this.campaigns,
    required this.creatorId,
    required this.fmt,
    required this.projectProv,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 11,
            color: Colors.grey,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: campaigns.isEmpty
              ? Center(
                  child: Text(
                    'No completed campaigns found.',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontStyle: FontStyle.italic,
                      fontSize: 13,
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: campaigns.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final camp = campaigns[index];
                    final ac = camp.assignedCreators.firstWhere(
                      (a) => a.creatorId == creatorId,
                    );
                    final project = projectProv.projectById(camp.projectId);

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        title: Text(
                          '${project?.projectName ?? 'Unknown Brand'} - ${camp.title}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ac.deliverables.isEmpty
                                    ? 'No deliverables specified'
                                    : ac.deliverables
                                          .map(
                                            (d) =>
                                                '${d.quantity}x ${d.type.value}',
                                          )
                                          .join(', '),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Target: ${DateFormat('dd MMM yyyy').format(ac.individualDeadline)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color:
                                      DateTime.now().isAfter(
                                        ac.individualDeadline,
                                      )
                                      ? Colors.red
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              project?.dealType == DealType.prGift
                                  ? 'Barter'
                                  : '₹${fmt.format(ac.agreedPayout)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            DreamStatusChip(label: ac.pipelineStatus.value),
                          ],
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          context.go('/projects/${camp.projectId}');
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// Dual-column layout rendering Active and Completed campaign queues side-by-side
class CreatorSplitCrmView extends StatelessWidget {
  final List<Campaign> activeCampaigns;
  final List<Campaign> pastCampaigns;
  final String creatorId;
  final NumberFormat fmt;
  final ProjectProvider projectProv;

  const CreatorSplitCrmView({
    super.key,
    required this.activeCampaigns,
    required this.pastCampaigns,
    required this.creatorId,
    required this.fmt,
    required this.projectProv,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: CampaignTrackingColumn(
            title: 'Active Campaigns',
            campaigns: activeCampaigns,
            creatorId: creatorId,
            fmt: fmt,
            projectProv: projectProv,
          ),
        ),
        const VerticalDivider(width: 48),
        Expanded(
          flex: 4,
          child: CampaignTrackingColumn(
            title: 'Completed Campaigns',
            campaigns: pastCampaigns,
            creatorId: creatorId,
            fmt: fmt,
            projectProv: projectProv,
          ),
        ),
      ],
    );
  }
}
