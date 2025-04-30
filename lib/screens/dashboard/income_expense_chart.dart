// lib/widgets/income_expense_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mudra_manager/providers/filter_provider.dart';

class IncomeExpenseCard extends ConsumerWidget {
  const IncomeExpenseCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(filteredDashboardTransactionsProvider);

    return summary.when(
        data: (data) {
      final income = data['income'] ?? 0.0;
      final expense = data['expense'] ?? 0.0;
      final total = income + expense;

      return Card.outlined(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 3,
        // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Left side: Income & Expense
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Income', style: Theme.of(context).textTheme.bodyLarge),
                    Text(
                      '₹${income.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.teal),
                    ),
                    const SizedBox(height: 12),
                    Text('Spent', style: Theme.of(context).textTheme.bodyLarge),
                    Text(
                      '₹${expense.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.redAccent),
                    ),
                  ],
                ),
              ),

              // Right side: Pie chart
              Expanded(
                flex: 3,
                child: total == 0
                    ? const Center(child: Text('No data'))
                    : SizedBox(
                  height: 120,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          color: Colors.teal,
                          value: income,
                          showTitle: false,
                          radius: 50,
                        ),
                        PieChartSectionData(
                          color: Colors.redAccent,
                          value: expense,
                          showTitle: false,
                          radius: 50,
                        ),
                      ],
                      centerSpaceRadius: 30,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (e, _) => Center(child: Text("Error: $e")),
    );
  }
}
