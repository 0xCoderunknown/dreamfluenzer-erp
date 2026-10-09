import 'package:flutter_test/flutter_test.dart';
import 'package:dreamfluenzer_erp/config/rule_messages.dart';
import 'package:dreamfluenzer_erp/domain/app_enums.dart';
import 'package:dreamfluenzer_erp/domain/froyo_rules.dart';
import 'package:dreamfluenzer_erp/models/campaign_model.dart';
import 'package:dreamfluenzer_erp/models/project_model.dart';

void main() {
  group('FroyoRules — canArchiveProject (Archive Lock)', () {
    final baseProject = Project(
      id: 'p1',
      clientId: 'c1',
      projectName: 'Test Project',
      leadName: '',
      dealType: DealType.cash,
      status: ProjectStatus.active,
      deadline: DateTime.now(),
      billingModel: BillingModel.oneOff,
      durationMonths: 1,
      baseBudget: 50000,
      isGstExclusive: false,
      advanceReceived: 50000,
      createdAt: DateTime.now(),
    );

    test('Fails when project has zero campaigns', () {
      final result = FroyoRules.canArchiveProject(baseProject, []);

      expect(result.isValid, isFalse);
      expect(result.message, RuleMessages.noProjectCampaigns);
    });

    test('Fails when a campaign has zero assigned creators', () {
      final campaigns = [
        Campaign(
          id: 'camp1',
          projectId: 'p1',
          title: 'Empty Campaign',
          cycleEndDate: DateTime.now(),
          expenses: 0,
          assignedCreators: [],
        ),
      ];

      final result = FroyoRules.canArchiveProject(baseProject, campaigns);

      expect(result.isValid, isFalse);
      expect(
        result.message,
        RuleMessages.campaignHasNoCreator('Empty Campaign'),
      );
    });

    test(
      'Fails when an assigned creator is still mid-pipeline (Reviewing)',
      () {
        final campaigns = [
          Campaign(
            id: 'camp1',
            projectId: 'p1',
            title: 'Live Campaign',
            cycleEndDate: DateTime.now(),
            expenses: 0,
            assignedCreators: [
              AssignedCreator(
                creatorId: 'cr1',
                creatorName: 'Rahul Sharma',
                individualDeadline: DateTime.now(),
                agreedPayout: 10000,
                pipelineStatus: PipelineStatus.reviewing,
                isPaid: false,
                deliverables: [],
              ),
            ],
          ),
        ];

        final result = FroyoRules.canArchiveProject(baseProject, campaigns);

        expect(result.isValid, isFalse);
        expect(
          result.message,
          RuleMessages.creatorWorkInProgress(
            'Rahul Sharma',
            PipelineStatus.reviewing.value,
          ),
        );
      },
    );

    test(
      'Fails when creator reached postedLive but is not yet marked isPaid',
      () {
        final campaigns = [
          Campaign(
            id: 'camp1',
            projectId: 'p1',
            title: 'Live Campaign',
            cycleEndDate: DateTime.now(),
            expenses: 0,
            assignedCreators: [
              AssignedCreator(
                creatorId: 'cr1',
                creatorName: 'Aarav Patel',
                individualDeadline: DateTime.now(),
                agreedPayout: 15000,
                pipelineStatus: PipelineStatus.postedLive,
                isPaid: false,
                deliverables: [],
              ),
            ],
          ),
        ];

        final result = FroyoRules.canArchiveProject(baseProject, campaigns);

        expect(result.isValid, isFalse);
        expect(
          result.message,
          RuleMessages.creatorUnpaidAfterPosting(
            'Aarav Patel',
            PipelineStatus.postedLive.value,
          ),
        );
      },
    );

    test('Passes when creator was dropped (terminal state)', () {
      final campaigns = [
        Campaign(
          id: 'camp1',
          projectId: 'p1',
          title: 'Live Campaign',
          cycleEndDate: DateTime.now(),
          expenses: 0,
          assignedCreators: [
            AssignedCreator(
              creatorId: 'cr1',
              creatorName: 'Dropped Creator',
              individualDeadline: DateTime.now(),
              agreedPayout: 15000,
              pipelineStatus: PipelineStatus.dropped,
              isPaid: false,
              deliverables: [],
            ),
          ],
        ),
      ];

      final result = FroyoRules.canArchiveProject(baseProject, campaigns);

      expect(result.isValid, isTrue);
      expect(result.message, isEmpty);
    });

    test('Passes when all creators are postedLive and marked as isPaid', () {
      final campaigns = [
        Campaign(
          id: 'camp1',
          projectId: 'p1',
          title: 'Completed Campaign',
          cycleEndDate: DateTime.now(),
          expenses: 0,
          assignedCreators: [
            AssignedCreator(
              creatorId: 'cr1',
              creatorName: 'Priya Das',
              individualDeadline: DateTime.now(),
              agreedPayout: 20000,
              pipelineStatus: PipelineStatus.postedLive,
              isPaid: true,
              deliverables: [],
            ),
          ],
        ),
      ];

      final result = FroyoRules.canArchiveProject(baseProject, campaigns);

      expect(result.isValid, isTrue);
      expect(result.message, isEmpty);
    });
  });

  group('FroyoRules — validateAdvancePayment (Advance Safety Net)', () {
    test('Fails when requested advance exceeds agreed payout', () {
      final result = FroyoRules.validateAdvancePayment(
        requestedAdvance: 15000,
        agreedPayout: 10000,
        projectAdvanceReceived: 50000,
        otherCreatorsTotalAdvance: 0,
      );

      expect(result.isValid, isFalse);
      expect(result.message, RuleMessages.advanceExceedsPayout(10000));
    });

    test(
      'Fails when requested advance exceeds agency cash balance from client',
      () {
        // Client paid 20000 advance. Other creators took 15000. Agency only has 5000 left.
        final result = FroyoRules.validateAdvancePayment(
          requestedAdvance: 8000,
          agreedPayout: 10000,
          projectAdvanceReceived: 20000,
          otherCreatorsTotalAdvance: 15000,
        );

        expect(result.isValid, isFalse);
        expect(result.message, RuleMessages.insufficientClientFunds(5000));
      },
    );

    test('Passes when advance is within agreed payout and agency balance', () {
      final result = FroyoRules.validateAdvancePayment(
        requestedAdvance: 5000,
        agreedPayout: 10000,
        projectAdvanceReceived: 30000,
        otherCreatorsTotalAdvance: 10000,
      );

      expect(result.isValid, isTrue);
      expect(result.message, isEmpty);
    });
  });
}
