import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ===========================================================================
  // 1. IDENTITY & ATOMIC TRANSACTION ENGINES
  // ===========================================================================

  /// Generates a unique ID for a collection without saving.
  String generateId(String collectionPath) =>
      _db.collection(collectionPath).doc().id;

  /// Returns a native DocumentReference needed for Batch operations.
  DocumentReference getDocumentReference(String path) => _db.doc(path);

  /// Provides a fresh WriteBatch for atomic operations.
  WriteBatch get batch => _db.batch();

  // ===========================================================================
  // 2. READ OPERATIONS (STREAMS & FUTURES)
  // ===========================================================================

  /// Streams a collection with an optional queryBuilder for sorting/filtering.
  Stream<List<T>> streamCollection<T>({
    required String path,
    required T Function(DocumentSnapshot doc) builder,
    Query Function(Query query)? queryBuilder,
  }) {
    Query query = _db.collection(path);
    if (queryBuilder != null) query = queryBuilder(query);

    return query.snapshots().map(
      (snap) => snap.docs.map((doc) => builder(doc)).toList(),
    );
  }

  /// Streams a collectionGroup (essential for sub-collection campaigns).
  Stream<List<T>> streamCollectionGroup<T>({
    required String collectionId,
    required T Function(DocumentSnapshot doc) builder,
    Query Function(Query query)? queryBuilder,
  }) {
    Query query = _db.collectionGroup(collectionId);
    if (queryBuilder != null) query = queryBuilder(query);

    return query.snapshots().map(
      (snap) => snap.docs.map((doc) => builder(doc)).toList(),
    );
  }

  /// Fetches a collection once (useful for "Deep Delete" lookups).
  Future<List<T>> getCollection<T>({
    required String path,
    required T Function(DocumentSnapshot doc) builder,
    Query Function(Query query)? queryBuilder,
  }) async {
    Query query = _db.collection(path);
    if (queryBuilder != null) query = queryBuilder(query);

    final snap = await query.get();
    return snap.docs.map((doc) => builder(doc)).toList();
  }

  // ===========================================================================
  // 3. WRITE OPERATIONS
  // ===========================================================================

  /// Sets data at a path. Uses merge: true by default to prevent data loss.
  Future<void> setData({
    required String path,
    required Map<String, dynamic> data,
    bool merge = true,
  }) => _db.doc(path).set(data, SetOptions(merge: merge));

  /// Updates existing data. Fails if the document doesn't exist.
  Future<void> updateData({
    required String path,
    required Map<String, dynamic> data,
  }) => _db.doc(path).update(data);

  /// Deletes a single document.
  Future<void> deleteData(String path) => _db.doc(path).delete();
}
