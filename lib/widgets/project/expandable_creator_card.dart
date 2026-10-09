import 'package:flutter/material.dart';

import '../../domain/app_enums.dart';
import '../../domain/froyo_rules.dart';
import '../../models/campaign_model.dart';
import '../../models/project_model.dart';
import '../../providers/campaign_provider.dart';
import '../../theme/app_theme.dart';
import '../common/ui_kit.dart';
import 'creator_card_status_rows.dart';
import 'creator_item_allocation_dialog.dart';
import 'creator_logistics_tile.dart';
import 'creator_submission_links_section.dart';

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
    if (widget.isLogisticsMode) {
      return CreatorLogisticsTile(
        creator: widget.creator,
        allocatedItems: _allocatedItems,
        onStatusChanged: (item, val) {
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
        },
      );
    }

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
          CreatorCardStatusRows(
            canChangePipeline: _canChangePipeline,
            pipelineStatus: _pipelineStatus,
            onPipelineStatusChanged: (val) {
              setState(() => _pipelineStatus = val);
              _checkForChanges();
            },
            canMarkPaid: _canMarkPaid,
            isPaid: _isPaid,
            onPaidChanged: (val) {
              setState(() => _isPaid = val);
              _checkForChanges();
            },
            advanceCtrl: _advanceCtrl,
            hasError: _hasError,
            errorMsg: _errorMsg,
            onAdvanceChanged: _checkForChanges,
            deadline: _deadline,
            onPickDate: _pickDate,
            isLocked: widget.isLocked,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Divider(height: 1),
          ),
          CreatorSubmissionLinksSection(
            allocatedItems: _allocatedItems,
            isLocked: widget.isLocked,
            onNotesChanged: (item, val) {
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
                onPressed: () => showCreatorItemAllocationDialog(
                  context: context,
                  campaign: widget.campaign,
                  creator: widget.creator,
                  currentAllocations: _allocatedItems,
                  onAllocated: (allocated) {
                    setState(() {
                      final existingIdx = _allocatedItems.indexWhere(
                        (i) => i.inventoryId == allocated.inventoryId,
                      );
                      if (existingIdx >= 0) {
                        final ex = _allocatedItems[existingIdx];
                        _allocatedItems[existingIdx] = AllocatedItem(
                          inventoryId: ex.inventoryId,
                          itemName: ex.itemName,
                          quantity: ex.quantity + allocated.quantity,
                          status: ex.status,
                          notes: ex.notes,
                        );
                      } else {
                        _allocatedItems.add(allocated);
                      }
                    });
                    _checkForChanges();
                  },
                ),
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
