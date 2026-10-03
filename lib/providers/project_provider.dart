import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/firestore_constants.dart';
import '../domain/app_enums.dart';
import '../domain/froyo_rules.dart';
import '../models/campaign_model.dart';
import '../models/client_model.dart';
import '../models/log_event_model.dart';
import '../models/project_model.dart';
import '../services/audit_logger_service.dart';
import '../services/firestore_service.dart';

class ProjectProvider extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();

  List<Project> _projects = [];
  StreamSubscription? _projectSub;

  bool _isLoading = true;
  String? _error;

  List<Project> get projects => List.unmodifiable(_projects);

  bool get isLoading => _isLoading;

  String? get error => _error;

  ProjectProvider() {
    _initProjectStream();
  }

  void _initProjectStream() {
    _projectSub = _service
        .streamCollection(
          path: CloudPaths.projects,
          builder: (doc) => Project.fromFirestore(doc),
        )
        .listen((list) {
          _projects = list;
          _isLoading = false;
          notifyListeners();
        }, onError: (err) => _handleError("Project Stream", err));
  }

  @override
  void dispose() {
    _projectSub?.cancel();
    super.dispose();
  }

  // ===========================================================================
  // PROJECT CRUD
  // ===========================================================================

  Project? projectById(String id) {
    return _projects.where((c) => c.id == id).firstOrNull;
  }

  Future<void> addProject(Project p) async => await _service.setData(
    path: '${CloudPaths.projects}/${p.id}',
    data: p.toMap(),
  );

  Future<void> updateProject(Project u) async => await _service.updateData(
    path: '${CloudPaths.projects}/${u.id}',
    data: u.toMap(),
  );

  Future<void> deleteProject(String projectId) async {
    try {
      final batch = _service.batch;
      final projectRef = _service.getDocumentReference(
        '${CloudPaths.projects}/$projectId',
      );

      // Sweep and stage deletions for nested subcollections since Firestore
      // does not delete subcollections automatically when deleting a parent document.
      final collectionsToSweep = [CloudPaths.campaigns, CloudPaths.history];

      for (var collectionPath in collectionsToSweep) {
        final documents = await _service.getCollection(
          path: '${CloudPaths.projects}/$projectId/$collectionPath',
          builder: (doc) => _service.getDocumentReference(
            '${CloudPaths.projects}/$projectId/$collectionPath/${doc.id}',
          ),
        );

        for (var ref in documents) {
          batch.delete(ref);
        }
      }

      // Stage the deletion of the project itself and commit atomically.
      batch.delete(projectRef);
      await batch.commit();
    } catch (e) {
      _handleError("Delete Project Failed", e);
      rethrow;
    }
  }

  // ─── PROJECT CREATION AND ONBOARDING ───
  Future<String> onboardNewProject({
    required Client? newClient,
    required Project project,
    required Campaign initialCampaign,
    String? sourceLeadId,
    String? sourceProposalId,
  }) async {
    final batch = _service.batch;

    // Step 1: Pre-generate unique Firestore IDs so models can refer to each other.
    final finalClientId = (newClient != null && newClient.id.isEmpty)
        ? _service.generateId(CloudPaths.clients)
        : (newClient?.id ?? project.clientId);

    final finalProjectId = project.id.isEmpty
        ? _service.generateId(CloudPaths.projects)
        : project.id;

    final finalCampaignId = initialCampaign.id.isEmpty
        ? _service.generateId(CloudPaths.campaigns)
        : initialCampaign.id;

    // Step 2: Bind cross-references internally.
    final updatedClient = newClient?.copyWith(id: finalClientId);

    final updatedProject = project.id.isEmpty || project.clientId.isEmpty
        ? Project(
            id: finalProjectId,
            clientId: finalClientId,
            projectName: project.projectName,
            leadName: project.leadName,
            dealType: project.dealType,
            status: project.status,
            deadline: project.deadline,
            billingModel: project.billingModel,
            durationMonths: project.durationMonths,
            baseBudget: project.baseBudget,
            gmvBudget: project.gmvBudget,
            isGstExclusive: project.isGstExclusive,
            advanceReceived: project.advanceReceived,
            createdAt: project.createdAt,
          )
        : project;

    final updatedCampaign =
        initialCampaign.id.isEmpty || initialCampaign.projectId.isEmpty
        ? Campaign(
            id: finalCampaignId,
            projectId: finalProjectId,
            title: initialCampaign.title,
            cycleEndDate: initialCampaign.cycleEndDate,
            expenses: initialCampaign.expenses,
            inventoryPool: initialCampaign.inventoryPool,
            assignedCreators: initialCampaign.assignedCreators,
          )
        : initialCampaign;

    // Step 3: Stage new document sets in the batch.
    if (updatedClient != null) {
      batch.set(
        _service.getDocumentReference(
          '${CloudPaths.clients}/${updatedClient.id}',
        ),
        updatedClient.toMap(),
      );
    }

    batch.set(
      _service.getDocumentReference(
        '${CloudPaths.projects}/${updatedProject.id}',
      ),
      updatedProject.toMap(),
    );
    batch.set(
      _service.getDocumentReference(
        '${CloudPaths.projects}/${updatedProject.id}/${CloudPaths.campaigns}/${updatedCampaign.id}',
      ),
      updatedCampaign.toMap(),
    );

    // Step 4: If converting from a lead/proposal, clean up the source records.
    if (sourceLeadId != null) {
      batch.delete(
        _service.getDocumentReference('${CloudPaths.leads}/$sourceLeadId'),
      );
    }
    if (sourceProposalId != null) {
      batch.delete(
        _service.getDocumentReference(
          '${CloudPaths.proposals}/$sourceProposalId',
        ),
      );
    }

    // Step 5: Attach creation audit log to project history.
    AuditLoggerService.attachLogToBatch(
      service: _service,
      batch: batch,
      projectId: updatedProject.id,
      creatorId: 'AGENCY',
      type: LogType.system,
      action: 'PROJECT_CREATED',
      note: 'Project bootstrapped via Wizard.',
    );

    // Step 6: Commit all transactions atomically.
    await batch.commit();
    return finalProjectId;
  }

  Future<List<LogEvent>> fetchProjectExecutionLogs(String projectId) =>
      AuditLoggerService.getProjectLogs(_service, projectId);

  Future<void> completeProject(
    String projectId, {
    List<Campaign>? campaigns,
  }) async {
    try {
      final p = projectById(projectId);
      if (p == null) return;

      if (campaigns != null) {
        final audit = FroyoRules.canArchiveProject(p, campaigns);
        if (!audit.isValid) {
          throw Exception(audit.message);
        }
      }

      final completedProject = p.copyWith(status: ProjectStatus.completed);
      final batch = _service.batch;

      batch.update(
        _service.getDocumentReference('${CloudPaths.projects}/$projectId'),
        completedProject.toMap(),
      );

      AuditLoggerService.attachLogToBatch(
        service: _service,
        batch: batch,
        projectId: projectId,
        creatorId: 'AGENCY',
        type: LogType.system,
        action: 'PROJECT_COMPLETED',
        note: 'Project officially moved to archive.',
      );

      await batch.commit();
    } catch (e) {
      _handleError("Complete Project Failed", e);
      rethrow;
    }
  }

  void _handleError(String context, dynamic e) {
    debugPrint("!! PROJECT ERROR [$context]: $e");
    _error = e.toString();
    notifyListeners();
  }
}
