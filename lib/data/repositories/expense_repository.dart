import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/firestore_paths.dart';
import '../models/expense.dart';

class ExpenseRepository {
  ExpenseRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(FirestorePaths.expenses);

  Future<Expense> logExpense({
    required String title,
    required double amount,
  }) async {
    final id = _uuid.v4();
    final expense = Expense(
      expenseId: id,
      title: title.trim(),
      amount: amount,
      date: DateTime.now(),
    );
    await _col.doc(id).set(expense.toJson());
    return expense;
  }

  Stream<List<Expense>> watchExpensesInRange({
    required DateTime start,
    required DateTime end,
  }) {
    return _col
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('date')
        .snapshots()
        .map((snap) => snap.docs.map(Expense.fromFirestore).toList());
  }
}
