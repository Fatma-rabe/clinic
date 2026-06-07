import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class MedicalRep extends Equatable {
  const MedicalRep({
    required this.repId,
    required this.repName,
    required this.companyName,
    required this.visitDate,
    required this.notes,
  });

  final String repId;
  final String repName;
  final String companyName;
  final DateTime visitDate;
  final String notes;

  factory MedicalRep.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return MedicalRep.fromJson({...data, 'rep_id': doc.id});
  }

  factory MedicalRep.fromJson(Map<String, dynamic> json) {
    return MedicalRep(
      repId: json['rep_id'] as String? ?? '',
      repName: json['rep_name'] as String? ?? '',
      companyName: json['company_name'] as String? ?? '',
      visitDate: _parseDate(json['visit_date']),
      notes: json['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'rep_id': repId,
        'rep_name': repName,
        'company_name': companyName,
        'visit_date': Timestamp.fromDate(visitDate),
        'notes': notes,
      };

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  @override
  List<Object?> get props => [repId, repName, companyName, visitDate, notes];
}
