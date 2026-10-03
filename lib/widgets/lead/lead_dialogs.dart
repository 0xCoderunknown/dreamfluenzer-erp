import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../domain/app_enums.dart';
import '../../models/lead_model.dart';
import '../../models/proposal_model.dart';
import '../../providers/creator_provider.dart';
import '../../providers/lead_provider.dart';
import '../../providers/proposal_provider.dart';
import '../../services/pdf/pdf_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
import '../common/ui_kit.dart';
import '../project/project_dialogs.dart';

// ===========================================================================
// LEAD OPERATIONS DASHBOARD PANEL
// ===========================================================================
class LeadOverviewDialog extends StatelessWidget {
  final Lead lead;

  const LeadOverviewDialog({super.key, required this.lead});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'en_IN');
    final proposals = context.select<ProposalProvider, List<Proposal>>(
      (prov) => prov.getProposalsForLead(lead.id),
    );

    final hasPitch = proposals.isNotEmpty;
    final activeProposal = hasPitch ? proposals.first : null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── ROW 1: BRAND TITLE & STATUS ACTIONS ───
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppTheme.primaryPurple.withValues(
                      alpha: 0.1,
                    ),
                    child: Text(
                      lead.businessName[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryPurple,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lead.businessName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            DreamStatusChip(label: lead.status.value),
                            const SizedBox(width: 8),
                            Text(
                              lead.primaryCategory.value,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.grey),
                    tooltip: 'Edit Lead',
                    onPressed: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (_) => AddEditLeadFormWindow(lead: lead),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 32),

              // ─── ROW 2: DETAILED META METRICS SHEET ───
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _metaLabel('CONTACT PERSON'),
                          _textDataTile(
                            Icons.person_outline_rounded,
                            lead.contactPerson,
                          ),
                          const SizedBox(height: 16),
                          _metaLabel('MOBILE NO.'),
                          _textDataTile(
                            Icons.phone_android_rounded,
                            lead.phone.isEmpty
                                ? 'None Provided'
                                : '+91 ${lead.phone}',
                          ),
                          const SizedBox(height: 16),
                          _metaLabel('INTERNAL NOTES'),
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: SingleChildScrollView(
                                child: Text(
                                  lead.notes.isEmpty
                                      ? 'No notes added yet.'
                                      : lead.notes,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.primaryDark,
                                    fontStyle: lead.notes.isEmpty
                                        ? FontStyle.italic
                                        : FontStyle.normal,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const VerticalDivider(width: 48),

                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _metaLabel('PROPOSALS'),
                          const SizedBox(height: 8),
                          if (activeProposal == null) ...[
                            _buildPitchLauncherButton(context),
                          ] else ...[
                            _buildActiveProposalCard(
                              context,
                              activeProposal,
                              fmt,
                            ),
                            const Spacer(),
                            if (lead.status == LeadStatus.won)
                              _buildConversionActionRow(
                                context,
                                activeProposal,
                              ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── PRIVATE ATOMIC HELPERS ───

  Widget _metaLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 9,
      fontWeight: FontWeight.bold,
      color: Color(0xFF9CA3AF),
      letterSpacing: 0.5,
    ),
  );

  Widget _textDataTile(IconData icon, String val) => Row(
    children: [
      Icon(icon, size: 16, color: AppTheme.primaryPurple),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          val,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryDark,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );

  Widget _buildPitchLauncherButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        color: AppTheme.primaryPurple.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryPurple.withValues(alpha: 0.15),
          style: BorderStyle.solid,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          context.push('/proposal_engine', extra: {'lead': lead});
        },
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rocket_launch_rounded,
              color: AppTheme.primaryPurple,
              size: 28,
            ),
            SizedBox(height: 8),
            Text(
              'Create Proposal',
              style: TextStyle(
                color: AppTheme.primaryPurple,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveProposalCard(
    BuildContext context,
    Proposal pitch,
    NumberFormat fmt,
  ) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: AppTheme.primaryPurple.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.primaryPurple.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        title: Text(
          '₹${fmt.format(pitch.totalClientPrice)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: AppTheme.primaryDark,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'Proposal Status: ${pitch.status.value}',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(
                Icons.edit_document,
                color: AppTheme.primaryPurple,
              ),
              tooltip: 'Edit Proposal',
              onPressed: () {
                Navigator.pop(context);
                context.push(
                  '/proposal_engine',
                  extra: {'lead': lead, 'proposal': pitch},
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
              tooltip: 'Export Campaign Document',
              onPressed: () => PdfService.generatePitchPdf(
                pitch,
                lead,
                context.read<CreatorProvider>(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversionActionRow(BuildContext context, Proposal pitch) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.success,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        onPressed: () {
          Navigator.pop(context);
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) =>
                ProjectCreationWizard(sourceLead: lead, sourceProposal: pitch),
          );
        },
        icon: const Icon(Icons.auto_awesome_motion_rounded, size: 18),
        label: const Text(
          'Convert to Live Project',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class AddEditLeadFormWindow extends StatefulWidget {
  final Lead? lead;

  const AddEditLeadFormWindow({super.key, this.lead});

  @override
  State<AddEditLeadFormWindow> createState() => _AddEditLeadFormWindowState();
}

class _AddEditLeadFormWindowState extends State<AddEditLeadFormWindow> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _bizCtrl,
      _contactCtrl,
      _phoneCtrl,
      _budgetCtrl,
      _notesCtrl;
  late LeadStatus _currentStatus;
  late PrimaryCategory _selectedCategory;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final l = widget.lead;
    _bizCtrl = TextEditingController(text: l?.businessName);
    _contactCtrl = TextEditingController(text: l?.contactPerson);
    _phoneCtrl = TextEditingController(text: l?.phone);
    _budgetCtrl = TextEditingController(
      text: (l != null && l.estimatedBudget > 0)
          ? l.estimatedBudget.toStringAsFixed(0)
          : '',
    );
    _notesCtrl = TextEditingController(text: l?.notes);
    _currentStatus = l?.status ?? LeadStatus.identified;
    _selectedCategory = l?.primaryCategory ?? PrimaryCategory.clothing;
  }

  @override
  void dispose() {
    for (var c in [
      _bizCtrl,
      _contactCtrl,
      _phoneCtrl,
      _budgetCtrl,
      _notesCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.lead == null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Text(
                      isNew ? 'New Lead' : 'Edit Lead Details',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _formField(
                        'Business Name *',
                        _bizCtrl,
                        val: (v) =>
                            Validators.validateRequired(v, 'Business Name'),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _formField(
                              'Contact Person *',
                              _contactCtrl,
                              val: (v) => Validators.validateRequired(
                                v,
                                'Contact Person',
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _formField(
                              'Phone No. *',
                              _phoneCtrl,
                              prefix: '+91 ',
                              val: Validators.validatePhone,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _formField(
                              'Estimated Budget (₹)',
                              _budgetCtrl,
                              digitsOnly: true,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Target Industry Category',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryDark,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<PrimaryCategory>(
                                  initialValue: _selectedCategory,
                                  items: PrimaryCategory.values
                                      .where(
                                        (cat) =>
                                            cat != PrimaryCategory.generalUgc,
                                      )
                                      .map(
                                        (cat) => DropdownMenuItem(
                                          value: cat,
                                          child: Text(cat.value),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => _selectedCategory = v!),
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (!isNew) ...[
                        const SizedBox(height: 16),
                        DropdownButtonFormField<LeadStatus>(
                          initialValue: _currentStatus,
                          items: LeadStatus.values
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s.value),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _currentStatus = v!),
                          decoration: const InputDecoration(
                            labelText: 'Lead Status',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      _formField('Internal Notes', _notesCtrl, maxLines: 3),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              _buildFormFooter(isNew),
            ],
          ),
        ),
      ),
    );
  }

  // ─── ATOMIC UI CONSTRUCTORS ───

  Widget _formField(
    String label,
    TextEditingController ctrl, {
    bool digitsOnly = false,
    int maxLines = 1,
    String? prefix,
    String? Function(String?)? val,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryDark,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          validator: val,
          maxLines: maxLines,
          inputFormatters: digitsOnly
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
          decoration: InputDecoration(
            prefixText: prefix,
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildFormFooter(bool isNew) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _isSaving ? null : _executeSaveOperation,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryPurple,
              foregroundColor: Colors.white,
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(isNew ? 'Create Lead' : 'Save Changes'),
          ),
        ],
      ),
    );
  }

  Future<void> _executeSaveOperation() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final isNew = widget.lead == null;
    final finalId = isNew ? '' : widget.lead!.id;

    final lead = Lead(
      id: finalId,
      businessName: _bizCtrl.text.trim(),
      contactPerson: _contactCtrl.text.trim(),
      phone: _phoneCtrl.text.replaceAll(RegExp(r'\s+'), ''),
      estimatedBudget: double.tryParse(_budgetCtrl.text) ?? 0.0,
      status: isNew ? LeadStatus.identified : _currentStatus,
      primaryCategory: _selectedCategory,
      notes: _notesCtrl.text.trim(),
    );

    if (isNew) {
      await context.read<LeadProvider>().addLead(lead);
    } else {
      await context.read<LeadProvider>().updateLeadDetails(lead);
    }
    if (mounted) Navigator.pop(context);
  }
}
