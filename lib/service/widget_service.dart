import 'package:home_widget/home_widget.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/providers/account_providers.dart';
import 'package:mudra_manager/providers/isar_provider.dart';
import 'package:mudra_manager/db/models/account.dart';
import 'package:mudra_manager/db/models/transaction.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

class WidgetService {
  static const String androidWidgetName = 'QuickAddWidgetProvider';

  static Future<void> updateWidget(WidgetRef ref) async {
    try {
      final isarService = ref.read(isarServiceProvider);
      final isar = await isarService.getInstance();
      
      final accounts = await isar.accounts.filter().isActiveEqualTo(true).findAll();
      final accountService = ref.read(accountServiceProvider);
      
      double totalBalance = 0;
      for (var account in accounts) {
        final balance = await accountService.getAccountBalance(account.id);
        totalBalance += balance;
      }

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);
      
      final transactions = await isar.transactions
          .filter()
          .dateBetween(startOfDay, endOfDay)
          .findAll();
      
      double todayExpense = 0;
      double todayIncome = 0;
      for (var txn in transactions) {
        if (txn.isExpense) {
          todayExpense += txn.amount;
        } else {
          todayIncome += txn.amount;
        }
      }

      await HomeWidget.saveWidgetData<String>('balance', '₹${totalBalance.toStringAsFixed(0)}');
      await HomeWidget.saveWidgetData<String>('todayExpense', '₹${todayExpense.toStringAsFixed(0)}');
      await HomeWidget.saveWidgetData<String>('todayIncome', '₹${todayIncome.toStringAsFixed(0)}');

      await HomeWidget.updateWidget(androidName: androidWidgetName);
    } catch (e) {
      debugPrint('Error updating widget: $e');
    }
  }
}
