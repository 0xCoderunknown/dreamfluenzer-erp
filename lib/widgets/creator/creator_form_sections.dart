import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../engines/crm_analytics_engine.dart';
import '../../models/creator_model.dart';
import '../../providers/campaign_provider.dart';
import '../../providers/creator_provider.dart';
import '../../theme/app_theme.dart';

/// Styled form field for creator forms
class CreatorFormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool digitsOnly;
  final int maxLines;
  final String? prefix;
  final String? hint;
  final String? Function(String?)? validator;

  const CreatorFormField({
    super.key,
    required this.label,
    required this.controller,
    this.digitsOnly = false,
    this.maxLines = 1,
    this.prefix,
    this.hint,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryDark,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          textInputAction: TextInputAction.next,
          inputFormatters: digitsOnly
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
          decoration: InputDecoration(
            prefixText: prefix,
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 13,
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}

/// Vacation / Away date range picker switch tile
class CreatorVacationSwitchTile extends StatelessWidget {
  final DateTimeRange? busyRange;
  final ValueChanged<DateTimeRange?> onRangeChanged;

  const CreatorVacationSwitchTile({
    super.key,
    required this.busyRange,
    required this.onRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SwitchListTile(
        title: const Text(
          'Mark as Away / Unavailable',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          busyRange != null
              ? 'Away: ${DateFormat('dd MMM').format(busyRange!.start)} to ${DateFormat('dd MMM').format(busyRange!.end)}'
              : 'Currently active and available for campaigns.',
          style: TextStyle(
            fontSize: 12,
            color: busyRange != null
                ? Colors.red.shade600
                : Colors.grey.shade600,
          ),
        ),
        value: busyRange != null,
        activeThumbColor: Colors.red,
        onChanged: (isTurnedOn) async {
          if (isTurnedOn) {
            final minDate = DateTime.now().add(const Duration(days: 30));
            final picked = await showDateRangePicker(
              context: context,
              firstDate: minDate,
              lastDate: DateTime.now().add(const Duration(days: 365)),
              helpText: 'Select Away Dates',
            );
            if (picked != null) onRangeChanged(picked);
          } else {
            onRangeChanged(null);
          }
        },
      ),
    );
  }
}

/// Confirmation and execution dialog for deleting or deactivating creators
Future<void> showDeleteCreatorDialog({
  required BuildContext context,
  required Creator creator,
}) async {
  final creatorProv = context.read<CreatorProvider>();
  final campaignProv = context.read<CampaignProvider>();
  final hasHistory = CrmAnalyticsEngine.getCampaignHistoryForCreator(
    creator.id,
    campaignProv.campaigns,
  ).isNotEmpty;

  final confirm = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: hasHistory ? Colors.orange : Colors.red,
          ),
          const SizedBox(width: 8),
          Text(
            hasHistory
                ? 'Deactivate Creator Profile?'
                : 'Permanently Delete Creator?',
          ),
        ],
      ),
      content: Text(
        hasHistory
            ? 'This creator has campaign history. They will be marked as Inactive instead of being deleted.'
            : 'Are you sure? This will permanently delete this creator.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: hasHistory ? Colors.orange : Colors.red,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(hasHistory ? 'Mark Inactive' : 'Delete Forever'),
        ),
      ],
    ),
  );

  if (confirm == true && context.mounted) {
    if (hasHistory) {
      await creatorProv.deactivateCreator(creator.id, actor: 'Admin');
    } else {
      await creatorProv.deleteCreator(creator.id);
    }
    if (context.mounted) Navigator.pop(context);
  }
}
