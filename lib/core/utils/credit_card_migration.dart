import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/logging/app_log.dart';

/// Migration utility to fix credit card balance calculation for existing users
class CreditCardMigration {
  static Future<void> migrateIfNeeded(Isar isar, AppLog log) async {
    try {
      final creditCards = await isar.accounts
          .filter()
          .accountTypeEqualTo(AccountType.creditCard)
          .findAll();

      if (creditCards.isEmpty) {
        log.i('No credit cards found, skipping migration');
        return;
      }

      log.i('Found ${creditCards.length} credit card(s), checking migration...');

      // Check if migration already done by looking for a marker
      // You can use SharedPreferences or a flag in the database
      // For now, we'll just log and let user decide

      for (var card in creditCards) {
        log.i('Credit card: ${card.name}, current initialBalance: ${card.initialBalance}');
      }

      log.w('Credit card balance logic has been updated. '
          'If you see incorrect balances, please verify your credit card initial balances.');
    } catch (e) {
      log.e('Migration check failed', e);
    }
  }
}
