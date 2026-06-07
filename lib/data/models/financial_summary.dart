import 'package:equatable/equatable.dart';

/// Client-side aggregation result for the doctor financial dashboard.
class FinancialSummary extends Equatable {
  const FinancialSummary({
    required this.totalRevenue,
    required this.totalExpenses,
    required this.netProfit,
    required this.highestRevenueDay,
    required this.lowestRevenueDay,
    required this.revenueByDay,
  });

  final double totalRevenue;
  final double totalExpenses;
  final double netProfit;
  final DayRevenue? highestRevenueDay;
  final DayRevenue? lowestRevenueDay;
  final Map<DateTime, double> revenueByDay;

  @override
  List<Object?> get props => [
        totalRevenue,
        totalExpenses,
        netProfit,
        highestRevenueDay,
        lowestRevenueDay,
        revenueByDay,
      ];
}

class DayRevenue extends Equatable {
  const DayRevenue({required this.date, required this.amount});

  final DateTime date;
  final double amount;

  @override
  List<Object?> get props => [date, amount];
}
