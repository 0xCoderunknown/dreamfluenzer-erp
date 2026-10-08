import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

export 'dream_audit_log_dialog.dart';

// ===========================================================================
// 1. UNIFIED DESIGN STATUS CHIP
// ===========================================================================
class DreamStatusChip extends StatelessWidget {
  final String label;
  final Color? customColor;

  const DreamStatusChip({super.key, required this.label, this.customColor});

  @override
  Widget build(BuildContext context) {
    final color = customColor ?? AppTheme.getStatusColor(label);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ===========================================================================
// 2. UNIFIED HORIZONTAL METADATA GRID (The 1x4 Real Estate Solver)
// ===========================================================================
class DreamMetadataGrid extends StatelessWidget {
  final List<DreamGridMetaTile> children;

  const DreamMetadataGrid({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool useHorizontalRow = constraints.maxWidth > 800;

          if (useHorizontalRow) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: children.map((tile) => Expanded(child: tile)).toList(),
            );
          } else {
            return Column(
              children: children
                  .map(
                    (tile) => Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: tile,
                    ),
                  )
                  .toList(),
            );
          }
        },
      ),
    );
  }
}

class DreamGridMetaTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const DreamGridMetaTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
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
    );
  }
}

// ===========================================================================
// 3. UNIFIED METADATA SECTION BOX
// ===========================================================================
class DreamSectionBox extends StatelessWidget {
  final String title;
  final Widget child;

  const DreamSectionBox({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade500,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ===========================================================================
// 4. GLOBAL SYSTEM CONFIRM DIALOGS
// ===========================================================================
Future<bool?> showDreamConfirm(
  BuildContext context, {
  required String title,
  required String body,
  String confirmText = 'Confirm',
  bool isDestructive = false,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isDestructive
                ? AppTheme.error
                : AppTheme.primaryPurple,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(confirmText),
        ),
      ],
    ),
  );
}

// ===========================================================================
// 5. GLOBAL PAGE LAYOUT SCROLL HEADERS
// ===========================================================================
class DreamPageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String searchHint;
  final ValueChanged<String> onSearch;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? filterWidget;

  const DreamPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.searchHint,
    required this.onSearch,
    this.actionLabel,
    this.onAction,
    this.filterWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.primaryDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
            ),
            if (onAction != null && actionLabel != null)
              ElevatedButton.icon(
                onPressed: onAction!,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            SizedBox(
              width: 360,
              child: TextField(
                onChanged: onSearch,
                decoration: InputDecoration(
                  hintText: searchHint,
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Colors.grey.shade400,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
              ),
            ),
            if (filterWidget != null) ...[
              const SizedBox(width: 24),
              filterWidget!,
            ],
          ],
        ),
      ],
    );
  }
}

// ===========================================================================
class DreamLedgerCard extends StatelessWidget {
  final String title;
  final String row1Label;
  final String row1Value;
  final String row2Label;
  final String row2Value;
  final String totalLabel;
  final String totalValue;
  final Color themeColor;

  const DreamLedgerCard({
    super.key,
    required this.title,
    required this.row1Label,
    required this.row1Value,
    required this.row2Label,
    required this.row2Value,
    required this.totalLabel,
    required this.totalValue,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: themeColor,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 12),
            _buildRow(row1Label, row1Value, false),
            _buildRow(row2Label, row2Value, false),
            const SizedBox(height: 4),
            _buildRow(totalLabel, totalValue, true),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, bool isBold) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? AppTheme.primaryDark : Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: AppTheme.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

class DreamMiniBadge extends StatelessWidget {
  final String label;
  final Color color;

  const DreamMiniBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}
