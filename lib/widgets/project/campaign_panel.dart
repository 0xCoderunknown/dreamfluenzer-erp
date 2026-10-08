import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/campaign_model.dart';
import '../../models/project_model.dart';
import '../../providers/campaign_provider.dart';
import '../../theme/app_theme.dart';
import '../common/ui_kit.dart';
import 'expandable_creator_card.dart';
import 'project_dialogs.dart';

class CampaignPanel extends StatefulWidget {
  final Campaign campaign;
  final Project project;
  final CampaignProvider campaignProv;
  final bool isExpanded;
  final bool isLocked;
  final VoidCallback onToggle;

  const CampaignPanel({
    super.key,
    required this.campaign,
    required this.project,
    required this.campaignProv,
    required this.isExpanded,
    required this.isLocked,
    required this.onToggle,
  });

  @override
  State<CampaignPanel> createState() => _CampaignPanelState();
}

class _CampaignPanelState extends State<CampaignPanel> {
  bool _isLogisticsMode = false;

  int _getAvailableQty(CampaignInventory item) {
    int used = 0;
    for (var ac in widget.campaign.assignedCreators) {
      for (var alloc in ac.allocatedItems) {
        if (alloc.inventoryId == item.id) used += alloc.quantity;
      }
    }
    return item.totalQuantity - used;
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isExpanded
              ? AppTheme.primaryPurple.withValues(alpha: 0.4)
              : Colors.grey.shade200,
          width: widget.isExpanded ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          _buildHeader(context, dateFmt),
          if (widget.isExpanded) _buildExpandedBody(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, DateFormat fmt) {
    return InkWell(
      onTap: widget.onToggle,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            _iconBox(Icons.campaign_rounded),
            const SizedBox(width: 14),
            Expanded(child: _titleSection(context, fmt)),
            const SizedBox(width: 12),
            if (widget.isExpanded)
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text(
                      'Finance & Content',
                      style: TextStyle(fontSize: 12),
                    ),
                    icon: Icon(Icons.monetization_on, size: 16),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text(
                      'Logistics Bay',
                      style: TextStyle(fontSize: 12),
                    ),
                    icon: Icon(Icons.inventory_2, size: 16),
                  ),
                ],
                selected: {_isLogisticsMode},
                onSelectionChanged: (val) =>
                    setState(() => _isLogisticsMode = val.first),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith<Color?>((
                    states,
                  ) {
                    if (states.contains(WidgetState.selected)) {
                      return Colors.orange.shade100;
                    }
                    return Colors.white;
                  }),
                ),
              ),
            const SizedBox(width: 12),
            _expandArrow(),
          ],
        ),
      ),
    );
  }

  Widget _iconBox(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.primaryPurple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: AppTheme.primaryPurple, size: 20),
    );
  }

  Widget _titleSection(BuildContext context, DateFormat fmt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.campaign.title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppTheme.primaryDark,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Text(
                widget.project.dealType.value,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
            if (!widget.isLocked) ...[
              const SizedBox(width: 12),
              _actionIcon(
                Icons.edit_rounded,
                Colors.grey,
                () => _editTitle(context),
              ),
              const SizedBox(width: 8),
              _actionIcon(
                Icons.delete_rounded,
                Colors.red,
                () => _confirmDelete(context),
              ),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(
          'Cycle ends: ${fmt.format(widget.campaign.cycleEndDate)}  ·  ${widget.campaign.assignedCreators.length} ${widget.campaign.assignedCreators.length == 1 ? "creator" : "creators"}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  Widget _actionIcon(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Icon(icon, size: 14, color: color.withValues(alpha: 0.6)),
    );
  }

  Widget _expandArrow() {
    return AnimatedRotation(
      turns: widget.isExpanded ? 0.5 : 0,
      duration: const Duration(milliseconds: 200),
      child: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: Colors.grey.shade400,
      ),
    );
  }

  Widget _buildExpandedBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_isLogisticsMode) _buildInventoryPoolHeader(context),

          const SizedBox(height: 16),

          if (widget.campaign.assignedCreators.isEmpty)
            _emptyState()
          else
            ...widget.campaign.assignedCreators.map(
              (creator) => ExpandableCreatorCard(
                creator: creator,
                campaign: widget.campaign,
                project: widget.project,
                campaignProv: widget.campaignProv,
                isLocked: widget.isLocked,
                isLogisticsMode: _isLogisticsMode,
              ),
            ),

          if (!widget.isLocked && !_isLogisticsMode) _assignButton(context),
        ],
      ),
    );
  }

  Widget _buildInventoryPoolHeader(BuildContext context) {
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
              if (!widget.isLocked)
                ElevatedButton.icon(
                  onPressed: () => _showAddEditInventoryDialog(context),
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
          if (widget.campaign.inventoryPool.isEmpty)
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
              children: widget.campaign.inventoryPool
                  .map((item) => _inventoryChip(item))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _inventoryChip(CampaignInventory item) {
    final available = _getAvailableQty(item);
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
              if (!widget.isLocked)
                InkWell(
                  onTap: () =>
                      _showAddEditInventoryDialog(context, existingItem: item),
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

  void _showAddEditInventoryDialog(
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
                            final updatedPool = widget.campaign.inventoryPool
                                .where((i) => i.id != existingItem.id)
                                .toList();
                            widget.campaignProv.updateCampaign(
                              widget.campaign.copyWith(
                                inventoryPool: updatedPool,
                              ),
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
                            widget.campaign.inventoryPool,
                          );
                          if (!isNew) {
                            final idx = updatedPool.indexWhere(
                              (i) => i.id == existingItem.id,
                            );
                            updatedPool[idx] = item;
                          } else {
                            updatedPool.add(item);
                          }

                          widget.campaignProv.updateCampaign(
                            widget.campaign.copyWith(
                              inventoryPool: updatedPool,
                            ),
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

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'No creator assigned to this campaign.',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        ),
      ),
    );
  }

  Widget _assignButton(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: OutlinedButton.icon(
          onPressed: () => showDialog(
            context: context,
            builder: (_) => AssigncreatorDialog(
              project: widget.project,
              campaign: widget.campaign,
              onAssign: (creator) =>
                  widget.campaignProv.assignCreatorToCampaign(
                    projectId: widget.project.id,
                    campaignId: widget.campaign.id,
                    creator: creator,
                  ),
            ),
          ),
          icon: const Icon(Icons.person_add_rounded, size: 16),
          label: const Text('Assign Creator'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primaryPurple,
            side: const BorderSide(color: AppTheme.primaryPurple),
          ),
        ),
      ),
    );
  }

  void _editTitle(BuildContext context) async {
    final ctrl = TextEditingController(text: widget.campaign.title);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    await showDialog(
      context: context,
      builder: (diagContext) => AlertDialog(
        title: const Text('Edit Campaign Title'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'New title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(diagContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newTitle = ctrl.text.trim();
              if (newTitle.isNotEmpty && newTitle != widget.campaign.title) {
                await widget.campaignProv.updateCampaignTitle(
                  widget.campaign.projectId,
                  widget.campaign.id,
                  newTitle,
                );

                if (!mounted) return;

                if (diagContext.mounted) Navigator.pop(diagContext);
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('Title updated')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    ctrl.dispose();
  }

  void _confirmDelete(BuildContext context) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDreamConfirm(
      context,
      title: 'Delete Campaign?',
      body:
          'This will remove all creator assignments within this cycle. This cannot be undone.',
      confirmText: 'Delete Cycle',
      isDestructive: true,
    ).then((confirmed) async {
      if (confirmed == true) {
        if (!mounted) return;
        try {
          await widget.campaignProv.deleteCampaign(
            widget.campaign.projectId,
            widget.campaign.id,
          );

          if (!mounted) return;

          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Campaign deleted')),
          );
        } catch (e) {
          if (!mounted) return;
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    });
  }
}
