import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:home_widget/home_widget.dart';
import 'package:isar_community/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/features/account/data/account_providers.dart';

class WidgetService {
  static const String androidWidgetName = 'com.mudramanager.app.QuickAddWidgetProvider';
  static final _log = AppLog(getLogger(), 'WidgetService');

  static Future<void> updateWidget(WidgetRef ref) async {
    try {
      _log.i('Updating widget data');
      final isarService = ref.read(isarServiceProvider);
      final isar = await isarService.getInstance();

      // Force Isar to sync any pending writes
      await isar.txn(() async {});

      final accounts = await isar.accounts
          .filter()
          .isActiveEqualTo(true)
          .findAll();
      final accountService = ref.read(accountServiceProvider);

      double totalBalance = 0;
      for (var account in accounts) {
        final balance = await accountService.getAccountBalance(account.id);
        totalBalance += balance;
      }

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

      _log.d('Querying transactions between $startOfDay and $endOfDay');

      // Check latest transactions
      final allTxns = await isar.transactions.where().sortByDateDesc().limit(5).findAll();
      _log.d('Latest 5 transactions:');
      for (var tx in allTxns) {
        _log.d('  ID: ${tx.id}, Date: ${tx.date}, Amount: ${tx.amount}, isExpense: ${tx.isExpense}');
      }

      final transactions = await isar.transactions
          .filter()
          .dateBetween(startOfDay, endOfDay)
          .findAll();

      _log.d('Found ${transactions.length} transactions for today');

      double todayExpense = 0;
      double todayIncome = 0;
      for (var txn in transactions) {
        _log.d('Txn: ${txn.description}, Amount: ${txn.amount}, isExpense: ${txn.isExpense}, isTransfer: ${txn.isTransfer}');
        if (txn.isTransfer) continue;
        if (txn.isExpense) {
          todayExpense += txn.baseAmount;
        } else {
          todayIncome += txn.baseAmount;
        }
      }

      await HomeWidget.saveWidgetData<String>(
        'balance',
        '${formatCurrency(totalBalance, code: BaseCurrency.code, decimals: 0)}',
      );
      await HomeWidget.saveWidgetData<String>(
        'todayExpense',
        '${formatCurrency(todayExpense, code: BaseCurrency.code, decimals: 0)}',
      );
      await HomeWidget.saveWidgetData<String>(
        'todayIncome',
        '${formatCurrency(todayIncome, code: BaseCurrency.code, decimals: 0)}',
      );

      try {
        await HomeWidget.updateWidget(androidName: androidWidgetName);
      } catch (e) {
        // Widget not found - ignore (happens in dev builds)
        _log.d('Widget update skipped: $e');
      }
      
      _log.i(
        'Widget updated: Balance=${formatCurrency(totalBalance, code: BaseCurrency.code, decimals: 0)}, Expense=${formatCurrency(todayExpense, code: BaseCurrency.code, decimals: 0)}, Income=${formatCurrency(todayIncome, code: BaseCurrency.code, decimals: 0)}',
      );
    } catch (e) {
      _log.e('Error updating widget', e);
    }
  }
}
