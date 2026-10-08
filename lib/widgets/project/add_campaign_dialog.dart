import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/campaign_model.dart';
import '../../models/project_model.dart';

class AddCampaignDialog extends StatefulWidget {
  final Project project;
  final ValueChanged<Campaign> onAdd;

  const AddCampaignDialog({
    super.key,
    required this.project,
    required this.onAdd,
  });

  @override
  State<AddCampaignDialog> createState() => AddCampaignDialogState();
}

class AddCampaignDialogState extends State<AddCampaignDialog> {
  late final TextEditingController _titleCtrl;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(
      text:
          '${widget.project.projectName} - ${DateFormat('MMM').format(DateTime.now())}',
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Campaign'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Campaign Title *'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_titleCtrl.text.trim().isEmpty) return;

            widget.onAdd(
              Campaign(
                id: '',
                projectId: widget.project.id,
                title: _titleCtrl.text.trim(),
                cycleEndDate: DateTime.now().add(const Duration(days: 30)),
                expenses: 0.0,
                inventoryPool: [],
                assignedCreators: [],
              ),
            );
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
