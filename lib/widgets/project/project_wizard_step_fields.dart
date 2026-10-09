import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/app_enums.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
import '../common/ui_kit.dart';

/// Step 2 project details & financial input fields for Project Creation Wizard
class ProjectWizardProjectFields extends StatelessWidget {
  final TextEditingController projectNameController;
  final DealType selectedDealType;
  final ValueChanged<DealType> onDealTypeChanged;
  final BillingModel selectedBillingModel;
  final ValueChanged<BillingModel> onBillingModelChanged;
  final TextEditingController durationMonthsController;
  final TextEditingController baseBudgetController;
  final TextEditingController advanceReceivedController;
  final TextEditingController gmvBudgetController;
  final bool isGstExclusive;
  final ValueChanged<bool> onGstExclusiveChanged;
  final DateTime deadline;
  final VoidCallback onSelectDeadline;
  final GlobalKey<FormState> formKey;

  const ProjectWizardProjectFields({
    super.key,
    required this.projectNameController,
    required this.selectedDealType,
    required this.onDealTypeChanged,
    required this.selectedBillingModel,
    required this.onBillingModelChanged,
    required this.durationMonthsController,
    required this.baseBudgetController,
    required this.advanceReceivedController,
    required this.gmvBudgetController,
    required this.isGstExclusive,
    required this.onGstExclusiveChanged,
    required this.deadline,
    required this.onSelectDeadline,
    required this.formKey,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPrGiftMode = selectedDealType == DealType.prGift;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DreamSectionBox(
          title: 'CORE DETAILS',
          child: Column(
            children: [
              TextFormField(
                controller: projectNameController,
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
                      initialValue: selectedDealType,
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
                      onChanged: (v) {
                        if (v != null) onDealTypeChanged(v);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<BillingModel>(
                      initialValue: selectedBillingModel,
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
                      onChanged: (v) {
                        if (v != null) onBillingModelChanged(v);
                      },
                    ),
                  ),
                ],
              ),
              if (selectedBillingModel == BillingModel.retainer &&
                  !isPrGiftMode) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: durationMonthsController,
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
                      controller: baseBudgetController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Cash Budget *',
                        prefixIcon: Icon(Icons.currency_rupee),
                      ),
                      keyboardType: TextInputType.number,
                      enabled: !isPrGiftMode,
                      validator: (v) => selectedDealType == DealType.prGift
                          ? null
                          : Validators.validateRequired(v, 'Cash Budget'),
                      onChanged: (_) => formKey.currentState?.validate(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: advanceReceivedController,
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
                            double.tryParse(baseBudgetController.text) ?? 0.0;
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
                      controller: gmvBudgetController,
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
                value: isGstExclusive,
                activeThumbColor: AppTheme.primaryPurple,
                onChanged: isPrGiftMode
                    ? null
                    : (v) => onGstExclusiveChanged(v),
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
              DateFormat('dd MMM yyyy').format(deadline),
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
            onTap: onSelectDeadline,
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
