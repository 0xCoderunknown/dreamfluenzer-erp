import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../config/agency_config.dart';
import '../config/proposal_templates.dart';
import '../domain/app_enums.dart';
import '../models/lead_model.dart';
import '../models/proposal_model.dart';
import '../providers/creator_provider.dart';
import '../providers/proposal_provider.dart';
import '../theme/app_theme.dart';
import '../engines/proposal_compiler_engine.dart';
import '../services/pdf/pdf_service.dart';
import '../widgets/proposal/proposal_add_on_tile.dart';
import '../widgets/proposal/proposal_row_item.dart';

class ProposalEngineScreen extends StatefulWidget {
  final Lead lead;
  final Proposal? existingProposal;

  const ProposalEngineScreen({
    super.key,
    required this.lead,
    this.existingProposal,
  });

  @override
  State<ProposalEngineScreen> createState() => _ProposalEngineScreenState();
}

class _ProposalEngineScreenState extends State<ProposalEngineScreen> {
  final _formKey = GlobalKey<FormState>();

  final _agencyFeeCtrl = TextEditingController(text: '5000');
  final _addOnDescCtrl = TextEditingController();
  final _addOnPriceCtrl = TextEditingController();
  final _internalNotesCtrl = TextEditingController();

  final _customObjectiveCtrl = TextEditingController();
  final _locationCityCtrl = TextEditingController(
    text: AgencyConfig.defaultCity,
  );

  final Set<String> _selectedCreatorIds = {};
  final Map<String, Map<DeliverableType, int>> _deliverableSelections = {};
  final Map<String, TextEditingController> _payoutControllers = {};

  final Map<String, TextEditingController> _usageRightsControllers = {};
  final Map<String, TextEditingController> _exclusivityControllers = {};

  final List<PitchAddOn> _addOnsList = [];

  ProposalType _selectedProposalType = ProposalType.localVisibility;
  bool _showAssignedOnly = false;
  bool _isProcessing = false;
  String? _selectedAddOnCreatorId;

  @override
  void initState() {
    super.initState();
    _initializeWorkspace();
  }

  @override
  void dispose() {
    _agencyFeeCtrl.dispose();
    _addOnDescCtrl.dispose();
    _addOnPriceCtrl.dispose();
    _internalNotesCtrl.dispose();
    _customObjectiveCtrl.dispose();
    _locationCityCtrl.dispose();
    for (var ctrl in _payoutControllers.values) {
      ctrl.dispose();
    }
    for (var ctrl in _usageRightsControllers.values) {
      ctrl.dispose();
    }
    for (var ctrl in _exclusivityControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _initializeWorkspace() {
    _customObjectiveCtrl.text = widget.lead.customObjective;
    _locationCityCtrl.text = widget.lead.locationCity.isNotEmpty
        ? widget.lead.locationCity
        : AgencyConfig.defaultCity;

    final prop = widget.existingProposal;
    if (prop != null) {
      _selectedProposalType = prop.proposalType;
      _agencyFeeCtrl.text = prop.agencyFee.toStringAsFixed(0);
      _internalNotesCtrl.text = prop.internalNotes;
      _addOnsList.addAll(prop.addOns);

      for (var pc in prop.creators) {
        _selectedCreatorIds.add(pc.creatorId);
        _payoutControllers[pc.creatorId] = TextEditingController(
          text: pc.baseRate.toStringAsFixed(0),
        );
        _usageRightsControllers[pc.creatorId] = TextEditingController(
          text: pc.usageRightsDuration,
        );
        _exclusivityControllers[pc.creatorId] = TextEditingController(
          text: pc.categoryExclusivity,
        );

        final delMap = <DeliverableType, int>{};
        for (var d in pc.deliverables) {
          delMap[d.type] = d.quantity;
        }
        _deliverableSelections[pc.creatorId] = delMap;
      }
    }
  }

  double get _calculateTotalCreatorsCost {
    double sum = 0.0;
    for (var id in _selectedCreatorIds) {
      final ctrl = _payoutControllers[id];
      sum += double.tryParse(ctrl?.text ?? '0') ?? 0.0;
    }
    return sum;
  }

  double get _calculateGeneralAddOnsCost {
    return _addOnsList
        .where((item) => item.creatorId == null)
        .fold(0.0, (sum, item) => sum + item.price);
  }

  double get _calculateCreatorSpecificAddOnsCost {
    return _addOnsList
        .where((item) => item.creatorId != null)
        .fold(0.0, (sum, item) => sum + item.price);
  }

  double get _calculateGrandTotal {
    final agencyFee = double.tryParse(_agencyFeeCtrl.text) ?? 0.0;
    return _calculateTotalCreatorsCost +
        _calculateGeneralAddOnsCost +
        _calculateCreatorSpecificAddOnsCost +
        agencyFee;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat('#,##0', 'en_IN');

    final rawCreators = context
        .watch<CreatorProvider>()
        .creators
        .where(
          (c) =>
              c.status == CreatorStatus.active ||
              c.status == CreatorStatus.trial,
        )
        .toList();

    final filteredCreators = rawCreators.where((c) {
      if (_showAssignedOnly) {
        return _selectedCreatorIds.contains(c.id);
      }
      return true;
    }).toList();

    final assignedCreatorsData = rawCreators
        .where((c) => _selectedCreatorIds.contains(c.id))
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text('New Proposal — ${widget.lead.businessName}'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'CAMPAIGN DETAILS',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: DropdownButtonFormField<ProposalType>(
                                    initialValue: _selectedProposalType,
                                    decoration: const InputDecoration(
                                      labelText: 'Campaign Type',
                                      isDense: true,
                                      border: OutlineInputBorder(),
                                    ),
                                    items: ProposalType.values.map((t) {
                                      return DropdownMenuItem(
                                        value: t,
                                        child: Text(
                                          t.value,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() {
                                          _selectedProposalType = val;
                                          _customObjectiveCtrl.text =
                                              ProposalTextBlueprintManager.getDefaultObjectiveText(
                                                widget.lead.businessName,
                                              );
                                        });
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 1,
                                  child: TextFormField(
                                    controller: _locationCityCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'City',
                                      isDense: true,
                                      border: OutlineInputBorder(),
                                    ),
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _customObjectiveCtrl,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                labelText: 'Campaign Objective',
                                hintText:
                                    'e.g. Get 300+ new customers to visit our store via Instagram Reels.',
                                border: OutlineInputBorder(),
                              ),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'SELECT CREATORS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 1,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: _showAssignedOnly,
                              activeColor: AppTheme.primaryPurple,
                              onChanged: (val) => setState(
                                () => _showAssignedOnly = val ?? false,
                              ),
                            ),
                            const Text(
                              'Show Assigned Only',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: filteredCreators.isEmpty
                          ? Center(
                              child: Text(
                                _showAssignedOnly
                                    ? 'No creators selected yet.'
                                    : 'No creators found.',
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontStyle: FontStyle.italic,
                                  fontSize: 13,
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: filteredCreators.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final creator = filteredCreators[index];
                                final isSelected = _selectedCreatorIds.contains(
                                  creator.id,
                                );

                                if (!_payoutControllers.containsKey(
                                  creator.id,
                                )) {
                                  _payoutControllers[creator
                                      .id] = TextEditingController(
                                    text: creator.baseRate.toStringAsFixed(0),
                                  );
                                }
                                if (!_usageRightsControllers.containsKey(
                                  creator.id,
                                )) {
                                  _usageRightsControllers[creator.id] =
                                      TextEditingController(
                                        text: ProposalTextBlueprintManager
                                            .defaultUsageRights,
                                      );
                                }
                                if (!_exclusivityControllers.containsKey(
                                  creator.id,
                                )) {
                                  _exclusivityControllers[creator.id] =
                                      TextEditingController(
                                        text: ProposalTextBlueprintManager
                                            .defaultExclusivity,
                                      );
                                }
                                if (!_deliverableSelections.containsKey(
                                  creator.id,
                                )) {
                                  _deliverableSelections[creator.id] = {
                                    DeliverableType.reel: 0,
                                  };
                                }

                                return Card(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: isSelected
                                          ? AppTheme.primaryPurple
                                          : Colors.grey.shade200,
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: ProposalRowItem(
                                    creator: creator,
                                    isSelected: isSelected,
                                    effectiveRate: creator.baseRate,
                                    activeTasks: 0,
                                    upcomingTasks: const [],
                                    deliverableCounts:
                                        _deliverableSelections[creator.id]!,
                                    rateCtrl: _payoutControllers[creator.id]!,
                                    usageRightsCtrl:
                                        _usageRightsControllers[creator.id]!,
                                    exclusivityCtrl:
                                        _exclusivityControllers[creator.id]!,
                                    onToggle: (val) => setState(() {
                                      if (val == true) {
                                        _selectedCreatorIds.add(creator.id);
                                      } else {
                                        _selectedCreatorIds.remove(creator.id);
                                        if (_selectedAddOnCreatorId ==
                                            creator.id) {
                                          _selectedAddOnCreatorId = null;
                                        }
                                      }
                                    }),
                                    onDeliverableChanged: (type, delta) =>
                                        setState(() {
                                          final currentCount =
                                              _deliverableSelections[creator
                                                  .id]![type] ??
                                              0;
                                          _deliverableSelections[creator
                                                  .id]![type] =
                                              (currentCount + delta).clamp(
                                                0,
                                                99,
                                              );
                                        }),
                                    onChanged: () => setState(() {}),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),

            // RIGHT SIDEBAR COLUMN: Accounting Console Summaries
            Expanded(
              flex: 2,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PRICING SUMMARY',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.grey,
                        letterSpacing: 1,
                      ),
                    ),
                    const Divider(height: 32),
                    _buildLedgerLine(
                      'Creator Fees',
                      '₹${currencyFmt.format(_calculateTotalCreatorsCost)}',
                    ),
                    const SizedBox(height: 12),
                    _buildLedgerLine(
                      'General Project Add-ons',
                      '₹${currencyFmt.format(_calculateGeneralAddOnsCost)}',
                    ),
                    const SizedBox(height: 12),
                    _buildLedgerLine(
                      'Creator Add-ons',
                      '₹${currencyFmt.format(_calculateCreatorSpecificAddOnsCost)}',
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Agency Markup Fee',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.primaryDark,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(
                          width: 140,
                          child: TextFormField(
                            controller: _agencyFeeCtrl,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.end,
                            decoration: const InputDecoration(
                              prefixText: '₹ ',
                              isDense: true,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Required';
                              }
                              final numVal = double.tryParse(v.trim()) ?? -1;
                              if (numVal < 0) return 'Cannot be negative';
                              return null;
                            },
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 40),
                    _buildLedgerLine(
                      'TOTAL CLIENT PRICE',
                      '₹${currencyFmt.format(_calculateGrandTotal)}',
                      isTotal: true,
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'ADDITIONAL EXPENSES',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: Colors.grey,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _addOnDescCtrl,
                            decoration: const InputDecoration(
                              hintText: 'e.g. Courier, Studio Shoot',
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 85,
                          child: TextFormField(
                            controller: _addOnPriceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: '₹ Price',
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String?>(
                            initialValue: _selectedAddOnCreatorId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(),
                            ),
                            hint: const Text(
                              'Link to a creator or keep general...',
                              style: TextStyle(fontSize: 12),
                            ),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text(
                                  'General Expense (not linked to a creator)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              ...assignedCreatorsData.map((cc) {
                                return DropdownMenuItem<String?>(
                                  value: cc.id,
                                  child: Text(
                                    'Link to: @${cc.handle}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.primaryPurple,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }),
                            ],
                            onChanged: (val) =>
                                setState(() => _selectedAddOnCreatorId = val),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle_rounded,
                            color: AppTheme.primaryPurple,
                            size: 28,
                          ),
                          onPressed: _addNewLogisticsAddOnElement,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _addOnsList.isEmpty
                          ? Center(
                              child: Text(
                                'No extra expenses added yet.',
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontStyle: FontStyle.italic,
                                  fontSize: 13,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _addOnsList.length,
                              itemBuilder: (context, idx) {
                                final item = _addOnsList[idx];
                                final linkedCc = item.creatorId != null
                                    ? rawCreators.firstWhere(
                                        (c) => c.id == item.creatorId,
                                        orElse: () => rawCreators.first,
                                      )
                                    : null;
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ProposalAddOnTile(
                                      addOn: item,
                                      onDelete: () => setState(
                                        () => _addOnsList.removeAt(idx),
                                      ),
                                    ),
                                    if (linkedCc != null)
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          12,
                                          2,
                                          0,
                                          8,
                                        ),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            '↳ Linked to: ${linkedCc.fullName} (@${linkedCc.handle})',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontStyle: FontStyle.italic,
                                              color: AppTheme.primaryPurple,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                    ),
                    TextFormField(
                      controller: _internalNotesCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Internal Notes',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryPurple,
                              side: const BorderSide(
                                color: AppTheme.primaryPurple,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed:
                                _selectedCreatorIds.isEmpty || _isProcessing
                                ? null
                                : () => _compileAndCommitProposalToLedger(
                                    exportPdf: false,
                                  ),
                            icon: _isProcessing
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppTheme.primaryPurple,
                                    ),
                                  )
                                : const Icon(Icons.save_rounded, size: 18),
                            label: const Text(
                              'Save Draft Configuration',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryPurple,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed:
                                _selectedCreatorIds.isEmpty || _isProcessing
                                ? null
                                : () => _compileAndCommitProposalToLedger(
                                    exportPdf: true,
                                  ),
                            icon: _isProcessing
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.picture_as_pdf_rounded,
                                    size: 18,
                                  ),
                            label: const Text(
                              'Save & Export Client PDF',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLedgerLine(String title, String val, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: isTotal ? 15 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: AppTheme.primaryDark,
          ),
        ),
        Text(
          val,
          style: TextStyle(
            fontSize: isTotal ? 22 : 15,
            fontWeight: FontWeight.bold,
            color: isTotal ? AppTheme.primaryPurple : AppTheme.primaryDark,
          ),
        ),
      ],
    );
  }

  void _addNewLogisticsAddOnElement() {
    final desc = _addOnDescCtrl.text.trim();
    final price = double.tryParse(_addOnPriceCtrl.text.trim()) ?? 0.0;
    if (desc.isNotEmpty && price > 0) {
      setState(() {
        _addOnsList.add(
          PitchAddOn(
            id: 'addon_${DateTime.now().millisecondsSinceEpoch}',
            description: desc,
            price: price,
            creatorId: _selectedAddOnCreatorId,
          ),
        );
        _addOnDescCtrl.clear();
        _addOnPriceCtrl.clear();
        _selectedAddOnCreatorId = null;
      });
    }
  }

  Future<void> _compileAndCommitProposalToLedger({
    required bool exportPdf,
  }) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isProcessing = true);

    final leadProvider = widget.lead.copyWith(
      customObjective: _customObjectiveCtrl.text.trim(),
      locationCity: _locationCityCtrl.text.trim(),
    );

    final allRosterCreators = context.read<CreatorProvider>().creators;

    final newProposal = ProposalCompilerEngine.compile(
      existingProposalId: widget.existingProposal?.id,
      leadId: widget.lead.id,
      proposalType: _selectedProposalType,
      selectedCreatorIds: _selectedCreatorIds,
      addOnsList: _addOnsList,
      agencyFee: double.tryParse(_agencyFeeCtrl.text) ?? 0.0,
      internalNotes: _internalNotesCtrl.text.trim(),
      payoutControllers: _payoutControllers,
      usageRightsControllers: _usageRightsControllers,
      exclusivityControllers: _exclusivityControllers,
      deliverableSelections: _deliverableSelections,
      allRosterCreators: allRosterCreators,
      defaultStatus: widget.existingProposal?.status ?? ProposalStatus.draft,
      defaultCreatedAt: widget.existingProposal?.createdAt ?? DateTime.now(),
    );

    final provider = context.read<ProposalProvider>();
    if (widget.existingProposal != null) {
      await provider.updateProposal(newProposal);
    } else {
      await provider.addProposal(newProposal);
    }

    if (exportPdf && mounted) {
      final creatorProvider = context.read<CreatorProvider>();
      await PdfService.generatePitchPdf(
        newProposal,
        leadProvider,
        creatorProvider,
      );
    }

    if (mounted) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            exportPdf
                ? 'Proposal saved and PDF generated!'
                : 'Draft saved successfully!',
          ),
          backgroundColor: AppTheme.primaryPurple,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
