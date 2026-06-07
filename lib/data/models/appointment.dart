import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Appointment extends Equatable {
  const Appointment({
    required this.appointmentId,
    required this.patientId,
    required this.doctorId,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.createdAt,
  });

  final String appointmentId;
  final String patientId;
  final String doctorId;
  final DateTime startTime;
  final DateTime endTime;
  final String status;
  final DateTime createdAt;

  factory Appointment.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Appointment.fromJson({...data, 'appointment_id': doc.id});
  }

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      appointmentId: json['appointment_id'] as String? ?? '',
      patientId: json['patient_id'] as String? ?? '',
      doctorId: json['doctor_id'] as String? ?? '',
      startTime: _parseDate(json['start_time']),
      endTime: _parseDate(json['end_time']),
      status: json['status'] as String? ?? 'scheduled',
      createdAt: _parseDate(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'appointment_id': appointmentId,
        'patient_id': patientId,
        'doctor_id': doctorId,
        'start_time': Timestamp.fromDate(startTime),
        'end_time': Timestamp.fromDate(endTime),
        'status': status,
        'created_at': Timestamp.fromDate(createdAt),
      };

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  @override
  List<Object?> get props => [
        appointmentId,
        patientId,
        doctorId,
        startTime,
        endTime,
        status,
        createdAt,
      ];
}
