import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';

import '../../../core/providers/providers.dart';
import '../../../data/models/financial_summary.dart';
import '../../auth/application/auth_controller.dart';

class FinanceRange {
  const FinanceRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

final financeRangeProvider = StateProvider<FinanceRange>((ref) {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, 1);
  return FinanceRange(start: start, end: now);
});

final financialSummaryProvider = StreamProvider<FinancialSummary>((ref) {
  final authState = ref.watch(authStateProvider);
  final range = ref.watch(financeRangeProvider);
  final invoiceRepo = ref.watch(invoiceRepositoryProvider);
  final expenseRepo = ref.watch(expenseRepositoryProvider);
  final aggregation = ref.watch(financialAggregationServiceProvider);

  // Security Guard: Prevent stream initialization for non-doctor accounts
  final user = authState.valueOrNull;
  
  // Type-safe check to avoid NoSuchMethodError on 'name' or other properties
  final bool hasDoctorAccess = user?.isDoctor ?? false;
  
  if (!hasDoctorAccess) {
    return Stream.error('Unauthorized: Financial access restricted to doctors.');
  }

  return Rx.combineLatest2(
    invoiceRepo.watchInvoicesInRange(start: range.start, end: range.end),
    expenseRepo.watchExpensesInRange(start: range.start, end: range.end),
    (invoices, expenses) => (invoices, expenses),
  ).asyncMap((tuple) async {
    return await aggregation.computeAsync(
      invoices: tuple.$1,
      expenses: tuple.$2,
      rangeStart: range.start,
      rangeEnd: range.end,
    );
  });
});
