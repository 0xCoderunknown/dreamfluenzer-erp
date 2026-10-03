import '../domain/app_enums.dart';
import '../models/campaign_model.dart';
import '../models/project_model.dart';

class CrmAnalyticsEngine {
  static List<Campaign> getCampaignHistoryForCreator(
    String creatorId,
    List<Campaign> allCampaigns,
  ) {
    return allCampaigns
        .where(
          (camp) =>
              camp.assignedCreators.any((ac) => ac.creatorId == creatorId),
        )
        .toList();
  }

  static double getLifetimeValueForCreator(
    String creatorId,
    List<Campaign> allCampaigns,
  ) {
    double total = 0.0;
    final history = getCampaignHistoryForCreator(creatorId, allCampaigns);

    for (var camp in history) {
      for (var ac in camp.assignedCreators) {
        if (ac.creatorId == creatorId) {
          total += ac.agreedPayout;
        }
      }
    }
    return total;
  }

  static int getActiveTasksForCreator(
    String creatorId,
    List<Campaign> allCampaigns,
  ) {
    int count = 0;
    for (var camp in allCampaigns) {
      for (var ac in camp.assignedCreators) {
        if (ac.creatorId == creatorId &&
            [
              PipelineStatus.draftRequested,
              PipelineStatus.reviewing,
              PipelineStatus.changesRequested,
            ].contains(ac.pipelineStatus)) {
          count++;
        }
      }
    }
    return count;
  }

  static List<Map<String, dynamic>> getUpcomingTasksForCreator(
    String creatorId,
    List<Campaign> allCampaigns,
    List<Project> allProjects,
  ) {
    final today = DateTime.now();
    final nextMonth = today.add(const Duration(days: 30));
    List<Map<String, dynamic>> upcoming = [];

    for (var camp in allCampaigns) {
      for (var ac in camp.assignedCreators) {
        if (ac.creatorId == creatorId &&
            [
              PipelineStatus.draftRequested,
              PipelineStatus.reviewing,
              PipelineStatus.changesRequested,
            ].contains(ac.pipelineStatus) &&
            ac.individualDeadline.isBefore(nextMonth)) {
          final parentProject = allProjects
              .where((p) => p.id == camp.projectId)
              .firstOrNull;
          String projectName = parentProject?.projectName ?? 'Unknown';

          upcoming.add({
            'campaign': camp.title,
            'project': projectName,
            'deadline': ac.individualDeadline,
            'status': ac.pipelineStatus.value,
          });
        }
      }
    }

    // Sort by soonest deadline
    upcoming.sort(
      (a, b) =>
          (a['deadline'] as DateTime).compareTo(b['deadline'] as DateTime),
    );
    return upcoming;
  }
}
