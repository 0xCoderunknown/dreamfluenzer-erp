import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../config/agency_config.dart';
import '../config/proposal_templates.dart';
import '../domain/app_enums.dart';
import '../engines/proposal_compiler_engine.dart';
import '../models/lead_model.dart';
import '../models/proposal_model.dart';
import '../providers/creator_provider.dart';
import '../providers/proposal_provider.dart';
import '../services/pdf/pdf_service.dart';
import '../theme/app_theme.dart';
import '../widgets/proposal/proposal_widgets.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeWorkspace();
  }

  @override
  void dispose() {
    _agencyFeeCtrl.dispose();
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

  @override
  Widget build(BuildContext context) {
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
                                hintText: 'e.g. Get 300+ new customers to visit our store via Instagram Reels.',
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
              child: ProposalCommercialsSidebar(
                totalCreatorsCost: _calculateTotalCreatorsCost,
                agencyFeeCtrl: _agencyFeeCtrl,
                internalNotesCtrl: _internalNotesCtrl,
                addOnsList: _addOnsList,
                assignedCreators: assignedCreatorsData,
                allCreators: rawCreators,
                hasSelectedCreators: _selectedCreatorIds.isNotEmpty,
                isProcessing: _isProcessing,
                onSaveDraft: () =>
                    _compileAndCommitProposalToLedger(exportPdf: false),
                onExportPdf: () =>
                    _compileAndCommitProposalToLedger(exportPdf: true),
                onChanged: () => setState(() {}),
              ),
            ),
          ],
        ),
      ),
    );
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
