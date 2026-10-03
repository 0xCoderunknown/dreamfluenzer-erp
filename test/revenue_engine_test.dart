import 'package:flutter_test/flutter_test.dart';
import 'package:dreamfluenzer_erp/domain/app_enums.dart';
import 'package:dreamfluenzer_erp/engines/revenue_engine.dart';
import 'package:dreamfluenzer_erp/models/campaign_model.dart';
import 'package:dreamfluenzer_erp/models/creator_model.dart';
import 'package:dreamfluenzer_erp/models/project_model.dart';

void main() {
  group('RevenueEngine — Invoice Calculations', () {
    test('Calculates invoice without GST (GST inclusive / false)', () {
      final project = Project(
        id: 'p1',
        clientId: 'c1',
        projectName: 'Summer Campaign',
        leadName: 'Lead 1',
        dealType: DealType.cash,
        status: ProjectStatus.active,
        deadline: DateTime(2026, 6, 1),
        billingModel: BillingModel.oneOff,
        durationMonths: 1,
        baseBudget: 100000,
        isGstExclusive: false,
        advanceReceived: 30000,
        createdAt: DateTime(2026, 1, 1),
      );

      final math = RevenueEngine.calculateInvoice(project);

      expect(math.subtotal, 100000.0);
      expect(math.gstAmount, 0.0);
      expect(math.grandTotal, 100000.0);
      expect(math.advanceReceived, 30000.0);
      expect(math.balanceDue, 70000.0);
      expect(math.isPaid, isFalse);
    });

    test('Calculates invoice with 18% GST (GST exclusive / true)', () {
      final project = Project(
        id: 'p2',
        clientId: 'c1',
        projectName: 'Winter Campaign',
        leadName: 'Lead 2',
        dealType: DealType.cash,
        status: ProjectStatus.active,
        deadline: DateTime(2026, 12, 1),
        billingModel: BillingModel.oneOff,
        durationMonths: 1,
        baseBudget: 100000,
        isGstExclusive: true,
        advanceReceived: 118000,
        createdAt: DateTime(2026, 1, 1),
      );

      final math = RevenueEngine.calculateInvoice(project);

      expect(math.subtotal, 100000.0);
      expect(math.gstAmount, 18000.0);
      expect(math.grandTotal, 118000.0);
      expect(math.advanceReceived, 118000.0);
      expect(math.balanceDue, 0.0);
      expect(math.isPaid, isTrue);
    });

    test('Calculates Retainer total contract value across multiple months', () {
      final project = Project(
        id: 'p3',
        clientId: 'c1',
        projectName: 'Annual Retainer',
        leadName: 'Lead 3',
        dealType: DealType.cash,
        status: ProjectStatus.active,
        deadline: DateTime(2026, 12, 31),
        billingModel: BillingModel.retainer,
        durationMonths: 6,
        baseBudget: 50000, // 50k per month for 6 months = 300k
        isGstExclusive: false,
        advanceReceived: 100000,
        createdAt: DateTime(2026, 1, 1),
      );

      final math = RevenueEngine.calculateInvoice(project);

      expect(math.subtotal, 300000.0);
      expect(math.grandTotal, 300000.0);
      expect(math.balanceDue, 200000.0);
    });
  });

  group('RevenueEngine — Cashflow & Advance Pool Guard', () {
    test('Calculates available advance pool subtracting other creator advances', () {
      final project = Project(
        id: 'p1',
        clientId: 'c1',
        projectName: 'Test Proj',
        leadName: '',
        dealType: DealType.cash,
        status: ProjectStatus.active,
        deadline: DateTime.now(),
        billingModel: BillingModel.oneOff,
        durationMonths: 1,
        baseBudget: 100000,
        isGstExclusive: false,
        advanceReceived: 50000,
        createdAt: DateTime.now(),
      );

      final campaigns = [
        Campaign(
          id: 'camp1',
          projectId: 'p1',
          title: 'Camp 1',
          cycleEndDate: DateTime.now(),
          expenses: 0,
          assignedCreators: [
            AssignedCreator(
              creatorId: 'c1',
              creatorName: 'Creator 1',
              individualDeadline: DateTime.now(),
              agreedPayout: 30000,
              pipelineStatus: PipelineStatus.draftRequested,
              isPaid: false,
              advancePaid: 20000,
              deliverables: [],
            ),
            AssignedCreator(
              creatorId: 'c2',
              creatorName: 'Creator 2',
              individualDeadline: DateTime.now(),
              agreedPayout: 20000,
              pipelineStatus: PipelineStatus.draftRequested,
              isPaid: false,
              advancePaid: 0,
              deliverables: [],
            ),
          ],
        ),
      ];

      // Checking pool available for Creator 2
      final pool = RevenueEngine.calculateAvailableAdvancePool(
        project,
        campaigns,
        'c2',
        'camp1',
      );

      expect(pool, 30000.0); // 50000 - 20000 = 30000
    });

    test('Advance pool never returns negative values', () {
      final project = Project(
        id: 'p1',
        clientId: 'c1',
        projectName: 'Test Proj',
        leadName: '',
        dealType: DealType.cash,
        status: ProjectStatus.active,
        deadline: DateTime.now(),
        billingModel: BillingModel.oneOff,
        durationMonths: 1,
        baseBudget: 100000,
        isGstExclusive: false,
        advanceReceived: 10000,
        createdAt: DateTime.now(),
      );

      final campaigns = [
        Campaign(
          id: 'camp1',
          projectId: 'p1',
          title: 'Camp 1',
          cycleEndDate: DateTime.now(),
          expenses: 0,
          assignedCreators: [
            AssignedCreator(
              creatorId: 'c1',
              creatorName: 'Creator 1',
              individualDeadline: DateTime.now(),
              agreedPayout: 30000,
              pipelineStatus: PipelineStatus.draftRequested,
              isPaid: false,
              advancePaid: 15000,
              deliverables: [],
            ),
          ],
        ),
      ];

      final pool = RevenueEngine.calculateAvailableAdvancePool(
        project,
        campaigns,
        'c2',
        'camp1',
      );

      expect(pool, 0.0);
    });
  });

  group('RevenueEngine — Logistics & Barter GMV', () {
    test('Calculates distributed vs retained Barter GMV accurately', () {
      final project = Project(
        id: 'p1',
        clientId: 'c1',
        projectName: 'Barter Proj',
        leadName: '',
        dealType: DealType.barter,
        status: ProjectStatus.active,
        deadline: DateTime.now(),
        billingModel: BillingModel.oneOff,
        durationMonths: 1,
        baseBudget: 0,
        gmvBudget: 25000,
        isGstExclusive: false,
        advanceReceived: 0,
        createdAt: DateTime.now(),
      );

      final campaigns = [
        Campaign(
          id: 'camp1',
          projectId: 'p1',
          title: 'Barter Camp',
          cycleEndDate: DateTime.now(),
          expenses: 0,
          inventoryPool: [
            const CampaignInventory(
              id: 'inv1',
              itemName: 'Face Cream',
              totalQuantity: 10,
              gmvPerUnit: 2500,
            ),
          ],
          assignedCreators: [
            AssignedCreator(
              creatorId: 'cr1',
              creatorName: 'Creator 1',
              individualDeadline: DateTime.now(),
              agreedPayout: 0,
              pipelineStatus: PipelineStatus.draftRequested,
              isPaid: true,
              deliverables: [],
              allocatedItems: const [
                AllocatedItem(
                  inventoryId: 'inv1',
                  itemName: 'Face Cream',
                  quantity: 4, // 4 * 2500 = 10000
                ),
              ],
            ),
          ],
        ),
      ];

      final logistics = RevenueEngine.calculateProjectLogistics(project, campaigns);

      expect(logistics.totalGmvBudget, 25000.0);
      expect(logistics.totalDistributedGmv, 10000.0);
      expect(logistics.retainedGmv, 15000.0);
    });
  });

  group('RevenueEngine — Master Ledger Aggregations', () {
    test('Calculates receivables, payables, margins and pending lists', () {
      final projects = [
        Project(
          id: 'p1',
          clientId: 'cl1',
          projectName: 'Active Brand A',
          leadName: '',
          dealType: DealType.cash,
          status: ProjectStatus.active,
          deadline: DateTime.now(),
          billingModel: BillingModel.oneOff,
          durationMonths: 1,
          baseBudget: 50000,
          isGstExclusive: false,
          advanceReceived: 20000, // Due: 30000
          createdAt: DateTime.now(),
        ),
        Project(
          id: 'p2',
          clientId: 'cl2',
          projectName: 'Dropped Deal',
          leadName: '',
          dealType: DealType.cash,
          status: ProjectStatus.dropped, // Should be ignored
          deadline: DateTime.now(),
          billingModel: BillingModel.oneOff,
          durationMonths: 1,
          baseBudget: 100000,
          isGstExclusive: false,
          advanceReceived: 0,
          createdAt: DateTime.now(),
        ),
      ];

      final campaigns = [
        Campaign(
          id: 'camp1',
          projectId: 'p1',
          title: 'Brand A Campaign',
          cycleEndDate: DateTime.now(),
          expenses: 5000,
          assignedCreators: [
            AssignedCreator(
              creatorId: 'cr1',
              creatorName: 'Creator 1',
              individualDeadline: DateTime.now(),
              agreedPayout: 15000,
              advancePaid: 5000,
              pipelineStatus: PipelineStatus.postedLive,
              isPaid: false, // Urgent payable: 10000
              deliverables: [],
            ),
          ],
        ),
      ];

      final creators = [
        const Creator(
          id: 'cr1',
          fullName: 'Creator One',
          handle: 'cr1_official',
          phoneNumber: '9876543210',
          status: CreatorStatus.active,
          type: CreatorType.influencer,
          primaryCategory: PrimaryCategory.clothing,
          secondaryNiche: 'OOTD',
          baseRate: 15000,
          followerCount: 50000,
          upiId: 'cr1@upi',
          location: 'Delhi',
          notes: '',
          rating: 4.8,
        ),
      ];

      final ledger = RevenueEngine.calculateLedger(
        projects: projects,
        campaigns: campaigns,
        creators: creators,
      );

      expect(ledger.totalReceivables, 30000.0);
      expect(ledger.totalPayables, 15000.0);
      // Margin = 50000 (effectiveBudget) - 5000 (expenses) - 15000 (agreedPayout) = 30000
      expect(ledger.projectedMargin, 30000.0);
      expect(ledger.pendingInvoices.length, 1);
      expect(ledger.pendingPayouts.length, 1);
      expect(ledger.pendingPayouts.first['isUrgent'], isTrue);
    });
  });
}
