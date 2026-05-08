import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:home_widget/home_widget.dart';
import 'package:isar_community/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/budget.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/features/account/data/account_providers.dart';

class WidgetService {
  static const _widgetNames = [
    'com.mudramanager.app.QuickAddWidgetProvider',
    'com.mudramanager.app.BalanceWidgetProvider',
    'com.mudramanager.app.TodaySpendWidgetProvider',
  ];
  static final _log = AppLog(getLogger(), 'WidgetService');

  static Future<void> updateWidget(WidgetRef ref) async {
    try {
      _log.i('Updating widget data');
      final isarService = ref.read(isarServiceProvider);
      final isar = await isarService.getInstance();

      // Force Isar to sync any pending writes
      await isar.txn(() async {});

      final accounts =
          await isar.accounts.filter().isActiveEqualTo(true).findAll();
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
      final allTxns =
          await isar.transactions.where().sortByDateDesc().limit(5).findAll();
      _log.d('Latest 5 transactions:');
      for (var tx in allTxns) {
        _log.d(
          '  ID: ${tx.id}, Date: ${tx.date}, Amount: ${tx.amount}, isExpense: ${tx.isExpense}',
        );
      }

      final transactions = await isar.transactions
          .filter()
          .dateBetween(startOfDay, endOfDay)
          .findAll();

      _log.d('Found ${transactions.length} transactions for today');

      double todayExpense = 0;
      double todayIncome = 0;
      for (var txn in transactions) {
        _log.d(
          'Txn: ${txn.description}, Amount: ${txn.amount}, isExpense: ${txn.isExpense}, isTransfer: ${txn.isTransfer}',
        );
        if (txn.isTransfer) continue;
        if (txn.isExpense) {
          todayExpense += txn.baseAmount;
        } else {
          todayIncome += txn.baseAmount;
        }
      }

      await HomeWidget.saveWidgetData<String>(
        'balance',
        formatCurrency(totalBalance, code: BaseCurrency.code, decimals: 0),
      );
      await HomeWidget.saveWidgetData<String>(
        'todayExpense',
        formatCurrency(todayExpense, code: BaseCurrency.code, decimals: 0),
      );
      await HomeWidget.saveWidgetData<String>(
        'todayIncome',
        formatCurrency(todayIncome, code: BaseCurrency.code, decimals: 0),
      );

      // Budget remaining for Today's Spend widget
      await _pushBudgetRemaining(isar);

      try {
        for (final name in _widgetNames) {
          await HomeWidget.updateWidget(androidName: name);
        }
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

  static Future<void> _pushBudgetRemaining(
    Isar isar,
  ) async {
    try {
      final now = DateTime.now();
      final budgets = await isar.budgets
          .filter()
          .isArchivedEqualTo(false)
          .findAll();

      // Find the first active budget that covers today
      Budget? active;
      for (final b in budgets) {
        if (b.startDate.isBefore(now) &&
            b.endDate.isAfter(now) &&
            b.amount > 0) {
          active = b;
          break;
        }
      }

      if (active != null) {
        // Sum all expenses in the budget period
        final periodTxns = await isar.transactions
            .filter()
            .dateBetween(active.startDate, active.endDate)
            .isExpenseEqualTo(true)
            .isTransferEqualTo(false)
            .findAll();
        double spent = 0;
        for (final t in periodTxns) {
          spent += t.baseAmount;
        }
        final remaining = active.amount - spent;
        final label = remaining >= 0
            ? '${formatCurrency(remaining, code: BaseCurrency.code, decimals: 0)} left'
            : '${formatCurrency(remaining.abs(), code: BaseCurrency.code, decimals: 0)} over';
        await HomeWidget.saveWidgetData<String>('budgetRemaining', label);
      } else {
        await HomeWidget.saveWidgetData<String>('budgetRemaining', '');
      }
    } catch (e) {
      _log.d('Budget remaining skipped: $e');
      await HomeWidget.saveWidgetData<String>('budgetRemaining', '');
    }
  }
}
