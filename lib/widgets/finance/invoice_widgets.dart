import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../engines/revenue_engine.dart';
import '../../models/campaign_model.dart';
import '../../models/client_model.dart';
import '../../models/project_model.dart';
import '../../services/pdf/pdf_service.dart';
import '../../theme/app_theme.dart';

class InvoiceCard extends StatelessWidget {
  final Project project;
  final Client? client;
  final List<Campaign> campaigns;
  final bool isPaidMode;

  const InvoiceCard({
    super.key,
    required this.project,
    this.client,
    required this.campaigns,
    required this.isPaidMode,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'en_IN');
    final invoice = RevenueEngine.calculateInvoice(project);

    // --- Safe Fallback Logic ---
    final displayClientName =
        client?.businessName ?? 'Unknown Client (Deleted)';
    final bool isOrphaned = client == null;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    displayClientName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.primaryDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _StatusBadge(isPaid: isPaidMode),
              ],
            ),
            Text(
              project.projectName,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Divider(height: 24),
            _AmountRow(
              label: 'Grand Total:',
              value: '₹${fmt.format(invoice.grandTotal)}',
            ),
            const SizedBox(height: 8),
            _AmountRow(
              label: 'Advance Paid:',
              value: '₹${fmt.format(invoice.advanceReceived)}',
              color: AppTheme.success,
            ),
            const SizedBox(height: 8),
            _AmountRow(
              label: 'Balance Due:',
              value: '₹${fmt.format(invoice.balanceDue)}',
              isBold: true,
              color: isPaidMode ? AppTheme.success : Colors.red,
            ),
            const Spacer(),
            _DownloadButton(
              onPressed: isOrphaned
                  ? null
                  : () => PdfService.generateInvoicePdf(
                      project,
                      client!,
                      campaigns,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Internal Helpers for the Card ---

class _StatusBadge extends StatelessWidget {
  final bool isPaid;

  const _StatusBadge({required this.isPaid});

  @override
  Widget build(BuildContext context) {
    final color = isPaid ? AppTheme.success : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isPaid ? 'PAID' : 'DUE',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  final String label, value;
  final Color? color;
  final bool isBold;

  const _AmountRow({
    required this.label,
    required this.value,
    this.color,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isBold ? 15 : 13,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _DownloadButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const _DownloadButton({this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
        label: const Text('Download Invoice PDF'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryPurple,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade200,
        ),
      ),
    );
  }
}
