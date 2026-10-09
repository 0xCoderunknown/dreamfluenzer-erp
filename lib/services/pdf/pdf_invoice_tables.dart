import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../config/agency_config.dart';
import '../../engines/revenue_engine.dart';
import '../../models/client_model.dart';
import '../../models/project_model.dart';
import 'pdf_invoice_terms_and_footer.dart';
import 'pdf_theme.dart';

typedef _Dt = PdfTheme;

/// Data class representing an allocated product line in invoice breakdown
class InventoryLineItem {
  final String description;
  final double value;
  final String campaignTitle;

  const InventoryLineItem({
    required this.description,
    required this.value,
    required this.campaignTitle,
  });
}

/// Header section with agency branding, tax invoice header, and Bill-To client card
pw.Widget buildInvoiceHeader({
  required PdfFontSet fonts,
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
          buildInvoiceMeta(
            label: 'Invoice No.',
            value: invoiceNumber,
            fonts: fonts,
            valueBold: true,
          ),
          pw.SizedBox(height: 3),
          buildInvoiceMeta(
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

/// Table displaying service line items and managed barter assets
pw.Widget buildInvoiceLineItemsTable({
  required PdfFontSet fonts,
  required Project project,
  required InvoiceMath invoice,
  required List<InventoryLineItem> inventoryLines,
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
      buildInvoiceLineRow(
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

/// Line row widget in table
pw.Widget buildInvoiceLineRow({
  required String description,
  required String subDescription,
  required String value,
  required PdfFontSet fonts,
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

/// Financial balance and GST summary box
pw.Widget buildInvoiceFinancialSummary({
  required PdfFontSet fonts,
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
        buildInvoiceSummaryRow(
          label: 'Subtotal',
          value: 'Rs. ${fmt.format(invoice.subtotal)}',
          fonts: fonts,
        ),
        if (invoice.isGstApplied)
          buildInvoiceSummaryRow(
            label: 'GST (${(RevenueEngine.currentGstRate * 100).toInt()}%)',
            value: 'Rs. ${fmt.format(invoice.gstAmount)}',
            fonts: fonts,
          ),
        buildInvoiceSummaryRow(
          label: 'Grand Total',
          value: 'Rs. ${fmt.format(invoice.grandTotal)}',
          fonts: fonts,
          isSub: false,
        ),
        buildInvoiceSummaryRow(
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

/// Single summary row in the financial calculation card
pw.Widget buildInvoiceSummaryRow({
  required String label,
  required String value,
  required PdfFontSet fonts,
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
