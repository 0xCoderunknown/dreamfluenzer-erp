import 'package:flutter/material.dart';

import '../../models/campaign_model.dart';

/// Presentation section rendering Google Drive submission links for allocated items
class CreatorSubmissionLinksSection extends StatelessWidget {
  final List<AllocatedItem> allocatedItems;
  final bool isLocked;
  final void Function(AllocatedItem item, String notes) onNotesChanged;

  const CreatorSubmissionLinksSection({
    super.key,
    required this.allocatedItems,
    required this.isLocked,
    required this.onNotesChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (allocatedItems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Submission Links',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 16),
        ...allocatedItems.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    item.itemName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 5,
                  child: TextFormField(
                    initialValue: item.notes,
                    enabled: !isLocked,
                    decoration: const InputDecoration(
                      hintText: 'Paste your Google Drive link here',
                      hintStyle: TextStyle(fontSize: 11, color: Colors.grey),
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      prefixIcon: Icon(Icons.link_rounded, size: 16),
                    ),
                    style: const TextStyle(fontSize: 12),
                    onChanged: (val) => onNotesChanged(item, val),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
