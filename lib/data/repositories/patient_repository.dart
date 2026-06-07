import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/firestore_paths.dart';
import '../models/patient.dart';

class PatientRepository {
  PatientRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(FirestorePaths.patients);

  Future<Patient> registerPatient({
    required String name,
    required String phone,
    required int age,
    required String generalHistory,
  }) async {
    if (name.trim().isEmpty) {
      throw ArgumentError('Patient name cannot be empty.');
    }
    if (age <= 0) {
      throw ArgumentError('Patient age must be a positive integer.');
    }
    final id = _uuid.v4();
    final patient = Patient(
      patientId: id,
      name: name.trim(),
      phone: phone.trim(),
      age: age,
      generalHistory: generalHistory.trim(),
      createdAt: DateTime.now(),
    );
    await _col.doc(id).set(patient.toJson());
    return patient;
  }

  Future<Patient?> getPatient(String patientId) async {
    final doc = await _col.doc(patientId).get();
    if (!doc.exists) return null;
    return Patient.fromFirestore(doc);
  }

  Stream<List<Patient>> searchByName(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return _col
          .orderBy('created_at', descending: true)
          .limit(50)
          .snapshots()
          .map((snap) => snap.docs.map(Patient.fromFirestore).toList());
    }

    final normalized = trimmed.toLowerCase();
    if (RegExp(r'^\d{3,}$').hasMatch(trimmed)) {
      return _col
          .where('phone', isEqualTo: trimmed)
          .limit(30)
          .snapshots()
          .map((snap) => snap.docs.map(Patient.fromFirestore).toList());
    }

    final end = '$normalized\uf8ff';
    return _col
        .orderBy('name_lowercase')
        .startAt([normalized])
        .endAt([end])
        .limit(30)
        .snapshots()
        .map((snap) => snap.docs.map(Patient.fromFirestore).toList());
  }
}
