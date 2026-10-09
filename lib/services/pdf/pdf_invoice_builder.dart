import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../domain/app_enums.dart';
import '../../engines/revenue_engine.dart';
import '../../models/campaign_model.dart';
import '../../models/client_model.dart';
import '../../models/project_model.dart';
import 'pdf_invoice_tables.dart';
import 'pdf_invoice_terms_and_footer.dart';
import 'pdf_theme.dart';

typedef _Dt = PdfTheme;
typedef _FontSet = PdfFontSet;

class PdfInvoiceBuilder {
  static _FontSet _fonts() => PdfFontSet.helvetica();

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

    final inventoryLines = <InventoryLineItem>[];
    if (project.dealType == DealType.barter ||
        project.dealType == DealType.hybrid ||
        project.dealType == DealType.prGift) {
      for (final camp in campaigns) {
        for (final item in camp.inventoryPool) {
          inventoryLines.add(
            InventoryLineItem(
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
        footer: (ctx) => buildInvoiceRunningFooter(
          fonts: fonts,
          dateStr: DateFormat('dd MMM yyyy').format(now),
          context: ctx,
        ),
        build: (_) => [
          buildInvoiceHeader(
            fonts: fonts,
            project: project,
            client: client,
            invoiceNumber: invoiceNumber,
            now: now,
          ),
          pw.SizedBox(height: _Dt.sp4),
          buildInvoiceLineItemsTable(
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
              child: buildInvoiceFinancialSummary(
                fonts: fonts,
                invoice: invoice,
                fmt: fmt,
              ),
            ),
          ),
          pw.SizedBox(height: _Dt.sp4),
          buildPaymentDetailsBox(fonts: fonts),
          pw.SizedBox(height: _Dt.sp3),
          buildInvoiceTerms(fonts: fonts),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
      name:
          'Invoice_${client.businessName.replaceAll(' ', '_')}_$invoiceNumber.pdf',
    );
  }
}
