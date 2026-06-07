import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Expense extends Equatable {
  const Expense({
    required this.expenseId,
    required this.title,
    required this.amount,
    required this.date,
  });

  final String expenseId;
  final String title;
  final double amount;
  final DateTime date;

  factory Expense.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Expense.fromJson({...data, 'expense_id': doc.id});
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      expenseId: json['expense_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      date: _parseDate(json['date']),
    );
  }

  Map<String, dynamic> toJson() => {
        'expense_id': expenseId,
        'title': title,
        'amount': amount,
        'date': Timestamp.fromDate(date),
      };

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  @override
  List<Object?> get props => [expenseId, title, amount, date];
}
