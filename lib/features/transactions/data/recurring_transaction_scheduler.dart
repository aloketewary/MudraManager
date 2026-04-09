import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:mudra_manager/features/gamification/services/gamification_service.dart';
import 'package:mudra_manager/features/transactions/data/recurring_transaction_service.dart';

class RecurringTransactionScheduler {
  static Future<void> processNow() async {
    final isarService = IsarService();
    final isar = await isarService.getInstance();
    final gamificationService = GamificationService(isar, AppLog(getLogger(), 'GamificationService'));
    final service = RecurringTransactionService(isarService, gamificationService);
    await service.processRecurringTransactions();
  }
}
