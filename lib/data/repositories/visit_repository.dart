import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/firestore_paths.dart';
import '../../core/services/image_compress_service.dart';
import '../models/visit.dart';

class VisitRepository {
  VisitRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    ImageCompressService? compressService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _compress = compressService ?? ImageCompressService();

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final ImageCompressService _compress;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> _visitsCol(String patientId) =>
      _firestore
          .collection(FirestorePaths.patients)
          .doc(patientId)
          .collection(FirestorePaths.visits);

  Stream<List<Visit>> watchVisits(String patientId) {
    return _visitsCol(patientId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Visit.fromFirestore).toList());
  }

  Future<Visit> createVisit({
    required String patientId,
    String diagnosis = '',
    String prescriptionText = '',
  }) async {
    final visitId = _uuid.v4();
    final visit = Visit(
      visitId: visitId,
      date: DateTime.now(),
      diagnosis: diagnosis,
      prescriptionText: prescriptionText,
      xRayUrl: '',
      selectedDrugs: const [],
    );
    await _visitsCol(patientId).doc(visitId).set(visit.toJson());
    return visit;
  }

  Future<void> updateVisit({
    required String patientId,
    required String visitId,
    String? diagnosis,
    String? prescriptionText,
    String? xRayUrl,
    List<String>? selectedDrugs,
  }) async {
    final updates = <String, dynamic>{};
    if (diagnosis != null) updates['diagnosis'] = diagnosis;
    if (prescriptionText != null) {
      updates['prescription_text'] = prescriptionText;
    }
    if (xRayUrl != null) updates['x_ray_url'] = xRayUrl;
    if (selectedDrugs != null) updates['selected_drugs'] = selectedDrugs;
    if (updates.isEmpty) return;
    await _visitsCol(patientId).doc(visitId).update(updates);
  }

  /// Compresses image, uploads to Storage, returns download URL saved to visit.
  Future<String> uploadXray({
    required String patientId,
    required String visitId,
    required Uint8List imageBytes,
  }) async {
    final compressed = await _compress.compressXray(imageBytes);
    final fileName = 'xray_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = FirestorePaths.xrayStoragePath(patientId, visitId, fileName);
    final ref = _storage.ref().child(path);
    await ref.putData(
      compressed,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    final url = await ref.getDownloadURL();
    await updateVisit(patientId: patientId, visitId: visitId, xRayUrl: url);
    return url;
  }
}
