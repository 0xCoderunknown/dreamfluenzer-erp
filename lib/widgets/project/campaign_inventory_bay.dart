import 'package:flutter/material.dart';

import '../../models/campaign_model.dart';
import '../../providers/campaign_provider.dart';
import '../../theme/app_theme.dart';

/// Product pool and logistics inventory bay for a campaign
class CampaignInventoryBay extends StatelessWidget {
  final Campaign campaign;
  final CampaignProvider campaignProv;
  final bool isLocked;

  const CampaignInventoryBay({
    super.key,
    required this.campaign,
    required this.campaignProv,
    required this.isLocked,
  });

  int getAvailableQty(CampaignInventory item) {
    int used = 0;
    for (var ac in campaign.assignedCreators) {
      for (var alloc in ac.allocatedItems) {
        if (alloc.inventoryId == item.id) used += alloc.quantity;
      }
    }
    return item.totalQuantity - used;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryPurple.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryPurple.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'PRODUCT POOL',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryPurple,
                  letterSpacing: 1,
                ),
              ),
              if (!isLocked)
                ElevatedButton.icon(
                  onPressed: () => showAddEditInventoryDialog(context),
                  icon: const Icon(Icons.add_box_outlined, size: 16),
                  label: const Text('Add Item to Pool'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPurple.withValues(
                      alpha: 0.1,
                    ),
                    foregroundColor: AppTheme.primaryPurple,
                    elevation: 0,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (campaign.inventoryPool.isEmpty)
            const Text(
              'No items received for this campaign yet.',
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            )
          else
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: campaign.inventoryPool
                  .map((item) => _inventoryChip(context, item))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _inventoryChip(BuildContext context, CampaignInventory item) {
    final available = getAvailableQty(item);
    final isDepleted = available <= 0;

    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDepleted ? Colors.grey.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDepleted ? Colors.grey.shade200 : Colors.blue.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.inventory_2_rounded,
                size: 20,
                color: isDepleted ? Colors.grey : Colors.blue.shade700,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.itemName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDepleted
                        ? Colors.grey.shade600
                        : AppTheme.primaryDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (item.isReturnable)
                const Tooltip(
                  message: 'Returnable Item',
                  child: Icon(
                    Icons.assignment_return,
                    size: 16,
                    color: Colors.red,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Remaining',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$available / ${item.totalQuantity}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDepleted ? Colors.red : AppTheme.success,
                    ),
                  ),
                ],
              ),
              if (!isLocked)
                InkWell(
                  onTap: () =>
                      showAddEditInventoryDialog(context, existingItem: item),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.edit_rounded,
                          size: 14,
                          color: AppTheme.primaryPurple,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Edit',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryPurple,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void showAddEditInventoryDialog(
    BuildContext context, {
    CampaignInventory? existingItem,
  }) {
    final nameCtrl = TextEditingController(text: existingItem?.itemName ?? '');
    final qtyCtrl = TextEditingController(
      text: existingItem?.totalQuantity.toString() ?? '1',
    );
    final gmvCtrl = TextEditingController(
      text: existingItem?.gmvPerUnit.toString() ?? '0',
    );
    bool isReturnable = existingItem?.isReturnable ?? false;
    final isNew = existingItem == null;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FF),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isNew ? Icons.add_box_rounded : Icons.edit_square,
                        color: AppTheme.primaryPurple,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isNew ? 'Add Item to Pool' : 'Edit Inventory Item',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        decoration: InputDecoration(
                          labelText: 'Item Name (e.g., Vitamin C Face Wash)',
                          prefixIcon: const Icon(Icons.inventory_2_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: qtyCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Total Quantity',
                                prefixIcon: const Icon(Icons.numbers_rounded),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: TextFormField(
                              controller: gmvCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'GMV / MRP per unit',
                                prefixIcon: const Icon(
                                  Icons.currency_rupee_rounded,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(
                        decoration: BoxDecoration(
                          color: isReturnable
                              ? Colors.red.shade50
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isReturnable
                                ? Colors.red.shade200
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: SwitchListTile(
                          title: const Text(
                            'Must be returned after use?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            'Turn ON if this is a high-value item (like a camera) that the creator needs to return after shooting.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          value: isReturnable,
                          activeThumbColor: Colors.red,
                          onChanged: (v) =>
                              setDialogState(() => isReturnable = v),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 24,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (!isNew)
                        TextButton.icon(
                          onPressed: () {
                            final updatedPool = campaign.inventoryPool
                                .where((i) => i.id != existingItem.id)
                                .toList();
                            campaignProv.updateCampaign(
                              campaign.copyWith(inventoryPool: updatedPool),
                            );
                            Navigator.pop(ctx);
                          },
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 18,
                          ),
                          label: const Text(
                            'Delete Item',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          final item = CampaignInventory(
                            id:
                                existingItem?.id ??
                                'inv_${DateTime.now().millisecondsSinceEpoch}',
                            itemName: nameCtrl.text.trim(),
                            totalQuantity: int.tryParse(qtyCtrl.text) ?? 1,
                            gmvPerUnit: double.tryParse(gmvCtrl.text) ?? 0.0,
                            isReturnable: isReturnable,
                          );

                          final updatedPool = List<CampaignInventory>.from(
                            campaign.inventoryPool,
                          );
                          if (!isNew) {
                            final idx = updatedPool.indexWhere(
                              (i) => i.id == existingItem.id,
                            );
                            updatedPool[idx] = item;
                          } else {
                            updatedPool.add(item);
                          }

                          campaignProv.updateCampaign(
                            campaign.copyWith(inventoryPool: updatedPool),
                          );
                          Navigator.pop(ctx);
                        },
                        child: Text(isNew ? 'Save to Pool' : 'Update Item'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
