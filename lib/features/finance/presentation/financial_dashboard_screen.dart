import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/responsive.dart';
import '../../../data/models/financial_summary.dart';
import '../../auth/application/auth_controller.dart';
import '../application/finance_controller.dart';

class FinancialDashboardScreen extends ConsumerWidget {
  const FinancialDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);
    final range = ref.watch(financeRangeProvider);
    final summaryAsync = ref.watch(financialSummaryProvider);
    final currency = NumberFormat.currency(symbol: '\$');

    return authAsync.when(
      data: (user) {
        if (user == null || !user.isDoctor) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Financial Dashboard'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline, size: 64, color: Colors.redAccent),
                    const SizedBox(height: 16),
                    Text(
                      'Access Denied',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Only doctors may view financial reports.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Financial Dashboard'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
          ),
          body: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: Responsive.contentMaxWidth(context),
                  minHeight: MediaQuery.of(context).size.height - 120,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _DateRangePicker(
                        start: range.start,
                        end: range.end,
                        onChanged: (start, end) {
                          ref.read(financeRangeProvider.notifier).state =
                              FinanceRange(start: start, end: end);
                        },
                      ),
                      const SizedBox(height: 24),
                      summaryAsync.when(
                        data: (summary) {
                          return GridView.count(
                            crossAxisCount:
                                Responsive.isDesktop(context) ? 3 : 1,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 1.8,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              _MetricCard(
                                title: 'Total Revenue',
                                value: currency.format(summary.totalRevenue),
                                icon: Icons.trending_up,
                                color: Colors.teal,
                              ),
                              _MetricCard(
                                title: 'Total Expenses',
                                value: currency.format(summary.totalExpenses),
                                icon: Icons.trending_down,
                                color: Colors.orange,
                              ),
                              _MetricCard(
                                title: 'Net Profit',
                                value: currency.format(summary.netProfit),
                                icon: Icons.account_balance_wallet,
                                color: summary.netProfit >= 0
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              _PeakCard(
                                title: 'Highest Revenue Day',
                                day: summary.highestRevenueDay,
                                currency: currency,
                              ),
                              _PeakCard(
                                title: 'Lowest Revenue Day',
                                day: summary.lowestRevenueDay,
                                currency: currency,
                              ),
                            ],
                          );
                        },
                        loading: () => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 48),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (e, _) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 48),
                          child: Center(child: Text('Error: $e')),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error loading user: $e')),
      ),
    );
  }
}
class _DateRangePicker extends StatelessWidget {
  const _DateRangePicker({
    required this.start,
    required this.end,
    required this.onChanged,
  });

  final DateTime start;
  final DateTime end;
  final void Function(DateTime start, DateTime end) onChanged;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat.yMMMd();
    return Wrap(
      spacing: 12,
      children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.calendar_today),
          label: Text('From: ${fmt.format(start)}'),
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: start,
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) onChanged(picked, end);
          },
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.calendar_today),
          label: Text('To: ${fmt.format(end)}'),
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: end,
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) onChanged(start, picked);
          },
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.05),
            color.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const Spacer(),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.grey[700],
                    letterSpacing: 0.2,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: 0.3,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _PeakCard extends StatelessWidget {
  const _PeakCard({
    required this.title,
    required this.day,
    required this.currency,
  });

  final String title;
  final DayRevenue? day;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final dateStr =
        day != null ? DateFormat.yMMMd().format(day!.date) : '—';
    final amountStr = day != null ? currency.format(day!.amount) : '—';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [
            Color(0xFF2D6A4F).withValues(alpha: 0.05),
            Color(0xFF2D6A4F).withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Color(0xFF2D6A4F).withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF2D6A4F).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFF2D6A4F).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.trending_up,
                color: Color(0xFF2D6A4F),
                size: 32,
              ),
            ),
            const Spacer(),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.grey[700],
                    letterSpacing: 0.2,
                  ),
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2D6A4F),
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  amountStr,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2D6A4F),
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
