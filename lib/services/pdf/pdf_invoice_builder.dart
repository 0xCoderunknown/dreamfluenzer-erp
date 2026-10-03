import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../config/agency_config.dart';
import '../../domain/app_enums.dart';
import '../../engines/revenue_engine.dart'; // Financial math and calculation formulas
import '../../models/campaign_model.dart';
import '../../models/client_model.dart';
import '../../models/project_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────
class _Dt {
  static const PdfColor brandPurple = PdfColor.fromInt(0xFF6C3FC5);
  static const PdfColor brandPurpleMid = PdfColor.fromInt(0xFFD6C5F5);
  static const PdfColor brandPurpleLight = PdfColor.fromInt(0xFFF0E9FF);
  static const PdfColor inkDark = PdfColor.fromInt(0xFF0F0A1E);
  static const PdfColor inkMid = PdfColor.fromInt(0xFF374151);
  static const PdfColor inkMuted = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor inkGhost = PdfColor.fromInt(0xFF9CA3AF);

  static const PdfColor surfaceWhite = PdfColors.white;
  static const PdfColor surfaceNeutral = PdfColor.fromInt(0xFFF9FAFB);
  static const PdfColor surfaceNeutralDeep = PdfColor.fromInt(0xFFF3F4F6);
  static const PdfColor surfaceBorder = PdfColor.fromInt(0xFFE5E7EB);
  static const PdfColor successGreen = PdfColor.fromInt(0xFF059669);
  static const PdfColor successGreenLight = PdfColor.fromInt(0xFFECFDF5);

  static const double spHalf = 3.0;
  static const double sp1 = 6.0;
  static const double sp2 = 12.0;
  static const double sp3 = 18.0;
  static const double sp4 = 24.0;

  static const double tsH1 = 20.0;
  static const double tsH2 = 15.0;
  static const double tsH3 = 11.5;
  static const double tsBody = 9.5;
  static const double tsCaption = 8.5;
  static const double tsMicro = 7.5;
}

class _FontSet {
  final pw.Font regular;
  final pw.Font semiBold;
  final pw.Font bold;

  const _FontSet({
    required this.regular,
    required this.semiBold,
    required this.bold,
  });
}

class _InventoryLineItem {
  final String description;
  final double value;
  final String campaignTitle;

  const _InventoryLineItem({
    required this.description,
    required this.value,
    required this.campaignTitle,
  });
}

class PdfInvoiceBuilder {
  static _FontSet _fonts() => _FontSet(
    regular: pw.Font.helvetica(),
    semiBold: pw.Font.helveticaBold(),
    bold: pw.Font.helveticaBold(),
  );

  static Future<void> generateInvoicePdf(
    Project project,
    Client client,
    List<Campaign> campaigns,
  ) async {
    final pdf = pw.Document();
    final fmt = NumberFormat('#,##0', 'en_IN');
    final fonts = _fonts();
    final invoice = RevenueEngine.calculateInvoice(project);
    final now = DateTime.now();
    final invoiceNumber =
        'INV-${project.id.substring(project.id.length > 6 ? project.id.length - 6 : 0).toUpperCase()}';

    final inventoryLines = <_InventoryLineItem>[];
    if (project.dealType == DealType.barter ||
        project.dealType == DealType.hybrid ||
        project.dealType == DealType.prGift) {
      for (final camp in campaigns) {
        for (final item in camp.inventoryPool) {
          inventoryLines.add(
            _InventoryLineItem(
              description: '${item.totalQuantity}x ${item.itemName}',
              value: item.gmvPerUnit * item.totalQuantity,
              campaignTitle: camp.title,
            ),
          );
        }
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 42, vertical: 38),
        footer: (ctx) => _buildRunningFooter(
          fonts: fonts,
          dateStr: DateFormat('dd MMM yyyy').format(now),
          context: ctx,
        ),
        build: (_) => [
          _buildInvoiceHeader(
            fonts: fonts,
            project: project,
            client: client,
            invoiceNumber: invoiceNumber,
            now: now,
          ),
          pw.SizedBox(height: _Dt.sp4),
          _buildInvoiceLineItemsTable(
            fonts: fonts,
            project: project,
            invoice: invoice,
            inventoryLines: inventoryLines,
            fmt: fmt,
          ),
          pw.SizedBox(height: _Dt.sp2),
          pw.Divider(color: _Dt.brandPurpleMid, thickness: 0.75),
          pw.SizedBox(height: _Dt.sp2),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.SizedBox(
              width: 260,
              child: _buildInvoiceFinancialSummary(
                fonts: fonts,
                invoice: invoice,
                fmt: fmt,
              ),
            ),
          ),
          pw.SizedBox(height: _Dt.sp4),
          _buildPaymentDetailsBox(fonts: fonts),
          pw.SizedBox(height: _Dt.sp3),
          _buildInvoiceTerms(fonts: fonts),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
      name:
          'Invoice_${client.businessName.replaceAll(' ', '_')}_$invoiceNumber.pdf',
    );
  }

  static pw.Widget _buildInvoiceHeader({
    required _FontSet fonts,
    required Project project,
    required Client client,
    required String invoiceNumber,
    required DateTime now,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Container(
                  width: 3,
                  height: 30,
                  margin: const pw.EdgeInsets.only(right: 8),
                  color: _Dt.brandPurple,
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      AgencyConfig.agencyName,
                      style: pw.TextStyle(
                        font: fonts.bold,
                        fontSize: _Dt.tsH1,
                        color: _Dt.inkDark,
                      ),
                    ),
                    pw.Text(
                      AgencyConfig.legalEntity,
                      style: pw.TextStyle(
                        font: fonts.regular,
                        fontSize: _Dt.tsCaption,
                        color: _Dt.inkMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: _Dt.sp2),
            pw.Text(
              AgencyConfig.location,
              style: pw.TextStyle(
                font: fonts.regular,
                fontSize: _Dt.tsCaption,
                color: _Dt.inkMuted,
              ),
            ),
            pw.Text(
              'GSTIN: ${AgencyConfig.gstNumber}',
              style: pw.TextStyle(
                font: fonts.regular,
                fontSize: _Dt.tsCaption,
                color: _Dt.inkMuted,
              ),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'TAX INVOICE',
              style: pw.TextStyle(
                font: fonts.bold,
                fontSize: _Dt.tsH1,
                color: _Dt.brandPurple,
                letterSpacing: 1,
              ),
            ),
            pw.SizedBox(height: _Dt.sp1),
            _buildInvoiceMeta(
              label: 'Invoice No.',
              value: invoiceNumber,
              fonts: fonts,
              valueBold: true,
            ),
            pw.SizedBox(height: 3),
            _buildInvoiceMeta(
              label: 'Date',
              value: DateFormat('dd MMM yyyy').format(now),
              fonts: fonts,
            ),
            pw.SizedBox(height: _Dt.sp2),
            pw.Container(
              decoration: pw.BoxDecoration(
                color: _Dt.surfaceWhite,
                border: pw.Border.all(color: _Dt.surfaceBorder, width: 0.5),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: pw.BoxDecoration(
                  color: _Dt.surfaceNeutral,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'BILL TO',
                      style: pw.TextStyle(
                        font: fonts.semiBold,
                        fontSize: _Dt.tsMicro,
                        color: _Dt.inkGhost,
                        letterSpacing: 1,
                      ),
                      textAlign: pw.TextAlign.right,
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      client.businessName,
                      style: pw.TextStyle(
                        font: fonts.bold,
                        fontSize: _Dt.tsH3,
                        color: _Dt.inkDark,
                      ),
                      textAlign: pw.TextAlign.right,
                    ),
                    if (client.contactName.isNotEmpty)
                      pw.Text(
                        'Attn: ${client.contactName}',
                        style: pw.TextStyle(
                          font: fonts.regular,
                          fontSize: _Dt.tsCaption,
                          color: _Dt.inkMuted,
                        ),
                        textAlign: pw.TextAlign.right,
                      ),
                    if (client.location.isNotEmpty)
                      pw.Text(
                        client.location,
                        style: pw.TextStyle(
                          font: fonts.regular,
                          fontSize: _Dt.tsCaption,
                          color: _Dt.inkMuted,
                        ),
                        textAlign: pw.TextAlign.right,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildInvoiceLineItemsTable({
    required _FontSet fonts,
    required Project project,
    required InvoiceMath invoice,
    required List<_InventoryLineItem> inventoryLines,
    required NumberFormat fmt,
  }) {
    return pw.Column(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          color: _Dt.inkDark,
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'DESCRIPTION',
                style: pw.TextStyle(
                  font: fonts.semiBold,
                  fontSize: _Dt.tsMicro,
                  color: _Dt.surfaceWhite,
                  letterSpacing: 1.2,
                ),
              ),
              pw.Text(
                'AMOUNT (Rs.)',
                style: pw.TextStyle(
                  font: fonts.semiBold,
                  fontSize: _Dt.tsMicro,
                  color: _Dt.surfaceWhite,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        _buildInvoiceLineRow(
          description: project.projectName,
          subDescription:
              'Campaign Service - Duration: ${project.durationMonths} Month(s)   |   Deal Type: ${project.dealType.value}',
          value: 'Rs. ${fmt.format(invoice.subtotal)}',
          fonts: fonts,
          isFirst: true,
        ),
        if (inventoryLines.isNotEmpty) ...[
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            color: _Dt.surfaceNeutralDeep,
            child: pw.Row(
              children: [
                pw.Text(
                  'Product & Inventory Managed Assets',
                  style: pw.TextStyle(
                    font: fonts.semiBold,
                    fontSize: _Dt.tsCaption,
                    color: _Dt.inkMid,
                  ),
                ),
              ],
            ),
          ),
          ...inventoryLines.map(
            (item) => pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 7,
              ),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  top: pw.BorderSide(color: _Dt.surfaceBorder, width: 0.5),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(
                    children: [
                      pw.SizedBox(width: _Dt.sp3),
                      pw.Text(
                        '↳ ${item.description}',
                        style: pw.TextStyle(
                          font: fonts.regular,
                          fontSize: _Dt.tsCaption,
                          color: _Dt.inkMuted,
                        ),
                      ),
                    ],
                  ),
                  pw.Text(
                    'Rs. ${fmt.format(item.value)}',
                    style: pw.TextStyle(
                      font: fonts.regular,
                      fontSize: _Dt.tsCaption,
                      color: _Dt.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  static pw.Widget _buildInvoiceFinancialSummary({
    required _FontSet fonts,
    required InvoiceMath invoice,
    required NumberFormat fmt,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: _Dt.surfaceWhite,
        border: pw.Border.all(color: _Dt.surfaceBorder, width: 0.5),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          _buildInvoiceSummaryRow(
            label: 'Subtotal',
            value: 'Rs. ${fmt.format(invoice.subtotal)}',
            fonts: fonts,
          ),
          if (invoice.isGstApplied)
            _buildInvoiceSummaryRow(
              label: 'GST (${(RevenueEngine.currentGstRate * 100).toInt()}%)',
              value: 'Rs. ${fmt.format(invoice.gstAmount)}',
              fonts: fonts,
            ),
          _buildInvoiceSummaryRow(
            label: 'Grand Total',
            value: 'Rs. ${fmt.format(invoice.grandTotal)}',
            fonts: fonts,
            isSub: false,
          ),
          _buildInvoiceSummaryRow(
            label: 'Advance Received',
            value: '- Rs. ${fmt.format(invoice.advanceReceived)}',
            fonts: fonts,
            valueColor: _Dt.successGreen,
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            decoration: pw.BoxDecoration(
              color: invoice.balanceDue <= 0
                  ? _Dt.successGreenLight
                  : _Dt.brandPurpleLight,
              borderRadius: const pw.BorderRadius.only(
                bottomLeft: pw.Radius.circular(8),
                bottomRight: pw.Radius.circular(8),
              ),
            ),
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Divider(color: _Dt.surfaceBorder, thickness: 0.5),
                pw.SizedBox(height: _Dt.spHalf),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      invoice.balanceDue <= 0 ? 'PAID IN FULL' : 'BALANCE DUE',
                      style: pw.TextStyle(
                        font: fonts.bold,
                        fontSize: _Dt.tsH3,
                        color: invoice.balanceDue <= 0
                            ? _Dt.successGreen
                            : _Dt.brandPurple,
                      ),
                    ),
                    pw.Text(
                      invoice.balanceDue <= 0
                          ? 'Rs. 0'
                          : 'Rs. ${fmt.format(invoice.balanceDue)}',
                      style: pw.TextStyle(
                        font: fonts.bold,
                        fontSize: _Dt.tsH2,
                        color: invoice.balanceDue <= 0
                            ? _Dt.successGreen
                            : _Dt.brandPurple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInvoiceLineRow({
    required String description,
    required String subDescription,
    required String value,
    required _FontSet fonts,
    bool isFirst = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: pw.BoxDecoration(
        color: isFirst ? _Dt.surfaceWhite : _Dt.surfaceNeutral,
        border: const pw.Border(
          top: pw.BorderSide(color: _Dt.surfaceBorder, width: 0.5),
          bottom: pw.BorderSide(color: _Dt.surfaceBorder, width: 0.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  description,
                  style: pw.TextStyle(
                    font: fonts.semiBold,
                    fontSize: _Dt.tsBody,
                    color: _Dt.inkDark,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  subDescription,
                  style: pw.TextStyle(
                    font: fonts.regular,
                    fontSize: _Dt.tsCaption,
                    color: _Dt.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: fonts.semiBold,
              fontSize: _Dt.tsBody,
              color: _Dt.inkDark,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInvoiceSummaryRow({
    required String label,
    required String value,
    required _FontSet fonts,
    bool isSub = true,
    PdfColor? valueColor,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: _Dt.surfaceBorder, width: 0.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              font: isSub ? fonts.regular : fonts.semiBold,
              fontSize: isSub ? _Dt.tsCaption : _Dt.tsBody,
              color: isSub ? _Dt.inkMuted : _Dt.inkDark,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: fonts.semiBold,
              fontSize: isSub ? _Dt.tsCaption : _Dt.tsBody,
              color: valueColor ?? _Dt.inkDark,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPaymentDetailsBox({required _FontSet fonts}) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: _Dt.surfaceWhite,
        border: pw.Border.all(color: _Dt.surfaceBorder, width: 0.5),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Container(
        padding: const pw.EdgeInsets.all(14),
        decoration: pw.BoxDecoration(
          color: _Dt.surfaceNeutral,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              children: [
                pw.Container(width: 3, height: 11, color: _Dt.successGreen),
                pw.SizedBox(width: _Dt.sp1),
                pw.Text(
                  'PAYMENT DETAILS',
                  style: pw.TextStyle(
                    font: fonts.semiBold,
                    fontSize: _Dt.tsCaption,
                    color: _Dt.inkDark,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: _Dt.sp1),
            pw.Row(
              children: [
                pw.Expanded(
                  child: _buildPaymentField(
                    label: 'Bank',
                    value: AgencyConfig.bankName,
                    fonts: fonts,
                  ),
                ),
                pw.Expanded(
                  child: _buildPaymentField(
                    label: 'Account Number',
                    value: AgencyConfig.accountNumber,
                    fonts: fonts,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: _Dt.sp1),
            pw.Row(
              children: [
                pw.Expanded(
                  child: _buildPaymentField(
                    label: 'IFSC Code',
                    value: AgencyConfig.ifscCode,
                    fonts: fonts,
                  ),
                ),
                pw.Expanded(
                  child: _buildPaymentField(
                    label: 'UPI ID',
                    value: AgencyConfig.upiId,
                    fonts: fonts,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildPaymentField({
    required String label,
    required String value,
    required _FontSet fonts,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            font: fonts.regular,
            fontSize: _Dt.tsMicro,
            color: _Dt.inkGhost,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            font: fonts.semiBold,
            fontSize: _Dt.tsCaption,
            color: _Dt.inkDark,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildInvoiceTerms({required _FontSet fonts}) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: _Dt.surfaceWhite,
        border: pw.Border.all(color: _Dt.surfaceBorder, width: 0.5),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            left: pw.BorderSide(color: _Dt.surfaceBorder, width: 2.5),
          ),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              children: [
                pw.Container(
                  width: 3,
                  height: 11,
                  color: _Dt.inkMuted,
                  margin: const pw.EdgeInsets.only(right: 6),
                ),
                pw.Text(
                  'TERMS & CONDITIONS',
                  style: pw.TextStyle(
                    font: fonts.semiBold,
                    fontSize: _Dt.tsMicro,
                    color: _Dt.inkDark,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: _Dt.sp1),
            pw.Text(
              '1. Payment is due within 7 days of invoice date unless otherwise agreed in writing.\n2. Late payments are subject to an interest charge of 1.5% per month on the outstanding balance.\n3. All billing disputes must be raised within 5 business days of invoice receipt.\n4. This invoice is computer-generated and is legally valid without a physical signature.',
              style: pw.TextStyle(
                font: fonts.regular,
                fontSize: _Dt.tsMicro,
                color: _Dt.inkMuted,
                lineSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildInvoiceMeta({
    required String label,
    required String value,
    required _FontSet fonts,
    bool valueBold = false,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          '$label ',
          style: pw.TextStyle(
            font: fonts.regular,
            fontSize: _Dt.tsCaption,
            color: _Dt.inkMuted,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            font: valueBold ? fonts.bold : fonts.regular,
            fontSize: _Dt.tsCaption,
            color: _Dt.inkDark,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildRunningFooter({
    required _FontSet fonts,
    required String dateStr,
    required pw.Context context,
  }) {
    return pw.Column(
      children: [
        pw.Divider(color: _Dt.surfaceBorder, thickness: 0.5),
        pw.SizedBox(height: _Dt.spHalf),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Confidential — ${AgencyConfig.agencyName} — $dateStr',
              style: pw.TextStyle(
                font: fonts.regular,
                fontSize: _Dt.tsMicro,
                color: _Dt.inkGhost,
              ),
            ),
            pw.Text(
              'Page ${context.pageNumber} / ${context.pagesCount}',
              style: pw.TextStyle(
                font: fonts.semiBold,
                fontSize: _Dt.tsMicro,
                color: _Dt.inkMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
