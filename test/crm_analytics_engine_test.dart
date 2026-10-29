import 'package:dreamfluenzer_erp/domain/app_enums.dart';
import 'package:dreamfluenzer_erp/engines/crm_analytics_engine.dart';
import 'package:dreamfluenzer_erp/models/campaign_model.dart';
import 'package:dreamfluenzer_erp/models/project_model.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures/mock_factory.dart';

void main() {
  group('CrmAnalyticsEngine Unit Tests', () {
    late Campaign campaign1;
    late Campaign campaign2;
    late Project project1;

    setUp(() {
      project1 = MockFactory.dummyProject(
        id: 'p-1',
        projectName: 'Tech Launch 2026',
      );

      campaign1 = MockFactory.dummyCampaign(
        id: 'camp-1',
        projectId: 'p-1',
        title: 'Phase 1 Teasers',
        assignedCreators: [
          MockFactory.dummyAssignedCreator(
            creatorId: 'c-1',
            agreedPayout: 25000.0,
            pipelineStatus: PipelineStatus.draftRequested,
            individualDeadline: DateTime.now().add(const Duration(days: 5)),
          ),
        ],
      );

      campaign2 = MockFactory.dummyCampaign(
        id: 'camp-2',
        projectId: 'p-1',
        title: 'Phase 2 Reveal',
        assignedCreators: [
          MockFactory.dummyAssignedCreator(
            creatorId: 'c-1',
            agreedPayout: 35000.0,
            pipelineStatus: PipelineStatus.postedLive,
            isPaid: true,
          ),
          MockFactory.dummyAssignedCreator(
            creatorId: 'c-2',
            agreedPayout: 50000.0,
          ),
        ],
      );
    });

    test('getCampaignHistoryForCreator filters accurately', () {
      final history = CrmAnalyticsEngine.getCampaignHistoryForCreator('c-1', [
        campaign1,
        campaign2,
      ]);
      expect(history.length, 2);
      expect(history.map((c) => c.id), containsAll(['camp-1', 'camp-2']));

      final otherHistory = CrmAnalyticsEngine.getCampaignHistoryForCreator(
        'c-2',
        [campaign1, campaign2],
      );
      expect(otherHistory.length, 1);
      expect(otherHistory.first.id, 'camp-2');
    });

    test('getLifetimeValueForCreator calculates cumulative payouts', () {
      final ltv = CrmAnalyticsEngine.getLifetimeValueForCreator('c-1', [
        campaign1,
        campaign2,
      ]);
      expect(ltv, 60000.0); // 25k + 35k
    });

    test(
      'getActiveTasksForCreator counts non-terminal pipeline deliverables',
      () {
        final activeTasks = CrmAnalyticsEngine.getActiveTasksForCreator('c-1', [
          campaign1,
          campaign2,
        ]);
        // campaign1 is draftRequested (active), campaign2 is postedLive (terminal)
        expect(activeTasks, 1);
      },
    );

    test('getUpcomingTasksForCreator returns sorted upcoming deliverables', () {
      final upcoming = CrmAnalyticsEngine.getUpcomingTasksForCreator(
        'c-1',
        [campaign1, campaign2],
        [project1],
      );
      expect(upcoming.length, 1);
      expect(upcoming.first['project'], 'Tech Launch 2026');
      expect(upcoming.first['campaign'], 'Phase 1 Teasers');
    });
  });
}
