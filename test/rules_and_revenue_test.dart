import 'package:flutter_test/flutter_test.dart';
import 'package:dreamfluenzer_erp/domain/app_enums.dart';
import 'package:dreamfluenzer_erp/domain/froyo_rules.dart';
import 'package:dreamfluenzer_erp/engines/revenue_engine.dart';
import 'package:dreamfluenzer_erp/models/campaign_model.dart';
import 'package:dreamfluenzer_erp/models/creator_model.dart';
import 'package:dreamfluenzer_erp/models/project_model.dart';

void main() {
  group('RevenueEngine - Twin Budget & Financial Isolation', () {
    test('Margin excludes GST on GST-exclusive projects', () {
      final project = Project(
        id: 'p1',
        clientId: 'c1',
        projectName: 'Test Project',
        leadName: 'Lead',
        dealType: DealType.cash,
        status: ProjectStatus.active,
        deadline: DateTime.now().add(const Duration(days: 30)),
        billingModel: BillingModel.oneOff,
        durationMonths: 1,
        baseBudget: 100000.0,
        gmvBudget: 0.0,
        isGstExclusive: true, // 18% GST added to invoice = 118,000
        advanceReceived: 50000.0,
        createdAt: DateTime.now(),
      );

      final invoice = RevenueEngine.calculateInvoice(project);
      expect(invoice.subtotal, equals(100000.0));
      expect(invoice.gstAmount, equals(18000.0));
      expect(invoice.grandTotal, equals(118000.0));

      final campaign = Campaign(
        id: 'camp1',
        projectId: 'p1',
        title: 'Campaign 1',
        cycleEndDate: DateTime.now(),
        expenses: 10000.0,
        assignedCreators: [
          AssignedCreator(
            creatorId: 'cr1',
            creatorName: 'Creator 1',
            agreedPayout: 40000.0,
            advancePaid: 10000.0,
            pipelineStatus: PipelineStatus.postedLive,
            isPaid: true,
            deliverables: [],
            individualDeadline: DateTime.now(),
          ),
        ],
      );

      // Total campaign costs = 10,000 (expenses) + 40,000 (creator) = 50,000
      final costs = RevenueEngine.totalCampaignCosts([campaign]);
      expect(costs, equals(50000.0));

      // Operating margin MUST be based on net revenue (100,000), NOT effectiveBudget (118,000)
      // 100,000 - 50,000 = 50,000 (50%)
      final margin = RevenueEngine.operatingMargin(project, [campaign]);
      expect(margin, equals(50000.0));

      final marginPct = RevenueEngine.operatingMarginPct(project, [campaign]);
      expect(marginPct, equals(50.0));

      const creator = Creator(
        id: 'cr1',
        fullName: 'Creator 1',
        handle: '@creator1',
        phoneNumber: '1234567890',
        status: CreatorStatus.active,
        type: CreatorType.influencer,
        primaryCategory: PrimaryCategory.tech,
        secondaryNiche: 'Gadgets',
        baseRate: 40000,
        followerCount: 50000,
        upiId: 'cr1@upi',
        location: 'Mumbai',
        notes: '',
        rating: 5.0,
      );

      // Ledger calculation should also base margin on totalContractValue
      final ledger = RevenueEngine.calculateLedger(
        projects: [project],
        campaigns: [campaign],
        creators: [creator],
      );
      // margin = 100000 - 10000 (camp expenses) - 40000 (creator payout) = 50000
      expect(ledger.projectedMargin, equals(50000.0));
    });
  });

  group('FroyoRules - Advance Safety Net', () {
    test('Fails when requested advance exceeds agreed payout', () {
      final result = FroyoRules.validateAdvancePayment(
        requestedAdvance: 60000.0,
        agreedPayout: 50000.0,
        projectAdvanceReceived: 100000.0,
        otherCreatorsTotalAdvance: 0.0,
      );
      expect(result.isValid, isFalse);
      expect(result.message, contains('Advance cannot exceed the total agreed payout'));
    });

    test('Fails when requested advance exceeds available client advance pool', () {
      final result = FroyoRules.validateAdvancePayment(
        requestedAdvance: 40000.0,
        agreedPayout: 50000.0,
        projectAdvanceReceived: 50000.0,
        otherCreatorsTotalAdvance: 20000.0, // Remaining pool = 30,000
      );
      expect(result.isValid, isFalse);
      expect(result.message, contains('Not enough client advance'));
    });

    test('Passes when requested advance is within both payout and client advance pool', () {
      final result = FroyoRules.validateAdvancePayment(
        requestedAdvance: 25000.0,
        agreedPayout: 50000.0,
        projectAdvanceReceived: 50000.0,
        otherCreatorsTotalAdvance: 20000.0, // Remaining pool = 30,000
      );
      expect(result.isValid, isTrue);
    });
  });

  group('FroyoRules - Project Archive Auditor', () {
    final project = Project(
      id: 'p1',
      clientId: 'c1',
      projectName: 'Test Project',
      leadName: 'Lead',
      dealType: DealType.cash,
      status: ProjectStatus.active,
      deadline: DateTime.now(),
      billingModel: BillingModel.oneOff,
      durationMonths: 1,
      baseBudget: 100000.0,
      isGstExclusive: true,
      advanceReceived: 50000.0,
      createdAt: DateTime.now(),
    );

    test('Fails when no campaigns exist', () {
      final result = FroyoRules.canArchiveProject(project, []);
      expect(result.isValid, isFalse);
    });

    test('Fails when campaign has no assigned creators', () {
      final campaign = Campaign(
        id: 'camp1',
        projectId: 'p1',
        title: 'Empty Camp',
        cycleEndDate: DateTime.now(),
        expenses: 0,
        assignedCreators: [],
      );
      final result = FroyoRules.canArchiveProject(project, [campaign]);
      expect(result.isValid, isFalse);
      expect(result.message, contains('has no creator assigned'));
    });

    test('Fails when creator deliverable is not in terminal state', () {
      final campaign = Campaign(
        id: 'camp1',
        projectId: 'p1',
        title: 'In Flight Camp',
        cycleEndDate: DateTime.now(),
        expenses: 0,
        assignedCreators: [
          AssignedCreator(
            creatorId: 'cr1',
            creatorName: 'Creator 1',
            agreedPayout: 20000,
            pipelineStatus: PipelineStatus.reviewing,
            isPaid: false,
            deliverables: [],
            individualDeadline: DateTime.now(),
          ),
        ],
      );
      final result = FroyoRules.canArchiveProject(project, [campaign]);
      expect(result.isValid, isFalse);
      expect(result.message, contains('Finish or drop their work before completing'));
    });

    test('Fails when creator posted live but remains unpaid', () {
      final campaign = Campaign(
        id: 'camp1',
        projectId: 'p1',
        title: 'Unpaid Camp',
        cycleEndDate: DateTime.now(),
        expenses: 0,
        assignedCreators: [
          AssignedCreator(
            creatorId: 'cr1',
            creatorName: 'Creator 1',
            agreedPayout: 20000,
            pipelineStatus: PipelineStatus.postedLive,
            isPaid: false,
            deliverables: [],
            individualDeadline: DateTime.now(),
          ),
        ],
      );
      final result = FroyoRules.canArchiveProject(project, [campaign]);
      expect(result.isValid, isFalse);
      expect(result.message, contains('hasn\'t been marked as Fully Paid'));
    });

    test('Passes when all deliverables are terminal and postedLive creators are paid', () {
      final campaign = Campaign(
        id: 'camp1',
        projectId: 'p1',
        title: 'Done Camp',
        cycleEndDate: DateTime.now(),
        expenses: 0,
        assignedCreators: [
          AssignedCreator(
            creatorId: 'cr1',
            creatorName: 'Creator 1',
            agreedPayout: 20000,
            pipelineStatus: PipelineStatus.postedLive,
            isPaid: true,
            deliverables: [],
            individualDeadline: DateTime.now(),
          ),
          AssignedCreator(
            creatorId: 'cr2',
            creatorName: 'Creator 2',
            agreedPayout: 15000,
            pipelineStatus: PipelineStatus.dropped,
            isPaid: false,
            deliverables: [],
            individualDeadline: DateTime.now(),
          ),
        ],
      );
      final result = FroyoRules.canArchiveProject(project, [campaign]);
      expect(result.isValid, isTrue);
    });
  });
}
