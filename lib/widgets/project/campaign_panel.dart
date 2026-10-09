import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/campaign_model.dart';
import '../../models/project_model.dart';
import '../../providers/campaign_provider.dart';
import '../../theme/app_theme.dart';
import '../common/ui_kit.dart';
import 'campaign_inventory_bay.dart';
import 'expandable_creator_card.dart';
import 'project_dialogs.dart';

class CampaignPanel extends StatefulWidget {
  final Campaign campaign;
  final Project project;
  final CampaignProvider campaignProv;
  final bool isExpanded;
  final bool isLocked;
  final VoidCallback onToggle;

  const CampaignPanel({
    super.key,
    required this.campaign,
    required this.project,
    required this.campaignProv,
    required this.isExpanded,
    required this.isLocked,
    required this.onToggle,
  });

  @override
  State<CampaignPanel> createState() => _CampaignPanelState();
}

class _CampaignPanelState extends State<CampaignPanel> {
  bool _isLogisticsMode = false;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isExpanded
              ? AppTheme.primaryPurple.withValues(alpha: 0.4)
              : Colors.grey.shade200,
          width: widget.isExpanded ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          _buildHeader(context, dateFmt),
          if (widget.isExpanded) _buildExpandedBody(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, DateFormat fmt) {
    return InkWell(
      onTap: widget.onToggle,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            _iconBox(Icons.campaign_rounded),
            const SizedBox(width: 14),
            Expanded(child: _titleSection(context, fmt)),
            const SizedBox(width: 12),
            if (widget.isExpanded)
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text(
                      'Finance & Content',
                      style: TextStyle(fontSize: 12),
                    ),
                    icon: Icon(Icons.monetization_on, size: 16),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text(
                      'Logistics Bay',
                      style: TextStyle(fontSize: 12),
                    ),
                    icon: Icon(Icons.inventory_2, size: 16),
                  ),
                ],
                selected: {_isLogisticsMode},
                onSelectionChanged: (val) =>
                    setState(() => _isLogisticsMode = val.first),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith<Color?>((
                    states,
                  ) {
                    if (states.contains(WidgetState.selected)) {
                      return Colors.orange.shade100;
                    }
                    return Colors.white;
                  }),
                ),
              ),
            const SizedBox(width: 12),
            _expandArrow(),
          ],
        ),
      ),
    );
  }

  Widget _iconBox(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.primaryPurple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: AppTheme.primaryPurple, size: 20),
    );
  }

  Widget _titleSection(BuildContext context, DateFormat fmt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.campaign.title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppTheme.primaryDark,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Text(
                widget.project.dealType.value,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
            if (!widget.isLocked) ...[
              const SizedBox(width: 12),
              _actionIcon(
                Icons.edit_rounded,
                Colors.grey,
                () => _editTitle(context),
              ),
              const SizedBox(width: 8),
              _actionIcon(
                Icons.delete_rounded,
                Colors.red,
                () => _confirmDelete(context),
              ),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(
          'Cycle ends: ${fmt.format(widget.campaign.cycleEndDate)}  ·  ${widget.campaign.assignedCreators.length} ${widget.campaign.assignedCreators.length == 1 ? "creator" : "creators"}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  Widget _actionIcon(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Icon(icon, size: 14, color: color.withValues(alpha: 0.6)),
    );
  }

  Widget _expandArrow() {
    return AnimatedRotation(
      turns: widget.isExpanded ? 0.5 : 0,
      duration: const Duration(milliseconds: 200),
      child: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: Colors.grey.shade400,
      ),
    );
  }

  Widget _buildExpandedBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_isLogisticsMode)
            CampaignInventoryBay(
              campaign: widget.campaign,
              campaignProv: widget.campaignProv,
              isLocked: widget.isLocked,
            ),

          const SizedBox(height: 16),

          if (widget.campaign.assignedCreators.isEmpty)
            _emptyState()
          else
            ...widget.campaign.assignedCreators.map(
              (creator) => ExpandableCreatorCard(
                creator: creator,
                campaign: widget.campaign,
                project: widget.project,
                campaignProv: widget.campaignProv,
                isLocked: widget.isLocked,
                isLogisticsMode: _isLogisticsMode,
              ),
            ),

          if (!widget.isLocked && !_isLogisticsMode) _assignButton(context),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'No creator assigned to this campaign.',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        ),
      ),
    );
  }

  Widget _assignButton(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: OutlinedButton.icon(
          onPressed: () => showDialog(
            context: context,
            builder: (_) => AssigncreatorDialog(
              project: widget.project,
              campaign: widget.campaign,
              onAssign: (creator) =>
                  widget.campaignProv.assignCreatorToCampaign(
                    projectId: widget.project.id,
                    campaignId: widget.campaign.id,
                    creator: creator,
                  ),
            ),
          ),
          icon: const Icon(Icons.person_add_rounded, size: 16),
          label: const Text('Assign Creator'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primaryPurple,
            side: const BorderSide(color: AppTheme.primaryPurple),
          ),
        ),
      ),
    );
  }

  void _editTitle(BuildContext context) async {
    final ctrl = TextEditingController(text: widget.campaign.title);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    await showDialog(
      context: context,
      builder: (diagContext) => AlertDialog(
        title: const Text('Edit Campaign Title'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'New title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(diagContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newTitle = ctrl.text.trim();
              if (newTitle.isNotEmpty && newTitle != widget.campaign.title) {
                await widget.campaignProv.updateCampaignTitle(
                  widget.campaign.projectId,
                  widget.campaign.id,
                  newTitle,
                );

                if (!mounted) return;

                if (diagContext.mounted) Navigator.pop(diagContext);
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('Title updated')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    ctrl.dispose();
  }

  void _confirmDelete(BuildContext context) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDreamConfirm(
      context,
      title: 'Delete Campaign?',
      body:
          'This will remove all creator assignments within this cycle. This cannot be undone.',
      confirmText: 'Delete Cycle',
      isDestructive: true,
    ).then((confirmed) async {
      if (confirmed == true) {
        if (!mounted) return;
        try {
          await widget.campaignProv.deleteCampaign(
            widget.campaign.projectId,
            widget.campaign.id,
          );

          if (!mounted) return;

          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Campaign deleted')),
          );
        } catch (e) {
          if (!mounted) return;
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    });
  }
}
