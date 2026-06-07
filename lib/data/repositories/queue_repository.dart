import 'package:cloud_firestore/cloud_firestore.dart';


import '../../core/constants/app_constants.dart';
import '../../core/constants/firestore_paths.dart';
import '../models/queue_entry.dart';

/// Real-time live queue using Firestore [Query.snapshots].
class QueueRepository {
  QueueRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(FirestorePaths.liveQueue);

  /// Active queue stream — fetches all and filters client-side for active statuses.
  Stream<List<QueueEntry>> watchLiveQueue() {
    try {
      return _col
          .where('status', whereIn: [
            AppConstants.queueStatusWaiting,
            AppConstants.queueStatusInConsultation,
          ])
          .orderBy('created_at', descending: false)
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map(QueueEntry.fromFirestore).toList());
    } catch (e) {
      // Fallback for missing indexes or permission issues
      return Stream.error('Failed to fetch queue. Ensure Firestore indexes are deployed. Error: $e');
    }
  }

  Future<QueueEntry> addToQueue({
    required String patientId,
    required String patientName,
    required String phone,
    String? visitId,
  }) async {
    final id = patientId;
    final queueEntry = QueueEntry(
      queueEntryId: id,
      patientId: patientId,
      patientName: patientName,
      phone: phone,
      status: AppConstants.queueStatusWaiting,
      createdAt: DateTime.now(),
      visitId: visitId,
    );

    final data = queueEntry.toJson();
    data['created_at'] = FieldValue.serverTimestamp();

    final docRef = _col.doc(id);
    await docRef.set(data, SetOptions(merge: true));
    final savedDoc = await docRef.get();
    return QueueEntry.fromFirestore(savedDoc);
  }

  Future<void> updateStatus(String queueEntryId, String status) async {
    await _col.doc(queueEntryId).update({'status': status});
  }

  Future<void> completeEntry(String queueEntryId) async {
    await updateStatus(queueEntryId, AppConstants.queueStatusCompleted);
  }
}
