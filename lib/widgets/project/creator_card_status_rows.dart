import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/app_enums.dart';

/// Form inputs for pipeline status, paid checkbox, advance payout, and individual deadline
class CreatorCardStatusRows extends StatelessWidget {
  final bool canChangePipeline;
  final PipelineStatus pipelineStatus;
  final ValueChanged<PipelineStatus> onPipelineStatusChanged;
  final bool canMarkPaid;
  final bool isPaid;
  final ValueChanged<bool> onPaidChanged;
  final TextEditingController advanceCtrl;
  final bool hasError;
  final String errorMsg;
  final VoidCallback onAdvanceChanged;
  final DateTime deadline;
  final VoidCallback onPickDate;
  final bool isLocked;

  const CreatorCardStatusRows({
    super.key,
    required this.canChangePipeline,
    required this.pipelineStatus,
    required this.onPipelineStatusChanged,
    required this.canMarkPaid,
    required this.isPaid,
    required this.onPaidChanged,
    required this.advanceCtrl,
    required this.hasError,
    required this.errorMsg,
    required this.onAdvanceChanged,
    required this.deadline,
    required this.onPickDate,
    required this.isLocked,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Tooltip(
                message: !canChangePipeline
                    ? 'Cannot change status until all allocated items are received or returned.'
                    : '',
                child: DropdownButtonFormField<PipelineStatus>(
                  initialValue: pipelineStatus,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    filled: !canChangePipeline,
                    fillColor: Colors.grey.shade200,
                  ),
                  items: PipelineStatus.values
                      .map(
                        (s) => DropdownMenuItem(value: s, child: Text(s.value)),
                      )
                      .toList(),
                  onChanged: (isLocked || !canChangePipeline)
                      ? null
                      : (val) {
                          if (val != null) onPipelineStatusChanged(val);
                        },
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Tooltip(
                message: !canMarkPaid
                    ? 'Cannot pay until all returnable items have been returned.'
                    : '',
                child: CheckboxListTile(
                  title: Text(
                    'Fully Paid',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: !canMarkPaid ? Colors.grey : Colors.black,
                    ),
                  ),
                  value: isPaid,
                  activeColor: Colors.green,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (isLocked || !canMarkPaid)
                      ? null
                      : (val) {
                          if (val != null) onPaidChanged(val);
                        },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: advanceCtrl,
                keyboardType: TextInputType.number,
                enabled: !isLocked,
                decoration: InputDecoration(
                  labelText: 'Advance Paid (₹)',
                  border: const OutlineInputBorder(),
                  isDense: true,
                  errorText: hasError ? errorMsg : null,
                ),
                onChanged: (_) => onAdvanceChanged(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: isLocked ? null : onPickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Creator Deadline',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('dd MMM yyyy').format(deadline)),
                      const Icon(Icons.calendar_today, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
