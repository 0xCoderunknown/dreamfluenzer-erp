import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/firestore_constants.dart';
import '../domain/app_enums.dart';
import '../models/lead_model.dart';
import '../services/firestore_service.dart';

class LeadProvider extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();

  List<Lead> _leads = [];
  StreamSubscription? _subscription;

  bool _isLoading = true;
  String? _error;

  List<Lead> get leads => List.unmodifiable(_leads);

  bool get isLoading => _isLoading;

  String? get error => _error;

  LeadProvider() {
    _initLeadStream();
  }

  void _initLeadStream() {
    // ─── TITANIUM REFACTOR: Using Service Stream ───
    _subscription = _service
        .streamCollection(
          path: CloudPaths.leads,
          builder: (doc) => Lead.fromFirestore(doc),
        )
        .listen(
          (list) {
            _leads = list;
            _isLoading = false;
            _error = null;
            notifyListeners();
          },
          onError: (err) {
            _handleError("Lead Sync Error", err);
            _isLoading = false;
          },
        );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  // ─── TITANIUM CRUD ───

  Future<void> addLead(Lead lead) async {
    try {
      final finalLead = lead.id.isEmpty
          ? lead.copyWith(id: _service.generateId(CloudPaths.leads))
          : lead;
      // ─── TITANIUM REFACTOR: Using Service Write ───
      await _service.setData(
        path: '${CloudPaths.leads}/${finalLead.id}',
        data: finalLead.toMap(),
      );
    } catch (e) {
      _handleError("Add Lead Failed", e);
      rethrow;
    }
  }

  /// Updates status using the strict LeadStatus Enum
  Future<void> updateLeadStatus(String id, LeadStatus newStatus) async {
    try {
      // ─── TITANIUM REFACTOR: Using Service Update ───
      await _service.updateData(
        path: '${CloudPaths.leads}/$id',
        data: {'status': newStatus.value},
      );
    } catch (e) {
      _handleError("Update Lead Status Failed", e);
      rethrow;
    }
  }

  Future<void> updateLeadDetails(Lead lead) async {
    try {
      // ─── TITANIUM REFACTOR: Using Service Update ───
      await _service.updateData(
        path: '${CloudPaths.leads}/${lead.id}',
        data: lead.toMap(),
      );
    } catch (e) {
      _handleError("Update Lead Details Failed", e);
      rethrow;
    }
  }

  /// Deep-Delete: Targeted query eliminates orphan data footprints efficiently without local memory spamming
  Future<void> deleteLead(String id) async {
    try {
      final batch = _service.batch;

      final targetedProposals = await _service.getCollection(
        path: CloudPaths.proposals,
        queryBuilder: (query) => query.where('lead_id', isEqualTo: id),
        builder: (doc) =>
            _service.getDocumentReference('${CloudPaths.proposals}/${doc.id}'),
      );

      for (var ref in targetedProposals) {
        batch.delete(ref);
      }

      batch.delete(_service.getDocumentReference('${CloudPaths.leads}/$id'));

      await batch.commit();
    } catch (e) {
      _handleError("Delete Lead Failed", e);
      rethrow;
    }
  }

  // ─── UTILITY ───
  void _handleError(String context, dynamic e) {
    debugPrint("!! LEAD ERROR [$context]: $e");
    _error = e.toString();
    notifyListeners();
  }
}
