import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/creator_model.dart';
import '../../models/proposal_model.dart';
import '../../theme/app_theme.dart';
import 'proposal_add_on_tile.dart';

class ProposalCommercialsSidebar extends StatefulWidget {
  final double totalCreatorsCost;
  final TextEditingController agencyFeeCtrl;
  final TextEditingController internalNotesCtrl;
  final List<PitchAddOn> addOnsList;
  final List<Creator> assignedCreators;
  final List<Creator> allCreators;
  final bool hasSelectedCreators;
  final bool isProcessing;
  final VoidCallback onSaveDraft;
  final VoidCallback onExportPdf;
  final VoidCallback? onChanged;

  const ProposalCommercialsSidebar({
    super.key,
    required this.totalCreatorsCost,
    required this.agencyFeeCtrl,
    required this.internalNotesCtrl,
    required this.addOnsList,
    required this.assignedCreators,
    required this.allCreators,
    required this.hasSelectedCreators,
    required this.isProcessing,
    required this.onSaveDraft,
    required this.onExportPdf,
    this.onChanged,
  });

  @override
  State<ProposalCommercialsSidebar> createState() =>
      _ProposalCommercialsSidebarState();
}

class _ProposalCommercialsSidebarState
    extends State<ProposalCommercialsSidebar> {
  final _addOnDescCtrl = TextEditingController();
  final _addOnPriceCtrl = TextEditingController();
  String? _selectedAddOnCreatorId;

  @override
  void dispose() {
    _addOnDescCtrl.dispose();
    _addOnPriceCtrl.dispose();
    super.dispose();
  }

  double get _calculateGeneralAddOnsCost {
    return widget.addOnsList
        .where((item) => item.creatorId == null)
        .fold(0.0, (sum, item) => sum + item.price);
  }

  double get _calculateCreatorSpecificAddOnsCost {
    return widget.addOnsList
        .where((item) => item.creatorId != null)
        .fold(0.0, (sum, item) => sum + item.price);
  }

  double get _calculateGrandTotal {
    final agencyFee = double.tryParse(widget.agencyFeeCtrl.text) ?? 0.0;
    return widget.totalCreatorsCost +
        _calculateGeneralAddOnsCost +
        _calculateCreatorSpecificAddOnsCost +
        agencyFee;
  }

  void _addNewLogisticsAddOnElement() {
    final desc = _addOnDescCtrl.text.trim();
    final price = double.tryParse(_addOnPriceCtrl.text.trim()) ?? 0.0;
    if (desc.isNotEmpty && price > 0) {
      setState(() {
        widget.addOnsList.add(
          PitchAddOn(
            id: 'addon_${DateTime.now().millisecondsSinceEpoch}',
            description: desc,
            price: price,
            creatorId: _selectedAddOnCreatorId,
          ),
        );
        _addOnDescCtrl.clear();
        _addOnPriceCtrl.clear();
        _selectedAddOnCreatorId = null;
      });
      widget.onChanged?.call();
    }
  }

  Widget _buildLedgerLine(String title, String val, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: isTotal ? 15 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: AppTheme.primaryDark,
          ),
        ),
        Text(
          val,
          style: TextStyle(
            fontSize: isTotal ? 22 : 15,
            fontWeight: FontWeight.bold,
            color: isTotal ? AppTheme.primaryPurple : AppTheme.primaryDark,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat('#,##0', 'en_IN');

    final activeCreatorId = widget.assignedCreators.any(
      (c) => c.id == _selectedAddOnCreatorId,
    )
        ? _selectedAddOnCreatorId
        : null;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PRICING SUMMARY',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.grey,
              letterSpacing: 1,
            ),
          ),
          const Divider(height: 32),
          _buildLedgerLine(
            'Creator Fees',
            '₹${currencyFmt.format(widget.totalCreatorsCost)}',
          ),
          const SizedBox(height: 12),
          _buildLedgerLine(
            'General Project Add-ons',
            '₹${currencyFmt.format(_calculateGeneralAddOnsCost)}',
          ),
          const SizedBox(height: 12),
          _buildLedgerLine(
            'Creator Add-ons',
            '₹${currencyFmt.format(_calculateCreatorSpecificAddOnsCost)}',
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Agency Markup Fee',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.primaryDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(
                width: 140,
                child: TextFormField(
                  controller: widget.agencyFeeCtrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.end,
                  decoration: const InputDecoration(
                    prefixText: '₹ ',
                    isDense: true,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Required';
                    }
                    final numVal = double.tryParse(v.trim()) ?? -1;
                    if (numVal < 0) return 'Cannot be negative';
                    return null;
                  },
                  onChanged: (_) {
                    setState(() {});
                    widget.onChanged?.call();
                  },
                ),
              ),
            ],
          ),
          const Divider(height: 40),
          _buildLedgerLine(
            'TOTAL CLIENT PRICE',
            '₹${currencyFmt.format(_calculateGrandTotal)}',
            isTotal: true,
          ),
          const SizedBox(height: 32),
          const Text(
            'ADDITIONAL EXPENSES',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: Colors.grey,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _addOnDescCtrl,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Courier, Studio Shoot',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 85,
                child: TextFormField(
                  controller: _addOnPriceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: '₹ Price',
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  initialValue: activeCreatorId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  hint: const Text(
                    'Link to a creator or keep general...',
                    style: TextStyle(fontSize: 12),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text(
                        'General Expense (not linked to a creator)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ...widget.assignedCreators.map((cc) {
                      return DropdownMenuItem<String?>(
                        value: cc.id,
                        child: Text(
                          'Link to: @${cc.handle}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.primaryPurple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }),
                  ],
                  onChanged: (val) =>
                      setState(() => _selectedAddOnCreatorId = val),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(
                  Icons.add_circle_rounded,
                  color: AppTheme.primaryPurple,
                  size: 28,
                ),
                onPressed: _addNewLogisticsAddOnElement,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: widget.addOnsList.isEmpty
                ? Center(
                    child: Text(
                      'No extra expenses added yet.',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontStyle: FontStyle.italic,
                        fontSize: 13,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: widget.addOnsList.length,
                    itemBuilder: (context, idx) {
                      final item = widget.addOnsList[idx];
                      final linkedCc = item.creatorId != null
                          ? widget.allCreators.firstWhere(
                              (c) => c.id == item.creatorId,
                              orElse: () => widget.allCreators.first,
                            )
                          : null;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ProposalAddOnTile(
                            addOn: item,
                            onDelete: () {
                              setState(
                                () => widget.addOnsList.removeAt(idx),
                              );
                              widget.onChanged?.call();
                            },
                          ),
                          if (linkedCc != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                12,
                                2,
                                0,
                                8,
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '↳ Linked to: ${linkedCc.fullName} (@${linkedCc.handle})',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontStyle: FontStyle.italic,
                                    color: AppTheme.primaryPurple,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
          ),
          TextFormField(
            controller: widget.internalNotesCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Internal Notes',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryPurple,
                    side: const BorderSide(
                      color: AppTheme.primaryPurple,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed:
                      !widget.hasSelectedCreators || widget.isProcessing
                      ? null
                      : widget.onSaveDraft,
                  icon: widget.isProcessing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primaryPurple,
                          ),
                        )
                      : const Icon(Icons.save_rounded, size: 18),
                  label: const Text(
                    'Save Draft Configuration',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed:
                      !widget.hasSelectedCreators || widget.isProcessing
                      ? null
                      : widget.onExportPdf,
                  icon: widget.isProcessing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.picture_as_pdf_rounded,
                          size: 18,
                        ),
                  label: const Text(
                    'Save & Export Client PDF',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
