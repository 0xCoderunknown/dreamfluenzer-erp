import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../config/proposal_templates.dart';
import '../../domain/app_enums.dart';
import '../../models/creator_model.dart';
import '../../models/lead_model.dart';
import '../../models/proposal_model.dart';
import '../../providers/creator_provider.dart';
import 'pdf_proposal_cover.dart';
import 'pdf_proposal_cover_and_creators.dart';
import 'pdf_proposal_sections.dart';
import 'pdf_theme.dart';

typedef _Dt = PdfTheme;
typedef _FontSet = PdfFontSet;

class PdfProposalBuilder {
  static _FontSet _fonts() => PdfFontSet.helvetica();

  static Future<void> generatePitchPdf(
    Proposal proposal,
    Lead lead,
    CreatorProvider creatorProvider,
  ) async {
    final doc = pw.Document();
    final fmt = NumberFormat('#,##0', 'en_IN');
    final fonts = _fonts();
    final now = DateTime.now();
    final dateStr = DateFormat('dd MMMM yyyy').format(now);
    final validUntil = DateFormat(
      'dd MMMM yyyy',
    ).format(now.add(const Duration(days: 30)));

    final cardDataList = proposal.creators.map((pc) {
      final original = creatorProvider.creators.firstWhere(
        (c) => c.id == pc.creatorId,
        orElse: () => Creator(
          id: '',
          fullName: pc.name,
          handle: pc.name.toLowerCase().replaceAll(' ', '_'),
          phoneNumber: '',
          status: CreatorStatus.active,
          type: CreatorType.influencer,
          primaryCategory: PrimaryCategory.generalUgc,
          secondaryNiche: '',
          baseRate: 0,
          followerCount: 0,
          upiId: '',
          location: '',
          notes: '',
          rating: 5,
        ),
      );
      return CreatorCardData(
        proposed: pc,
        original: original,
        linkedAddOns: proposal.addOns
            .where((a) => a.creatorId == pc.creatorId)
            .toList(),
      );
    }).toList();

    final String planSubtitle = ProposalTextBlueprintManager.getPlanSubtitle(
      proposal.proposalType,
    );

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (_) => buildCoverPage(
          fonts: fonts,
          lead: lead,
          proposal: proposal,
          dateStr: dateStr,
          validUntil: validUntil,
          planSubtitle: planSubtitle,
        ),
      ),
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 42, vertical: 38),
        header: (_) => buildRunningHeader(fonts: fonts, lead: lead),
        footer: (ctx) =>
            buildRunningFooter(context: ctx, fonts: fonts, dateStr: dateStr),
        build: (_) => [
          buildSectionLabel(
            'SECTION 01',
            'CREATORS IN THIS CAMPAIGN',
            fonts: fonts,
          ),
          pw.SizedBox(height: _Dt.sp3),
          if (cardDataList.isEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: _Dt.sp2),
              child: pw.Text(
                'No creators have been added to this proposal yet.',
                style: pw.TextStyle(
                  font: fonts.regular,
                  fontSize: _Dt.tsBody,
                  color: _Dt.inkMuted,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            )
          else
            ...cardDataList.asMap().entries.map(
              (e) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: _Dt.sp2),
                child: buildCreatorCard(
                  data: e.value,
                  index: e.key,
                  fonts: fonts,
                ),
              ),
            ),

          pw.SizedBox(height: _Dt.sp5),
          buildSectionLabel(
            'SECTION 02',
            'WHAT YOU ARE GETTING',
            fonts: fonts,
          ),
          pw.SizedBox(height: _Dt.sp2),
          buildMetricsDashboard(
            fonts: fonts,
            lead: lead,
            proposal: proposal,
            cardDataList: cardDataList,
          ),

          pw.NewPage(),

          buildSectionLabel('SECTION 03', 'PRICING SUMMARY', fonts: fonts),
          pw.SizedBox(height: _Dt.sp3),
          buildPricingSection(fonts: fonts, proposal: proposal, fmt: fmt),
          pw.SizedBox(height: _Dt.sp1),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              '* All figures exclusive of 18% GST as applicable.',
              style: pw.TextStyle(
                font: fonts.regular,
                fontSize: _Dt.tsMicro,
                color: _Dt.inkGhost,
              ),
            ),
          ),
          pw.SizedBox(height: _Dt.sp4),

          buildSectionLabel('SECTION 04', 'TERMS & CONDITIONS', fonts: fonts),
          pw.SizedBox(height: _Dt.sp3),
          buildGuidelinesPanel(
            fonts: fonts,
            cardDataList: cardDataList,
            lead: lead,
            proposal: proposal,
          ),
          pw.SizedBox(height: _Dt.sp3),
          buildNextStepsActionPanel(fonts: fonts),
          pw.SizedBox(height: _Dt.sp3),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) async => doc.save(),
      name: 'Proposal_${lead.businessName.replaceAll(' ', '_')}_$dateStr.pdf',
    );
  }
}
