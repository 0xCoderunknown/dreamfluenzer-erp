import '../config/rule_messages.dart';
import '../domain/app_enums.dart';
import '../models/campaign_model.dart';
import '../models/project_model.dart';

/// Standardized result for all Agency Rule validations.
class RuleResult {
  final bool isValid;
  final String message;

  const RuleResult(this.isValid, this.message);

  factory RuleResult.pass() => const RuleResult(true, '');

  factory RuleResult.fail(String msg) => RuleResult(false, msg);
}

class FroyoRules {
  // ===========================================================================
  // 1. THE ARCHIVE AUDITOR (Project Closure)
  // ===========================================================================

  /// Scans the project to ensure no deliverables or payments are pending.
  /// A project cannot be archived if work is still "in flight."
  static RuleResult canArchiveProject(
    Project project,
    List<Campaign> campaigns,
  ) {
    if (campaigns.isEmpty) {
      return RuleResult.fail(RuleMessages.noProjectCampaigns);
    }

    for (var camp in campaigns) {
      // Rule: Every campaign must have had at least one creator assigned
      if (camp.assignedCreators.isEmpty) {
        return RuleResult.fail(RuleMessages.campaignHasNoCreator(camp.title));
      }

      for (var creator in camp.assignedCreators) {
        final status = creator.pipelineStatus;

        // Terminal States: Work is finished or officially stopped.
        final isTerminal = [
          PipelineStatus.postedLive,
          PipelineStatus.dropped,
        ].contains(status);

        if (!isTerminal) {
          return RuleResult.fail(
            RuleMessages.creatorWorkInProgress(
              creator.creatorName,
              status.value,
            ),
          );
        }

        // Financial Closure: If the content went live, the creator must be paid.
        final wasSuccessful = status == PipelineStatus.postedLive;

        if (wasSuccessful && !creator.isPaid) {
          return RuleResult.fail(
            RuleMessages.creatorUnpaidAfterPosting(
              creator.creatorName,
              status.value,
            ),
          );
        }
      }
    }

    return RuleResult.pass();
  }

  // ===========================================================================
  // 2. THE ADVANCE SAFETY NET (Cash Flow Management)
  // ===========================================================================

  /// Prevents the agency from paying out more than the client has advanced.
  /// This is critical for protecting the agency's personal liquidity.
  static RuleResult validateAdvancePayment({
    required double requestedAdvance,
    required double agreedPayout,
    required double projectAdvanceReceived,
    required double otherCreatorsTotalAdvance,
  }) {
    // Check 1: Individual Payout Cap
    if (requestedAdvance > agreedPayout) {
      return RuleResult.fail(RuleMessages.advanceExceedsPayout(agreedPayout));
    }

    // Check 2: Agency Cash Flow Cap
    final agencyBalance = projectAdvanceReceived - otherCreatorsTotalAdvance;

    if (requestedAdvance > agencyBalance) {
      final maxAvailable = agencyBalance < 0 ? 0.0 : agencyBalance;
      return RuleResult.fail(
        RuleMessages.insufficientClientFunds(maxAvailable),
      );
    }

    return RuleResult.pass();
  }
}
