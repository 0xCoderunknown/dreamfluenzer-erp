import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../config/agency_config.dart';
import '../../config/proposal_templates.dart';
import '../../domain/app_enums.dart';
import '../../models/lead_model.dart';
import '../../models/proposal_model.dart';
import 'pdf_proposal_cover_and_creators.dart';
import 'pdf_theme.dart';

typedef _Dt = PdfTheme;

/// KPI metric display model for proposal dashboard section
class KpiData {
  final String value;
  final String label;
  final PdfColor color;

  const KpiData({
    required this.value,
    required this.label,
    required this.color,
  });
}

/// Metrics and deliverables aggregate dashboard (Section 02)
pw.Widget buildMetricsDashboard({
  required PdfFontSet fonts,
  required Lead lead,
  required Proposal proposal,
  required List<CreatorCardData> cardDataList,
}) {
  int totalReels = 0, totalStories = 0, totalPosts = 0, totalVideos = 0;
  for (final card in cardDataList) {
    for (final d in card.proposed.deliverables) {
      switch (d.type) {
        case DeliverableType.reel:
          totalReels += d.quantity;
          break;
        case DeliverableType.story:
          totalStories += d.quantity;
          break;
        case DeliverableType.post:
          totalPosts += d.quantity;
          break;
        case DeliverableType.video:
          totalVideos += d.quantity;
          break;
      }
    }
  }

  final List<KpiData> dynamicKpis = [];
  if (proposal.proposalType == ProposalType.ugcProduction) {
    dynamicKpis.addAll([
      KpiData(
        value: '${cardDataList.length}',
        label: 'Content Creators',
        color: _Dt.brandPurple,
      ),
      KpiData(
        value: '${totalReels + totalVideos}',
        label: 'Videos',
        color: _Dt.brandPurple,
      ),
      KpiData(
        value: '$totalPosts',
        label: 'Photos / Posts',
        color: _Dt.brandPurple,
      ),
      const KpiData(
        value: '~3 Weeks',
        label: 'Turnaround Time',
        color: _Dt.successGreen,
      ),
    ]);
  } else {
    dynamicKpis.addAll([
      KpiData(
        value: '${cardDataList.length}',
        label: 'Creators',
        color: _Dt.brandPurple,
      ),
      KpiData(value: '$totalReels', label: 'Reels', color: _Dt.brandPurple),
      KpiData(value: '$totalStories', label: 'Stories', color: _Dt.brandPurple),
      const KpiData(
        value: '~4 Weeks',
        label: 'Campaign Duration',
        color: _Dt.successGreen,
      ),
    ]);
  }

  return pw.Container(
    decoration: pw.BoxDecoration(
      color: _Dt.surfaceNeutral,
      border: pw.Border.all(color: _Dt.surfaceBorder, width: 0.5),
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Column(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(14),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: buildKpiRow(kpis: dynamicKpis, fonts: fonts),
          ),
        ),
      ],
    ),
  );
}

/// Helper building row of formatted KPI indicators
List<pw.Widget> buildKpiRow({
  required List<KpiData> kpis,
  required PdfFontSet fonts,
}) {
  final widgets = <pw.Widget>[];
  for (int i = 0; i < kpis.length; i++) {
    widgets.add(
      pw.Column(
        children: [
          pw.Text(
            kpis[i].value,
            style: pw.TextStyle(
              font: fonts.bold,
              fontSize: _Dt.tsH2,
              color: kpis[i].color,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            kpis[i].label,
            style: pw.TextStyle(
              font: fonts.regular,
              fontSize: _Dt.tsMicro,
              color: _Dt.inkMuted,
            ),
          ),
        ],
      ),
    );
    if (i < kpis.length - 1) {
      widgets.add(
        pw.Container(width: 0.5, height: 30, color: _Dt.surfaceBorder),
      );
    }
  }
  return widgets;
}

/// Pricing breakdown and agency fee summary card (Section 03)
pw.Widget buildPricingSection({
  required PdfFontSet fonts,
  required Proposal proposal,
  required NumberFormat fmt,
}) {
  final campaignCost = proposal.totalBaseCost + proposal.agencyFee;
  final additionalCosts = proposal.totalAddOnsCost;
  return pw.Container(
    decoration: pw.BoxDecoration(
      color: _Dt.surfaceWhite,
      border: pw.Border.all(color: _Dt.surfaceBorder, width: 0.5),
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Column(
      children: [
        buildSummaryRow(
          label: 'Campaign Fee',
          value: 'Rs. ${fmt.format(campaignCost)}',
          fonts: fonts,
        ),
        if (additionalCosts > 0)
          buildSummaryRow(
            label: 'Additional Services (Logistics, On-location, etc.)',
            value: 'Rs. ${fmt.format(additionalCosts)}',
            fonts: fonts,
          ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: const pw.BoxDecoration(
            color: _Dt.brandPurpleLight,
            borderRadius: pw.BorderRadius.only(
              bottomLeft: pw.Radius.circular(8),
              bottomRight: pw.Radius.circular(8),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Total Amount',
                style: pw.TextStyle(
                  font: fonts.bold,
                  fontSize: _Dt.tsH3,
                  color: _Dt.brandPurpleDark,
                ),
              ),
              pw.Text(
                'Rs. ${fmt.format(proposal.totalClientPrice)}',
                style: pw.TextStyle(
                  font: fonts.bold,
                  fontSize: _Dt.tsH2,
                  color: _Dt.brandPurpleDark,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Helper row in the pricing card
pw.Widget buildSummaryRow({
  required String label,
  required String value,
  required PdfFontSet fonts,
}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            font: fonts.regular,
            fontSize: _Dt.tsCaption,
            color: _Dt.inkMid,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            font: fonts.bold,
            fontSize: _Dt.tsCaption,
            color: _Dt.inkDark,
          ),
        ),
      ],
    ),
  );
}

/// Mandatory campaign guidelines panel (Section 04)
pw.Widget buildGuidelinesPanel({
  required PdfFontSet fonts,
  required List<CreatorCardData> cardDataList,
  required Lead lead,
  required Proposal proposal,
}) {
  final items = ProposalTextBlueprintManager.getMandatoryGuidelines(
    proposal.proposalType,
  );
  return pw.Container(
    padding: const pw.EdgeInsets.all(16),
    decoration: pw.BoxDecoration(
      color: _Dt.surfaceWhite,
      border: pw.Border.all(color: _Dt.surfaceBorder, width: 0.5),
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Column(
      children: items.asMap().entries.map((entry) {
        final isLast = entry.key == items.length - 1;
        final parts = entry.value.split(': ');
        final String title = parts.isNotEmpty ? parts[0] : '';
        final String body = parts.length > 1 ? parts[1] : '';
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 16,
                  height: 16,
                  margin: const pw.EdgeInsets.only(right: 8),
                  decoration: pw.BoxDecoration(
                    color: _Dt.brandPurpleLight,
                    borderRadius: pw.BorderRadius.circular(3),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      '${entry.key + 1}',
                      style: pw.TextStyle(
                        font: fonts.bold,
                        fontSize: _Dt.tsMicro,
                        color: _Dt.brandPurple,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                ),
                pw.Expanded(
                  child: pw.RichText(
                    text: pw.TextSpan(
                      children: [
                        pw.TextSpan(
                          text: '$title: ',
                          style: pw.TextStyle(
                            font: fonts.bold,
                            fontSize: _Dt.tsCaption,
                            color: _Dt.inkDark,
                          ),
                        ),
                        pw.TextSpan(
                          text: body,
                          style: pw.TextStyle(
                            font: fonts.regular,
                            fontSize: _Dt.tsCaption,
                            color: _Dt.inkMid,
                            lineSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (!isLast) ...[
              pw.SizedBox(height: _Dt.sp1),
              pw.Divider(color: _Dt.surfaceBorder, thickness: 0.5),
              pw.SizedBox(height: _Dt.sp1),
            ],
          ],
        );
      }).toList(),
    ),
  );
}

/// Call-to-action onboarding steps box at the end of proposal
pw.Widget buildNextStepsActionPanel({required PdfFontSet fonts}) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(16),
    decoration: pw.BoxDecoration(
      color: _Dt.surfaceNeutral,
      border: pw.Border.all(color: _Dt.surfaceBorder, width: 0.5),
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'NEXT STEPS',
          style: pw.TextStyle(
            font: fonts.bold,
            fontSize: _Dt.tsCaption,
            color: _Dt.inkDark,
            letterSpacing: 1,
          ),
        ),
        pw.SizedBox(height: _Dt.sp1),
        pw.Text(
          '1. Let us know if you want to move forward — reach out to your point of contact at ${AgencyConfig.agencyName}.\n2. Pay the 50% advance to confirm your booking and lock in the creators and dates.\n3. Once payment is confirmed, we will share a brief and get the campaign started.',
          style: pw.TextStyle(
            font: fonts.regular,
            fontSize: _Dt.tsMicro + 0.5,
            color: _Dt.inkMid,
            lineSpacing: 1.5,
          ),
        ),
      ],
    ),
  );
}
