import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../config/agency_config.dart';
import '../../config/proposal_templates.dart';
import '../../domain/app_enums.dart';
import '../../models/creator_model.dart';
import '../../models/lead_model.dart';
import '../../models/proposal_model.dart';
import '../../providers/creator_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────
class _Dt {
  static const PdfColor brandPurple = PdfColor.fromInt(0xFF6C3FC5);
  static const PdfColor brandPurpleDark = PdfColor.fromInt(0xFF4B1FA8);
  static const PdfColor brandPurpleSubtle = PdfColor.fromInt(0xFF8B5CF6);
  static const PdfColor brandPurpleLight = PdfColor.fromInt(0xFFF0E9FF);
  static const PdfColor brandPurpleMid = PdfColor.fromInt(0xFFD6C5F5);

  static const PdfColor ugcAccent = PdfColor.fromInt(0xFF2563EB);
  static const PdfColor ugcAccentLight = PdfColor.fromInt(0xFFEFF6FF);
  static const PdfColor influencerAccent = PdfColor.fromInt(0xFF7C3AED);
  static const PdfColor influencerAccentLight = PdfColor.fromInt(0xFFF5F3FF);
  static const PdfColor localAccent = PdfColor.fromInt(0xFFD97706);
  static const PdfColor localAccentLight = PdfColor.fromInt(0xFFFFFBEB);

  static const PdfColor inkDark = PdfColor.fromInt(0xFF0F0A1E);
  static const PdfColor inkDeep = PdfColor.fromInt(0xFF1C1035);
  static const PdfColor inkMid = PdfColor.fromInt(0xFF374151);
  static const PdfColor inkMuted = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor inkGhost = PdfColor.fromInt(0xFF9CA3AF);

  static const PdfColor surfaceWhite = PdfColors.white;
  static const PdfColor surfaceNeutral = PdfColor.fromInt(0xFFF9FAFB);
  static const PdfColor surfaceBorder = PdfColor.fromInt(0xFFE5E7EB);
  static const PdfColor successGreen = PdfColor.fromInt(0xFF059669);

  static const double spHalf = 3.0;
  static const double sp1 = 6.0;
  static const double sp2 = 12.0;
  static const double sp3 = 18.0;
  static const double sp4 = 24.0;
  static const double sp5 = 36.0;
  static const double sp6 = 48.0;

  static const double tsDisplay = 28.0;
  static const double tsH2 = 15.0;
  static const double tsH3 = 11.5;
  static const double tsBody = 9.5;
  static const double tsCaption = 8.5;
  static const double tsMicro = 7.5;
}

class _FontSet {
  final pw.Font regular;
  final pw.Font medium;
  final pw.Font semiBold;
  final pw.Font bold;

  const _FontSet({
    required this.regular,
    required this.medium,
    required this.semiBold,
    required this.bold,
  });
}

class _CreatorCardData {
  final ProposedCreator proposed;
  final Creator original;
  final List<PitchAddOn> linkedAddOns;

  const _CreatorCardData({
    required this.proposed,
    required this.original,
    required this.linkedAddOns,
  });
}

class _KpiData {
  final String value;
  final String label;
  final PdfColor color;

  const _KpiData({
    required this.value,
    required this.label,
    required this.color,
  });
}

class PdfProposalBuilder {
  static _FontSet _fonts() => _FontSet(
    regular: pw.Font.helvetica(),
    medium: pw.Font.helvetica(),
    semiBold: pw.Font.helveticaBold(),
    bold: pw.Font.helveticaBold(),
  );

  static String _getFriendlyDeliverableName(
    DeliverableType type,
    int quantity,
  ) {
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
      return _CreatorCardData(
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
        build: (_) => _buildCoverPage(
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
        header: (_) => _buildRunningHeader(fonts: fonts, lead: lead),
        footer: (ctx) =>
            _buildRunningFooter(context: ctx, fonts: fonts, dateStr: dateStr),
        build: (_) => [
          _buildSectionLabel(
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
                child: _buildCreatorCard(
                  data: e.value,
                  index: e.key,
                  fonts: fonts,
                ),
              ),
            ),

          pw.SizedBox(height: _Dt.sp5),
          _buildSectionLabel(
            'SECTION 02',
            'WHAT YOU ARE GETTING',
            fonts: fonts,
          ),
          pw.SizedBox(height: _Dt.sp2),
          _buildMetricsDashboard(
            fonts: fonts,
            lead: lead,
            proposal: proposal,
            cardDataList: cardDataList,
          ),

          pw.NewPage(),

          _buildSectionLabel('SECTION 03', 'PRICING SUMMARY', fonts: fonts),
          pw.SizedBox(height: _Dt.sp3),
          _buildPricingSection(fonts: fonts, proposal: proposal, fmt: fmt),
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

          _buildSectionLabel('SECTION 04', 'TERMS & CONDITIONS', fonts: fonts),
          pw.SizedBox(height: _Dt.sp3),
          _buildGuidelinesPanel(
            fonts: fonts,
            cardDataList: cardDataList,
            lead: lead,
            proposal: proposal,
          ),
          pw.SizedBox(height: _Dt.sp3),
          _buildNextStepsActionPanel(fonts: fonts),
          pw.SizedBox(height: _Dt.sp3),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) async => doc.save(),
      name: 'Proposal_${lead.businessName.replaceAll(' ', '_')}_$dateStr.pdf',
    );
  }

  static pw.Widget _buildCoverPage({
    required _FontSet fonts,
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

  static pw.Widget _buildRunningHeader({
    required _FontSet fonts,
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

  static pw.Widget _buildRunningFooter({
    required pw.Context context,
    required _FontSet fonts,
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

  static pw.Widget _buildSectionLabel(
    String number,
    String title, {
    required _FontSet fonts,
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

  static pw.Widget _buildCreatorCard({
    required _CreatorCardData data,
    required int index,
    required _FontSet fonts,
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
          (d) =>
              '${d.quantity}x ${_getFriendlyDeliverableName(d.type, d.quantity)}',
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

  static pw.Widget _buildMetricsDashboard({
    required _FontSet fonts,
    required Lead lead,
    required Proposal proposal,
    required List<_CreatorCardData> cardDataList,
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

    final List<_KpiData> dynamicKpis = [];
    if (proposal.proposalType == ProposalType.ugcProduction) {
      dynamicKpis.addAll([
        _KpiData(
          value: '${cardDataList.length}',
          label: 'Content Creators',
          color: _Dt.brandPurple,
        ),
        _KpiData(
          value: '${totalReels + totalVideos}',
          label: 'Videos',
          color: _Dt.brandPurple,
        ),
        _KpiData(
          value: '$totalPosts',
          label: 'Photos / Posts',
          color: _Dt.brandPurple,
        ),
        const _KpiData(
          value: '~3 Weeks',
          label: 'Turnaround Time',
          color: _Dt.successGreen,
        ),
      ]);
    } else {
      dynamicKpis.addAll([
        _KpiData(
          value: '${cardDataList.length}',
          label: 'Creators',
          color: _Dt.brandPurple,
        ),
        _KpiData(value: '$totalReels', label: 'Reels', color: _Dt.brandPurple),
        _KpiData(
          value: '$totalStories',
          label: 'Stories',
          color: _Dt.brandPurple,
        ),
        const _KpiData(
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
              children: _buildKpiRow(kpis: dynamicKpis, fonts: fonts),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildGuidelinesPanel({
    required _FontSet fonts,
    required List<_CreatorCardData> cardDataList,
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

  static pw.Widget _buildNextStepsActionPanel({required _FontSet fonts}) {
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

  static pw.Widget _buildPricingSection({
    required _FontSet fonts,
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
          _buildSummaryRow(
            label: 'Campaign Fee',
            value: 'Rs. ${fmt.format(campaignCost)}',
            fonts: fonts,
          ),
          if (additionalCosts > 0)
            _buildSummaryRow(
              label: 'Additional Services (Logistics, On-location, etc.)',
              value: 'Rs. ${fmt.format(additionalCosts)}',
              fonts: fonts,
            ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
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

  static pw.Widget _buildSummaryRow({
    required String label,
    required String value,
    required _FontSet fonts,
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

  static List<pw.Widget> _buildKpiRow({
    required List<_KpiData> kpis,
    required _FontSet fonts,
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
}
