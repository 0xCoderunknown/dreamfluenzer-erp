import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../config/agency_config.dart';
import '../../config/proposal_templates.dart';
import '../../models/lead_model.dart';
import '../../models/proposal_model.dart';
import 'pdf_theme.dart';

typedef _Dt = PdfTheme;

/// Modern dark-theme hero cover page for proposal PDF
pw.Widget buildCoverPage({
  required PdfFontSet fonts,
  required Lead lead,
  required Proposal proposal,
  required String dateStr,
  required String validUntil,
  required String planSubtitle,
}) {
  final typeWordingParagraph = lead.customObjective.isNotEmpty
      ? lead.customObjective
      : ProposalTextBlueprintManager.getDeploymentMethodology(
          proposal.proposalType,
          lead.businessName,
        );

  return pw.Stack(
    children: [
      pw.Positioned.fill(child: pw.Container(color: _Dt.inkDeep)),
      pw.Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: pw.Container(height: 5, color: _Dt.brandPurple),
      ),
      pw.Positioned(
        left: 0,
        top: 5,
        bottom: 0,
        child: pw.Container(width: 3, color: _Dt.brandPurpleSubtle),
      ),
      pw.Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: pw.Container(
          height: 110,
          color: const PdfColor.fromInt(0xFF0D0820),
        ),
      ),
      pw.Positioned(
        right: 0,
        top: 5,
        bottom: 110,
        child: pw.Container(
          width: 180,
          color: const PdfColor.fromInt(0xFF160D30),
        ),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.fromLTRB(52, 76, 52, 40),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              AgencyConfig.agencyName,
              style: pw.TextStyle(
                font: fonts.bold,
                fontSize: _Dt.tsMicro + 1.5,
                color: _Dt.brandPurple,
                letterSpacing: 4,
              ),
            ),
            pw.SizedBox(height: _Dt.spHalf),
            pw.Container(width: 32, height: 2, color: _Dt.brandPurpleSubtle),
            pw.SizedBox(height: _Dt.sp6),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 5,
              ),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFF2D1F4E),
                borderRadius: pw.BorderRadius.circular(3),
              ),
              child: pw.Text(
                'CAMPAIGN PROPOSAL',
                style: pw.TextStyle(
                  font: fonts.semiBold,
                  fontSize: _Dt.tsCaption,
                  color: _Dt.brandPurpleMid,
                  letterSpacing: 2.5,
                ),
              ),
            ),
            pw.SizedBox(height: _Dt.sp4),
            pw.Text(
              lead.businessName,
              style: pw.TextStyle(
                font: fonts.bold,
                fontSize: _Dt.tsDisplay,
                color: _Dt.surfaceWhite,
                lineSpacing: 4,
              ),
            ),
            pw.SizedBox(height: _Dt.sp2),
            pw.Text(
              planSubtitle,
              style: pw.TextStyle(
                font: fonts.regular,
                fontSize: _Dt.tsH3,
                color: _Dt.brandPurpleMid,
                lineSpacing: 1.5,
              ),
            ),
            pw.SizedBox(height: _Dt.sp5),
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFF1A1038),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Container(
                        width: 3,
                        height: 10,
                        color: _Dt.brandPurple,
                      ),
                      pw.SizedBox(width: _Dt.sp1),
                      pw.Text(
                        'ABOUT THIS PROPOSAL',
                        style: pw.TextStyle(
                          font: fonts.semiBold,
                          fontSize: _Dt.tsMicro,
                          color: _Dt.brandPurpleMid,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: _Dt.sp2),
                  pw.Text(
                    typeWordingParagraph,
                    style: pw.TextStyle(
                      font: fonts.regular,
                      fontSize: _Dt.tsH3,
                      color: const PdfColor.fromInt(0xFFD8D0F0),
                      lineSpacing: 1.8,
                    ),
                  ),
                ],
              ),
            ),
            pw.Spacer(),
            pw.Container(
              height: 0.5,
              color: const PdfColor.fromInt(0xFF2D1F4E),
            ),
            pw.SizedBox(height: _Dt.sp2),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(
                  children: [
                    pw.Text(
                      'Proposal Issued: $dateStr',
                      style: pw.TextStyle(
                        font: fonts.medium,
                        fontSize: _Dt.tsMicro + 0.5,
                        color: _Dt.inkGhost,
                      ),
                    ),
                    pw.Text(
                      '   |   ',
                      style: const pw.TextStyle(
                        color: PdfColor.fromInt(0xFF3D2870),
                      ),
                    ),
                    pw.Text(
                      'Valid Until: $validUntil',
                      style: pw.TextStyle(
                        font: fonts.bold,
                        fontSize: _Dt.tsMicro + 0.5,
                        color: _Dt.brandPurpleSubtle,
                      ),
                    ),
                  ],
                ),
                pw.Text(
                  '${AgencyConfig.defaultCity} Operational HQ',
                  style: pw.TextStyle(
                    font: fonts.regular,
                    fontSize: _Dt.tsMicro,
                    color: _Dt.inkMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  );
}
