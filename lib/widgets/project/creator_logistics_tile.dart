import 'package:flutter/material.dart';

import '../../domain/app_enums.dart';
import '../../models/campaign_model.dart';
import '../../theme/app_theme.dart';

/// Logistics dispatch & return tracking tile for an assigned creator
class CreatorLogisticsTile extends StatelessWidget {
  final AssignedCreator creator;
  final List<AllocatedItem> allocatedItems;
  final void Function(AllocatedItem item, AllocationStatus newStatus)
  onStatusChanged;

  const CreatorLogisticsTile({
    super.key,
    required this.creator,
    required this.allocatedItems,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.orange.shade200),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primaryPurple.withValues(alpha: 0.12),
                child: Text(
                  creator.creatorName[0].toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryPurple,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                creator.creatorName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          if (allocatedItems.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'No items allocated.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            )
          else
            ...allocatedItems.map(
              (item) => Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${item.quantity}x ${item.itemName}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<AllocationStatus>(
                        initialValue: item.status,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                        ),
                        items: AllocationStatus.values
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(
                                  s.value,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) onStatusChanged(item, val);
                        },
                      ),
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
