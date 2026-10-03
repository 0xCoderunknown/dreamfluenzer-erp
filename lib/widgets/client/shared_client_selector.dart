import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/app_enums.dart';
import '../../models/client_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
import '../common/ui_kit.dart';

// ===========================================================================
// Shared Client Selector widget.
// ===========================================================================

class SharedClientSelector extends StatefulWidget {
  final List<Client> existingClients;
  final bool isLinkingExisting;
  final String? selectedClientId;
  final TextEditingController businessNameCtrl,
      industryCtrl,
      contactPersonCtrl,
      phoneCtrl,
      emailCtrl,
      instaCtrl,
      locationCtrl;
  final ClientTier selectedTier;
  final ValueChanged<ClientTier> onTierChanged;
  final ValueChanged<bool> onModeChanged;
  final ValueChanged<String?> onClientSelected;

  const SharedClientSelector({
    super.key,
    required this.existingClients,
    required this.isLinkingExisting,
    required this.selectedClientId,
    required this.businessNameCtrl,
    required this.industryCtrl,
    required this.contactPersonCtrl,
    required this.phoneCtrl,
    required this.emailCtrl,
    required this.instaCtrl,
    required this.locationCtrl,
    required this.selectedTier,
    required this.onTierChanged,
    required this.onModeChanged,
    required this.onClientSelected,
  });

  @override
  State<SharedClientSelector> createState() => _SharedClientSelectorState();
}

class _SharedClientSelectorState extends State<SharedClientSelector> {
  Client? _duplicateMatch;
  late final SearchController _clientSearchController;

  @override
  void initState() {
    super.initState();
    final initialClient = widget.existingClients
        .where((c) => c.id == widget.selectedClientId)
        .firstOrNull;
    _clientSearchController = SearchController()
      ..text = initialClient?.businessName ?? '';
    widget.phoneCtrl.addListener(_performBackgroundLookup);
  }

  @override
  void didUpdateWidget(SharedClientSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phoneCtrl != widget.phoneCtrl) {
      oldWidget.phoneCtrl.removeListener(_performBackgroundLookup);
      widget.phoneCtrl.addListener(_performBackgroundLookup);
    }
    if (oldWidget.selectedClientId != widget.selectedClientId ||
        oldWidget.existingClients != widget.existingClients) {
      final match = widget.existingClients
          .where((c) => c.id == widget.selectedClientId)
          .firstOrNull;
      _clientSearchController.text = match?.businessName ?? '';
    }
  }

  @override
  void dispose() {
    widget.phoneCtrl.removeListener(_performBackgroundLookup);
    _clientSearchController.dispose();
    super.dispose();
  }

  void _performBackgroundLookup() {
    final input = widget.phoneCtrl.text.trim();
    if (widget.isLinkingExisting || input.length < 10) {
      if (_duplicateMatch != null) setState(() => _duplicateMatch = null);
      return;
    }

    final match = widget.existingClients
        .where(
          (c) => c.contactPhone.replaceAll(RegExp(r'\D'), '').contains(input),
        )
        .firstOrNull;

    if (match != null) {
      if (_duplicateMatch?.id != match.id) {
        setState(() => _duplicateMatch = match);
      }
    } else {
      if (_duplicateMatch != null) setState(() => _duplicateMatch = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Expanded(
                child: _ToggleButton(
                  label: 'Create New Profile',
                  isSelected: !widget.isLinkingExisting,
                  onTap: () => widget.onModeChanged(false),
                ),
              ),
              Expanded(
                child: _ToggleButton(
                  label: 'Link Existing Client',
                  isSelected: widget.isLinkingExisting,
                  onTap: () => widget.onModeChanged(true),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        if (widget.isLinkingExisting)
          DreamSectionBox(
            title: 'Search Clients',
            child: SearchAnchor(
              searchController: _clientSearchController,
              builder: (BuildContext context, SearchController controller) {
                return TextFormField(
                  controller: controller,
                  readOnly: true,
                  onTap: () => controller.openView(),
                  decoration: const InputDecoration(
                    labelText: 'Select Client Account',
                    prefixIcon: Icon(Icons.search),
                    suffixIcon: Icon(Icons.arrow_drop_down),
                  ),
                  validator: (v) => widget.selectedClientId == null
                      ? 'Please select a client.'
                      : null,
                );
              },
              suggestionsBuilder:
                  (BuildContext context, SearchController controller) {
                    final keyword = controller.text.toLowerCase();
                    final matches = widget.existingClients.where(
                      (c) => c.businessName.toLowerCase().contains(keyword),
                    );
                    return matches.map((c) {
                      return ListTile(
                        title: Text(c.businessName),
                        onTap: () {
                          controller.closeView(c.businessName);
                          widget.onClientSelected(c.id);
                        },
                      );
                    });
                  },
            ),
          )
        else
          Column(
            children: [
              DreamSectionBox(
                title: 'BUSINESS IDENTITY',
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: widget.businessNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Business Name *',
                          prefixIcon: Icon(Icons.business_rounded),
                        ),
                        validator: (v) =>
                            Validators.validateRequired(v, 'Business Name'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: widget.industryCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Industry Type *',
                          prefixIcon: Icon(Icons.category_rounded),
                        ),
                        validator: (v) =>
                            Validators.validateRequired(v, 'Industry Type'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              DreamSectionBox(
                title: 'CONTACT DETAILS',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: widget.contactPersonCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Contact Person Name *',
                              prefixIcon: Icon(Icons.person_rounded),
                            ),
                            validator: (v) =>
                                Validators.validateRequired(v, 'Contact Name'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: widget.phoneCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number *',
                              prefixIcon: Icon(Icons.phone_rounded),
                              prefixText: '+91 ',
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            keyboardType: TextInputType.phone,
                            validator: Validators.validatePhone,
                          ),
                        ),
                      ],
                    ),
                    if (_duplicateMatch != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline_rounded,
                                size: 16,
                                color: Colors.amber.shade800,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Matched in Roster: ${_duplicateMatch!.businessName}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.amber.shade900,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () => widget.onModeChanged(true),
                                child: const Text(
                                  'Link Instead?',
                                  style: TextStyle(fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              DreamSectionBox(
                title: 'Location & Social Profiles',
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: widget.locationCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Operational HQ Location',
                              prefixIcon: Icon(Icons.location_on_rounded),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<ClientTier>(
                            initialValue: widget.selectedTier,
                            items: ClientTier.values
                                .map(
                                  (t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(t.value),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => widget.onTierChanged(v!),
                            decoration: const InputDecoration(
                              labelText: 'Account Tier',
                              prefixIcon: Icon(Icons.workspace_premium_rounded),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: widget.emailCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Email Address (Optional)',
                              prefixIcon: Icon(Icons.email_rounded),
                            ),
                            validator: Validators.optional(
                              Validators.validateEmail,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: widget.instaCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Instagram Handle (Optional)',
                              prefixIcon: Icon(Icons.alternate_email_rounded),
                              prefixText: '@',
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.deny(RegExp(r'^@')),
                            ],
                            validator: Validators.optional(
                              Validators.validateInstagramHandle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppTheme.primaryPurple : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}
