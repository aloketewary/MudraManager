import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/sms_activity.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:mudra_manager/features/sms/data/bank_sms_parser.dart';
import 'package:mudra_manager/features/sms/data/category_matcher_service.dart';
import 'package:mudra_manager/features/transactions/data/transaction_matching_service.dart';
import 'package:mudra_manager/features/sms/data/recurring_detector_service.dart';

class SmsActivityService {
  static final SmsActivityService instance = SmsActivityService._();
  static final AppLog _log = AppLog(getLogger(), 'SmsActivityService');

  SmsActivityService._();

  Future<Isar> _getIsar() async {
    if (Isar.instanceNames.isEmpty) {
      return await IsarService.initIsar();
    }
    return Isar.getInstance()!;
  }

  // Calculate parsing confidence based on available data
  int _calculateConfidence(SmsActivity activity) {
    int score = 0;

    if (activity.amount != null && activity.amount! > 0) score += 40;
    if (activity.account != null && activity.account!.isNotEmpty) score += 20;
    if (activity.isIncome != null) score += 20;
    if (activity.fromBank != null && activity.fromBank!.isNotEmpty) score += 10;
    if (activity.transactionRef != null) score += 10;

    return score;
  }

  // Detect potential duplicates within time window
  // Detect potential duplicates within time window (check both SMS and manual transactions)
  Future<List<dynamic>> _findPotentialDuplicates(
    SmsActivity activity,
    Duration timeWindow,
  ) async {
    final isar = await _getIsar();

    if (activity.amount == null) return [];

    final startTime = activity.date.subtract(timeWindow);
    final endTime = activity.date.add(timeWindow);

    // Check SMS activities
    final smsDuplicates = await isar.smsActivitys
        .filter()
        .dateBetween(startTime, endTime)
        .and()
        .amountEqualTo(activity.amount)
        .and()
        .not()
        .smsHashEqualTo(activity.smsHash)
        .findAll();

    // Check manual transactions
    final manualDuplicates = await isar.transactions
        .filter()
        .dateBetween(startTime, endTime)
        .and()
        .amountEqualTo(activity.amount?.toDouble() ?? 0.0)
        .and()
        .isExpenseEqualTo(!(activity.isIncome == true))
        .findAll();

    return [...smsDuplicates, ...manualDuplicates];
  }

  Future<SmsActivity> addActivity({
    required String sender,
    required String body,
    required DateTime date,
    required String smsHash,
    double? amount,
    bool? isIncome,
    String? account,
    String? fromBank,
    String? toAccount,
    String? transactionRef,
    String? category,
  }) async {
    final isar = await _getIsar();
    final categories = await isar.categorys.where().findAll();

    // Use bank parser for better extraction
    final parsed = BankSmsParser.parse(sender, body);

    final activity = SmsActivity()
      ..sender = sender
      ..body = body
      ..date = date
      ..createdAt = DateTime.now()
      ..smsHash = smsHash
      ..amount = parsed?.amount ?? amount
      ..isIncome = parsed?.isIncome ?? isIncome
      ..account = parsed?.account ?? account
      ..fromBank = fromBank
      ..toAccount = toAccount
      ..transactionRef = transactionRef
      ..category = category
      ..transactionType = parsed?.transactionType
      ..balance = parsed?.balance
      ..merchant = parsed?.merchant ??
          CategoryMatcherService.detectMerchant(body, categories)
      ..paymentType = CategoryMatcherService.detectPaymentType(body);

    // Calculate confidence
    activity.confidence = _calculateConfidence(activity);

    // Check for duplicates (within 5 minutes)
    final duplicates = await _findPotentialDuplicates(
      activity,
      const Duration(minutes: 5),
    );

    if (duplicates.isNotEmpty) {
      activity.isPotentialDuplicate = true;
      activity.similarActivityIds =
          duplicates.whereType<SmsActivity>().map((d) => d.id).toList();
      activity.status = ActivityStatus.duplicate;
      final manualCount = duplicates.whereType<Transaction>().length;
      final smsCount = duplicates.whereType<SmsActivity>().length;
      _log.w(
          'Potential duplicate detected: $smsCount SMS + $manualCount manual transactions');
    } else if (activity.confidence! < 60) {
      activity.status = ActivityStatus.needsReview;
      _log.i('Low confidence (${activity.confidence}%), needs review');
    } else {
      // Try auto-approval
      final accounts = await isar.accounts.where().findAll();
      final categories = await isar.categorys.where().findAll();

      final matchResult = TransactionMatchingService.matchTransaction(
        pending: _activityToPending(activity),
        accounts: accounts,
        categories: categories,
      );

      if (matchResult != null) {
        // Auto-approve and create transaction
        final transaction = Transaction()
          ..amount = activity.amount ?? 0
          ..date = activity.date
          ..description = activity.body
          ..isExpense = !(activity.isIncome == true)
          ..isTransfer = false;

        transaction.account.value = matchResult.account;
        transaction.category.value = matchResult.category;

        await isar.writeTxn(() async {
          await isar.transactions.put(transaction);
          await transaction.account.save();
          await transaction.category.save();

          activity.status = ActivityStatus.approved;
          activity.transactionId = transaction.id;
          await isar.smsActivitys.put(activity);
        });

        transaction.isFromSms = true;
        transaction.smsActivityId = activity.id;
        await isar.writeTxn(() async {
          await isar.transactions.put(transaction);
        });

        _log.i(
            'Auto-approved with confidence ${activity.confidence}% -> Transaction ${transaction.id}');
        return activity;
      } else {
        activity.status = ActivityStatus.pending;
        _log.i('Pending review (no match found)');
      }
    }

    await isar.writeTxn(() async {
      await isar.smsActivitys.put(activity);
    });

    _log.i('Activity added: ${activity.status.name} - ₹${activity.amount}');
    return activity;
  }

  Future<void> approveActivity(
    SmsActivity activity,
    Account account,
    Category category,
  ) async {
    final isar = await _getIsar();

    final transaction = Transaction()
      ..amount = activity.amount ?? 0
      ..date = activity.date
      ..description = activity.body
      ..isExpense = !(activity.isIncome == true)
      ..isTransfer = false;

    transaction.account.value = account;
    transaction.category.value = category;
    transaction.isFromSms = true;
    transaction.smsActivityId = activity.id;

    await isar.writeTxn(() async {
      await isar.transactions.put(transaction);
      await transaction.account.save();
      await transaction.category.save();

      activity.status = ActivityStatus.approved;
      activity.transactionId = transaction.id;
      await isar.smsActivitys.put(activity);
    });

    // Learn new keywords from SMS
    await _learnKeywordsFromSms(activity.body, category, isar);

    // Detect recurring patterns
    await RecurringDetectorService.detectAndTagRecurring(transaction);

    _log.i(
      'Activity approved: ID ${activity.id} -> Transaction ${transaction.id}',
    );
  }

  Future<void> _learnKeywordsFromSms(
    String smsBody,
    Category category,
    Isar isar,
  ) async {
    final bodyLower = smsBody.toLowerCase();
    final words = bodyLower.split(RegExp(r'\s+'));

    // Extract potential merchant names (3-15 chars, alphabetic)
    final potentialKeywords = words
        .where((w) =>
            w.length >= 3 && w.length <= 15 && RegExp(r'^[a-z]+$').hasMatch(w))
        .toList();

    if (potentialKeywords.isEmpty) return;

    // Add new keywords to category
    final existingKeywords = category.keywords ?? [];
    final newKeywords = potentialKeywords
        .where((k) => !existingKeywords.contains(k))
        .take(3)
        .toList(); // Limit to 3 new keywords per SMS

    if (newKeywords.isNotEmpty) {
      category.keywords = [...existingKeywords, ...newKeywords];
      await isar.writeTxn(() async {
        await isar.categorys.put(category);
      });
      _log.i(
          'Learned new keywords for ${category.name}: ${newKeywords.join(", ")}');
    }
  }

  Future<void> rejectActivity(SmsActivity activity, String? reason) async {
    final isar = await _getIsar();

    await isar.writeTxn(() async {
      activity.status = ActivityStatus.rejected;
      activity.reviewNotes = reason;
      await isar.smsActivitys.put(activity);
    });

    _log.i('Activity rejected: ID ${activity.id}');
  }

  Future<void> markAsNotDuplicate(SmsActivity activity) async {
    final isar = await _getIsar();

    await isar.writeTxn(() async {
      activity.isPotentialDuplicate = false;
      activity.status = ActivityStatus.pending;
      await isar.smsActivitys.put(activity);
    });
  }

  Future<List<SmsActivity>> getAllActivities() async {
    final isar = await _getIsar();
    return await isar.smsActivitys.where().sortByCreatedAtDesc().findAll();
  }

  Future<List<SmsActivity>> getActivitiesByStatus(ActivityStatus status) async {
    final isar = await _getIsar();
    return await isar.smsActivitys
        .filter()
        .statusEqualTo(status)
        .sortByCreatedAtDesc()
        .findAll();
  }

  Future<int> getPendingCount() async {
    final isar = await _getIsar();
    final pending = await isar.smsActivitys
        .filter()
        .statusEqualTo(ActivityStatus.pending)
        .or()
        .statusEqualTo(ActivityStatus.needsReview)
        .or()
        .statusEqualTo(ActivityStatus.duplicate)
        .count();
    return pending;
  }

  dynamic _activityToPending(SmsActivity activity) {
    return _PendingTransactionAdapter(
      account: activity.account,
      amount: activity.amount,
      isIncome: activity.isIncome,
      body: activity.body,
      sender: activity.sender,
      transactionRef: activity.transactionRef,
      category: activity.category,
      smsHash: activity.smsHash,
      toAccount: activity.toAccount,
      fromBank: activity.fromBank,
    );
  }
}

// Adapter class to match transaction matching interface
class _PendingTransactionAdapter {
  final String? account;
  final double? amount;
  final bool? isIncome;
  final String body;
  final String sender;
  final String? transactionRef;
  final String? category;
  final String smsHash;
  final String? toAccount;
  final String? fromBank;

  _PendingTransactionAdapter({
    this.account,
    this.amount,
    this.isIncome,
    required this.body,
    required this.sender,
    this.transactionRef,
    this.category,
    required this.smsHash,
    this.toAccount,
    this.fromBank,
  });
}
