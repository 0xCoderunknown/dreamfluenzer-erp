import 'package:dreamfluenzer_erp/domain/app_enums.dart';
import 'package:dreamfluenzer_erp/models/campaign_model.dart';
import 'package:dreamfluenzer_erp/models/client_model.dart';
import 'package:dreamfluenzer_erp/models/creator_model.dart';
import 'package:dreamfluenzer_erp/models/lead_model.dart';
import 'package:dreamfluenzer_erp/models/log_event_model.dart';
import 'package:dreamfluenzer_erp/models/project_model.dart';
import 'package:dreamfluenzer_erp/models/proposal_model.dart';

/// Centralized Mock Factory for fast, token-efficient testing.
/// Provides default dummy instances so AI maintainers can write tests in 1-2 lines.
class MockFactory {
  static Project dummyProject({
    String id = 'proj-123',
    String clientId = 'client-456',
    String projectName = 'Acme Summer Campaign',
    String leadName = 'Acme Lead',
    DealType dealType = DealType.cash,
    ProjectStatus status = ProjectStatus.active,
    DateTime? deadline,
    BillingModel billingModel = BillingModel.oneOff,
    int durationMonths = 1,
    double baseBudget = 50000.0,
    double gmvBudget = 0.0,
    bool isGstExclusive = true,
    double advanceReceived = 20000.0,
    DateTime? createdAt,
  }) {
    return Project(
      id: id,
      clientId: clientId,
      projectName: projectName,
      leadName: leadName,
      dealType: dealType,
      status: status,
      deadline: deadline ?? DateTime(2026, 12, 31),
      billingModel: billingModel,
      durationMonths: durationMonths,
      baseBudget: baseBudget,
      gmvBudget: gmvBudget,
      isGstExclusive: isGstExclusive,
      advanceReceived: advanceReceived,
      createdAt: createdAt ?? DateTime(2026, 1, 1),
    );
  }

  static CampaignInventory dummyInventory({
    String id = 'inv-1',
    String itemName = 'Lipstick Kit',
    int totalQuantity = 50,
    double gmvPerUnit = 1200.0,
    bool isReturnable = false,
    InventoryStatus status = InventoryStatus.waitingOnBrand,
  }) {
    return CampaignInventory(
      id: id,
      itemName: itemName,
      totalQuantity: totalQuantity,
      gmvPerUnit: gmvPerUnit,
      isReturnable: isReturnable,
      status: status,
    );
  }

  static AllocatedItem dummyAllocatedItem({
    String inventoryId = 'inv-1',
    String itemName = 'Lipstick Kit',
    int quantity = 2,
    AllocationStatus status = AllocationStatus.pending,
    String notes = 'Genie #1234',
  }) {
    return AllocatedItem(
      inventoryId: inventoryId,
      itemName: itemName,
      quantity: quantity,
      status: status,
      notes: notes,
    );
  }

  static AssignedCreator dummyAssignedCreator({
    String creatorId = 'creator-1',
    String creatorName = 'Jane Doe',
    DateTime? individualDeadline,
    double agreedPayout = 15000.0,
    PipelineStatus pipelineStatus = PipelineStatus.draftRequested,
    bool isPaid = false,
    List<Deliverable>? deliverables,
    double advancePaid = 5000.0,
    List<AllocatedItem>? allocatedItems,
  }) {
    return AssignedCreator(
      creatorId: creatorId,
      creatorName: creatorName,
      individualDeadline: individualDeadline ?? DateTime(2026, 11, 1),
      agreedPayout: agreedPayout,
      pipelineStatus: pipelineStatus,
      isPaid: isPaid,
      deliverables:
          deliverables ??
          const [Deliverable(type: DeliverableType.reel, quantity: 1)],
      advancePaid: advancePaid,
      allocatedItems: allocatedItems ?? [dummyAllocatedItem()],
    );
  }

  static Campaign dummyCampaign({
    String id = 'camp-1',
    String projectId = 'proj-123',
    String title = 'Diwali Influencer Blast',
    DateTime? cycleEndDate,
    double expenses = 500.0,
    List<CampaignInventory>? inventoryPool,
    List<AssignedCreator>? assignedCreators,
  }) {
    return Campaign(
      id: id,
      projectId: projectId,
      title: title,
      cycleEndDate: cycleEndDate ?? DateTime(2026, 11, 15),
      expenses: expenses,
      inventoryPool: inventoryPool ?? [dummyInventory()],
      assignedCreators: assignedCreators ?? [dummyAssignedCreator()],
    );
  }

  static Creator dummyCreator({
    String id = 'creator-1',
    String fullName = 'Ananya Sharma',
    String handle = 'ananya_vlogs',
    String phoneNumber = '9876543210',
    CreatorStatus status = CreatorStatus.active,
    CreatorType type = CreatorType.influencer,
    PrimaryCategory primaryCategory = PrimaryCategory.clothing,
    String secondaryNiche = 'Travel',
    double baseRate = 25000.0,
    int followerCount = 150000,
    String upiId = 'ananya@upi',
    String location = 'Mumbai',
    String notes = 'Reliable turnaround',
    double rating = 4.8,
    int strikeLevel = 0,
  }) {
    return Creator(
      id: id,
      fullName: fullName,
      handle: handle,
      phoneNumber: phoneNumber,
      status: status,
      type: type,
      primaryCategory: primaryCategory,
      secondaryNiche: secondaryNiche,
      baseRate: baseRate,
      followerCount: followerCount,
      upiId: upiId,
      location: location,
      notes: notes,
      rating: rating,
      strikeLevel: strikeLevel,
    );
  }

  static Client dummyClient({
    String id = 'client-1',
    String businessName = 'Nykaa Fashion',
    String industryType = 'E-commerce',
    String contactName = 'Rahul Verma',
    String contactPhone = '9998887776',
    String email = 'rahul@nykaa.com',
    String instaHandle = 'nykaafashion',
    String location = 'Gurugram',
    ClientTier tier = ClientTier.tier1,
    String notes = 'Key account',
  }) {
    return Client(
      id: id,
      businessName: businessName,
      industryType: industryType,
      contactName: contactName,
      contactPhone: contactPhone,
      email: email,
      instaHandle: instaHandle,
      location: location,
      tier: tier,
      notes: notes,
    );
  }

  static Lead dummyLead({
    String id = 'lead-1',
    String businessName = 'Mamaearth',
    String contactPerson = 'Pooja Hegde',
    String phone = '9123456780',
    double estimatedBudget = 200000.0,
    LeadStatus status = LeadStatus.pitched,
    PrimaryCategory primaryCategory = PrimaryCategory.skincare,
    String notes = 'Q4 campaign interest',
  }) {
    return Lead(
      id: id,
      businessName: businessName,
      contactPerson: contactPerson,
      phone: phone,
      estimatedBudget: estimatedBudget,
      status: status,
      primaryCategory: primaryCategory,
      notes: notes,
    );
  }

  static Proposal dummyProposal({
    String id = 'prop-1',
    String leadId = 'lead-1',
    ProposalType proposalType = ProposalType.localVisibility,
    double agencyFee = 15000.0,
    ProposalStatus status = ProposalStatus.draft,
    DateTime? createdAt,
    String internalNotes = 'Targeting 2M impressions',
    List<ProposedCreator>? creators,
    List<PitchAddOn>? addOns,
  }) {
    return Proposal(
      id: id,
      leadId: leadId,
      proposalType: proposalType,
      agencyFee: agencyFee,
      status: status,
      createdAt: createdAt ?? DateTime(2026, 10, 1),
      internalNotes: internalNotes,
      creators:
          creators ??
          [
            const ProposedCreator(
              creatorId: 'creator-1',
              name: 'Ananya Sharma',
              baseRate: 25000.0,
              proposedAdvance: 10000.0,
              deliverables: [
                Deliverable(type: DeliverableType.reel, quantity: 2),
              ],
            ),
          ],
      addOns:
          addOns ??
          [
            const PitchAddOn(
              id: 'addon-1',
              creatorId: 'creator-1',
              description: 'Whitelisting Ads Rights',
              price: 5000.0,
            ),
          ],
    );
  }

  static LogEvent dummyLogEvent({
    String id = 'log-1',
    LogType type = LogType.finance,
    String action = 'Advance Released',
    String note = 'Released INR 5,000 to creator-1',
    DateTime? timestamp,
    String actor = 'Admin',
    double? amount = 5000.0,
    String? reason = 'Production expenses',
  }) {
    return LogEvent(
      id: id,
      type: type,
      action: action,
      note: note,
      timestamp: timestamp ?? DateTime(2026, 10, 5),
      actor: actor,
      amount: amount,
      reason: reason,
    );
  }
}
