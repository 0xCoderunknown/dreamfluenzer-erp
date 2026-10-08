import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/app_enums.dart';
import '../../models/log_event_model.dart';
import '../../theme/app_theme.dart';

class DreamAuditLogDialog extends StatelessWidget {
  final String title;
  final Future<List<LogEvent>> fetchLogs;

  const DreamAuditLogDialog({
    super.key,
    required this.title,
    required this.fetchLogs,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(28, 22, 16, 18),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.history_rounded,
                      color: Colors.blueGrey,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'History Log: $title',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: Colors.grey.shade400,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<LogEvent>>(
                future: fetchLogs,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading history.',
                        style: TextStyle(color: Colors.red.shade400),
                      ),
                    );
                  }

                  final logs = snapshot.data ?? [];

                  if (logs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.receipt_long_rounded,
                            size: 48,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No history logs recorded yet.',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      return _TimelineItem(
                        log: logs[index],
                        isLast: index == logs.length - 1,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final LogEvent log;
  final bool isLast;

  const _TimelineItem({required this.log, required this.isLast});

  Color _getColor() {
    switch (log.type) {
      case LogType.finance:
        return AppTheme.success;
      case LogType.creator:
        return (log.action.contains('STRIKE')) ? Colors.red : Colors.blue;
      case LogType.project:
        return AppTheme.primaryPurple;
      case LogType.logistics:
        return AppTheme.warning;
      default:
        return Colors.grey.shade500;
    }
  }

  IconData _getIcon() {
    switch (log.type) {
      case LogType.finance:
        return Icons.attach_money_rounded;
      case LogType.creator:
        return (log.action.contains('STRIKE'))
            ? Icons.warning_amber_rounded
            : Icons.sync_rounded;
      case LogType.project:
        return Icons.assignment_ind_rounded;
      case LogType.logistics:
        return Icons.local_shipping_rounded;
      case LogType.lead:
        return Icons.leaderboard_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    final fmt = NumberFormat('#,##0', 'en_IN');

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_getIcon(), size: 16, color: color),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: Colors.grey.shade200),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        log.action.replaceAll('_', ' '),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: color,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        DateFormat(
                          'dd MMM yyyy, hh:mm a',
                        ).format(log.timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    log.note,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.primaryDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (log.amount != null && log.amount! > 0) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Amount: ₹${fmt.format(log.amount)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                  ],
                  if (log.reason != null && log.reason!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.format_quote_rounded,
                            size: 14,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              log.reason!,
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'by ${log.actor}',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

