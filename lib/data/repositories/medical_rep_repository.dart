import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/firestore_paths.dart';
import '../models/medical_rep.dart';

class MedicalRepRepository {
  MedicalRepRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(FirestorePaths.medicalReps);

  Future<MedicalRep> logVisit({
    required String repName,
    required String companyName,
    required String notes,
    DateTime? visitDate,
  }) async {
    final id = _uuid.v4();
    final rep = MedicalRep(
      repId: id,
      repName: repName.trim(),
      companyName: companyName.trim(),
      visitDate: visitDate ?? DateTime.now(),
      notes: notes.trim(),
    );
    await _col.doc(id).set(rep.toJson());
    return rep;
  }

  Stream<List<MedicalRep>> watchRecent({int limit = 50}) {
    return _col
        .orderBy('visit_date', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(MedicalRep.fromFirestore).toList());
  }
}
