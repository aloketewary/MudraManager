import 'package:isar_community/isar.dart';
import 'package:mudra_manager/db/models/backup_metadata.dart';
import 'package:mudra_manager/db/models/budget.dart';
import 'package:mudra_manager/db/models/budget_category_allocation.dart';
import 'package:mudra_manager/db/models/category.dart';
import 'package:mudra_manager/db/models/goal.dart';
import 'package:mudra_manager/db/models/notification_record.dart';
import 'package:mudra_manager/db/models/pending_transaction.dart';
import 'package:mudra_manager/db/models/recurring_bill.dart';
import 'package:mudra_manager/db/models/recurring_transaction.dart';
import 'package:mudra_manager/db/models/tag.dart';
import 'package:mudra_manager/db/models/transaction.dart';
import 'package:mudra_manager/db/models/trip.dart';
import 'package:mudra_manager/db/models/user_profile.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mudra_manager/db/models/account.dart';

class IsarService {
  final Future<Isar> _db;

  IsarService() : _db = initIsar();

  static Future<Isar> initIsar() async {
    final dir = await getApplicationDocumentsDirectory();
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
