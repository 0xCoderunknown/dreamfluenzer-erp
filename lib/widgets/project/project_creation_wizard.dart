import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
import '../client/shared_client_selector.dart';
import 'project_wizard_step_fields.dart';

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
                    : Form(
                        key: _formKeyStep2,
                        child: ProjectWizardProjectFields(
                          projectNameController: _projectNameController,
                          selectedDealType: _selectedDealType,
                          onDealTypeChanged: (v) => setState(() {
                            _selectedDealType = v;
                            if (_selectedDealType == DealType.prGift) {
                              _selectedBillingModel = BillingModel.oneOff;
                              _baseBudgetController.text = '0';
                              _advanceReceivedController.text = '0';
                            }
                          }),
                          selectedBillingModel: _selectedBillingModel,
                          onBillingModelChanged: (v) =>
                              setState(() => _selectedBillingModel = v),
                          durationMonthsController: _durationMonthsController,
                          baseBudgetController: _baseBudgetController,
                          advanceReceivedController:
                              _advanceReceivedController,
                          gmvBudgetController: _gmvBudgetController,
                          isGstExclusive: _isGstExclusive,
                          onGstExclusiveChanged: (v) =>
                              setState(() => _isGstExclusive = v),
                          deadline: _deadline,
                          onSelectDeadline: () => _selectDeadline(context),
                          formKey: _formKeyStep2,
                        ),
                      ),
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
}
