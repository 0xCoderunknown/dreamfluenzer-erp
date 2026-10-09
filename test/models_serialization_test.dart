import 'package:flutter_test/flutter_test.dart';
import 'package:dreamfluenzer_erp/domain/app_enums.dart';
import 'package:dreamfluenzer_erp/models/campaign_model.dart';
import 'package:dreamfluenzer_erp/models/client_model.dart';
import 'package:dreamfluenzer_erp/models/creator_model.dart';
import 'package:dreamfluenzer_erp/models/lead_model.dart';
import 'package:dreamfluenzer_erp/models/log_event_model.dart';
import 'package:dreamfluenzer_erp/models/project_model.dart';
import 'package:dreamfluenzer_erp/models/proposal_model.dart';

import 'fixtures/mock_factory.dart';

void main() {
  group('Model Serialization & Roundtrip Contract Tests', () {
    test('Project fromMap / toMap roundtrip preserves data integrity', () {
      final original = MockFactory.dummyProject(
        id: 'proj-999',
        projectName: 'Festive Mega Blast',
        dealType: DealType.hybrid,
        billingModel: BillingModel.retainer,
        durationMonths: 6,
        baseBudget: 150000.0,
        gmvBudget: 35000.0,
        isGstExclusive: true,
        advanceReceived: 50000.0,
      );

      final map = original.toMap();
      final reconstructed = Project.fromMap(map, id: original.id);

      expect(reconstructed.id, equals(original.id));
      expect(reconstructed.projectName, equals(original.projectName));
      expect(reconstructed.dealType, equals(original.dealType));
      expect(reconstructed.billingModel, equals(original.billingModel));
      expect(reconstructed.durationMonths, equals(original.durationMonths));
      expect(reconstructed.baseBudget, equals(original.baseBudget));
      expect(reconstructed.gmvBudget, equals(original.gmvBudget));
      expect(reconstructed.isGstExclusive, equals(original.isGstExclusive));
      expect(reconstructed.advanceReceived, equals(original.advanceReceived));
      expect(reconstructed.totalContractValue, equals(150000.0 * 6));
    });

    test('Campaign & Nested Creator / Inventory fromMap / toMap roundtrip', () {
      final original = MockFactory.dummyCampaign(
        id: 'camp-888',
        title: 'Influencer Seeding',
      );

      final map = original.toMap();
      final reconstructed = Campaign.fromMap(map, id: original.id);

      expect(reconstructed.id, equals(original.id));
      expect(reconstructed.title, equals(original.title));
      expect(reconstructed.expenses, equals(original.expenses));
      expect(reconstructed.inventoryPool.length, equals(1));
      expect(
        reconstructed.inventoryPool.first.itemName,
        equals('Lipstick Kit'),
      );
      expect(reconstructed.assignedCreators.length, equals(1));
      expect(
        reconstructed.assignedCreators.first.creatorName,
        equals('Jane Doe'),
      );
      expect(
        reconstructed.assignedCreators.first.allocatedItems.length,
        equals(1),
      );
    });

    test(
      'Creator fromMap / toMap roundtrip preserves all operational fields',
      () {
        final original = MockFactory.dummyCreator(
          id: 'creator-777',
          fullName: 'Rohan Mehra',
          handle: 'rohan_travels',
          status: CreatorStatus.active,
          type: CreatorType.influencer,
          primaryCategory: PrimaryCategory.tech,
          secondaryNiche: 'Trekking',
          baseRate: 35000.0,
          followerCount: 220000,
          upiId: 'rohan@okaxis',
          location: 'Delhi',
          rating: 4.9,
          strikeLevel: 0,
        );

        final map = original.toMap();
        final reconstructed = Creator.fromMap(map, id: original.id);

        expect(reconstructed.id, equals(original.id));
        expect(reconstructed.fullName, equals(original.fullName));
        expect(reconstructed.handle, equals(original.handle));
        expect(reconstructed.status, equals(original.status));
        expect(reconstructed.type, equals(original.type));
        expect(reconstructed.primaryCategory, equals(original.primaryCategory));
        expect(reconstructed.baseRate, equals(original.baseRate));
        expect(reconstructed.followerCount, equals(original.followerCount));
        expect(reconstructed.upiId, equals(original.upiId));
        expect(reconstructed.location, equals(original.location));
        expect(reconstructed.rating, equals(original.rating));
      },
    );

    test('Client fromMap / toMap roundtrip preserves company info & tier', () {
      final original = MockFactory.dummyClient(
        id: 'client-666',
        businessName: 'Zomato Live',
        tier: ClientTier.tier1,
        email: 'partners@zomato.com',
      );

      final map = original.toMap();
      final reconstructed = Client.fromMap(map);

      expect(reconstructed.id, equals(original.id));
      expect(reconstructed.businessName, equals(original.businessName));
      expect(reconstructed.tier, equals(original.tier));
      expect(reconstructed.email, equals(original.email));
    });

    test(
      'Lead fromMap / toMap roundtrip preserves pipeline status & budget',
      () {
        final original = MockFactory.dummyLead(
          id: 'lead-555',
          businessName: 'Sugar Cosmetics',
          estimatedBudget: 80000.0,
          status: LeadStatus.pitched,
          primaryCategory: PrimaryCategory.skincare,
        );

        final map = original.toMap();
        final reconstructed = Lead.fromMap(map, id: original.id);

        expect(reconstructed.id, equals(original.id));
        expect(reconstructed.businessName, equals(original.businessName));
        expect(reconstructed.estimatedBudget, equals(original.estimatedBudget));
        expect(reconstructed.status, equals(original.status));
        expect(reconstructed.primaryCategory, equals(original.primaryCategory));
      },
    );

    test(
      'Proposal fromMap / toMap roundtrip preserves add-ons and deliverables',
      () {
        final original = MockFactory.dummyProposal(
          id: 'prop-444',
          leadId: 'lead-555',
          agencyFee: 20000.0,
        );

        final map = original.toMap();
        final reconstructed = Proposal.fromMap(map, id: original.id);

        expect(reconstructed.id, equals(original.id));
        expect(reconstructed.leadId, equals(original.leadId));
        expect(reconstructed.agencyFee, equals(original.agencyFee));
        expect(reconstructed.creators.length, equals(1));
        expect(reconstructed.addOns.length, equals(1));
        expect(
          reconstructed.addOns.first.description,
          equals('Whitelisting Ads Rights'),
        );
      },
    );

    test('LogEvent fromMap / toMap roundtrip preserves audit fields', () {
      final original = MockFactory.dummyLogEvent(
        id: 'log-333',
        type: LogType.project,
        action: 'Status Changed to Completed',
        actor: 'Lead Manager',
        amount: null,
      );

      final map = original.toMap();
      final reconstructed = LogEvent.fromMap(map, id: original.id);

      expect(reconstructed.id, equals(original.id));
      expect(reconstructed.type, equals(original.type));
      expect(reconstructed.action, equals(original.action));
      expect(reconstructed.actor, equals(original.actor));
    });
  });
}
