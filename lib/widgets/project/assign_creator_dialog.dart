import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../domain/app_enums.dart';
import '../../engines/crm_analytics_engine.dart';
import '../../models/campaign_model.dart';
import '../../models/creator_model.dart';
import '../../models/project_model.dart';
import '../../models/proposal_model.dart';
import '../../providers/campaign_provider.dart';
import '../../providers/creator_provider.dart';
import '../../providers/project_provider.dart';

class AssigncreatorDialog extends StatefulWidget {
  final Project project;
  final Campaign campaign;
  final ValueChanged<AssignedCreator> onAssign;

  const AssigncreatorDialog({
    super.key,
    required this.project,
    required this.campaign,
    required this.onAssign,
  });

  @override
  State<AssigncreatorDialog> createState() => AssigncreatorDialogState();
}

class AssigncreatorDialogState extends State<AssigncreatorDialog> {
  Creator? _selectedCreator;
  final _payoutCtrl = TextEditingController();
  late final SearchController _creatorSearchController;

  @override
  void initState() {
    super.initState();
    _creatorSearchController = SearchController()
      ..text = _selectedCreator?.fullName ?? '';
  }

  @override
  void dispose() {
    _payoutCtrl.dispose();
    _creatorSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final creators = context.select<CreatorProvider, List<Creator>>(
      (p) => p.creators
          .where(
            (c) =>
                c.status == CreatorStatus.active ||
                c.status == CreatorStatus.trial,
          )
          .toList(),
    );

    return AlertDialog(
      title: const Text('Assign Creator'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SearchAnchor(
                searchController: _creatorSearchController,
                builder: (BuildContext context, SearchController controller) {
                  return TextFormField(
                    controller: controller,
                    readOnly: true,
                    onTap: () => controller.openView(),
                    decoration: const InputDecoration(
                      labelText: 'Select Creator',
                      suffixIcon: Icon(Icons.arrow_drop_down),
                    ),
                  );
                },
                suggestionsBuilder:
                    (BuildContext context, SearchController controller) {
                      final keyword = controller.text.toLowerCase();
                      final matches = creators.where(
                        (c) => c.fullName.toLowerCase().contains(keyword),
                      );
                      return matches.map((c) {
                        return ListTile(
                          title: Text(c.fullName),
                          onTap: () {
                            controller.closeView(c.fullName);
                            setState(() {
                              _selectedCreator = c;
                              _payoutCtrl.text = c.baseRate.toStringAsFixed(0);
                            });
                          },
                        );
                      });
                    },
              ),

              if (_selectedCreator != null) ...[
                const SizedBox(height: 16),
                _buildCapacityIntelCard(context, _selectedCreator!),
              ],

              const SizedBox(height: 16),
              TextField(
                controller: _payoutCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Agreed Payout (₹)',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_selectedCreator != null) {
              widget.onAssign(
                AssignedCreator(
                  creatorId: _selectedCreator!.id,
                  creatorName: _selectedCreator!.fullName,
                  individualDeadline: DateTime.now().add(
                    const Duration(days: 14),
                  ),
                  agreedPayout: double.tryParse(_payoutCtrl.text) ?? 0.0,
                  pipelineStatus: PipelineStatus.draftRequested,
                  isPaid: false,
                  deliverables: const [
                    Deliverable(type: DeliverableType.reel, quantity: 1),
                  ],
                ),
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Assign'),
        ),
      ],
    );
  }

  Widget _buildCapacityIntelCard(BuildContext context, Creator creator) {
    final projectProv = context.read<ProjectProvider>();
    final campaignProv = context.read<CampaignProvider>();

    final upcomingTasks = CrmAnalyticsEngine.getUpcomingTasksForCreator(
      creator.id,
      campaignProv.campaigns,
      projectProv.projects,
    );

    const String blockedDaysInfo = 'None marked';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blueGrey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Capacity Overview (Next 30 Days)',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 8),

          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.block, size: 14, color: Colors.red),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Unavailable Days: $blockedDaysInfo',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: Colors.white),
          ),

          const Row(
            children: [
              Icon(Icons.pending_actions, size: 14, color: Colors.orange),
              SizedBox(width: 6),
              Text(
                'Pending Tasks:',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),

          if (upcomingTasks.isEmpty)
            const Text(
              '  Schedule clear. No pending tasks.',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            ...upcomingTasks.map(
              (task) => Padding(
                padding: const EdgeInsets.only(top: 4, left: 20),
                child: Text(
                  '• ${task['campaign']} (${DateFormat('dd MMM').format(task['deadline'])}) - ${task['status']}',
                  style: const TextStyle(fontSize: 11, color: Colors.black87),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
