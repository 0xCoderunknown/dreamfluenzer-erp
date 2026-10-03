import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../domain/app_enums.dart';
import '../../models/client_model.dart';
import '../../providers/client_provider.dart';
import '../../providers/project_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
import '../common/ui_kit.dart';
import 'client_widgets.dart';

// ===========================================================================
// CLIENT PROFILE DASHBOARD (CRM VIEW)
// ===========================================================================
class ClientProfileDialog extends StatelessWidget {
  final Client client;
  final VoidCallback onEdit;

  const ClientProfileDialog({
    super.key,
    required this.client,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'en_IN');
    final projectProv = context.watch<ProjectProvider>();

    final clientProjects = projectProv.projects
        .where((p) => p.clientId == client.id)
        .toList();
    final active = clientProjects
        .where((p) => p.status == ProjectStatus.active)
        .toList();
    final past = clientProjects
        .where(
          (p) => [
            ProjectStatus.completed,
            ProjectStatus.dropped,
          ].contains(p.status),
        )
        .toList();
    final ltv = clientProjects.fold(
      0.0,
      (double sum, p) => sum + p.effectiveBudget,
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 950, maxHeight: 850),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopIdentity(context),
              const SizedBox(height: 24),
              _buildKpiBar(active, past, ltv, fmt),
              const SizedBox(height: 24),
              // 🚀 UNIFIED HORIZONTAL 1x4 CLIENT METADATA SHEET
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: _buildGridMetaTile(
                        Icons.person_outline_rounded,
                        'Contact Person',
                        client.contactName.isEmpty ? 'N/A' : client.contactName,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 32,
                      color: Colors.grey.shade200,
                    ),
                    Expanded(
                      child: _buildGridMetaTile(
                        Icons.phone_android_rounded,
                        'Phone Number',
                        client.contactPhone,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 32,
                      color: Colors.grey.shade200,
                    ),
                    Expanded(
                      child: _buildGridMetaTile(
                        Icons.alternate_email_rounded,
                        'Email Address',
                        client.email.isEmpty ? 'N/A' : client.email,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 32,
                      color: Colors.grey.shade200,
                    ),
                    Expanded(
                      child: _buildGridMetaTile(
                        Icons.location_city_rounded,
                        'Location',
                        client.location.isEmpty ? 'N/A' : client.location,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Expanded(child: _buildSplitCrmView(context, active, past, fmt)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopIdentity(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClientAvatar(name: client.businessName, size: 44),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                client.businessName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryDark,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  ClientTierChip(tier: client.tier),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      client.industryType.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        _buildActionButtons(context),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          tooltip: 'Delete Client',
          onPressed: () => _confirmDelete(context),
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: Colors.grey),
          tooltip: 'Modify Settings',
          onPressed: () {
            Navigator.pop(context);
            onEdit();
          },
        ),
        const SizedBox(width: 8),
        Container(width: 1, height: 20, color: Colors.grey.shade300),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.close_rounded, color: AppTheme.primaryDark),
          tooltip: 'Close',
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildKpiBar(List active, List past, double ltv, NumberFormat fmt) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          ClientKpiStat(
            label: 'Total Campaigns',
            value: (active.length + past.length).toString(),
          ),
          ClientKpiStat(
            label: 'Active Campaigns',
            value: active.length.toString(),
            valueColor: active.isNotEmpty ? Colors.orange : null,
          ),
          ClientKpiStat(
            label: 'Total Billings (LTV)',
            value: '₹${fmt.format(ltv)}',
            valueColor: AppTheme.success,
          ),
        ],
      ),
    );
  }

  Widget _buildGridMetaTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Icon(icon, size: 18, color: AppTheme.primaryPurple),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF9CA3AF),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitCrmView(
    BuildContext context,
    List active,
    List past,
    NumberFormat fmt,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: _ProjectColumn(
            title: 'Active Brand Campaigns',
            projects: active,
            isSecondary: false,
            fmt: fmt,
          ),
        ),
        const VerticalDivider(width: 48),
        Expanded(
          flex: 4,
          child: _ProjectColumn(
            title: 'Closed Campaigns',
            projects: past,
            isSecondary: true,
            fmt: fmt,
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDreamConfirm(
      context,
      title: 'Delete Client?',
      body: 'Permanently remove ${client.businessName}?',
      confirmText: 'Delete',
      isDestructive: true,
    );
    if (confirmed == true) {
      if (!context.mounted) return;
      await context.read<ClientProvider>().deleteClient(client.id);
      if (!context.mounted) return;
      Navigator.pop(context);
    }
  }
}

class _ProjectColumn extends StatelessWidget {
  final String title;
  final List projects;
  final bool isSecondary;
  final NumberFormat fmt;

  const _ProjectColumn({
    required this.title,
    required this.projects,
    required this.isSecondary,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 11,
            color: Colors.grey,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: projects.isEmpty
              ? Center(
                  child: Text(
                    'No campaigns mapped.',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontStyle: FontStyle.italic,
                      fontSize: 13,
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: projects.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final p = projects[i];
                    return ListTile(
                      tileColor: isSecondary
                          ? Colors.transparent
                          : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      title: Text(
                        p.projectName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        DateFormat('dd MMM yyyy').format(p.deadline),
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: Text(
                        p.dealType == DealType.prGift
                            ? 'Barter'
                            : '₹${fmt.format(p.effectiveBudget)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSecondary ? Colors.grey : AppTheme.success,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/projects/${p.id}');
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

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
