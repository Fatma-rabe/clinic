import 'dart:isolate';

import '../models/expense.dart';
import '../models/financial_summary.dart';
import '../models/invoice.dart';

/// Pure Dart aggregation for revenue, expenses, net profit, and daily peaks.
class FinancialAggregationService {
  Future<FinancialSummary> computeAsync({
    required List<Invoice> invoices,
    required List<Expense> expenses,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) async {
    return await Isolate.run(() {
      final totalRevenue =
          invoices.fold<double>(0, (sum, i) => sum + i.amountPaid);
      final totalExpenses =
          expenses.fold<double>(0, (sum, e) => sum + e.amount);
      final netProfit = totalRevenue - totalExpenses;

      final revenueByDay = <DateTime, double>{};
      for (final invoice in invoices) {
        final dayKey = DateTime(
          invoice.date.year,
          invoice.date.month,
          invoice.date.day,
        );
        revenueByDay[dayKey] = (revenueByDay[dayKey] ?? 0) + invoice.amountPaid;
      }

      DayRevenue? highest;
      DayRevenue? lowest;

      if (revenueByDay.isNotEmpty) {
        final entries = revenueByDay.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));

        var maxEntry = entries.first;
        var minEntry = entries.first;

        for (final entry in entries) {
          if (entry.value > maxEntry.value) maxEntry = entry;
          if (entry.value < minEntry.value) minEntry = entry;
        }

        highest = DayRevenue(date: maxEntry.key, amount: maxEntry.value);
        lowest = DayRevenue(date: minEntry.key, amount: minEntry.value);
      }

      return FinancialSummary(
        totalRevenue: totalRevenue,
        totalExpenses: totalExpenses,
        netProfit: netProfit,
        highestRevenueDay: highest,
        lowestRevenueDay: lowest,
        revenueByDay: revenueByDay,
      );
    });
  }
}
