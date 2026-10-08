import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Design tokens and palette for all exported PDF documents (proposals & invoices).
class PdfTheme {
  // Brand Palette
  static const PdfColor brandPurple = PdfColor.fromInt(0xFF6C3FC5);
  static const PdfColor brandPurpleDark = PdfColor.fromInt(0xFF4B1FA8);
  static const PdfColor brandPurpleSubtle = PdfColor.fromInt(0xFF8B5CF6);
  static const PdfColor brandPurpleLight = PdfColor.fromInt(0xFFF0E9FF);
  static const PdfColor brandPurpleMid = PdfColor.fromInt(0xFFD6C5F5);

  // Category Accents
  static const PdfColor ugcAccent = PdfColor.fromInt(0xFF2563EB);
  static const PdfColor ugcAccentLight = PdfColor.fromInt(0xFFEFF6FF);
  static const PdfColor influencerAccent = PdfColor.fromInt(0xFF7C3AED);
  static const PdfColor influencerAccentLight = PdfColor.fromInt(0xFFF5F3FF);
  static const PdfColor localAccent = PdfColor.fromInt(0xFFD97706);
  static const PdfColor localAccentLight = PdfColor.fromInt(0xFFFFFBEB);

  // Inks & Typography Neutral Shades
  static const PdfColor inkDark = PdfColor.fromInt(0xFF0F0A1E);
  static const PdfColor inkDeep = PdfColor.fromInt(0xFF1C1035);
  static const PdfColor inkMid = PdfColor.fromInt(0xFF374151);
  static const PdfColor inkMuted = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor inkGhost = PdfColor.fromInt(0xFF9CA3AF);

  // Surfaces & Borders
  static const PdfColor surfaceWhite = PdfColors.white;
  static const PdfColor surfaceNeutral = PdfColor.fromInt(0xFFF9FAFB);
  static const PdfColor surfaceNeutralDeep = PdfColor.fromInt(0xFFF3F4F6);
  static const PdfColor surfaceBorder = PdfColor.fromInt(0xFFE5E7EB);

  // Feedback & Success Colors
  static const PdfColor successGreen = PdfColor.fromInt(0xFF059669);
  static const PdfColor successGreenLight = PdfColor.fromInt(0xFFECFDF5);

  // Spacing & Margins
  static const double spHalf = 3.0;
  static const double sp1 = 6.0;
  static const double sp2 = 12.0;
  static const double sp3 = 18.0;
  static const double sp4 = 24.0;
  static const double sp5 = 36.0;
  static const double sp6 = 48.0;

  // Typography Scales
  static const double tsDisplay = 28.0;
  static const double tsH1 = 20.0;
  static const double tsH2 = 15.0;
  static const double tsH3 = 11.5;
  static const double tsBody = 9.5;
  static const double tsCaption = 8.5;
  static const double tsMicro = 7.5;
}

/// Typography font bundle for PDF generators.
class PdfFontSet {
  final pw.Font regular;
  final pw.Font medium;
  final pw.Font semiBold;
  final pw.Font bold;

  const PdfFontSet({
    required this.regular,
    required this.medium,
    required this.semiBold,
    required this.bold,
  });

  factory PdfFontSet.helvetica() => PdfFontSet(
    regular: pw.Font.helvetica(),
    medium: pw.Font.helvetica(),
    semiBold: pw.Font.helveticaBold(),
    bold: pw.Font.helveticaBold(),
  );
}
