import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../domain/app_enums.dart';
import '../../models/lead_model.dart';
import '../../providers/lead_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';

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
