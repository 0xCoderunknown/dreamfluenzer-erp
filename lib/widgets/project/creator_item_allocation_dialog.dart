import 'package:flutter/material.dart';

import '../../models/campaign_model.dart';

/// Modal dialog allowing project operators to allocate products from the Campaign Inventory Pool
Future<void> showCreatorItemAllocationDialog({
  required BuildContext context,
  required Campaign campaign,
  required AssignedCreator creator,
  required List<AllocatedItem> currentAllocations,
  required ValueChanged<AllocatedItem> onAllocated,
}) async {
  final availableItems = campaign.inventoryPool.where((item) {
    int usedElsewhere = 0;
    for (var ac in campaign.assignedCreators) {
      if (ac.creatorId != creator.creatorId) {
        for (var alloc in ac.allocatedItems) {
          if (alloc.inventoryId == item.id) usedElsewhere += alloc.quantity;
        }
      }
    }
    int usedHere = 0;
    for (var alloc in currentAllocations) {
      if (alloc.inventoryId == item.id) usedHere += alloc.quantity;
    }
    return (item.totalQuantity - usedElsewhere - usedHere) > 0;
  }).toList();

  if (availableItems.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No inventory items left in the campaign pool.'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  CampaignInventory? selectedItem;
  final qtyCtrl = TextEditingController(text: '1');
  String? errorText;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Allocate from Pool'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<CampaignInventory>(
              items: availableItems
                  .map(
                    (i) => DropdownMenuItem(value: i, child: Text(i.itemName)),
                  )
                  .toList(),
              onChanged: (v) => setDialogState(() {
                selectedItem = v;
                errorText = null;
              }),
              decoration: const InputDecoration(labelText: 'Select Item'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Quantity',
                errorText: errorText,
              ),
              onChanged: (_) => setDialogState(() => errorText = null),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (selectedItem == null) return;

              final requestedQty = int.tryParse(qtyCtrl.text) ?? 0;
              if (requestedQty <= 0) return;

              int totalUsedElsewhere = 0;
              for (var ac in campaign.assignedCreators) {
                if (ac.creatorId != creator.creatorId) {
                  for (var item in ac.allocatedItems) {
                    if (item.inventoryId == selectedItem!.id) {
                      totalUsedElsewhere += item.quantity;
                    }
                  }
                }
              }

              int usedHere = 0;
              for (var item in currentAllocations) {
                if (item.inventoryId == selectedItem!.id) {
                  usedHere += item.quantity;
                }
              }

              final availableQty =
                  selectedItem!.totalQuantity - totalUsedElsewhere - usedHere;

              if (requestedQty > availableQty) {
                setDialogState(() => errorText = 'Only $availableQty left!');
                return;
              }

              onAllocated(
                AllocatedItem(
                  inventoryId: selectedItem!.id,
                  itemName: selectedItem!.itemName,
                  quantity: requestedQty,
                ),
              );

              Navigator.pop(ctx);
            },
            child: const Text('Allocate'),
          ),
        ],
      ),
    ),
  );
}
