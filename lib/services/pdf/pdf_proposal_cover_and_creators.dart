import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../config/agency_config.dart';
import '../../domain/app_enums.dart';
import '../../models/creator_model.dart';
import '../../models/lead_model.dart';
import '../../models/proposal_model.dart';
import 'pdf_theme.dart';

typedef _Dt = PdfTheme;

/// Data class grouping proposed creator, catalog profile, and linked add-ons
class CreatorCardData {
  final ProposedCreator proposed;
  final Creator original;
  final List<PitchAddOn> linkedAddOns;

  const CreatorCardData({
    required this.proposed,
    required this.original,
    required this.linkedAddOns,
  });
}

/// Helper converting deliverable type enum to friendly pluralized string
String getFriendlyDeliverableName(DeliverableType type, int quantity) {
  switch (type) {
    case DeliverableType.reel:
      return quantity == 1 ? 'Promotional Reel' : 'Promotional Reels';
    case DeliverableType.post:
      return quantity == 1 ? 'Promotional Post' : 'Promotional Posts';
    case DeliverableType.story:
      return quantity == 1 ? 'Story Mention' : 'Story Mentions';
    case DeliverableType.video:
      return quantity == 1 ? 'Promotional Video' : 'Promotional Videos';
  }
}


/// Running header shown on inner proposal pages
pw.Widget buildRunningHeader({
  required PdfFontSet fonts,
  required Lead lead,
}) {
  return pw.Column(
    children: [
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            AgencyConfig.agencyName,
            style: pw.TextStyle(
              font: fonts.bold,
              fontSize: _Dt.tsCaption,
              color: _Dt.brandPurple,
              letterSpacing: 2,
            ),
          ),
          pw.Text(
            'Campaign Proposal — ${lead.businessName}',
            style: pw.TextStyle(
              font: fonts.regular,
              fontSize: _Dt.tsMicro,
              color: _Dt.inkGhost,
            ),
          ),
        ],
      ),
      pw.SizedBox(height: _Dt.sp1),
      pw.Divider(color: _Dt.surfaceBorder, thickness: 0.5),
      pw.SizedBox(height: _Dt.sp2),
    ],
  );
}

/// Running footer with page count and confidentiality stamp
pw.Widget buildRunningFooter({
  required pw.Context context,
  required PdfFontSet fonts,
  required String dateStr,
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

/// Numbered section header divider bar
pw.Widget buildSectionLabel(
  String number,
  String title, {
  required PdfFontSet fonts,
}) {
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.center,
    children: [
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        color: _Dt.brandPurple,
        child: pw.Text(
          number,
          style: pw.TextStyle(
            font: fonts.bold,
            fontSize: _Dt.tsMicro - 0.5,
            color: _Dt.surfaceWhite,
            letterSpacing: 0.5,
          ),
        ),
      ),
      pw.SizedBox(width: _Dt.sp1),
      pw.Text(
        title,
        style: pw.TextStyle(
          font: fonts.bold,
          fontSize: _Dt.tsCaption + 0.5,
          color: _Dt.inkDark,
          letterSpacing: 1.2,
        ),
      ),
      pw.SizedBox(width: _Dt.sp2),
      pw.Expanded(
        child: pw.Divider(color: _Dt.surfaceBorder, thickness: 0.5),
      ),
    ],
  );
}

/// Creator card block inside Section 01
pw.Widget buildCreatorCard({
  required CreatorCardData data,
  required int index,
  required PdfFontSet fonts,
}) {
  final type = data.original.type;
  final PdfColor accentColor = type == CreatorType.ugcCreator
      ? _Dt.ugcAccent
      : (data.original.location.isNotEmpty
            ? _Dt.localAccent
            : _Dt.influencerAccent);
  final PdfColor accentLight = type == CreatorType.ugcCreator
      ? _Dt.ugcAccentLight
      : (data.original.location.isNotEmpty
            ? _Dt.localAccentLight
            : _Dt.influencerAccentLight);
  final String typeBadgeLabel = type == CreatorType.ugcCreator
      ? 'CONTENT CREATOR'
      : (data.original.location.isNotEmpty ? 'LOCAL CREATOR' : 'INFLUENCER');

  final deliverableBullets = data.proposed.deliverables
      .map(
        (d) => '${d.quantity}x ${getFriendlyDeliverableName(d.type, d.quantity)}',
      )
      .toList();

  return pw.Container(
    decoration: pw.BoxDecoration(
      color: _Dt.surfaceWhite,
      border: pw.Border.all(color: _Dt.surfaceBorder, width: 0.5),
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 42,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: accentLight,
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(8),
                bottomLeft: pw.Radius.circular(8),
              ),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 4,
                  height: 60,
                  color: accentColor,
                  margin: const pw.EdgeInsets.only(right: 10),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: 24,
                        height: 2.5,
                        color: accentColor,
                      ),
                      pw.SizedBox(height: _Dt.sp1),
                      pw.Text(
                        data.proposed.name,
                        style: pw.TextStyle(
                          font: fonts.bold,
                          fontSize: _Dt.tsH3 + 0.5,
                          color: _Dt.inkDark,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        '@${data.original.handle}',
                        style: pw.TextStyle(
                          font: fonts.regular,
                          fontSize: _Dt.tsMicro + 0.5,
                          color: _Dt.inkMuted,
                        ),
                      ),
                      pw.SizedBox(height: _Dt.sp2),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: pw.BoxDecoration(
                          color: accentColor,
                          borderRadius: pw.BorderRadius.circular(3),
                        ),
                        child: pw.Text(
                          typeBadgeLabel,
                          style: pw.TextStyle(
                            font: fonts.bold,
                            fontSize: _Dt.tsMicro - 0.5,
                            color: _Dt.surfaceWhite,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        pw.Expanded(
          flex: 58,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(14),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'DELIVERABLES',
                  style: pw.TextStyle(
                    font: fonts.bold,
                    fontSize: _Dt.tsMicro,
                    color: _Dt.inkGhost,
                    letterSpacing: 0.8,
                  ),
                ),
                pw.SizedBox(height: _Dt.sp1),
                if (deliverableBullets.isEmpty)
                  pw.Text(
                    'No deliverables added yet.',
                    style: pw.TextStyle(
                      font: fonts.regular,
                      fontSize: _Dt.tsCaption,
                      color: _Dt.inkGhost,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  )
                else
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: deliverableBullets.map((item) {
                      return pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 5),
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Container(
                              width: 4,
                              height: 4,
                              margin: const pw.EdgeInsets.only(
                                top: 3,
                                right: 6,
                              ),
                              decoration: pw.BoxDecoration(
                                color: accentColor,
                                shape: pw.BoxShape.circle,
                              ),
                            ),
                            pw.Expanded(
                              child: pw.Text(
                                item,
                                style: pw.TextStyle(
                                  font: fonts.medium,
                                  fontSize: _Dt.tsCaption,
                                  color: _Dt.inkMid,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                pw.SizedBox(height: _Dt.sp1),
                pw.Container(height: 0.5, color: _Dt.surfaceBorder),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Usage Rights: ${data.proposed.usageRightsDuration}',
                  style: pw.TextStyle(
                    font: fonts.regular,
                    fontSize: _Dt.tsMicro,
                    color: _Dt.inkMuted,
                  ),
                ),
                pw.Text(
                  'Exclusivity: ${data.proposed.categoryExclusivity}',
                  style: pw.TextStyle(
                    font: fonts.regular,
                    fontSize: _Dt.tsMicro,
                    color: _Dt.inkMuted,
                  ),
                ),
                if (data.linkedAddOns.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  ...data.linkedAddOns.map(
                    (addOn) => pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 1),
                      child: pw.Text(
                        '+ Add-on: ${addOn.description}',
                        style: pw.TextStyle(
                          font: fonts.regular,
                          fontSize: _Dt.tsMicro,
                          color: _Dt.brandPurpleDark,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
