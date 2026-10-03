import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/firestore_constants.dart';
import '../domain/app_enums.dart';
import '../models/proposal_model.dart';
import '../services/firestore_service.dart';

class ProposalProvider extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();

  List<Proposal> _proposals = [];
  StreamSubscription? _subscription;

  bool _isLoading = true;
  String? _error;

  List<Proposal> get proposals => List.unmodifiable(_proposals);

  bool get isLoading => _isLoading;

  String? get error => _error;

  ProposalProvider() {
    _initProposalStream();
  }

  void _initProposalStream() {
    _subscription = _service
        .streamCollection(
          path: CloudPaths.proposals,
          queryBuilder: (query) =>
              query.orderBy('created_at', descending: true),
          builder: (doc) => Proposal.fromFirestore(doc),
        )
        .listen(
          (snapshot) {
            _proposals = snapshot;
            _isLoading = false;
            _error = null;
            notifyListeners();
          },
          onError: (err) {
            _handleError("Proposal Sync Failed", err);
            _isLoading = false;
          },
        );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  // ─── SEARCH & UTILITY ───

  List<Proposal> getProposalsForLead(String leadId) {
    return _proposals.where((p) => p.leadId == leadId).toList();
  }

  Proposal? findById(String id) {
    return _proposals.where((c) => c.id == id).firstOrNull;
  }

  // ─── TITANIUM CRUD OPERATIONS ───

  Future<void> addProposal(Proposal proposal) async {
    try {
      await _service.setData(
        path: '${CloudPaths.proposals}/${proposal.id}',
        data: proposal.toMap(),
      );
    } catch (e) {
      _handleError("Add Proposal", e);
      rethrow;
    }
  }

  Future<void> updateProposal(Proposal proposal) async {
    try {
      await _service.updateData(
        path: '${CloudPaths.proposals}/${proposal.id}',
        data: proposal.toMap(),
      );
    } catch (e) {
      _handleError("Update Proposal", e);
      rethrow;
    }
  }

  Future<void> updateProposalStatus(String id, ProposalStatus newStatus) async {
    try {
      await _service.updateData(
        path: '${CloudPaths.proposals}/$id',
        data: {CloudFields.status: newStatus.value},
      );
    } catch (e) {
      _handleError("Status Update", e);
      rethrow;
    }
  }

  Future<void> deleteProposal(String id) async {
    try {
      await _service.deleteData('${CloudPaths.proposals}/$id');
    } catch (e) {
      _handleError("Delete Proposal", e);
      rethrow;
    }
  }

  void _handleError(String context, dynamic e) {
    debugPrint("!! PROPOSAL ERROR [$context]: $e");
    _error = e.toString();
    notifyListeners();
  }
}
