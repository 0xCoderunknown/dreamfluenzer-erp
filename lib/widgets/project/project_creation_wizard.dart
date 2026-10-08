import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/rule_messages.dart';
import '../../domain/app_enums.dart';
import '../../models/campaign_model.dart';
import '../../models/client_model.dart';
import '../../models/lead_model.dart';
import '../../models/project_model.dart';
import '../../models/proposal_model.dart';
import '../../providers/client_provider.dart';
import '../../providers/project_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
import '../client/shared_client_selector.dart';
import '../common/ui_kit.dart';

class ProjectCreationWizard extends StatefulWidget {
  final Lead? sourceLead;
  final Proposal? sourceProposal;

  const ProjectCreationWizard({
    super.key,
    this.sourceLead,
    this.sourceProposal,
  });

  @override
  State<ProjectCreationWizard> createState() => _ProjectCreationWizardState();
}

class _ProjectCreationWizardState extends State<ProjectCreationWizard> {
  int _currentStep = 1;
  bool _isSubmitting = false;
  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();

  bool _linkExistingClient = false;
  String? _selectedClientId;

  // ─── CLIENT CONTROLLERS ───
  late TextEditingController _businessNameController;
  late TextEditingController _industryController;
  late TextEditingController _contactPersonController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _instaController;
  late TextEditingController _locationController;
  ClientTier _selectedTier = ClientTier.tier3;

  // ─── PROJECT CONTROLLERS ───
  late TextEditingController _projectNameController;
  DealType _selectedDealType = DealType.cash;
  BillingModel _selectedBillingModel = BillingModel.oneOff;

  late TextEditingController _durationMonthsController;
  late TextEditingController _baseBudgetController;
  late TextEditingController _gmvBudgetController;
  late TextEditingController _advanceReceivedController;
  bool _isGstExclusive = true;
  DateTime _deadline = DateTime.now().add(const Duration(days: 30));

  @override
  void initState() {
    super.initState();
    _businessNameController = TextEditingController(
      text: widget.sourceLead?.businessName ?? '',
    );
    _contactPersonController = TextEditingController(
      text: widget.sourceLead?.contactPerson ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.sourceLead?.phone ?? '',
    );

    _industryController = TextEditingController();
    _emailController = TextEditingController();
    _instaController = TextEditingController();
    _locationController = TextEditingController();

    _projectNameController = TextEditingController(
      text: widget.sourceLead != null
          ? '${widget.sourceLead!.businessName} Campaign'
          : '',
    );
    _durationMonthsController = TextEditingController(text: '3');
    _baseBudgetController = TextEditingController(
      text: widget.sourceProposal?.totalClientPrice.toStringAsFixed(0) ?? '',
    );
    _gmvBudgetController = TextEditingController(text: '0');
    _advanceReceivedController = TextEditingController(text: '0');

    if (widget.sourceLead == null) {
      _linkExistingClient = true;
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _industryController.dispose();
    _contactPersonController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _instaController.dispose();
    _locationController.dispose();
    _projectNameController.dispose();
    _durationMonthsController.dispose();
    _baseBudgetController.dispose();
    _gmvBudgetController.dispose();
    _advanceReceivedController.dispose();
    super.dispose();
  }

  Future<void> _selectDeadline(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null && picked != _deadline) {
      setState(() => _deadline = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKeyStep2.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final projectProv = context.read<ProjectProvider>();

      String finalClientId;
      Client? newClient;

      if (_linkExistingClient) {
        if (_selectedClientId == null) throw Exception("Select a client.");
        finalClientId = _selectedClientId!;
      } else {
        finalClientId = '';
        newClient = Client(
          id: '',
          businessName: _businessNameController.text.trim(),
          industryType: _industryController.text.trim(),
          contactName: _contactPersonController.text.trim(),
          contactPhone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          instaHandle: _instaController.text.trim().replaceAll('@', ''),
          location: _locationController.text.trim(),
          tier: _selectedTier,
          notes: widget.sourceLead?.notes ?? '',
        );
      }

      final newProject = Project(
        id: '',
        clientId: finalClientId,
        projectName: _projectNameController.text.trim(),
        leadName: _contactPersonController.text.trim(),
        dealType: _selectedDealType,
        status: ProjectStatus.active,
        deadline: _deadline,
        billingModel: _selectedBillingModel,
        durationMonths: (int.tryParse(_durationMonthsController.text) ?? 1),
        baseBudget: (double.tryParse(_baseBudgetController.text) ?? 0.0),
        gmvBudget: double.tryParse(_gmvBudgetController.text) ?? 0.0,
        isGstExclusive: _selectedDealType == DealType.prGift
            ? false
            : _isGstExclusive,
        advanceReceived:
            (double.tryParse(_advanceReceivedController.text) ?? 0.0),
        createdAt: DateTime.now(),
      );

      List<AssignedCreator> assignedCreators = [];
      if (widget.sourceProposal != null) {
        assignedCreators = widget.sourceProposal!.creators.map((pc) {
          return AssignedCreator(
            creatorId: pc.creatorId,
            creatorName: pc.name,
            individualDeadline: _deadline,
            agreedPayout: pc.baseRate,
            pipelineStatus: PipelineStatus.draftRequested,
            isPaid: false,
            deliverables: pc.deliverables,
          );
        }).toList();
      }

      final campaign = Campaign(
        id: '',
        projectId: '',
        title: 'Initial Phase',
        cycleEndDate: _deadline,
        expenses: 0.0,
        inventoryPool: [],
        assignedCreators: assignedCreators,
      );

      final createdProjectId = await projectProv.onboardNewProject(
        newClient: newClient,
        project: newProject,
        initialCampaign: campaign,
        sourceLeadId: widget.sourceLead?.id,
        sourceProposalId: widget.sourceProposal?.id,
      );

      if (!mounted) return;
      context.pop();
      context.go('/projects/$createdProjectId');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final existingClients = context.select<ClientProvider, List<Client>>(
      (p) => p.clients,
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 850),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(32, 24, 32, 16),
                child: _currentStep == 1
                    ? Form(
                        key: _formKeyStep1,
                        child: SharedClientSelector(
                          existingClients: existingClients,
                          isLinkingExisting: _linkExistingClient,
                          selectedClientId: _selectedClientId,
                          businessNameCtrl: _businessNameController,
                          industryCtrl: _industryController,
                          contactPersonCtrl: _contactPersonController,
                          phoneCtrl: _phoneController,
                          emailCtrl: _emailController,
                          instaCtrl: _instaController,
                          locationCtrl: _locationController,
                          selectedTier: _selectedTier,
                          onTierChanged: (v) =>
                              setState(() => _selectedTier = v),
                          onModeChanged: (v) =>
                              setState(() => _linkExistingClient = v),
                          onClientSelected: (id) => setState(() {
                            _selectedClientId = id;
                            if (id != null && widget.sourceLead == null) {
                              final client = existingClients.firstWhere(
                                (c) => c.id == id,
                              );
                              _projectNameController.text =
                                  '${client.businessName} Campaign';
                            }
                          }),
                        ),
                      )
                    : Form(key: _formKeyStep2, child: _buildProjectFields()),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FF),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _currentStep == 1
                    ? Icons.business_rounded
                    : Icons.rocket_launch_rounded,
                color: AppTheme.primaryPurple,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                _currentStep == 1
                    ? 'Step 1: Client Profile'
                    : 'Step 2: Project Details',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryDark,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => context.pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPurple,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: _currentStep == 2
                        ? AppTheme.primaryPurple
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_currentStep == 2)
            TextButton(
              onPressed: () => setState(() => _currentStep = 1),
              child: const Text('Back'),
            )
          else
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Cancel'),
            ),
          const SizedBox(width: 16),
          if (_currentStep == 1)
            ElevatedButton(
              onPressed: () {
                if (_formKeyStep1.currentState!.validate()) {
                  if (_linkExistingClient && _selectedClientId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(RuleMessages.noClientSelected),
                        backgroundColor: AppTheme.error,
                      ),
                    );
                    return;
                  }
                  setState(() => _currentStep = 2);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: const Text('Next Step →'),
            )
          else
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Create Project'),
            ),
        ],
      ),
    );
  }

  Widget _buildProjectFields() {
    final bool isPrGiftMode = _selectedDealType == DealType.prGift;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DreamSectionBox(
          title: 'CORE DETAILS',
          child: Column(
            children: [
              TextFormField(
                controller: _projectNameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Project Name *',
                  prefixIcon: Icon(Icons.drive_file_rename_outline),
                ),
                validator: (v) =>
                    Validators.validateRequired(v, 'Project Name'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<DealType>(
                      initialValue: _selectedDealType,
                      decoration: const InputDecoration(
                        labelText: 'Deal Type',
                        prefixIcon: Icon(Icons.handshake_outlined),
                      ),
                      items: DealType.values
                          .map(
                            (t) => DropdownMenuItem(
                              value: t,
                              child: Text(t.value),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() {
                        _selectedDealType = v!;
                        if (_selectedDealType == DealType.prGift) {
                          _selectedBillingModel = BillingModel.oneOff;
                          _baseBudgetController.text = '0';
                          _advanceReceivedController.text = '0';
                        }
                      }),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<BillingModel>(
                      initialValue: _selectedBillingModel,
                      decoration: const InputDecoration(
                        labelText: 'Billing Model',
                        prefixIcon: Icon(Icons.receipt_long_outlined),
                      ),
                      disabledHint: Text(BillingModel.oneOff.value),
                      items: isPrGiftMode
                          ? null
                          : BillingModel.values
                                .map(
                                  (t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(t.value),
                                  ),
                                )
                                .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedBillingModel = v!),
                    ),
                  ),
                ],
              ),
              if (_selectedBillingModel == BillingModel.retainer &&
                  !isPrGiftMode) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _durationMonthsController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Duration (Months) *',
                    prefixIcon: Icon(Icons.timelapse),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => Validators.validateRequired(v, 'Duration'),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        DreamSectionBox(
          title: isPrGiftMode ? 'Barter Budget' : 'FINANCIALS',
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _baseBudgetController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Cash Budget *',
                        prefixIcon: Icon(Icons.currency_rupee),
                      ),
                      keyboardType: TextInputType.number,
                      enabled: !isPrGiftMode,
                      validator: (v) => _selectedDealType == DealType.prGift
                          ? null
                          : Validators.validateRequired(v, 'Cash Budget'),
                      onChanged: (_) => _formKeyStep2.currentState?.validate(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _advanceReceivedController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Advance Payment',
                        prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                      ),
                      keyboardType: TextInputType.number,
                      enabled: !isPrGiftMode,
                      validator: (v) {
                        if (isPrGiftMode) return null;
                        final advance = double.tryParse(v ?? '0') ?? 0.0;
                        final budget =
                            double.tryParse(_baseBudgetController.text) ?? 0.0;
                        if (advance > budget) return 'Cannot exceed budget';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _gmvBudgetController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Product/Barter Value (GMV)',
                        prefixIcon: Icon(Icons.inventory_2_outlined),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text(
                  'GST Exclusive Pricing',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Turn on if budget excludes 18% GST',
                  style: TextStyle(fontSize: 12),
                ),
                value: _isGstExclusive,
                activeThumbColor: AppTheme.primaryPurple,
                onChanged: isPrGiftMode
                    ? null
                    : (v) => setState(() => _isGstExclusive = v),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        DreamSectionBox(
          title: 'TIMELINE',
          child: ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            tileColor: Colors.white,
            title: const Text(
              'Target Deadline',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            subtitle: Text(
              DateFormat('dd MMM yyyy').format(_deadline),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryDark,
                fontSize: 16,
              ),
            ),
            trailing: const Icon(
              Icons.calendar_today,
              color: AppTheme.primaryPurple,
            ),
            onTap: () => _selectDeadline(context),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
          ),
        ),
      ],
    );
  }
}
