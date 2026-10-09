import 'package:pdf/widgets.dart' as pw;

import '../../config/agency_config.dart';
import 'pdf_theme.dart';

typedef _Dt = PdfTheme;

/// Payment details bank accounts box for PDF invoices
pw.Widget buildPaymentDetailsBox({required PdfFontSet fonts}) {
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
                child: buildPaymentField(
                  label: 'Bank',
                  value: AgencyConfig.bankName,
                  fonts: fonts,
                ),
              ),
              pw.Expanded(
                child: buildPaymentField(
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
                child: buildPaymentField(
                  label: 'IFSC Code',
                  value: AgencyConfig.ifscCode,
                  fonts: fonts,
                ),
              ),
              pw.Expanded(
                child: buildPaymentField(
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

/// Key-value label/value for payment banking box
pw.Widget buildPaymentField({
  required String label,
  required String value,
  required PdfFontSet fonts,
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

/// Terms and conditions box for PDF invoices
pw.Widget buildInvoiceTerms({required PdfFontSet fonts}) {
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

/// Metadata label & value alignment row for invoice header
pw.Widget buildInvoiceMeta({
  required String label,
  required String value,
  required PdfFontSet fonts,
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

/// Running footer with page count and confidentiality stamp
pw.Widget buildInvoiceRunningFooter({
  required PdfFontSet fonts,
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
