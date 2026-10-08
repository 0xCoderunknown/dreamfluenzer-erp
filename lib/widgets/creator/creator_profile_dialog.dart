import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/app_enums.dart';
import '../../engines/crm_analytics_engine.dart';
import '../../models/campaign_model.dart';
import '../../models/creator_model.dart';
import '../../providers/campaign_provider.dart';
import '../../providers/creator_provider.dart';
import '../../providers/project_provider.dart';
import '../../theme/app_theme.dart';
import '../common/ui_kit.dart';

// CREATOR PROFILE DIALOG
class CreatorProfileDialog extends StatelessWidget {
  final Creator creator;
  final ProjectProvider projectProv;
  final VoidCallback onEdit;

  const CreatorProfileDialog({
    super.key,
    required this.creator,
    required this.projectProv,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final campaignProv = context.read<CampaignProvider>();
    final allCampaigns = campaignProv.campaigns;
    final fmt = NumberFormat('#,##0', 'en_IN');
    final history = CrmAnalyticsEngine.getCampaignHistoryForCreator(
      creator.id,
      allCampaigns,
    );
    final ltv = CrmAnalyticsEngine.getLifetimeValueForCreator(
      creator.id,
      allCampaigns,
    );

    final activeTasks = <Campaign>{};
    final pastTasks = <Campaign>{};

    for (var camp in history) {
      final ac = camp.assignedCreators.firstWhere(
        (a) => a.creatorId == creator.id,
      );
      if ([
        PipelineStatus.draftRequested,
        PipelineStatus.reviewing,
        PipelineStatus.changesRequested,
      ].contains(ac.pipelineStatus)) {
        activeTasks.add(camp);
      } else {
        pastTasks.add(camp);
      }
    }

    final pastList = pastTasks.toList()
      ..sort((a, b) => b.cycleEndDate.compareTo(a.cycleEndDate));
    final recentPast = pastList.take(5).toList();
    final completedCount = history.length - activeTasks.length;
    final double displayRating = (5.0 - (creator.strikeLevel * 0.5)).clamp(
      1.0,
      5.0,
    );
    final bool isBusy =
        creator.busyFrom != null &&
        creator.busyTo != null &&
        creator.busyTo!.isAfter(DateTime.now());

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 950, maxHeight: 850),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopIdentity(context, displayRating, isBusy),
              const SizedBox(height: 24),
              _buildKpiBar(
                creator,
                activeTasks.length,
                completedCount,
                ltv,
                fmt,
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: _buildGridMetaTile(
                        Icons.phone_android_rounded,
                        'Phone Number',
                        creator.phoneNumber,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 32,
                      color: Colors.grey.shade200,
                    ),
                    Expanded(
                      child: _buildGridMetaTile(
                        Icons.location_city_rounded,
                        'City',
                        creator.location.isEmpty ? 'N/A' : creator.location,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 32,
                      color: Colors.grey.shade200,
                    ),
                    Expanded(
                      child: _buildGridMetaTile(
                        Icons.account_balance_wallet_rounded,
                        'UPI ID',
                        creator.upiId.isEmpty ? 'N/A' : creator.upiId,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 32,
                      color: Colors.grey.shade200,
                    ),
                    Expanded(
                      child: _buildGridMetaTile(
                        Icons.local_offer_rounded,
                        'Primary Niche',
                        creator.type == CreatorType.influencer
                            ? '${creator.primaryCategory.value}${creator.secondaryNiche.isEmpty ? "" : " ➔ ${creator.secondaryNiche}"}'
                            : creator.primaryCategory.value,
                      ),
                    ),
                  ],
                ),
              ),
              if (creator.notes.isNotEmpty) ...[
                const SizedBox(height: 20),
                _buildNotesSection(),
              ],
              const SizedBox(height: 32),
              Expanded(
                child: _buildSplitCrmView(
                  context,
                  activeTasks.toList(),
                  recentPast,
                  fmt,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridMetaTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Icon(icon, size: 18, color: AppTheme.primaryPurple),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF9CA3AF),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopIdentity(
    BuildContext context,
    double displayRating,
    bool isBusy,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: AppTheme.primaryPurple.withValues(alpha: 0.1),
          child: Text(
            creator.fullName[0].toUpperCase(),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryPurple,
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    creator.fullName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    children: List.generate(
                      5,
                      (index) => Icon(
                        index < displayRating.floor()
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: Colors.amber.shade600,
                        size: 20,
                      ),
                    ),
                  ),
                  if (creator.strikeLevel > 0)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        '(${creator.strikeLevel} Strikes)',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: () async {
                  final url = Uri.parse(
                    'https://instagram.com/${creator.handle}',
                  );
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '@${creator.handle}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.primaryPurple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.open_in_new_rounded,
                      size: 12,
                      color: AppTheme.primaryPurple,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  DreamStatusChip(label: creator.type.value),
                  DreamStatusChip(
                    label: creator.status.value,
                    customColor: creator.status == CreatorStatus.active
                        ? Colors.green
                        : (creator.status == CreatorStatus.inactive
                              ? Colors.red
                              : Colors.orange),
                  ),
                  if (isBusy)
                    DreamStatusChip(
                      label:
                          'Away: ${DateFormat('dd MMM').format(creator.busyFrom!)} - ${DateFormat('dd MMM').format(creator.busyTo!)}',
                      customColor: Colors.red,
                    ),
                ],
              ),
            ],
          ),
        ),
        _buildActionMenuRow(context),
      ],
    );
  }

  Widget _buildActionMenuRow(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.history_rounded, color: Colors.blueGrey),
          tooltip: 'View History',
          onPressed: () {
            final logsFuture = context.read<CreatorProvider>().getCreatorLogs(
              creator.id,
            );
            showDialog(
              context: context,
              builder: (ctx) => DreamAuditLogDialog(
                title: creator.fullName,
                fetchLogs: logsFuture,
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: Colors.grey),
          tooltip: 'Edit Creator Profile',
          onPressed: () {
            Navigator.pop(context);
            onEdit();
          },
        ),
      ],
    );
  }

  Widget _buildKpiBar(
    Creator c,
    int activeCount,
    int completedCount,
    double ltv,
    NumberFormat fmt,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ProfileStatKpi(
            label: 'Base Rate',
            value: '₹${fmt.format(c.baseRate)}',
          ),
          _ProfileStatKpi(
            label: 'Followers',
            value: fmt.format(c.followerCount),
          ),
          _ProfileStatKpi(
            label: 'Active Campaigns',
            value: activeCount.toString(),
            valueColor: activeCount > 0 ? Colors.orange.shade700 : null,
          ),
          _ProfileStatKpi(
            label: 'Completed Campaigns',
            value: completedCount.toString(),
          ),
          _ProfileStatKpi(
            label: 'Lifetime Value (LTV)',
            value: '₹${fmt.format(ltv)}',
            valueColor: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.notes_rounded, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Internal Notes',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  creator.notes,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.primaryDark,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitCrmView(
    BuildContext context,
    List<Campaign> active,
    List<Campaign> past,
    NumberFormat fmt,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: _CampaignTrackingColumn(
            title: 'Active Campaigns',
            campaigns: active,
            creatorId: creator.id,
            fmt: fmt,
            projectProv: projectProv,
          ),
        ),
        const VerticalDivider(width: 48),
        Expanded(
          flex: 4,
          child: _CampaignTrackingColumn(
            title: 'Completed Campaigns',
            campaigns: past,
            creatorId: creator.id,
            fmt: fmt,
            projectProv: projectProv,
          ),
        ),
      ],
    );
  }
}

class _CampaignTrackingColumn extends StatelessWidget {
  final String title;
  final List<Campaign> campaigns;
  final String creatorId;
  final NumberFormat fmt;
  final ProjectProvider projectProv;

  const _CampaignTrackingColumn({
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

class _ProfileStatKpi extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _ProfileStatKpi({
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
