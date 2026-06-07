import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/firestore_paths.dart';
import '../models/appointment.dart';

class AppointmentRepository {
  AppointmentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(FirestorePaths.appointments);

  Future<Appointment> createAppointment({
    required String patientId,
    required String doctorId,
    required DateTime startTime,
    required DateTime endTime,
    String status = 'scheduled',
  }) async {
    if (!endTime.isAfter(startTime)) {
      throw ArgumentError('Appointment end time must be after start time.');
    }

    final isOverlap = await hasOverlappingAppointment(
      doctorId: doctorId,
      startTime: startTime,
      endTime: endTime,
    );
    if (isOverlap) {
      throw StateError('Doctor already has an overlapping appointment.');
    }

    final id = _uuid.v4();
    final appointment = Appointment(
      appointmentId: id,
      patientId: patientId,
      doctorId: doctorId,
      startTime: startTime,
      endTime: endTime,
      status: status,
      createdAt: DateTime.now(),
    );
    await _col.doc(id).set(appointment.toJson());
    return appointment;
  }

  Future<bool> hasOverlappingAppointment({
    required String doctorId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    // Query for appointments for this doctor that start before the new one ends
    // and are not cancelled.
    // Optimized: Only check appointments within a reasonable window (e.g., same day)
    final dayStart = DateTime(startTime.year, startTime.month, startTime.day);
    final query = await _col
        .where('doctor_id', isEqualTo: doctorId)
        .where('status', isNotEqualTo: 'cancelled')
        .where('start_time', isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
        .where('start_time', isLessThan: Timestamp.fromDate(endTime))
        .orderBy('start_time')
        .get();

    return query.docs.any((doc) {
      final appointment = Appointment.fromFirestore(doc);
      // Overlap exists if existing appointment ends after the new one starts
      return appointment.endTime.isAfter(startTime);
    });
  }

  Stream<List<Appointment>> watchAppointmentsForDoctor(String doctorId) {
    return _col
        .where('doctor_id', isEqualTo: doctorId)
        .orderBy('start_time')
        .snapshots()
        .map((snap) => snap.docs.map(Appointment.fromFirestore).toList());
  }
}
