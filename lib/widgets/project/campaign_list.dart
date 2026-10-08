import 'package:flutter/material.dart';

import '../../models/campaign_model.dart';
import '../../models/project_model.dart';
import '../../providers/campaign_provider.dart';
import 'campaign_panel.dart';

class CampaignList extends StatefulWidget {
  final List<Campaign> campaigns;
  final Project project;
  final CampaignProvider campaignProv;
  final bool isLocked;

  const CampaignList({
    super.key,
    required this.campaigns,
    required this.project,
    required this.campaignProv,
    required this.isLocked,
  });

  @override
  State<CampaignList> createState() => CampaignListState();
}

class CampaignListState extends State<CampaignList> {
  final Set<String> _expandedIds = {};

  @override
  void initState() {
    super.initState();
    if (widget.campaigns.isNotEmpty) {
      _expandedIds.add(widget.campaigns.last.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: widget.campaigns.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final c = widget.campaigns[i];
        return CampaignPanel(
          campaign: c,
          project: widget.project,
          campaignProv: widget.campaignProv,
          isExpanded: _expandedIds.contains(c.id),
          isLocked: widget.isLocked,
          onToggle: () => setState(() {
            _expandedIds.contains(c.id)
                ? _expandedIds.remove(c.id)
                : _expandedIds.add(c.id);
          }),
        );
      },
    );
  }
}
