import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/db/models/transaction.dart';
import 'package:mudra_manager/providers/isar_provider.dart';

final chartDataProvider = FutureProvider.family<ChartData, String>((ref, filter) async {
  final isar = await ref.watch(isarServiceProvider).getInstance();
  DateTime now = DateTime.now();
  DateTime start;
  DateTime end = now;

  switch (filter) {
    case 'Week':
      start = now.subtract(Duration(days: now.weekday - 1));
      break;
    case 'Month':
      start = DateTime(now.year, now.month, 1);
      break;
    case 'Year':
      start = DateTime(now.year, 1, 1);
      break;
    default:
      start = DateTime(now.year - 4, 1, 1);
  }

  // OPTIMIZED: Single query with date filter
  final txns = await isar.transactions
      .where()
      .dateBetween(start, end)
      .filter()
      .isTransferEqualTo(false)
      .findAll();

  List<DateTime> range = [];
  switch (filter) {
    case 'Week':
      range = List.generate(7, (i) => start.add(Duration(days: i)));
      break;
    case 'Month':
      range = List.generate(30, (i) => start.add(Duration(days: i)));
      break;
    case 'Year':
      range = List.generate(12, (i) => DateTime(now.year, i + 1, 1));
      break;
    default:
      range = List.generate(5, (i) => DateTime(now.year - 4 + i, 1, 1));
  }

  List<double> totals = List.filled(range.length, 0);

  // Single pass through filtered transactions
  for (final txn in txns) {
    for (int i = 0; i < range.length; i++) {
      final current = range[i];
      bool match = false;
      
      if (filter == 'Week' || filter == 'Month') {
        match = txn.date.year == current.year && 
                txn.date.month == current.month && 
                txn.date.day == current.day;
      } else if (filter == 'Year') {
        match = txn.date.year == current.year && txn.date.month == current.month;
      } else {
        match = txn.date.year == current.year;
      }

      if (match) {
        totals[i] += txn.isExpense ? -txn.amount : txn.amount;
        break;
      }
    }
  }

  final spots = List.generate(totals.length, (i) => FlSpot(i.toDouble(), totals[i]));
  final labels = range.map((date) {
    if (filter == 'Week' || filter == 'Month') {
      return "${date.day}/${date.month}";
    } else if (filter == 'Year') {
      return "${date.month}/${date.year}";
    } else {
      return "${date.year}";
    }
  }).toList();

  return ChartData(spots: spots, labels: labels);
});

class ChartData {
  final List<FlSpot> spots;
  final List<String> labels;
  ChartData({required this.spots, required this.labels});
}
