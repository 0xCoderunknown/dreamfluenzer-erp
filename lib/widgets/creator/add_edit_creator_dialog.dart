import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../domain/app_enums.dart';
import '../../engines/crm_analytics_engine.dart';
import '../../models/creator_model.dart';
import '../../providers/campaign_provider.dart';
import '../../providers/creator_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';

class AddEditCreatorDialog extends StatefulWidget {
  final Creator? creator;

  const AddEditCreatorDialog({super.key, this.creator});

  @override
  State<AddEditCreatorDialog> createState() => AddEditCreatorDialogState();
}

class AddEditCreatorDialogState extends State<AddEditCreatorDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl,
      _handleCtrl,
      _phoneCtrl,
      _rateCtrl,
      _followerCtrl,
      _upiCtrl,
      _locCtrl,
      _notesCtrl,
      _secondaryNicheCtrl;

  late CreatorType _selectedType;
  late PrimaryCategory _selectedCategory;
  late CreatorStatus _selectedStatus;
  DateTimeRange? _busyRange;

  @override
  void initState() {
    super.initState();
    final c = widget.creator;
    _nameCtrl = TextEditingController(text: c?.fullName);
    _handleCtrl = TextEditingController(text: c?.handle);
    _phoneCtrl = TextEditingController(text: c?.phoneNumber);
    _rateCtrl = TextEditingController(text: c?.baseRate.toStringAsFixed(0));
    _followerCtrl = TextEditingController(text: c?.followerCount.toString());
    _upiCtrl = TextEditingController(text: c?.upiId);
    _locCtrl = TextEditingController(text: c?.location);
    _notesCtrl = TextEditingController(text: c?.notes);
    _secondaryNicheCtrl = TextEditingController(text: c?.secondaryNiche ?? '');
    _selectedType = c?.type ?? CreatorType.influencer;
    _selectedCategory = c?.primaryCategory ?? PrimaryCategory.generalUgc;
    _selectedStatus = c?.status ?? CreatorStatus.trial;
  }

  @override
  void dispose() {
    for (var ctrl in [
      _nameCtrl,
      _handleCtrl,
      _phoneCtrl,
      _rateCtrl,
      _followerCtrl,
      _upiCtrl,
      _locCtrl,
      _notesCtrl,
      _secondaryNicheCtrl,
    ]) {
      ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.creator == null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 850),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          key: const ValueKey('AddEditCreatorFormWrapper'),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // ─── STAGE 1: WINDOW HEADER ───
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isNew ? 'Add Creator Profile' : 'Edit Creator Details',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),

                // ─── STAGE 2: FORM INPUT SHEET CONTROLS ───
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel('Personal Information'),
                        Row(
                          children: [
                            Expanded(
                              child: _formField(
                                'Full Name *',
                                _nameCtrl,
                                val: (v) =>
                                    Validators.validateRequired(v, 'Name'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _formField(
                                'Instagram Handle *',
                                _handleCtrl,
                                prefix: '@',
                                val: Validators.validateInstagramHandle,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        _sectionLabel('Role & Classification'),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Role',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryDark,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<CreatorType>(
                                    initialValue: _selectedType,
                                    items: CreatorType.values
                                        .map(
                                          (t) => DropdownMenuItem(
                                            value: t,
                                            child: Text(t.value),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) {
                                      if (v != null) {
                                        setState(() {
                                          _selectedType = v;
                                          if (_selectedType !=
                                              CreatorType.influencer) {
                                            _selectedCategory =
                                                PrimaryCategory.generalUgc;
                                            _followerCtrl.text = '0';
                                          } else {
                                            _selectedCategory =
                                                PrimaryCategory.clothing;
                                          }
                                        });
                                      }
                                    },
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Status',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryDark,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<CreatorStatus>(
                                    initialValue: _selectedStatus,
                                    items: CreatorStatus.values
                                        .map(
                                          (s) => DropdownMenuItem(
                                            value: s,
                                            child: Text(s.value),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) =>
                                        setState(() => _selectedStatus = v!),
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        if (_selectedType == CreatorType.influencer) ...[
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Primary Category *',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryDark,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    DropdownButtonFormField<PrimaryCategory>(
                                      initialValue:
                                          _selectedCategory ==
                                              PrimaryCategory.generalUgc
                                          ? PrimaryCategory.clothing
                                          : _selectedCategory,
                                      items: PrimaryCategory.values
                                          .where(
                                            (cat) =>
                                                cat !=
                                                PrimaryCategory.generalUgc,
                                          )
                                          .map(
                                            (cat) => DropdownMenuItem(
                                              value: cat,
                                              child: Text(cat.value),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (v) => setState(
                                        () => _selectedCategory = v!,
                                      ),
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _formField(
                                  'Secondary Niche',
                                  _secondaryNicheCtrl,
                                  hint: 'e.g. Skincare, Bridal, Cosmetics',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],

                        _buildVacationToggleSwitch(),
                        const SizedBox(height: 16),

                        _sectionLabel('Financial Details'),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _formField(
                                _selectedType == CreatorType.sandboxTrainee
                                    ? 'Stipend (₹) *'
                                    : 'Base Rate (₹) *',
                                _rateCtrl,
                                digitsOnly: true,
                                val: (v) =>
                                    Validators.validateRequired(v, 'Rate'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _formField(
                                    'Follower Count',
                                    _followerCtrl,
                                    digitsOnly: true,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: _formField(
                                'Contact Number *',
                                _phoneCtrl,
                                val: Validators.validatePhone,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(child: _formField('City', _locCtrl)),
                          ],
                        ),
                        const SizedBox(height: 16),

                        _formField(
                          'UPI ID',
                          _upiCtrl,
                          val: Validators.optional(Validators.validateUpi),
                        ),
                        const SizedBox(height: 16),

                        _formField('Internal Notes', _notesCtrl, maxLines: 3),
                      ],
                    ),
                  ),
                ),

                // ─── STAGE 3: FOOTER ROW ACTIONS ───
                const Divider(),
                _buildFooterRow(isNew),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVacationToggleSwitch() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SwitchListTile(
        title: const Text(
          'Mark as Away / Unavailable',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          _busyRange != null
              ? 'Away: ${DateFormat('dd MMM').format(_busyRange!.start)} to ${DateFormat('dd MMM').format(_busyRange!.end)}'
              : 'Currently active and available for campaigns.',
          style: TextStyle(
            fontSize: 12,
            color: _busyRange != null
                ? Colors.red.shade600
                : Colors.grey.shade600,
          ),
        ),
        value: _busyRange != null,
        activeThumbColor: Colors.red,
        onChanged: (isTurnedOn) async {
          if (isTurnedOn) {
            final minDate = DateTime.now().add(const Duration(days: 30));
            final picked = await showDateRangePicker(
              context: context,
              firstDate: minDate,
              lastDate: DateTime.now().add(const Duration(days: 365)),
              helpText: 'Select Away Dates',
            );
            if (picked != null) setState(() => _busyRange = picked);
          } else {
            setState(() => _busyRange = null);
          }
        },
      ),
    );
  }

  Widget _buildFooterRow(bool isNew) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (!isNew)
          TextButton.icon(
            onPressed: () => _handleDeleteRequest(context, widget.creator!),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: const Text('Delete Creator'),
          ),
        const Spacer(),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 16),
        Navigator(
          onGenerateRoute: (_) => MaterialPageRoute(
            builder: (ctx) => ElevatedButton(
              onPressed: () {
                if (!_formKey.currentState!.validate()) return;

                final newCreator = Creator(
                  id: isNew ? '' : widget.creator!.id,
                  fullName: _nameCtrl.text.trim(),
                  handle: _handleCtrl.text.trim().replaceAll('@', ''),
                  phoneNumber: _phoneCtrl.text.replaceAll(RegExp(r'\s+'), ''),
                  status: _selectedStatus,
                  type: _selectedType,

                  primaryCategory: _selectedType == CreatorType.influencer
                      ? (_selectedCategory == PrimaryCategory.generalUgc
                            ? PrimaryCategory.clothing
                            : _selectedCategory)
                      : PrimaryCategory.generalUgc,

                  secondaryNiche: _selectedType == CreatorType.influencer
                      ? _secondaryNicheCtrl.text.trim()
                      : '',
                  baseRate: (double.tryParse(_rateCtrl.text) ?? 0.0).abs(),
                  followerCount: _selectedType == CreatorType.influencer
                      ? (int.tryParse(_followerCtrl.text) ?? 0).abs()
                      : 0,
                  upiId: _upiCtrl.text.trim(),
                  location: _locCtrl.text.trim(),
                  notes: _notesCtrl.text.trim(),
                  rating: widget.creator?.rating ?? 5.0,
                  strikeLevel: widget.creator?.strikeLevel ?? 0,
                  busyFrom: _busyRange?.start,
                  busyTo: _busyRange?.end,
                );

                final provider = context.read<CreatorProvider>();
                if (isNew) {
                  provider.addCreator(newCreator);
                } else {
                  provider.updateCreator(newCreator);
                }
                Navigator.pop(context);
              },
              child: Text(isNew ? 'Create Profile' : 'Save Changes'),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleDeleteRequest(
    BuildContext context,
    Creator creator,
  ) async {
    final creatorProv = context.read<CreatorProvider>();
    final campaignProv = context.read<CampaignProvider>();
    final hasHistory = CrmAnalyticsEngine.getCampaignHistoryForCreator(
      creator.id,
      campaignProv.campaigns,
    ).isNotEmpty;

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: hasHistory ? Colors.orange : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(
              hasHistory
                  ? 'Deactivate Creator Profile?'
                  : 'Permanently Delete Creator?',
            ),
          ],
        ),
        content: Text(
          hasHistory
              ? 'This creator has campaign history. They will be marked as Inactive instead of being deleted.'
              : 'Are you sure? This will permanently delete this creator.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: hasHistory ? Colors.orange : Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(hasHistory ? 'Mark Inactive' : 'Delete Forever'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      if (hasHistory) {
        await creatorProv.deactivateCreator(creator.id, actor: 'Admin');
      } else {
        await creatorProv.deleteCreator(creator.id);
      }
      if (context.mounted) Navigator.pop(context);
    }
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
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

  Widget _formField(
    String label,
    TextEditingController ctrl, {
    bool digitsOnly = false,
    int maxLines = 1,
    String? prefix,
    String? hint,
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
          textInputAction: TextInputAction.next,
          inputFormatters: digitsOnly
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
          decoration: InputDecoration(
            prefixText: prefix,
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 13,
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
