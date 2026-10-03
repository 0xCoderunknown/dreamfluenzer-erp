import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/app_enums.dart';
import '../../models/creator_model.dart';
import '../../theme/app_theme.dart';

class ProposalRowItem extends StatelessWidget {
  final Creator creator;
  final bool isSelected;
  final double effectiveRate;
  final int activeTasks;
  final List<Map<String, dynamic>> upcomingTasks;
  final Map<DeliverableType, int> deliverableCounts;
  final Function(DeliverableType type, int delta) onDeliverableChanged;
  final TextEditingController rateCtrl;

  final TextEditingController usageRightsCtrl;
  final TextEditingController exclusivityCtrl;

  final Function(bool?) onToggle;
  final VoidCallback onChanged;

  const ProposalRowItem({
    super.key,
    required this.creator,
    required this.isSelected,
    required this.effectiveRate,
    required this.activeTasks,
    required this.upcomingTasks,
    required this.deliverableCounts,
    required this.onDeliverableChanged,
    required this.rateCtrl,
    required this.usageRightsCtrl,
    required this.exclusivityCtrl,
    required this.onToggle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat('#,##0', 'en_IN');
    final bool isBusy =
        creator.busyFrom != null &&
        creator.busyTo != null &&
        creator.busyTo!.isAfter(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isBusy || upcomingTasks.isNotEmpty)
          _buildCapacityIntelBanner(isBusy),
        Container(
          color: isSelected
              ? AppTheme.primaryPurple.withValues(alpha: 0.03)
              : Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CheckboxListTile(
                activeColor: AppTheme.primaryPurple,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                value: isSelected,
                onChanged: onToggle,
                title: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppTheme.primaryPurple.withValues(
                        alpha: 0.1,
                      ),
                      child: Text(
                        creator.fullName[0].toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppTheme.primaryPurple,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                creator.fullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppTheme.primaryDark,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '@${creator.handle}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              if (creator.status == CreatorStatus.trial)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: Colors.amber.shade300,
                                    ),
                                  ),
                                  child: Text(
                                    'TRIAL CC',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber.shade900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _metaBadge(
                                Icons.movie_creation_outlined,
                                creator.primaryCategory.value,
                              ),
                              if (creator.secondaryNiche.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                _metaBadge(
                                  Icons.analytics_outlined,
                                  creator.secondaryNiche,
                                ),
                              ],
                              if (creator.location.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                _metaBadge(
                                  Icons.location_on_outlined,
                                  creator.location,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 14.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Base Rate: ₹${currencyFmt.format(effectiveRate)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (creator.type == CreatorType.influencer) ...[
                            Text(
                              '  ·  ',
                              style: TextStyle(color: Colors.grey.shade400),
                            ),
                            Icon(
                              Icons.people_outline_rounded,
                              size: 13,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${currencyFmt.format(creator.followerCount)} followers',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: creator.type == CreatorType.ugcCreator
                              ? Colors.teal.shade50
                              : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: creator.type == CreatorType.ugcCreator
                                ? Colors.teal.shade200
                                : Colors.blue.shade200,
                          ),
                        ),
                        child: Text(
                          creator.type == CreatorType.ugcCreator
                              ? 'Professional UGC'
                              : creator.type.value.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: creator.type == CreatorType.ugcCreator
                                ? Colors.teal.shade800
                                : Colors.blue.shade800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isSelected)
                Padding(
                  padding: const EdgeInsets.fromLTRB(72.0, 0.0, 16.0, 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text(
                        'Deliverables:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: DeliverableType.values.map((type) {
                          final count = deliverableCounts[type] ?? 0;
                          return _buildCounter(type, count);
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: usageRightsCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Content Usage Rights',
                                hintText: 'e.g. 30 Days (Social Media)',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: exclusivityCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Category Exclusivity',
                                hintText: 'e.g. 14 Days (Same Category)',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: 220,
                        child: TextFormField(
                          controller: rateCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Agreed Payout (₹)',
                            isDense: true,
                            prefixIcon: const Icon(
                              Icons.currency_rupee_rounded,
                              size: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryDark,
                          ),
                          onChanged: (_) => onChanged(),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _metaBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapacityIntelBanner(bool isBusy) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border(
          left: BorderSide(color: Colors.orange.shade300, width: 4),
          bottom: BorderSide(color: Colors.orange.shade100),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isBusy)
            Row(
              children: [
                const Icon(Icons.block, size: 14, color: Colors.red),
                const SizedBox(width: 6),
                Text(
                  'AWAY: ${DateFormat('dd MMM').format(creator.busyFrom!)} to ${DateFormat('dd MMM').format(creator.busyTo!)}',
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          if (isBusy && upcomingTasks.isNotEmpty) const SizedBox(height: 4),
          if (upcomingTasks.isNotEmpty)
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 14,
                  color: Colors.orange.shade900,
                ),
                const SizedBox(width: 6),
                Text(
                  'HEAVY WORKLOAD: ${upcomingTasks.length} pending tasks in next 30 days.',
                  style: TextStyle(
                    color: Colors.orange.shade900,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCounter(DeliverableType type, int count) {
    final isActive = count > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.primaryPurple.withValues(alpha: 0.1)
            : Colors.grey.shade100,
        border: Border.all(
          color: isActive
              ? AppTheme.primaryPurple.withValues(alpha: 0.3)
              : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            type.value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isActive ? AppTheme.primaryPurple : Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: count > 0 ? () => onDeliverableChanged(type, -1) : null,
            child: Icon(
              Icons.remove_circle_outline,
              size: 20,
              color: isActive ? AppTheme.primaryPurple : Colors.grey.shade400,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isActive ? AppTheme.primaryDark : Colors.grey.shade500,
              ),
            ),
          ),
          InkWell(
            onTap: () => onDeliverableChanged(type, 1),
            child: const Icon(
              Icons.add_circle_outline,
              size: 20,
              color: AppTheme.primaryPurple,
            ),
          ),
        ],
      ),
    );
  }
}
