import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Invoice extends Equatable {
  const Invoice({
    required this.invoiceId,
    required this.patientId,
    required this.amountPaid,
    required this.serviceType,
    required this.date,
  });

  final String invoiceId;
  final String patientId;
  final double amountPaid;
  final String serviceType;
  final DateTime date;

  factory Invoice.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Invoice.fromJson({...data, 'invoice_id': doc.id});
  }

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      invoiceId: json['invoice_id'] as String? ?? '',
      patientId: json['patient_id'] as String? ?? '',
      amountPaid: (json['amount_paid'] as num?)?.toDouble() ?? 0,
      serviceType: json['service_type'] as String? ?? '',
      date: _parseDate(json['date']),
    );
  }

  Map<String, dynamic> toJson() => {
        'invoice_id': invoiceId,
        'patient_id': patientId,
        'amount_paid': amountPaid,
        'service_type': serviceType,
        'date': Timestamp.fromDate(date),
      };

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  @override
  List<Object?> get props =>
      [invoiceId, patientId, amountPaid, serviceType, date];
}
