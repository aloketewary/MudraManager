import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/backup_metadata.dart';
import 'package:mudra_manager/core/db/models/budget.dart';
import 'package:mudra_manager/core/db/models/budget_category_allocation.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/goal.dart';
import 'package:mudra_manager/core/db/models/notification_record.dart';
import 'package:mudra_manager/core/db/models/pending_transaction.dart';
import 'package:mudra_manager/core/db/models/recurring_bill.dart';
import 'package:mudra_manager/core/db/models/recurring_transaction.dart';
import 'package:mudra_manager/core/db/models/tag.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/db/models/trip.dart';
import 'package:mudra_manager/core/db/models/user_profile.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:path_provider/path_provider.dart';

class IsarService {
  final Future<Isar> _db;
  static final _log = AppLog(getLogger(), 'IsarService');

  IsarService() : _db = initIsar();

  static Future<Isar> initIsar() async {
    final dir = await getApplicationDocumentsDirectory();
    _log.i('Initializing Isar database at ${dir.path}');
    return await Isar.open([
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
      PendingTransactionSchema,
      NotificationRecordSchema,
      TripSchema,
      TripParticipantSchema,
      TripTransactionSchema,
      SettlementSchema,
    ], directory: dir.path);
  }

  Future<Isar> getInstance() async {
    return _db;
  }
}
