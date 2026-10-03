import 'package:flutter/material.dart';

import '../../models/lead_model.dart';
import '../../models/proposal_model.dart';
import '../../theme/app_theme.dart';
import 'lead_dialogs.dart';

class LeadCard extends StatelessWidget {
  final Lead lead;
  final bool isDragging;
  final bool hasPitch;
  final Proposal? activeProposal;
  final double displayValue;

  const LeadCard({
    super.key,
    required this.lead,
    this.isDragging = false,
    required this.hasPitch,
    required this.activeProposal,
    required this.displayValue,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = AppTheme.getStatusColor(lead.status.value);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      elevation: isDragging ? 8.0 : 1.0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDragging ? AppTheme.primaryPurple : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: isDragging
            ? null
            : () => showDialog(
                context: context,
                builder: (_) => LeadOverviewDialog(lead: lead),
              ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 6, color: statusColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              lead.businessName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppTheme.primaryDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (hasPitch) _pitchedBadge(),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _infoRow(
                        Icons.person_outline_rounded,
                        lead.contactPerson,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.currency_rupee_rounded,
                                size: 13,
                                color: activeProposal != null
                                    ? AppTheme.primaryPurple
                                    : Colors.grey.shade500,
                              ),
                              Text(
                                displayValue.toStringAsFixed(0),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: activeProposal != null
                                      ? AppTheme.primaryPurple
                                      : AppTheme.primaryDark,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              lead.primaryCategory.value.toUpperCase(),
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) => Row(
    children: [
      Icon(icon, size: 13, color: Colors.grey.shade400),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          text,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );

  Widget _pitchedBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: AppTheme.primaryPurple.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(4),
    ),
    child: const Text(
      'PROPOSAL SENT',
      style: TextStyle(
        fontSize: 8,
        fontWeight: FontWeight.bold,
        color: AppTheme.primaryPurple,
      ),
    ),
  );
}
