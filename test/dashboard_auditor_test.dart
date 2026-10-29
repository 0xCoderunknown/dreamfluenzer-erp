import 'package:dreamfluenzer_erp/domain/app_enums.dart';
import 'package:dreamfluenzer_erp/engines/dashboard_auditor.dart';
import 'package:dreamfluenzer_erp/providers/dashboard_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures/mock_factory.dart';

void main() {
  group('DashboardAuditor & DashboardProvider Tests', () {
    test('Auditor computes active creators and live projects accurately', () {
      final activeCreator = MockFactory.dummyCreator(
        id: 'c-1',
        status: CreatorStatus.active,
      );
      final inactiveCreator = MockFactory.dummyCreator(
        id: 'c-2',
        status: CreatorStatus.inactive,
      );

      final liveProject = MockFactory.dummyProject(
        id: 'p-1',
        status: ProjectStatus.active,
        baseBudget: 100000.0,
        advanceReceived: 40000.0,
        isGstExclusive: false,
      );
      final completedProject = MockFactory.dummyProject(
        id: 'p-2',
        status: ProjectStatus.completed,
      );

      final auditor = DashboardAuditor.process(
        [liveProject, completedProject],
        [],
        [activeCreator, inactiveCreator],
      );

      expect(auditor.activeCreatorsCount, 1);
      expect(auditor.liveProjects.length, 1);
      expect(auditor.liveProjects.first.id, 'p-1');
      // 60k pending from live project + 39k uncollected final payment on completed project
      expect(auditor.pendingClientDues, 99000.0);
    });

    test('Auditor flags overdue projects in financial actions', () {
      final overdueProject = MockFactory.dummyProject(
        id: 'p-overdue',
        projectName: 'Late Campaign',
        status: ProjectStatus.active,
        deadline: DateTime.now().subtract(const Duration(days: 3)),
      );

      final auditor = DashboardAuditor.process([overdueProject], [], []);

      expect(auditor.financialActions.length, 1);
      expect(auditor.financialActions.first.title, contains('Overdue Project'));
      expect(auditor.financialActions.first.targetRoute, '/projects/p-overdue');
    });

    test('DashboardProvider updateData is idempotent and updates state', () {
      final provider = DashboardProvider();
      expect(provider.isLoading, isTrue);
      expect(provider.auditor, isNull);

      final p = MockFactory.dummyProject(id: 'p-1');
      final c = MockFactory.dummyCreator(id: 'c-1');

      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.updateData(projects: [p], campaigns: [], creators: [c]);

      expect(provider.isLoading, isFalse);
      expect(provider.auditor, isNotNull);
      expect(notifyCount, 1);

      // Calling updateData again with identical instances does not notify again
      provider.updateData(projects: [p], campaigns: [], creators: [c]);
      expect(notifyCount, 1);
    });
  });
}
