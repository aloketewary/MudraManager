import 'dart:async';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/archived_transaction.dart';
import 'package:mudra_manager/core/db/models/backup_metadata.dart';
import 'package:mudra_manager/core/db/models/dashboard_widget_preference.dart';
import 'package:mudra_manager/core/db/models/exchange_rate.dart';
import 'package:mudra_manager/core/db/models/investment_holding.dart';
import 'package:mudra_manager/core/db/models/balance_snapshot.dart';
import 'package:mudra_manager/core/db/models/budget.dart';
import 'package:mudra_manager/core/db/models/budget_category_allocation.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/category_rule.dart';
import 'package:mudra_manager/core/db/models/goal.dart';
import 'package:mudra_manager/core/db/models/notification_record.dart';
import 'package:mudra_manager/core/db/models/reconciliation_status.dart';
import 'package:mudra_manager/core/db/models/sms_activity.dart';
import 'package:mudra_manager/core/db/models/recurring_bill.dart';
import 'package:mudra_manager/core/db/models/recurring_transaction.dart';
import 'package:mudra_manager/core/db/models/tag.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/db/models/trip.dart';
import 'package:mudra_manager/core/db/models/user_profile.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:mudra_manager/features/gamification/models/achievement.dart';
import 'package:path_provider/path_provider.dart';

class IsarService {
  static final _log = AppLog(getLogger(), 'IsarService');
  static Isar? _instance;
  static Completer<Isar>? _initCompleter;

  static Future<Isar> initIsar() async {
    // Check cached instance
    if (_instance != null && _instance!.isOpen) return _instance!;

    // Check if Isar already has an open instance (survives hot restart)
    final existing = Isar.getInstance();
    if (existing != null && existing.isOpen) {
      _instance = existing;
      return _instance!;
    }

    // Prevent concurrent initialization
    if (_initCompleter != null) return _initCompleter!.future;

    _initCompleter = Completer<Isar>();
    try {
      final dir = await getApplicationDocumentsDirectory();
      _log.i('Initializing Isar database at ${dir.path}');

      // Timeout Isar.open() to avoid infinite hang on hot restart
      _instance = await Isar.open(
        [
          AccountSchema,
          BackupMetadataSchema,
          BudgetSchema,
          CategorySchema,
          CategoryRuleSchema,
          GoalSchema,
          RecurringBillSchema,
          RecurringTransactionSchema,
          TagSchema,
          TransactionSchema,
          UserProfileSchema,
          BudgetCategoryAllocationSchema,
          SmsActivitySchema,
          NotificationRecordSchema,
          TripSchema,
          TripParticipantSchema,
          TripTransactionSchema,
          SplitExpenseSchema,
          SettlementSchema,
          AchievementSchema,
          StreakSchema,
          ChallengeSchema,
          UserLevelSchema,
          XpLogSchema,
          AppConfigSchema,
          BalanceSnapshotSchema,
          ReconciliationStatusSchema,
          InvestmentHoldingSchema,
          DashboardWidgetPreferenceSchema,
          ExchangeRateSchema,
          ArchivedTransactionSchema,
        ],
        directory: dir.path,
      ).timeout(const Duration(seconds: 5));

      _initCompleter!.complete(_instance!);
    } catch (e) {
      _log.w('Isar.open() failed or timed out: $e');
      // Fallback: try getInstance one more time
      final fallback = Isar.getInstance();
      if (fallback != null && fallback.isOpen) {
        _instance = fallback;
        _initCompleter!.complete(_instance!);
      } else {
        // Last resort: try opening with a different name or re-throw
        _initCompleter!.completeError(e);
        _initCompleter = null;
        rethrow;
      }
    }
    return _instance!;
  }

  Future<Isar> getInstance() async {
    // Fast path: already initialized and open
    if (_instance != null && _instance!.isOpen) return _instance!;

    // Check for surviving native instance
    final existing = Isar.getInstance();
    if (existing != null && existing.isOpen) {
      _instance = existing;
      return _instance!;
    }

    return await initIsar();
  }
}
