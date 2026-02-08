import 'package:go_router/go_router.dart';
// lib/widgets/income_expense_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mudra_manager/providers/filter_provider.dart';
import 'package:mudra_manager/l10n/app_localizations.dart';
import 'package:mudra_manager/util/localization_extension.dart';

class IncomeExpenseCard extends ConsumerWidget {
  const IncomeExpenseCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(filteredDashboardTransactionsProvider);
    final ctxt = AppLocalizations.of(context)!;

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
                    Text(ctxt.dashboard_incomeLabel, style: Theme.of(context).textTheme.bodyLarge),
                    Text(
                      ctxt.formatCurrencyWithSign(2, income),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.teal),
                    ),
                    const SizedBox(height: 12),
                    Text(ctxt.dashboard_spentLabel, style: Theme.of(context).textTheme.bodyLarge),
                    Text(
                      ctxt.formatCurrencyWithSign(2, expense),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.redAccent),
                    ),
                  ],
                ),
              ),

              // Right side: Pie chart
              Expanded(
                flex: 3,
                child: total == 0
                    ? Center(child: Text(ctxt.dashboard_noDataLabel))
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
