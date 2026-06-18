import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Visit extends Equatable {
  const Visit({
    required this.visitId,
    required this.date,
    required this.diagnosis,
    required this.prescriptionText,
    required this.xRayUrl,
    this.selectedDrugs = const [],
  });

  final String visitId;
  final DateTime date;
  final String diagnosis;
  final String prescriptionText;
  final String xRayUrl;
  final List<String> selectedDrugs;

  bool get hasXray => xRayUrl.isNotEmpty;

  factory Visit.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Visit.fromJson({...data, 'visit_id': doc.id});
  }

  factory Visit.fromJson(Map<String, dynamic> json) {
    return Visit(
      visitId: json['visit_id'] as String? ?? '',
      date: _parseDate(json['date']),
      diagnosis: json['diagnosis'] as String? ?? '',
      prescriptionText: json['prescription_text'] as String? ?? '',
      xRayUrl: json['x_ray_url'] as String? ?? '',
      selectedDrugs: (json['selected_drugs'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'visit_id': visitId,
        'date': Timestamp.fromDate(date),
        'diagnosis': diagnosis,
        'prescription_text': prescriptionText,
        'x_ray_url': xRayUrl,
        'selected_drugs': selectedDrugs,
      };

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  @override
  List<Object?> get props =>
      [visitId, date, diagnosis, prescriptionText, xRayUrl, selectedDrugs];
}
