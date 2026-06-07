import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class QueueEntry extends Equatable {
  const QueueEntry({
    required this.queueEntryId,
    required this.patientId,
    required this.patientName,
    required this.phone,
    required this.status,
    required this.createdAt,
    this.visitId,
  });

  final String queueEntryId;
  final String patientId;
  final String patientName;
  final String phone;
  final String status;
  final DateTime createdAt;
  final String? visitId;

  factory QueueEntry.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return QueueEntry.fromJson({...data, 'queue_entry_id': doc.id});
  }

  factory QueueEntry.fromJson(Map<String, dynamic> json) {
    return QueueEntry(
      queueEntryId: json['queue_entry_id'] as String? ?? '',
      patientId: json['patient_id'] as String? ?? '',
      patientName: json['patient_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      status: json['status'] as String? ?? 'waiting',
      createdAt: _parseDate(json['created_at']),
      visitId: json['visit_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'queue_entry_id': queueEntryId,
        'patient_id': patientId,
        'patient_name': patientName,
        'phone': phone,
        'status': status,
        'created_at': Timestamp.fromDate(createdAt),
        if (visitId != null) 'visit_id': visitId,
      };

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  @override
  List<Object?> get props =>
      [queueEntryId, patientId, patientName, phone, status, createdAt, visitId];
}
