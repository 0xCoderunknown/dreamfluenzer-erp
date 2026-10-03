import '../domain/app_enums.dart';

class ProposalTextBlueprintManager {
  static const String defaultUsageRights = '30 Days (Social Media)';
  static const String defaultExclusivity = '14 Days (Same Category)';

  static String getPlanSubtitle(ProposalType type) {
    switch (type) {
      case ProposalType.ugcProduction:
        return 'Content Creation Plan';
      case ProposalType.d2cPromotion:
        return 'Product Promotion Plan';
      case ProposalType.localVisibility:
        return 'Local Visibility Plan';
    }
  }

  static String getDefaultObjectiveText(String businessName) {
    return 'This proposal is prepared for $businessName. We will work with selected creators who will visit your location, create content, and post it in a planned schedule — keeping your business visible to the right audience over the coming weeks.';
  }

  static String getDeploymentMethodology(
    ProposalType type,
    String businessName,
  ) {
    switch (type) {
      case ProposalType.ugcProduction:
        return 'We will produce ready-to-use video and photo content for $businessName — optimised for your ads, social media pages, and online store. You own the content and can reuse it anytime.';
      case ProposalType.d2cPromotion:
        return 'Creators will promote your products to their audience online. This brings your brand in front of new customers who are likely to buy — driving both awareness and sales.';
      case ProposalType.localVisibility:
        return 'Creators will post about $businessName on a planned schedule, spaced out across multiple weeks. This keeps your business visible to local customers consistently — not just for a day or two.';
    }
  }

  static List<String> getMandatoryGuidelines(ProposalType type) {
    return [
      'Advance Payment: A 50% advance payment is required before we book the creators and begin work. The campaign will start once the payment is confirmed.',
      'Revisions: Each creator\'s content includes one round of revisions. Please send your feedback within 48 hours of receiving the draft.',
      'Creator Booking: Creators are booked only after the advance payment is received. If a creator becomes unavailable, we will replace them with someone of equal reach at no extra cost.',
      'Schedule Changes: Any changes to shoot dates or posting dates must be requested at least 3 working days in advance.',
      'Final Payment: The remaining amount is due within 7 days of campaign completion.',
      if (type == ProposalType.ugcProduction)
        'Content Rights: You have full rights to use this content in your ads and pages for 30 to 60 days. After that, we recommend refreshing with new content to keep performance strong.'
      else
        'Post Duration: All creator posts will remain live on their profile for at least 30 days after going live.',
    ];
  }
}
