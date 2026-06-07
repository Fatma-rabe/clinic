import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Patient extends Equatable {
  const Patient({
    required this.patientId,
    required this.name,
    required this.phone,
    required this.age,
    required this.generalHistory,
    required this.createdAt,
  });

  final String patientId;
  final String name;
  final String phone;
  final int age;
  final String generalHistory;
  final DateTime createdAt;

  factory Patient.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Patient.fromJson({...data, 'patient_id': doc.id});
  }

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      patientId: json['patient_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      age: (json['age'] as num?)?.toInt() ?? 0,
      generalHistory: json['general_history'] as String? ?? '',
      createdAt: _parseDate(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'patient_id': patientId,
        'name': name,
        'name_lowercase': name.toLowerCase(),
        'phone': phone,
        'age': age,
        'general_history': generalHistory,
        'created_at': Timestamp.fromDate(createdAt),
      };

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  @override
  List<Object?> get props =>
      [patientId, name, phone, age, generalHistory, createdAt];
}
