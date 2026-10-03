import '../../models/campaign_model.dart';
import '../../models/client_model.dart';
import '../../models/lead_model.dart';
import '../../models/project_model.dart';
import '../../models/proposal_model.dart';
import '../../providers/creator_provider.dart';
import 'pdf_invoice_builder.dart';
import 'pdf_proposal_builder.dart';

class PdfService {
  /// Generates a pitch PDF for a proposal.
  static Future<void> generatePitchPdf(
    Proposal proposal,
    Lead lead,
    CreatorProvider creatorProvider,
  ) => PdfProposalBuilder.generatePitchPdf(proposal, lead, creatorProvider);

  /// Generates a tax invoice PDF for a project.
  static Future<void> generateInvoicePdf(
    Project project,
    Client client,
    List<Campaign> campaigns,
  ) => PdfInvoiceBuilder.generateInvoicePdf(project, client, campaigns);
}
