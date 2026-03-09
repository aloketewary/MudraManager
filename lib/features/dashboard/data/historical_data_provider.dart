import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';

final historicalBalanceProvider =
    FutureProvider.autoDispose<List<double>>((ref) async {
  final isar = ref.watch(isarServiceProvider);
  final db = await isar.getInstance();

  final now = DateTime.now();
  final last7Days = <double>[];

  for (int i = 6; i >= 0; i--) {
    final date = now.subtract(Duration(days: i));
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final txns = await db.transactions
        .where()
        .dateBetween(DateTime.fromMillisecondsSinceEpoch(0), endOfDay)
        .findAll();

    double balance = 0;
    for (var txn in txns) {
      if (!txn.isExpense && !txn.isTransfer) {
        balance += txn.amount;
      } else if (txn.isExpense && !txn.isTransfer) {
        balance -= txn.amount;
      }
    }

    last7Days.add(balance);
  }

  return last7Days;
});

final historicalIncomeProvider =
    FutureProvider.autoDispose<List<double>>((ref) async {
  final isar = ref.watch(isarServiceProvider);
  final db = await isar.getInstance();

  final now = DateTime.now();
  final last6Days = <double>[];

  for (int i = 5; i >= 0; i--) {
    final date = now.subtract(Duration(days: i));
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final txns = await db.transactions
        .where()
        .dateBetween(startOfDay, endOfDay)
        .findAll();

    double income = 0;
    for (var txn in txns) {
      if (!txn.isExpense && !txn.isTransfer) {
        income += txn.amount;
      }
    }

    last6Days.add(income);
  }

  return last6Days;
});

final historicalExpenseProvider =
    FutureProvider.autoDispose<List<double>>((ref) async {
  final isar = ref.watch(isarServiceProvider);
  final db = await isar.getInstance();

  final now = DateTime.now();
  final last6Days = <double>[];

  for (int i = 5; i >= 0; i--) {
    final date = now.subtract(Duration(days: i));
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final txns = await db.transactions
        .where()
        .dateBetween(startOfDay, endOfDay)
        .findAll();

    double expense = 0;
    for (var txn in txns) {
      if (txn.isExpense && !txn.isTransfer) {
        expense += txn.amount;
      }
    }

    last6Days.add(expense);
  }

  return last6Days;
});
