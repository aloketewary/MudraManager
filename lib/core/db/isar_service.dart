import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/backup_metadata.dart';
import 'package:mudra_manager/core/db/models/investment_holding.dart';
import 'package:mudra_manager/core/db/models/balance_snapshot.dart';
import 'package:mudra_manager/core/db/models/budget.dart';
import 'package:mudra_manager/core/db/models/budget_category_allocation.dart';
import 'package:mudra_manager/core/db/models/category.dart';
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

  static Future<Isar> initIsar() async {
    if (_instance != null) return _instance!;

    final dir = await getApplicationDocumentsDirectory();
    _log.i('Initializing Isar database at ${dir.path}');
    _instance = await Isar.open(
      [
        AccountSchema,
        BackupMetadataSchema,
        BudgetSchema,
        CategorySchema,
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
      ],
      directory: dir.path,
    );
    return _instance!;
  }

 Future<Isar> getInstance() async {
    return _instance ?? await initIsar();
  }
}
