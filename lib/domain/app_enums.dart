/// A global extension to handle safe string-to-enum parsing.
/// Hardened to handle case-insensitivity and both Name/Value matching.
extension EnumParser<T extends Enum> on Iterable<T> {
  T fromString(String? val, {required T fallback}) {
    if (val == null || val.trim().isEmpty) return fallback;
    final search = val.trim().toLowerCase();

    return firstWhere((e) {
      if (e.name.toLowerCase() == search) return true;
      try {
        final displayVal = (e as dynamic).value.toString().toLowerCase();
        return displayVal == search;
      } catch (_) {
        return false;
      }
    }, orElse: () => fallback);
  }
}

// ===========================================================================
// 1. LEAD & PROPOSAL (The Top of the Funnel)
// ===========================================================================

enum LeadStatus {
  identified('Identified'),
  pitched('Pitched'),
  negotiating('Negotiating'),
  won('Won'),
  lost('Lost');

  final String value;

  const LeadStatus(this.value);

  static LeadStatus fromString(String val) =>
      LeadStatus.values.fromString(val, fallback: LeadStatus.identified);
}

enum ProposalStatus {
  draft('Draft'),
  sent('Sent'),
  accepted('Accepted'),
  rejected('Rejected');

  final String value;

  const ProposalStatus(this.value);

  static ProposalStatus fromString(String val) =>
      ProposalStatus.values.fromString(val, fallback: ProposalStatus.draft);
}

enum ProposalType {
  localVisibility('Local Visibility'),
  d2cPromotion('D2C Promotion'),
  ugcProduction('UGC Production');

  final String value;

  const ProposalType(this.value);

  static ProposalType fromString(String val) => ProposalType.values.fromString(
    val,
    fallback: ProposalType.localVisibility,
  );
}

// ===========================================================================
// 2. PROJECT & CAMPAIGN (The Operational Core)
// ===========================================================================

enum ProjectStatus {
  active('Active'),
  completed('Completed'),
  archived('Archived'),
  dropped('Dropped');

  final String value;

  const ProjectStatus(this.value);

  static ProjectStatus fromString(String val) =>
      ProjectStatus.values.fromString(val, fallback: ProjectStatus.active);
}

enum PipelineStatus {
  draftRequested('Draft Requested'),
  reviewing('Reviewing'),
  changesRequested('Changes Requested'),
  approvedByAgency('Approved by Agency'),
  awaitingClientSignoff('Awaiting Client Sign-off'),
  postedLive('Posted Live'),
  dropped('Dropped');

  final String value;

  const PipelineStatus(this.value);

  static PipelineStatus fromString(String val) => PipelineStatus.values
      .fromString(val, fallback: PipelineStatus.draftRequested);
}

// ===========================================================================
// 3. creator (The Roster Management)
// ===========================================================================

enum CreatorStatus {
  active('Active'),
  trial('Trial'),
  inactive('Inactive');

  final String value;

  const CreatorStatus(this.value);

  static CreatorStatus fromString(String val) =>
      CreatorStatus.values.fromString(val, fallback: CreatorStatus.trial);
}

enum CreatorType {
  influencer('Influencer'),
  ugcCreator('Professional UGC'),
  sandboxTrainee('Trainee');

  final String value;

  const CreatorType(this.value);

  static CreatorType fromString(String val) =>
      CreatorType.values.fromString(val, fallback: CreatorType.influencer);
}

enum PrimaryCategory {
  clothing('Apparel / Clothing'),
  skincare('Skincare / Wellness'),
  food('Food / F&B'),
  tech('Tech / Digital'),
  generalUgc('General UGC Content');

  final String value;

  const PrimaryCategory(this.value);

  static PrimaryCategory fromString(String val) => PrimaryCategory.values
      .fromString(val, fallback: PrimaryCategory.generalUgc);
}

// ===========================================================================
// 4. FINANCE & DEALS (The Ledger)
// ===========================================================================

enum DealType {
  cash('Cash'),
  barter('Barter'),
  hybrid('Hybrid'),
  prGift('PR/Gift');

  final String value;

  const DealType(this.value);

  static DealType fromString(String val) =>
      DealType.values.fromString(val, fallback: DealType.cash);
}

enum BillingModel {
  oneOff('One-Off'),
  retainer('Retainer');

  final String value;

  const BillingModel(this.value);

  static BillingModel fromString(String val) =>
      BillingModel.values.fromString(val, fallback: BillingModel.oneOff);
}

// ===========================================================================
// 5. SYSTEM & CLIENTS (The Infrastructure)
// ===========================================================================

enum ClientTier {
  tier1('Tier 1'),
  tier2('Tier 2'),
  tier3('Tier 3');

  final String value;

  const ClientTier(this.value);

  static ClientTier fromString(String val) =>
      ClientTier.values.fromString(val, fallback: ClientTier.tier3);
}

enum LogType {
  project('Project'),
  creator('creator'),
  finance('Finance'),
  logistics('Logistics'),
  lead('Lead'),
  system('System');

  final String value;

  const LogType(this.value);

  static LogType fromString(String val) =>
      LogType.values.fromString(val, fallback: LogType.system);
}

// ===========================================================================
// 6. DELIVERABLES (The Output Engine)
// ===========================================================================

enum DeliverableType {
  reel('Reel'),
  post('Post'),
  story('Story'),
  video('Video');

  final String value;

  const DeliverableType(this.value);

  static DeliverableType fromString(String val) =>
      DeliverableType.values.fromString(val, fallback: DeliverableType.reel);
}

// ===========================================================================
// 7. INVENTORY & LOGISTICS (The Supply Chain)
// ===========================================================================

// TODO: [Roadmap Scaffolding] Planned for Warehouse Stock Tracking & Logistics Module.
enum InventoryStatus {
  waitingOnBrand('Waiting on Brand'),
  receivedAtHQ('Received at Office');

  final String value;

  const InventoryStatus(this.value);

  static InventoryStatus fromString(String val) => InventoryStatus.values
      .fromString(val, fallback: InventoryStatus.waitingOnBrand);
}

enum AllocationStatus {
  pending('Pending Dispatch'),
  shipped('Shipped / In Transit'),
  received('With Creator'),
  returned('Returned to Office');

  final String value;

  const AllocationStatus(this.value);

  static AllocationStatus fromString(String val) => AllocationStatus.values
      .fromString(val, fallback: AllocationStatus.pending);
}
