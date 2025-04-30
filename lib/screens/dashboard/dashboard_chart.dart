import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/providers/transaction_provider.dart'
    show filteredTransactionProvider;

class ExpenseChartScreen extends ConsumerStatefulWidget {
  const ExpenseChartScreen({super.key});

  @override
  ConsumerState<ExpenseChartScreen> createState() => _ExpenseChartScreenState();
}

class _ExpenseChartScreenState extends ConsumerState<ExpenseChartScreen> {
  String selectedFilter = 'Month';
  DateTime selectedDate = DateTime.now();

  String get formattedDateRange {
    if (selectedFilter == 'Week') {
      final start = selectedDate.subtract(
        Duration(days: selectedDate.weekday - 1),
      );
      final end = start.add(const Duration(days: 6));
      return "${_formatDate(start)} - ${_formatDate(end)}";
    } else if (selectedFilter == 'Month') {
      final start = DateTime(selectedDate.year, selectedDate.month, 1);
      final end = DateTime(selectedDate.year, selectedDate.month + 1, 0);
      return "${_formatDate(start)} - ${_formatDate(end)}";
    } else if (selectedFilter == 'Year') {
      return "${selectedDate.year}";
    } else {
      return "All Time";
    }
  }

  String _formatDate(DateTime date) {
    return "${_monthName(date.month)} ${date.day}";
  }

  String _monthName(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month];
  }

  void _pickDateRange() async {
    if (selectedFilter == 'Week') {
      final picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(2022),
        lastDate: DateTime(2100),
      );
      if (picked != null) setState(() => selectedDate = picked);
    } else if (selectedFilter == 'Month') {
      final picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(2022),
        lastDate: DateTime(2100),
        initialDatePickerMode: DatePickerMode.year,
      );
      if (picked != null) setState(() => selectedDate = picked);
    } else {
      final picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(2022),
        lastDate: DateTime(2100),
        initialDatePickerMode: DatePickerMode.year,
      );
      if (picked != null) setState(() => selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncTransactions = ref.watch(filteredTransactionProvider('all'));
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GestureDetector(
                onTap: _pickDateRange,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // const Icon(Icons.arrow_back_ios),
                    Column(
                      children: [
                        Text(
                          formattedDateRange,
                          style: textTheme.titleMedium?.copyWith(
                            color: color.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                    // const Icon(Icons.arrow_forward_ios),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: asyncTransactions.when(
                data: (transactions) {
                  var grouped = <String, Map<String, double>>{};

                  for (final txn in transactions) {
                    String label;
                    if (selectedFilter == 'Week') {
                      final startOfWeek = selectedDate.subtract(
                        Duration(days: selectedDate.weekday - 1),
                      );
                      final endOfWeek = startOfWeek.add(
                        const Duration(days: 6),
                      );
                      if (txn.date.isBefore(startOfWeek) ||
                          txn.date.isAfter(endOfWeek)) {
                        continue;
                      }
                      label = DateFormat('E').format(txn.date);
                    } else if (selectedFilter == 'Month') {
                      if (txn.date.month != selectedDate.month ||
                          txn.date.year != selectedDate.year) {
                        continue;
                      }
                      label = DateFormat('d').format(txn.date);
                    } else if (selectedFilter == 'Year') {
                      if (txn.date.year != selectedDate.year) continue;
                      label = DateFormat('MMM').format(txn.date);
                    } else {
                      label = txn.date.year.toString();
                    }

                    grouped[label] ??= {'income': 0, 'expense': 0};
                    if (txn.isExpense) {
                      grouped[label]!['expense'] =
                          grouped[label]!['expense']! + txn.amount;
                    } else {
                      grouped[label]!['income'] =
                          grouped[label]!['income']! + txn.amount;
                    }
                  }

                  final keys = grouped.keys.toList()..sort();

                  final barGroups = List.generate(keys.length, (i) {
                    final data = grouped[keys[i]]!;
                    return BarChartGroupData(
                      x: i,
                      groupVertically: false,
                      barRods: [
                        BarChartRodData(
                          toY: data['income']!,
                          gradient: LinearGradient(
                            colors: [Colors.greenAccent, Colors.green],
                            stops: const [0.1, 0.9],
                          ),
                          width: 10,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        BarChartRodData(
                          toY: data['expense']!,
                          gradient: LinearGradient(
                            colors: [Colors.redAccent, Colors.red],
                            stops: const [0.1, 0.9],
                          ),
                          width: 10,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                      showingTooltipIndicators: [0, 1],
                    );
                  });
                  final allValues =
                      grouped.values.expand((e) => e.values).toList();
                  final maxY =
                      allValues.isNotEmpty
                          ? allValues.reduce((a, b) => a > b ? a : b) + 100
                          : 100.0;

                  final bottomTitles =
                      grouped.keys
                          .map(
                            (date) => DateFormat('d MMM').format(selectedDate),
                          )
                          .toList();
                  getTitlesWidget:
                  (value, meta) {
                    int index = value.toInt();
                    if (index >= 0 && index < bottomTitles.length) {
                      return Text(
                        bottomTitles[index],
                        style: const TextStyle(fontSize: 10),
                      );
                    } else {
                      return const Text('');
                    }
                  };

                  if (grouped.isEmpty) {
                    // fallback to a single group to avoid RangeError
                    grouped = {
                      DateFormat('d MMM').format(DateTime.now()): {
                        'all': 0.0,
                        'income': 0.0,
                        'expense': 0.0,
                      },
                    };
                  }

                  return BarChart(
                    BarChartData(
                      barTouchData: BarTouchData(
                        enabled: false,
                        touchTooltipData: BarTouchTooltipData(
                          tooltipBgColor: Colors.transparent,
                          tooltipPadding: EdgeInsets.zero,
                          tooltipMargin: 0,
                          getTooltipItem:
                              (_, __, ___, ____) => null, // Hide tooltip
                        ),
                      ),
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY,
                      barGroups: barGroups,
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 200,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '₹${value.toInt()}',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: color.onPrimaryContainer,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 && index < keys.length) {
                                return Text(
                                  keys[index].toString(),
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: color.onPrimaryContainer,
                                  ),
                                );
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(show: true),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text("Error: $e")),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTimeFilterButton('Week'),
                  _buildTimeFilterButton('Month'),
                  _buildTimeFilterButton('Year'),
                  _buildTimeFilterButton('All'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeFilterButton(String title) {
    var color = Theme.of(context).colorScheme;
    final isSelected = selectedFilter == title;
    return OutlinedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor:
            isSelected ? color.onSecondary : color.onPrimaryContainer,
        backgroundColor: isSelected ? color.secondary : Colors.transparent,
        shape: const StadiumBorder(),
      ),
      onPressed: () {
        setState(() {
          selectedFilter = title;
        });
      },
      child: Text(title),
    );
  }
}
