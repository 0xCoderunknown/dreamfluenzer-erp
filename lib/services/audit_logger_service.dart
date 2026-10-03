import 'package:cloud_firestore/cloud_firestore.dart'
    show WriteBatch, Transaction;
import 'package:flutter/foundation.dart';

import '../config/firestore_constants.dart';
import '../domain/app_enums.dart';
import '../models/log_event_model.dart';
import 'firestore_service.dart';

class AuditLoggerService {
  // ─── 1. BATCH LOGGING ───
  /// Automatically writes the log to the Project's history using a WriteBatch.
  static void attachLogToBatch({
    required FirestoreService service,
    required WriteBatch batch,
    required String projectId,
    required String creatorId,
    required LogType type,
    required String action,
    required String note,
    String actor = 'System',
    double? amount,
    String? reason,
  }) {
    final log = LogEvent(
      id: 'log_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      action: action,
      note: note,
      timestamp: DateTime.now(),
      actor: actor,
      amount: amount,
      reason: reason,
    );

    final projectLogRef = service.getDocumentReference(
      '${CloudPaths.projects}/$projectId/${CloudPaths.history}/${log.id}',
    );
    batch.set(projectLogRef, log.toMap());

    if (creatorId.isNotEmpty && creatorId != 'AGENCY') {
      final creatorLogRef = service.getDocumentReference(
        '${CloudPaths.creators}/$creatorId/${CloudPaths.history}/${log.id}',
      );
      batch.set(creatorLogRef, log.toMap());
    }
  }

  // ─── 2. TRANSACTION LOGGING ───
  /// Automatically writes the log to the Project's history using an atomic Transaction.
  /// If a specific Creator ID is provided, it also writes the log to the Creator's history.
  static void attachLogToTransaction({
    required FirestoreService service,
    required Transaction transaction,
    required String projectId,
    required String creatorId,
    required LogType type,
    required String action,
    required String note,
    String actor = 'System',
    double? amount,
    String? reason,
  }) {
    final log = LogEvent(
      id: 'log_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      action: action,
      note: note,
      timestamp: DateTime.now(),
      actor: actor,
      amount: amount,
      reason: reason,
    );

    final projectLogRef = service.getDocumentReference(
      '${CloudPaths.projects}/$projectId/${CloudPaths.history}/${log.id}',
    );
    transaction.set(projectLogRef, log.toMap());

    if (creatorId.isNotEmpty && creatorId != 'AGENCY') {
      final creatorLogRef = service.getDocumentReference(
        '${CloudPaths.creators}/$creatorId/${CloudPaths.history}/${log.id}',
      );
      transaction.set(creatorLogRef, log.toMap());
    }
  }


  // ─── 4. FETCHING LOGS ───
  static Future<List<LogEvent>> getProjectLogs(
    FirestoreService service,
    String projectId,
  ) async {
    try {
      return await service.getCollection(
        path: '${CloudPaths.projects}/$projectId/${CloudPaths.history}',
        queryBuilder: (q) => q.orderBy(CloudFields.timestamp, descending: true),
        builder: (d) => LogEvent.fromFirestore(d),
      );
    } catch (e) {
      debugPrint('!! Error fetching project logs: $e');
      rethrow;
    }
  }
}
