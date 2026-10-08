import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/app_enums.dart';
import '../../models/client_model.dart';
import '../../providers/client_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';

class AddClientDialog extends StatefulWidget {
  final Client? clientToEdit;

  const AddClientDialog({super.key, this.clientToEdit});

  @override
  State<AddClientDialog> createState() => _AddClientDialogState();
}

class _AddClientDialogState extends State<AddClientDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _bizNameCtrl,
      _industryCtrl,
      _contactNameCtrl,
      _phoneCtrl,
      _instaCtrl,
      _locationCtrl,
      _notesCtrl,
      _emailCtrl;
  ClientTier _selectedTier = ClientTier.tier3;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.clientToEdit;
    _bizNameCtrl = TextEditingController(text: c?.businessName);
    _industryCtrl = TextEditingController(text: c?.industryType);
    _contactNameCtrl = TextEditingController(text: c?.contactName);
    _phoneCtrl = TextEditingController(text: c?.contactPhone);
    _instaCtrl = TextEditingController(text: c?.instaHandle);
    _locationCtrl = TextEditingController(text: c?.location);
    _notesCtrl = TextEditingController(text: c?.notes);
    _emailCtrl = TextEditingController(text: c?.email);
    _selectedTier = c?.tier ?? ClientTier.tier3;
  }

  @override
  void dispose() {
    for (final c in [
      _bizNameCtrl,
      _industryCtrl,
      _contactNameCtrl,
      _phoneCtrl,
      _instaCtrl,
      _locationCtrl,
      _notesCtrl,
      _emailCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: _buildForm(),
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
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          const Icon(Icons.business_rounded, color: AppTheme.primaryPurple),
          const SizedBox(width: 16),
          Text(
            widget.clientToEdit == null
                ? 'Add New Client Profile'
                : 'Edit Client Details',
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
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Business Information'),
          Row(
            children: [
              Expanded(
                child: _field(
                  'Business Name *',
                  _bizNameCtrl,
                  val: (v) => Validators.validateRequired(v, 'Business Name'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _field(
                  'Industry Type *',
                  _industryCtrl,
                  val: (v) => Validators.validateRequired(v, 'Industry Type'),
                  hint: 'e.g. F&B, Apparel, Pharmacy',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _field('HQ Location', _locationCtrl)),
              const SizedBox(width: 16),
              Expanded(child: _tierDropdown()),
            ],
          ),
          const SizedBox(height: 32),
          _sectionLabel('Contact Information'),
          Row(
            children: [
              Expanded(child: _field('Contact Person', _contactNameCtrl)),
              const SizedBox(width: 16),
              Expanded(
                child: _field(
                  'Phone Number *',
                  _phoneCtrl,
                  val: Validators.validatePhone,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _field(
                  'Email Address',
                  _emailCtrl,
                  val: Validators.optional(Validators.validateEmail),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _field(
                  'Instagram Handle',
                  _instaCtrl,
                  prefix: '@',
                  val: Validators.optional(Validators.validateInstagramHandle),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _sectionLabel('Internal Notes'),
          _field('Notes', _notesCtrl, maxLines: 3),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    String? Function(String?)? val,
    String? hint,
    String? prefix,
    int maxLines = 1,
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
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(hintText: hint, prefixText: prefix),
        ),
      ],
    );
  }

  Widget _tierDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Client Account Tier',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryDark,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<ClientTier>(
          initialValue: _selectedTier,
          items: ClientTier.values
              .map((t) => DropdownMenuItem(value: t, child: Text(t.value)))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _selectedTier = v);
          },
          decoration: const InputDecoration(),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade400,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildFooter() {
    final bool isNew = widget.clientToEdit == null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(isNew ? 'Create Client' : 'Save Client'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final isNew = widget.clientToEdit == null;
    final finalId = isNew
        ? FirebaseFirestore.instance.collection('clients').doc().id
        : widget.clientToEdit!.id;

    final client = Client(
      id: finalId,
      businessName: _bizNameCtrl.text.trim(),
      industryType: _industryCtrl.text.trim(),
      contactName: _contactNameCtrl.text.trim(),
      contactPhone: _phoneCtrl.text.trim(),
      instaHandle: _instaCtrl.text.trim().replaceAll('@', ''),
      location: _locationCtrl.text.trim(),
      tier: _selectedTier,
      notes: _notesCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
    );

    try {
      if (widget.clientToEdit != null) {
        await context.read<ClientProvider>().updateClient(client);
      } else {
        await context.read<ClientProvider>().addClient(client);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _saving = false);
    }
  }
}
