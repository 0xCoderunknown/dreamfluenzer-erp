import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../config/agency_config.dart';
import '../config/firestore_constants.dart';
import '../domain/app_enums.dart';
import '../models/creator_model.dart';
import '../models/log_event_model.dart';
import '../services/firestore_service.dart';

class CreatorProvider extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();

  List<Creator> _creators = [];
  StreamSubscription? _subscription;

  // ─── STATE MANAGEMENT ───
  bool _isLoading = true;
  String? _error;

  List<Creator> get creators => List.unmodifiable(_creators);

  bool get isLoading => _isLoading;

  String? get error => _error;

  CreatorProvider() {
    _initCreatorStream();
  }

  void _initCreatorStream() {
    _subscription = _service
        .streamCollection(
          path: CloudPaths.creators,
          builder: (doc) => Creator.fromFirestore(doc),
        )
        .listen(
          (snapshot) {
            _creators = snapshot;
            _isLoading = false;
            _error = null;
            notifyListeners();
          },
          onError: (err) {
            _error = "creator Sync Failed: $err";
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  // ─── SEARCH & UTILITY ───

  Creator? creatorById(String id) {
    return _creators.where((c) => c.id == id).firstOrNull;
  }

  // ─── CRUD OPERATIONS ───

  Future<void> addCreator(Creator creator) async {
    try {
      final finalCreator = creator.id.isEmpty
          ? creator.copyWith(id: _service.generateId(CloudPaths.creators))
          : creator;
      await _service.setData(
        path: '${CloudPaths.creators}/${finalCreator.id}',
        data: finalCreator.toMap(),
      );
    } catch (e) {
      _handleError("Add Creator Failed", e);
      rethrow;
    }
  }

  Future<void> updateCreator(Creator updatedCreator) async {
    try {
      await _service.updateData(
        path: '${CloudPaths.creators}/${updatedCreator.id}',
        data: updatedCreator.toMap(),
      );
    } catch (e) {
      _handleError("Update Creator Failed", e);
      rethrow;
    }
  }

  /// Deep-Delete: Optimized limit guard validates architecture footprints without downloading large log profiles
  Future<void> deleteCreator(String id) async {
    try {
      final historyCheck = await _service.getCollection(
        path: '${CloudPaths.creators}/$id/${CloudPaths.history}',
        queryBuilder: (query) => query.limit(1),
        builder: (doc) => doc,
      );

      if (historyCheck.isNotEmpty) {
        throw Exception(
          "Cannot hard-delete this creator because they have a logged history "
          "(projects, payments, or strikes). Please 'Deactivate' them instead "
          "to preserve accounting records.",
        );
      }

      await _service.deleteData('${CloudPaths.creators}/$id');
    } catch (e) {
      _handleError("Delete Creator Failed", e);
      rethrow;
    }
  }

  /// Soft-Delete: Marks as Inactive and logs the event
  Future<void> deactivateCreator(
    String creatorId, {
    String actor = 'System',
  }) async {
    final batch = _service.batch;
    final creatorRef = _service.getDocumentReference(
      '${CloudPaths.creators}/$creatorId',
    );

    batch.update(creatorRef, {
      CloudFields.status: CreatorStatus.inactive.value,
    });

    final log = LogEvent(
      id: 'log_${DateTime.now().millisecondsSinceEpoch}',
      type: LogType.creator,
      action: 'CREATOR_DEACTIVATED',
      note: 'Creator marked as Inactive/Retired.',
      timestamp: DateTime.now(),
      actor: actor,
    );

    final logRef = _service.getDocumentReference(
      '${CloudPaths.creators}/$creatorId/${CloudPaths.history}/${log.id}',
    );
    batch.set(logRef, log.toMap());

    await batch.commit();
  }

  // ─── BEHAVIOR: Strike System (3-Strikes Auto-Deactivation) ───

  Future<void> issueStrike(
    String creatorId,
    String reason,
    String actor,
  ) async {
    final creator = creatorById(creatorId);
    if (creator == null) return;

    final newStrikeLevel = creator.strikeLevel + 1;
    final batch = _service.batch;
    final creatorRef = _service.getDocumentReference(
      '${CloudPaths.creators}/$creatorId',
    );

    batch.update(creatorRef, {'strike_level': newStrikeLevel});

    // 2. Automate: 3 Strikes = Auto-Deactivation
    if (newStrikeLevel >= 3) {
      batch.update(creatorRef, {
        CloudFields.status: CreatorStatus.inactive.value,
      });

      final deactivationLog = LogEvent(
        id: 'log_auto_${DateTime.now().millisecondsSinceEpoch}',
        type: LogType.creator,
        action: 'AUTO_DEACTIVATED',
        note: 'Deactivated due to reaching 3 strikes.',
        timestamp: DateTime.now().add(const Duration(seconds: 1)),
        actor: '${AgencyConfig.agencyName} System',
      );

      final deactivationLogRef = _service.getDocumentReference(
        '${CloudPaths.creators}/$creatorId/${CloudPaths.history}/${deactivationLog.id}',
      );
      batch.set(deactivationLogRef, deactivationLog.toMap());
    }

    final strikeLog = LogEvent(
      id: 'log_${DateTime.now().millisecondsSinceEpoch}',
      type: LogType.creator,
      action: 'STRIKE_ISSUED',
      note:
          'Strike $newStrikeLevel issued. Cooldown probation active until: ${DateFormat('dd MMM yyyy').format(DateTime.now().add(const Duration(days: 60)))}',
      timestamp: DateTime.now(),
      actor: actor,
      reason: reason,
    );

    final strikeLogRef = _service.getDocumentReference(
      '${CloudPaths.creators}/$creatorId/${CloudPaths.history}/${strikeLog.id}',
    );
    batch.set(strikeLogRef, strikeLog.toMap());

    await batch.commit();
  }

  // ─── LOGGING & HISTORY ───

  Future<List<LogEvent>> getCreatorLogs(String creatorId) async {
    return await _service.getCollection(
      path: '${CloudPaths.creators}/$creatorId/${CloudPaths.history}',
      queryBuilder: (query) =>
          query.orderBy(CloudFields.timestamp, descending: true),
      builder: (d) => LogEvent.fromFirestore(d),
    );
  }

  void _handleError(String context, dynamic e) {
    debugPrint("!! CREATOR ERROR [$context]: $e");
    _error = e.toString();
    notifyListeners();
  }
}
