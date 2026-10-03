import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/app_enums.dart';
import '../../domain/froyo_rules.dart';
import '../../models/campaign_model.dart';
import '../../models/project_model.dart';
import '../../providers/campaign_provider.dart';
import '../../theme/app_theme.dart';
import '../common/ui_kit.dart';
import 'project_dialogs.dart';

// ===========================================================================
// CAMPAIGN LIST (Manages Expansion State)
// ===========================================================================
class CampaignList extends StatefulWidget {
  final List<Campaign> campaigns;
  final Project project;
  final CampaignProvider campaignProv;
  final bool isLocked;

  const CampaignList({
    super.key,
    required this.campaigns,
    required this.project,
    required this.campaignProv,
    required this.isLocked,
  });

  @override
  State<CampaignList> createState() => CampaignListState();
}

class CampaignListState extends State<CampaignList> {
  final Set<String> _expandedIds = {};

  @override
  void initState() {
    super.initState();
    if (widget.campaigns.isNotEmpty) {
      _expandedIds.add(widget.campaigns.last.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: widget.campaigns.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final c = widget.campaigns[i];
        return CampaignPanel(
          campaign: c,
          project: widget.project,
          campaignProv: widget.campaignProv,
          isExpanded: _expandedIds.contains(c.id),
          isLocked: widget.isLocked,
          onToggle: () => setState(() {
            _expandedIds.contains(c.id)
                ? _expandedIds.remove(c.id)
                : _expandedIds.add(c.id);
          }),
        );
      },
    );
  }
}

// ===========================================================================
// CAMPAIGN PANEL (Inventory Pool + Logistics Mode Toggle)
// ===========================================================================
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

// CREATOR CARD
class ExpandableCreatorCard extends StatefulWidget {
  final AssignedCreator creator;
  final Campaign campaign;
  final Project project;
  final CampaignProvider campaignProv;
  final bool isLocked;
  final bool isLogisticsMode;

  const ExpandableCreatorCard({
    super.key,
    required this.creator,
    required this.campaign,
    required this.project,
    required this.campaignProv,
    required this.isLocked,
    required this.isLogisticsMode,
  });

  @override
  State<ExpandableCreatorCard> createState() => ExpandableCreatorCardState();
}

class ExpandableCreatorCardState extends State<ExpandableCreatorCard> {
  bool _isExpanded = false;
  late TextEditingController _advanceCtrl;
  late DateTime _deadline;
  late PipelineStatus _pipelineStatus;
  late bool _isPaid;
  late List<AllocatedItem> _allocatedItems;

  bool _hasUnsavedChanges = false;
  bool _hasError = false;
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
    _advanceCtrl = TextEditingController();
    _initForm();
  }

  @override
  void dispose() {
    _advanceCtrl.dispose();
    super.dispose();
  }

  void _initForm() {
    _advanceCtrl.text = widget.creator.advancePaid.toStringAsFixed(0);
    _deadline = widget.creator.individualDeadline;
    _pipelineStatus = widget.creator.pipelineStatus;
    _isPaid = widget.creator.isPaid;
    _allocatedItems = List.from(widget.creator.allocatedItems);
    _validateMath();
  }

  void _checkForChanges() {
    setState(() => _hasUnsavedChanges = true);
    _validateMath();
  }

  void _validateMath() {
    final enteredAdvance = double.tryParse(_advanceCtrl.text) ?? 0.0;

    // Calculate total advance paid to other creators in this project across campaigns
    double otherAdvances = 0.0;
    for (final camp in widget.campaignProv.campaigns) {
      if (camp.projectId != widget.project.id) continue;
      for (final ac in camp.assignedCreators) {
        if (camp.id != widget.campaign.id ||
            ac.creatorId != widget.creator.creatorId) {
          otherAdvances += ac.advancePaid;
        }
      }
    }

    final validation = FroyoRules.validateAdvancePayment(
      requestedAdvance: enteredAdvance,
      agreedPayout: widget.creator.agreedPayout,
      projectAdvanceReceived: widget.project.advanceReceived,
      otherCreatorsTotalAdvance: otherAdvances,
    );

    if (!validation.isValid) {
      setState(() {
        _hasError = true;
        _errorMsg = validation.message;
      });
      return;
    }

    setState(() {
      _hasError = false;
      _errorMsg = '';
    });
  }

  void _save() {
    if (_hasError) return;

    final updatedCreator = widget.creator.copyWith(
      individualDeadline: _deadline,
      pipelineStatus: _pipelineStatus,
      isPaid: _isPaid,
      advancePaid: double.tryParse(_advanceCtrl.text) ?? 0.0,
      allocatedItems: _allocatedItems,
    );
    widget.campaignProv.updateCreatorInCampaign(
      projectId: widget.project.id,
      campaignId: widget.campaign.id,
      updatedCreator: updatedCreator,
    );
    setState(() {
      _hasUnsavedChanges = false;
      _isExpanded = false;
    });
  }

  bool get _canChangePipeline {
    if (_allocatedItems.isEmpty) return true;
    return _allocatedItems.every((item) {
      final poolItem = widget.campaign.inventoryPool
          .where((p) => p.id == item.inventoryId)
          .firstOrNull;

      if (poolItem != null && !poolItem.isReturnable) return true;

      return item.status == AllocationStatus.received ||
          item.status == AllocationStatus.returned;
    });
  }

  bool get _canMarkPaid {
    for (var item in _allocatedItems) {
      final poolItem = widget.campaign.inventoryPool
          .where((p) => p.id == item.inventoryId)
          .firstOrNull;

      if (poolItem != null &&
          poolItem.isReturnable &&
          item.status != AllocationStatus.returned) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLogisticsMode) return _buildLogisticsOnlyRow();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: _isExpanded ? 3 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _isExpanded ? AppTheme.primaryPurple : Colors.grey.shade200,
        ),
      ),
      child: ExpansionTile(
        initiallyExpanded: _isExpanded,
        onExpansionChanged: (val) => setState(() => _isExpanded = val),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: _buildCardHeader(),
        children: [_buildEditForm()],
      ),
    );
  }

  Widget _buildLogisticsOnlyRow() {
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
              _avatar(),
              const SizedBox(width: 12),
              Text(
                widget.creator.creatorName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          if (_allocatedItems.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'No items allocated.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            )
          else
            ..._allocatedItems.map(
              (item) => _buildExplicitLogisticsControls(item),
            ),
        ],
      ),
    );
  }

  Widget _buildExplicitLogisticsControls(AllocatedItem item) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '${item.quantity}x ${item.itemName}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
                if (val != null) {
                  setState(() {
                    final idx = _allocatedItems.indexWhere(
                      (i) => i.inventoryId == item.inventoryId,
                    );
                    _allocatedItems[idx] = AllocatedItem(
                      inventoryId: item.inventoryId,
                      itemName: item.itemName,
                      quantity: item.quantity,
                      status: val,
                      notes: item.notes,
                    );
                  });
                  _checkForChanges();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardHeader() {
    int totalItemsAllocated = _allocatedItems.fold(
      0,
      (sum, item) => sum + item.quantity,
    );

    return Row(
      children: [
        _avatar(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.creator.creatorName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Text(
                'Allocated: $totalItemsAllocated products',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        DreamStatusChip(label: widget.creator.pipelineStatus.value),
      ],
    );
  }

  Widget _avatar() {
    return CircleAvatar(
      radius: 16,
      backgroundColor: AppTheme.primaryPurple.withValues(alpha: 0.12),
      child: Text(
        widget.creator.creatorName[0].toUpperCase(),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryPurple,
        ),
      ),
    );
  }

  Widget _buildEditForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAllocationSection(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Divider(height: 1),
          ),
          _buildStatusHeader('STATUS & PAYMENT'),
          const SizedBox(height: 16),
          _formRow1(),
          const SizedBox(height: 16),
          _formRow2(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Divider(height: 1),
          ),
          _buildTrackingSection(),
          if (!widget.isLocked) _actionButtons(),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildAllocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatusHeader('Allocated Products'),
            if (!widget.isLocked)
              TextButton.icon(
                onPressed: _showOriginalItemDialog,
                icon: const Icon(Icons.add, size: 14),
                label: const Text(
                  'Allocate Item',
                  style: TextStyle(fontSize: 11),
                ),
              ),
          ],
        ),
        if (_allocatedItems.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No items allocated to this creator yet.',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          )
        else
          ..._allocatedItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item.quantity}x ${item.itemName}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Text(
                    'Status: ${item.status.value}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryPurple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!widget.isLocked)
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.red,
                      ),
                      padding: const EdgeInsets.only(left: 16),
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        setState(
                          () => _allocatedItems.removeWhere(
                            (i) => i.inventoryId == item.inventoryId,
                          ),
                        );
                        _checkForChanges();
                      },
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTrackingSection() {
    if (_allocatedItems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatusHeader('Submission Links'),
        const SizedBox(height: 16),
        ..._allocatedItems.map(
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
                    enabled: !widget.isLocked,
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
                    onChanged: (val) {
                      setState(() {
                        final idx = _allocatedItems.indexWhere(
                          (i) => i.inventoryId == item.inventoryId,
                        );
                        _allocatedItems[idx] = AllocatedItem(
                          inventoryId: item.inventoryId,
                          itemName: item.itemName,
                          quantity: item.quantity,
                          status: item.status,
                          notes: val,
                        );
                      });
                      _checkForChanges();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showOriginalItemDialog() {
    final availableItems = widget.campaign.inventoryPool.where((item) {
      int usedElsewhere = 0;
      for (var ac in widget.campaign.assignedCreators) {
        if (ac.creatorId != widget.creator.creatorId) {
          for (var alloc in ac.allocatedItems) {
            if (alloc.inventoryId == item.id) usedElsewhere += alloc.quantity;
          }
        }
      }
      int usedHere = 0;
      for (var alloc in _allocatedItems) {
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

    showDialog(
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
                      (i) =>
                          DropdownMenuItem(value: i, child: Text(i.itemName)),
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
                for (var ac in widget.campaign.assignedCreators) {
                  if (ac.creatorId != widget.creator.creatorId) {
                    for (var item in ac.allocatedItems) {
                      if (item.inventoryId == selectedItem!.id) {
                        totalUsedElsewhere += item.quantity;
                      }
                    }
                  }
                }

                int usedHere = 0;
                for (var item in _allocatedItems) {
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

                setState(() {
                  final existingIdx = _allocatedItems.indexWhere(
                    (i) => i.inventoryId == selectedItem!.id,
                  );
                  if (existingIdx >= 0) {
                    final ex = _allocatedItems[existingIdx];
                    _allocatedItems[existingIdx] = AllocatedItem(
                      inventoryId: ex.inventoryId,
                      itemName: ex.itemName,
                      quantity: ex.quantity + requestedQty,
                      status: ex.status,
                      notes: ex.notes,
                    );
                  } else {
                    _allocatedItems.add(
                      AllocatedItem(
                        inventoryId: selectedItem!.id,
                        itemName: selectedItem!.itemName,
                        quantity: requestedQty,
                      ),
                    );
                  }
                });

                _checkForChanges();
                Navigator.pop(ctx);
              },
              child: const Text('Allocate'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _formRow1() {
    return Row(
      children: [
        Expanded(
          child: Tooltip(
            message: !_canChangePipeline
                ? 'Cannot change status until all allocated items are received or returned.'
                : '',
            child: DropdownButtonFormField<PipelineStatus>(
              initialValue: _pipelineStatus,
              decoration: InputDecoration(
                labelText: 'Status',
                border: const OutlineInputBorder(),
                isDense: true,
                filled: !_canChangePipeline,
                fillColor: Colors.grey.shade200,
              ),
              items: PipelineStatus.values
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.value)))
                  .toList(),
              onChanged: (widget.isLocked || !_canChangePipeline)
                  ? null
                  : (val) {
                      if (val != null) {
                        setState(() => _pipelineStatus = val);
                        _checkForChanges();
                      }
                    },
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Tooltip(
            message: !_canMarkPaid
                ? 'Cannot pay until all returnable items have been returned.'
                : '',
            child: CheckboxListTile(
              title: Text(
                'Fully Paid',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: !_canMarkPaid ? Colors.grey : Colors.black,
                ),
              ),
              value: _isPaid,
              activeColor: Colors.green,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (widget.isLocked || !_canMarkPaid)
                  ? null
                  : (val) {
                      if (val != null) {
                        setState(() => _isPaid = val);
                        _checkForChanges();
                      }
                    },
            ),
          ),
        ),
      ],
    );
  }

  Widget _formRow2() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _advanceCtrl,
            keyboardType: TextInputType.number,
            enabled: !widget.isLocked,
            decoration: InputDecoration(
              labelText: 'Advance Paid (₹)',
              border: const OutlineInputBorder(),
              isDense: true,
              errorText: _hasError ? _errorMsg : null,
            ),
            onChanged: (_) => _checkForChanges(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: InkWell(
            onTap: widget.isLocked ? null : _pickDate,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Creator Deadline',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(DateFormat('dd MMM yyyy').format(_deadline)),
                  const Icon(Icons.calendar_today, size: 16),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: widget.project.deadline,
    );

    if (!mounted) return;

    if (picked != null) {
      setState(() => _deadline = picked);
      _checkForChanges();
    }
  }

  Widget _actionButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () {
              _initForm();
              setState(() {
                _hasUnsavedChanges = false;
                _isExpanded = false;
              });
            },
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: (_hasUnsavedChanges && !_hasError) ? _save : null,
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }
}
