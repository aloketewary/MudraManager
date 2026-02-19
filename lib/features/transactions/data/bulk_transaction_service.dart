import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:mudra_manager/core/utils/error_handler.dart';

class BulkTransactionService {
  static final _log = AppLog(getLogger(), 'BulkTxnService');

  /// Delete multiple transactions
  static Future<bool> deleteMultiple(List<int> ids) async {
    return await withRetry(() async {
      try {
        final isar = await IsarService().getInstance();
        await isar.writeTxn(() async {
          await isar.transactions.deleteAll(ids);
        });
        _log.i('Deleted ${ids.length} transactions');
        return true;
      } catch (e) {
        _log.e('Failed to delete transactions', e);
        throw DatabaseException('Failed to delete transactions', error: e);
      }
    });
  }

  /// Update category for multiple transactions
  static Future<bool> updateCategory(List<int> ids, int categoryId) async {
    return await withRetry(() async {
      try {
        final isar = await IsarService().getInstance();
        await isar.writeTxn(() async {
          final transactions = await isar.transactions.getAll(ids);
          for (final transaction in transactions) {
            if (transaction != null) {
              transaction.category.value = await isar.categorys.get(categoryId);
              await isar.transactions.put(transaction);
              await transaction.category.save();
            }
          }
        });
        _log.i('Updated category for ${ids.length} transactions');
        return true;
      } catch (e) {
        _log.e('Failed to update category', e);
        throw DatabaseException('Failed to update category', error: e);
      }
    });
  }

  /// Update account for multiple transactions
  static Future<bool> updateAccount(List<int> ids, int accountId) async {
    return await withRetry(() async {
      try {
        final isar = await IsarService().getInstance();
        await isar.writeTxn(() async {
          final transactions = await isar.transactions.getAll(ids);
          for (final transaction in transactions) {
            if (transaction != null) {
              transaction.account.value = await isar.accounts.get(accountId);
              await isar.transactions.put(transaction);
              await transaction.account.save();
            }
          }
        });
        _log.i('Updated account for ${ids.length} transactions');
        return true;
      } catch (e) {
        _log.e('Failed to update account', e);
        throw DatabaseException('Failed to update account', error: e);
      }
    });
  }

  /// Export transactions to CSV format
  static Future<String> exportToCSV(List<Transaction> transactions) async {
    try {
      final buffer = StringBuffer();
      buffer.writeln('Date,Amount,Type,Category,Account,Description,Notes');

      for (final t in transactions) {
        final category = t.category.value?.name ?? 'Uncategorized';
        final account = t.account.value?.name ?? 'Unknown';
        final type = t.isExpense ? 'Expense' : 'Income';
        final description = t.description?.replaceAll(',', ';') ?? '';

        buffer.writeln(
          '${t.date},${t.amount},$type,$category,$account,$description',
        );
      }

      _log.i('Exported ${transactions.length} transactions');
      return buffer.toString();
    } catch (e) {
      _log.e('Failed to export transactions', e);
      throw AppException(
        code: 'EXPORT_ERROR',
        message: 'Failed to export transactions',
        userMessage: 'Could not export data. Please try again.',
        originalError: e,
      );
    }
  }
}
