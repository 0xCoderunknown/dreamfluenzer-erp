/// Single source of truth for all business-rule validation messages.
///
/// These strings are returned by [FroyoRules] when a rule check fails.
/// They surface in dialogs, snackbars, and alert prompts across the app.
/// Any copy change to a rule failure message should be made here only.
class RuleMessages {
  RuleMessages._();

  // ===========================================================================
  // Project Archive Rules
  // ===========================================================================

  /// Shown when a project has zero campaigns and cannot be archived.
  static const String noProjectCampaigns =
      'Cannot complete a project with no campaigns. Add at least one campaign first.';

  /// Template: Shown when a specific campaign has no creator assigned.
  /// Usage: [campaignHasNoCreator('Campaign Name')]
  static String campaignHasNoCreator(String campaignTitle) =>
      'Campaign "$campaignTitle" has no creator assigned. Assign one before completing.';

  /// Template: Shown when a creator is still mid-workflow.
  /// Usage: [creatorWorkInProgress('Rahul', 'Reviewing')]
  static String creatorWorkInProgress(String creatorName, String status) =>
      '$creatorName is still "$status". Finish or drop their work before completing the project.';

  /// Template: Shown when a creator went live but hasn't been marked as paid.
  /// Usage: [creatorUnpaidAfterPosting('Rahul', 'Posted Live')]
  static String creatorUnpaidAfterPosting(String creatorName, String status) =>
      '$creatorName is marked "$status" but hasn\'t been marked as Fully Paid.';

  // ===========================================================================
  // Advance Payment Rules
  // ===========================================================================

  /// Shown when the requested advance exceeds the agreed payout for that creator.
  static String advanceExceedsPayout(double agreedPayout) =>
      'Advance cannot exceed the total agreed payout (₹$agreedPayout).';

  /// Shown when the agency doesn't have enough client advance to cover the payment.
  static String insufficientClientFunds(double maxAvailable) =>
      'Not enough client advance to cover this. Max you can pay right now: ₹${maxAvailable.toStringAsFixed(0)}.';

  // ===========================================================================
  // Project Creation / Wizard
  // ===========================================================================

  /// Shown when the user tries to proceed without selecting an existing client.
  static const String noClientSelected = 'Please select a client to continue.';
}
