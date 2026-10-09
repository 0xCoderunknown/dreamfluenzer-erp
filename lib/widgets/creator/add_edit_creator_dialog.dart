import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/app_enums.dart';
import '../../models/creator_model.dart';
import '../../providers/creator_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
import 'creator_form_sections.dart';

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
                              child: CreatorFormField(
                                label: 'Full Name *',
                                controller: _nameCtrl,
                                validator: (v) =>
                                    Validators.validateRequired(v, 'Name'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CreatorFormField(
                                label: 'Instagram Handle *',
                                controller: _handleCtrl,
                                prefix: '@',
                                validator: Validators.validateInstagramHandle,
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
                                child: CreatorFormField(
                                  label: 'Secondary Niche',
                                  controller: _secondaryNicheCtrl,
                                  hint: 'e.g. Skincare, Bridal, Cosmetics',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],

                        CreatorVacationSwitchTile(
                          busyRange: _busyRange,
                          onRangeChanged: (range) =>
                              setState(() => _busyRange = range),
                        ),
                        const SizedBox(height: 16),

                        _sectionLabel('Financial Details'),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: CreatorFormField(
                                label: _selectedType == CreatorType.sandboxTrainee
                                    ? 'Stipend (₹) *'
                                    : 'Base Rate (₹) *',
                                controller: _rateCtrl,
                                digitsOnly: true,
                                validator: (v) =>
                                    Validators.validateRequired(v, 'Rate'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CreatorFormField(
                                    label: 'Follower Count',
                                    controller: _followerCtrl,
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
                              child: CreatorFormField(
                                label: 'Contact Number *',
                                controller: _phoneCtrl,
                                validator: Validators.validatePhone,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CreatorFormField(
                                label: 'City',
                                controller: _locCtrl,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        CreatorFormField(
                          label: 'UPI ID',
                          controller: _upiCtrl,
                          validator: Validators.optional(Validators.validateUpi),
                        ),
                        const SizedBox(height: 16),

                        CreatorFormField(
                          label: 'Internal Notes',
                          controller: _notesCtrl,
                          maxLines: 3,
                        ),
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

  Widget _buildFooterRow(bool isNew) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (!isNew)
          TextButton.icon(
            onPressed: () => showDeleteCreatorDialog(
              context: context,
              creator: widget.creator!,
            ),
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
}
