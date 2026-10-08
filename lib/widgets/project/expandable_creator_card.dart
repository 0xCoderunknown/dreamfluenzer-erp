import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/app_enums.dart';
import '../../domain/froyo_rules.dart';
import '../../models/campaign_model.dart';
import '../../models/project_model.dart';
import '../../providers/campaign_provider.dart';
import '../../theme/app_theme.dart';
import '../common/ui_kit.dart';

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
