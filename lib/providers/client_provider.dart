import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/firestore_constants.dart';
import '../models/client_model.dart';
import '../services/firestore_service.dart';

class ClientProvider extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();

  List<Client> _clients = [];
  StreamSubscription? _subscription;

  // ─── STATE MANAGEMENT ───
  bool _isLoading = true;
  String? _error;

  List<Client> get clients => List.unmodifiable(_clients);

  bool get isLoading => _isLoading;

  String? get error => _error;

  ClientProvider() {
    _initClientStream();
  }

  void _initClientStream() {
    _isLoading = true;
    _subscription = _service
        .streamCollection(
          path: CloudPaths.clients,
          queryBuilder: (query) => query.orderBy('business_name'),
          builder: (doc) => Client.fromFirestore(doc),
        )
        .listen(
          (list) {
            _clients = list;
            _isLoading = false;
            _error = null;
            notifyListeners();
          },
          onError: (err) {
            _error = "Failed to sync clients: $err";
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

  // ─── TITANIUM CRUD OPERATIONS ───

  Future<void> addClient(Client client) async {
    try {
      await _service.setData(
        path: '${CloudPaths.clients}/${client.id}',
        data: client.toMap(),
      );
    } catch (e) {
      _handleError("Add Client Failed", e);
      rethrow;
    }
  }

  Future<void> updateClient(Client updatedClient) async {
    try {
      await _service.updateData(
        path: '${CloudPaths.clients}/${updatedClient.id}',
        data: updatedClient.toMap(),
      );
    } catch (e) {
      _handleError("Update Client Failed", e);
      rethrow;
    }
  }

  Future<void> deleteClient(String id) async {
    try {
      // ─── TITANIUM ANTI-ORPHAN GUARD ───
      final projectCheck = await _service.getCollection(
        path: CloudPaths.projects,
        queryBuilder: (query) =>
            query.where('client_id', isEqualTo: id).limit(1),
        builder: (doc) => doc,
      );

      if (projectCheck.isNotEmpty) {
        throw Exception(
          "Cannot delete this client because they have existing projects. "
          "Please delete or reassign their projects first.",
        );
      }

      await _service.deleteData('${CloudPaths.clients}/$id');
    } catch (e) {
      _handleError("Delete Client Failed", e);
      rethrow;
    }
  }

  // ─── SEARCH & UTILITY ───

  Client? findById(String id) {
    return _clients.where((c) => c.id == id).firstOrNull;
  }

  void _handleError(String context, dynamic e) {
    debugPrint("!! ERROR [$context]: $e");
    _error = e.toString();
    notifyListeners();
  }
}
