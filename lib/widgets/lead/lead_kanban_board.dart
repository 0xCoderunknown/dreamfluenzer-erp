import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/app_enums.dart';
import '../../models/lead_model.dart';
import '../../models/proposal_model.dart';
import '../../providers/lead_provider.dart';
import '../../providers/proposal_provider.dart';
import '../../theme/app_theme.dart';
import 'lead_widgets.dart';

class LeadKanbanBoard extends StatelessWidget {
  final List<Lead> leads;

  const LeadKanbanBoard({super.key, required this.leads});

  @override
  Widget build(BuildContext context) {
    const statuses = LeadStatus.values;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: statuses.map((status) {
        final leadsForStatus = leads.where((l) => l.status == status).toList();
        final statusColor = AppTheme.getStatusColor(status.value);

        return Expanded(
          child: DragTarget<Lead>(
            onAcceptWithDetails: (details) {
              final lead = details.data;
              if (lead.status != status) {
                context.read<LeadProvider>().updateLeadStatus(lead.id, status);
              }
            },
            builder: (context, candidateData, _) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                decoration: BoxDecoration(
                  color: candidateData.isNotEmpty
                      ? statusColor.withValues(alpha: 0.08)
                      : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: candidateData.isNotEmpty
                        ? statusColor.withValues(alpha: 0.3)
                        : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  children: [
                    _buildColumnHeader(
                      status,
                      statusColor,
                      leadsForStatus.length,
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        itemCount: leadsForStatus.length,
                        itemBuilder: (context, index) =>
                            _DraggableLeadCard(lead: leadsForStatus[index]),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildColumnHeader(LeadStatus status, Color color, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            status.value.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: 1.2,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DraggableLeadCard extends StatelessWidget {
  final Lead lead;

  const _DraggableLeadCard({required this.lead});

  @override
  Widget build(BuildContext context) {
    final proposals = context.select<ProposalProvider, List<Proposal>>(
      (prov) => prov.getProposalsForLead(lead.id),
    );

    final hasPitch = proposals.isNotEmpty;
    final activeProposal = hasPitch
        ? proposals.firstWhere(
            (p) => p.status == ProposalStatus.accepted,
            orElse: () => proposals.first,
          )
        : null;
    final displayValue =
        activeProposal?.totalClientPrice ?? lead.estimatedBudget;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Draggable<Lead>(
        data: lead,
        feedback: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          color: Colors.transparent,
          child: SizedBox(
            width: 260,
            child: LeadCard(
              lead: lead,
              isDragging: true,
              hasPitch: hasPitch,
              activeProposal: activeProposal,
              displayValue: displayValue,
            ),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.2,
          child: LeadCard(
            lead: lead,
            hasPitch: hasPitch,
            activeProposal: activeProposal,
            displayValue: displayValue,
          ),
        ),
        child: LeadCard(
          lead: lead,
          hasPitch: hasPitch,
          activeProposal: activeProposal,
          displayValue: displayValue,
        ),
      ),
    );
  }
}
