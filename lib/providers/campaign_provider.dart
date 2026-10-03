import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../config/firestore_constants.dart';
import '../domain/app_enums.dart';
import '../models/campaign_model.dart';
import '../services/audit_logger_service.dart';
import '../services/firestore_service.dart';

class CampaignProvider extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();

  List<Campaign> _campaigns = [];
  StreamSubscription? _campaignSub;
  String? _activeProjectId;

  bool _isLoading = true;
  String? _error;

  List<Campaign> get campaigns => List.unmodifiable(_campaigns);

  bool get isLoading => _isLoading;

  String? get error => _error;

  String? get activeProjectId => _activeProjectId;

  CampaignProvider() {
    _initCampaignStream();
  }

  /// ─── GLOBAL CAMPAIGN STREAM INSTANTIATION ───
  /// Streams all campaigns across all projects via collectionGroup so that
  /// Dashboard, Financial Ledger, and Invoices reflect the entire agency.
  void _initCampaignStream() {
    _isLoading = true;
    _error = null;

    _campaignSub = _service
        .streamCollectionGroup<Campaign?>(
          collectionId: CloudPaths.campaigns,
          builder: (doc) {
            try {
              return Campaign.fromFirestore(doc);
            } catch (e) {
              debugPrint(
                '!! Ghost Campaign Blocked [${doc.id}]: Schema mismatch. $e',
              );
              return null;
            }
          },
        )
        .listen(
          (list) {
            _campaigns = list.whereType<Campaign>().toList();
            _isLoading = false;
            _error = null;
            notifyListeners();
          },
          onError: (err) => _handleError("Global Campaign Stream", err),
        );
  }

  /// Sets the active project focus for contextual views without purging global state.
  void setProjectScope(String? projectId) {
    if (_activeProjectId == projectId) return;
    _activeProjectId = projectId;
    notifyListeners();
  }

  @override
  void dispose() {
    _campaignSub?.cancel();
    super.dispose();
  }

  // ===========================================================================
  // CAMPAIGN BASE CRUD
  // ===========================================================================

  List<Campaign> campaignsForProject(String projectId) {
    return _campaigns.where((c) => c.projectId == projectId).toList();
  }

  Future<void> addCampaign(Campaign c) async {
    final finalCampaign = c.id.isEmpty
        ? c.copyWith(id: _service.generateId(CloudPaths.campaigns))
        : c;
    await _service.setData(
      path:
          '${CloudPaths.projects}/${finalCampaign.projectId}/${CloudPaths.campaigns}/${finalCampaign.id}',
      data: finalCampaign.toMap(),
    );
  }

  Future<void> updateCampaign(Campaign u) async {
    await _service.updateData(
      path:
          '${CloudPaths.projects}/${u.projectId}/${CloudPaths.campaigns}/${u.id}',
      data: u.toMap(),
    );
  }

  Future<void> updateCampaignTitle(
    String projectId,
    String campaignId,
    String newTitle,
  ) async {
    final campaign = _campaigns.firstWhere((c) => c.id == campaignId);
    await updateCampaign(campaign.copyWith(title: newTitle));
  }

  Future<void> deleteCampaign(String projectId, String campaignId) async {
    try {
      await _service.deleteData(
        '${CloudPaths.projects}/$projectId/${CloudPaths.campaigns}/$campaignId',
      );
    } catch (e) {
      _handleError("Delete Campaign", e);
      rethrow;
    }
  }

  // ===========================================================================
  // CAMPAIGN OPERATIONS (creator & Logistics via Transactions)
  // ===========================================================================

  Future<void> assignCreatorToCampaign({
    required String projectId,
    required String campaignId,
    required AssignedCreator creator,
  }) async {
    final docRef = FirebaseFirestore.instance.doc(
      '${CloudPaths.projects}/$projectId/${CloudPaths.campaigns}/$campaignId',
    );

    // Use an atomic transaction to read the existing list of creators and modify it,
    // avoiding overwrite race conditions if multiple admins are modifying assignments simultaneously.
    await FirebaseFirestore.instance
        .runTransaction((transaction) async {
          final snapshot = await transaction.get(docRef);
          if (!snapshot.exists) throw Exception("Campaign not found");

          final currentCampaign = Campaign.fromFirestore(snapshot);
          final updatedList = [
            ...currentCampaign.assignedCreators,
            creator,
          ].map((ac) => ac.toMap()).toList();

          transaction.update(docRef, {
            CloudFields.assignedCreators: updatedList,
          });

          AuditLoggerService.attachLogToTransaction(
            service: _service,
            transaction: transaction,
            projectId: projectId,
            creatorId: creator.creatorId,
            type: LogType.project,
            action: 'CREATOR_ASSIGNED',
            note: 'Added to ${currentCampaign.title}',
          );
        })
        .catchError((err) {
          _handleError("Transaction Assign Failed", err);
          throw err;
        });
  }

  Future<void> updateCreatorInCampaign({
    required String projectId,
    required String campaignId,
    required AssignedCreator updatedCreator,
  }) async {
    final docRef = FirebaseFirestore.instance.doc(
      '${CloudPaths.projects}/$projectId/${CloudPaths.campaigns}/$campaignId',
    );

    await FirebaseFirestore.instance
        .runTransaction((transaction) async {
          final snapshot = await transaction.get(docRef);
          if (!snapshot.exists) throw Exception("Campaign not found");

          final currentCampaign = Campaign.fromFirestore(snapshot);
          final oldCreator = currentCampaign.assignedCreators.firstWhere(
            (ac) => ac.creatorId == updatedCreator.creatorId,
            orElse: () =>
                throw Exception("Creator not found in target campaign"),
          );

          if (oldCreator.pipelineStatus != updatedCreator.pipelineStatus) {
            AuditLoggerService.attachLogToTransaction(
              service: _service,
              transaction: transaction,
              projectId: projectId,
              creatorId: updatedCreator.creatorId,
              type: LogType.creator,
              action: 'PIPELINE_UPDATED',
              note:
                  'Status moved to ${updatedCreator.pipelineStatus.value} for ${currentCampaign.title}',
            );
          }

          final updatedList = currentCampaign.assignedCreators
              .map(
                (ac) => ac.creatorId == updatedCreator.creatorId
                    ? updatedCreator
                    : ac,
              )
              .map((ac) => ac.toMap())
              .toList();

          transaction.update(docRef, {
            CloudFields.assignedCreators: updatedList,
          });
        })
        .catchError((err) {
          _handleError("Transaction Modification Failed", err);
          throw err;
        });
  }

  Future<void> removeCreatorFromCampaign({
    required String projectId,
    required String campaignId,
    required String creatorId,
  }) async {
    final docRef = FirebaseFirestore.instance.doc(
      '${CloudPaths.projects}/$projectId/${CloudPaths.campaigns}/$campaignId',
    );

    await FirebaseFirestore.instance
        .runTransaction((transaction) async {
          final snapshot = await transaction.get(docRef);
          if (!snapshot.exists) throw Exception("Campaign not found");

          final currentCampaign = Campaign.fromFirestore(snapshot);
          final updatedList = currentCampaign.assignedCreators
              .where((ac) => ac.creatorId != creatorId)
              .map((ac) => ac.toMap())
              .toList();

          transaction.update(docRef, {
            CloudFields.assignedCreators: updatedList,
          });

          AuditLoggerService.attachLogToTransaction(
            service: _service,
            transaction: transaction,
            projectId: projectId,
            creatorId: creatorId,
            type: LogType.project,
            action: 'CREATOR_REMOVED',
            note: 'Removed from campaign: ${currentCampaign.title}',
          );
        })
        .catchError((err) {
          _handleError("Transaction Removal Failed", err);
          throw err;
        });
  }

  void _handleError(String context, dynamic e) {
    debugPrint("!! CAMPAIGN ERROR [$context]: $e");
    _error = e.toString();
    _isLoading = false;
    notifyListeners();
  }
}
