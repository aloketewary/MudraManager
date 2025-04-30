import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:mudra_manager/db/models/transaction.dart';
import 'package:mudra_manager/providers/transaction_provider.dart';

final chartDataProvider = FutureProvider.family<ChartData, String>((
  ref,
  filter,
) async {
  final service = ref.watch(transactionProvider);
  final allTxns = await service.getAll();

  DateTime now = DateTime.now();
  List<DateTime> range = [];

  switch (filter) {
    case 'Week':
      final start = now.subtract(Duration(days: now.weekday - 1));
      range = List.generate(7, (i) => start.add(Duration(days: i)));
      break;
    case 'Month':
      final first = DateTime(now.year, now.month, 1);
      range = List.generate(30, (i) => first.add(Duration(days: i)));
      break;
    case 'Year':
      range = List.generate(12, (i) => DateTime(now.year, i + 1, 1));
      break;
    default:
      range = List.generate(5, (i) => DateTime(now.year - 4 + i, 1, 1));
  }

  List<double> totals = List.filled(range.length, 0);

  for (final txn in allTxns) {
    for (int i = 0; i < range.length; i++) {
      final current = range[i];

      bool match = false;
      if (filter == 'Week' || filter == 'Month') {
        match =
            txn.date.year == current.year &&
            txn.date.month == current.month &&
            txn.date.day == current.day;
      } else if (filter == 'Year') {
        match =
            txn.date.year == current.year && txn.date.month == current.month;
      } else {
        match = txn.date.year == current.year;
      }

      if (match) {
        totals[i] += txn.isExpense ? -txn.amount : txn.amount;
        break;
      }
    }
  }

  final spots = List.generate(
    totals.length,
    (i) => FlSpot(i.toDouble(), totals[i]),
  );

  final labels =
      range.map((date) {
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

final filteredTransactionsByDateProvider = FutureProvider.family<
  List<Transaction>,
  ({String filter, DateTime selectedDate})>((ref, args) async {
  final service = ref.watch(transactionProvider);

  DateTime start;
  DateTime end;

  if (args.filter == 'Week') {
    start = args.selectedDate.subtract(
      Duration(days: args.selectedDate.weekday - 1),
    );
    end = start.add(const Duration(days: 6));
  } else if (args.filter == 'Month') {
    start = DateTime(args.selectedDate.year, args.selectedDate.month, 1);
    end = DateTime(args.selectedDate.year, args.selectedDate.month + 1, 0);
  } else if (args.filter == 'Year') {
    start = DateTime(args.selectedDate.year, 1, 1);
    end = DateTime(args.selectedDate.year, 12, 31);
  } else {
    return await service.getByType(isExpense: true);
  }

  final isar = await service.isarService.getInstance();
  return await isar.transactions
      .where()
      .filter()
      .isExpenseEqualTo(true)
      .dateBetween(start, end)
      .sortByDate()
      .findAll();
});
