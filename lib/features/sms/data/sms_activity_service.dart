import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/sms_activity.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/exchange_rate.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';
import 'package:mudra_manager/features/sms/data/bank_sms_parser.dart';
import 'package:mudra_manager/features/sms/data/category_matcher_service.dart';
import 'package:mudra_manager/features/sms/domain/detection_level.dart';
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

    if (activity.amount != null && activity.amount! > 0)
      score += 35; // Increased
    if (activity.isIncome != null) score += 25; // Increased
    if (activity.account != null && activity.account!.isNotEmpty) score += 20;
    if (activity.fromBank != null && activity.fromBank!.isNotEmpty) score += 10;
    if (activity.transactionRef != null) score += 10;

    // Bonus for merchant detection
    if (activity.merchant != null && activity.merchant!.isNotEmpty) score += 15;

    // Bonus for payment type detection
    if (activity.paymentType != null && activity.paymentType!.isNotEmpty)
      score += 10;

    return score.clamp(0, 100);
  }

  // Detect potential duplicates within time window (check both SMS and manual transactions)
  Future<List<dynamic>> _findPotentialDuplicates(
    SmsActivity activity,
    Duration timeWindow,
  ) async {
    final isar = await _getIsar();

    if (activity.amount == null) return [];

    final startTime = activity.date.subtract(timeWindow);
    final endTime = activity.date.add(timeWindow);

    // Check SMS activities (exclude self by hash, skip already-approved ones)
    final rawSmsDuplicates = await isar.smsActivitys
        .filter()
        .dateBetween(startTime, endTime)
        .and()
        .amountEqualTo(activity.amount)
        .and()
        .not()
        .smsHashEqualTo(activity.smsHash)
        .findAll();

    // Content-aware: only keep SMS dupes from same sender or same account
    final smsDuplicates = rawSmsDuplicates.where((d) {
      if (activity.sender == d.sender) return true;
      if (activity.account != null &&
          activity.account!.isNotEmpty &&
          activity.account == d.account) {
        return true;
      }
      return false;
    }).toList();

    // Check manual/SMS-created transactions
    final rawManualDuplicates = await isar.transactions
        .filter()
        .dateBetween(startTime, endTime)
        .and()
        .amountEqualTo(activity.amount?.toDouble() ?? 0.0)
        .and()
        .isExpenseEqualTo(!(activity.isIncome == true))
        .findAll();

    // Content-aware: only keep manual dupes linked to same account
    final manualDuplicates = rawManualDuplicates.where((txn) {
      if (activity.account == null || activity.account!.isEmpty) return true;
      final txnAccount = txn.account.value;
      if (txnAccount == null) return true;
      final acNum = txnAccount.accountNumber ?? '';
      return acNum.isEmpty || acNum.endsWith(activity.account!);
    }).toList();

    // Also check if any existing transaction was already created from this SMS
    // (handles the case where user edited the transaction's amount/date)
    final linkedTxn = await isar.transactions
        .filter()
        .smsActivityIdEqualTo(activity.id)
        .findFirst();
    if (linkedTxn != null && !manualDuplicates.contains(linkedTxn)) {
      return [...smsDuplicates, ...manualDuplicates, linkedTxn];
    }

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
    final parsed = await BankSmsParser.parse(sender, body);
    final existing =
        await isar.smsActivitys.filter().smsHashEqualTo(smsHash).findFirst();

    if (existing != null) {
      _log.w('Duplicate SMS detected at DB level: $smsHash');
      return existing;
    }

    // Clamp date to now if it's in the future (SMS parsing error)
    final now = DateTime.now();
    final safeDate = date.isAfter(now) ? now : date;

    final activity = SmsActivity()
      ..sender = sender
      ..body = body
      ..date = safeDate
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
      ..isLikelyTransfer = parsed?.isLikelyTransfer ?? false
      ..paymentType = CategoryMatcherService.detectPaymentType(body);

    // Calculate confidence
    activity.confidence = _calculateConfidence(activity);

    // ── 1. Check for transfer pair (opposite direction, same amount, different account, within 15 min)
    final transferPair = await _claimTransferPair(activity);

    if (transferPair != null) {
      activity.isLikelyTransfer = true;
      activity.transactionType = 'Transfer';
      activity.status = ActivityStatus.pending;

      await isar.writeTxn(() async {
        // Save activity first to get ID
        final activityId = await isar.smsActivitys.put(activity);

        // Finalize pairing
        transferPair.pairedActivityId = activityId;
        activity.pairedActivityId = transferPair.id;
        await isar.smsActivitys.put(transferPair);
        await isar.smsActivitys.put(activity);
      });

      _log.i(
        'Transfer pair detected (safe): ${activity.id} <-> ${transferPair.id}',
      );

      return activity;
    }

    // ── 2. Check for duplicates (same direction, same amount, within 5 min)
    final duplicates = await _findPotentialDuplicates(
      activity,
      const Duration(minutes: 5),
    );
    final mode = SharedPrefsUtil.instance.getDetectionMode();
    final threshold = getThreshold(mode);

    if (duplicates.isNotEmpty) {
      activity.isPotentialDuplicate = true;
      activity.similarActivityIds =
          duplicates.whereType<SmsActivity>().map((d) => d.id).toList();
      activity.status = ActivityStatus.pending;
      final manualCount = duplicates.whereType<Transaction>().length;
      final smsCount = duplicates.whereType<SmsActivity>().length;
      _log.w(
        'Potential duplicate detected: $smsCount SMS + $manualCount manual transactions',
      );
    } else if (activity.confidence! < threshold) {
      activity.status = ActivityStatus.needsReview;
      _log.i('Low confidence (${activity.confidence}%), needs review');
    } else {
      // Try auto-approval
      final accounts = await isar.accounts.where().findAll();

      final matchResult = TransactionMatchingService.matchTransaction(
        pending: _activityToPending(activity),
        accounts: accounts,
        categories: categories,
      );

      if (matchResult != null) {
        // Inherit currency from matched account
        final accountCurrency = matchResult.account.currencyCode;
        double? convertedAmount;
        double? rateUsed;
        if (accountCurrency != null) {
          final rate = await isar.exchangeRates
              .filter()
              .currencyCodeEqualTo(accountCurrency)
              .findFirst();
          if (rate != null) {
            convertedAmount = (activity.amount ?? 0) * rate.rateToBase;
            rateUsed = rate.rateToBase;
          }
        }

        final transaction = Transaction()
          ..amount = activity.amount ?? 0
          ..date = safeDate
          ..description = activity.body
          ..isExpense = !(activity.isIncome == true)
          ..isTransfer = false
          ..isFromSms = true
          ..currencyCode = accountCurrency
          ..convertedAmount = convertedAmount
          ..rateUsed = rateUsed;

        transaction.account.value = matchResult.account;
        transaction.category.value = matchResult.category;

        await isar.writeTxn(() async {
          // Save activity FIRST
          final activityId = await isar.smsActivitys.put(activity);

          await isar.transactions.put(transaction);
          await transaction.account.save();
          await transaction.category.save();

          transaction.smsActivityId = activityId;
          await isar.transactions.put(transaction);

          activity.status = ActivityStatus.approved;
          activity.transactionId = transaction.id;
          await isar.smsActivitys.put(activity);
        });

        _log.i(
          'Auto-approved with confidence ${activity.confidence}% -> Transaction ${transaction.id}',
        );
        return activity;
      } else {
        activity.status = ActivityStatus.pending;
        _log.i('Pending review (no match found)');
      }
    }

    await isar.writeTxn(() async {
      await isar.smsActivitys.put(activity);
    });

    _log.i(
      'Activity added: ${activity.status.name} - ${BaseCurrency.symbol}${activity.amount}',
    );
    return activity;
  }

  Future<void> approveActivity(
    SmsActivity activity,
    Account account,
    Category category,
  ) async {
    final isar = await _getIsar();

    // Clamp date to now if it's in the future
    final now = DateTime.now();
    final safeDate = activity.date.isAfter(now) ? now : activity.date;

    final transaction = Transaction()
      ..amount = activity.amount ?? 0
      ..date = safeDate
      ..description = activity.body
      ..isExpense = !(activity.isIncome == true)
      ..isTransfer = false;

    // Inherit currency from account
    final accountCurrency = account.currencyCode;
    if (accountCurrency != null) {
      transaction.currencyCode = accountCurrency;
      final rate = await isar.exchangeRates
          .filter()
          .currencyCodeEqualTo(accountCurrency)
          .findFirst();
      if (rate != null) {
        transaction.convertedAmount = (activity.amount ?? 0) * rate.rateToBase;
        transaction.rateUsed = rate.rateToBase;
      }
    }

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
    final categories = await isar.categorys.where().findAll();
    final merchant = CategoryMatcherService.detectMerchant(smsBody, categories);
    if (merchant == null) return;

    final keyword = merchant.toLowerCase().trim();
    if (keyword.length < 3 || _smsNoiseWords.contains(keyword)) return;

    final existingKeywords = category.keywords ?? [];
    if (existingKeywords.contains(keyword)) return;

    category.keywords = [...existingKeywords, keyword];
    await isar.writeTxn(() async {
      await isar.categorys.put(category);
    });
    _log.i('Learned merchant keyword for ${category.name}: $keyword');
  }

  static const _smsNoiseWords = {
    'debited',
    'credited',
    'account',
    'balance',
    'available',
    'transaction',
    'transfer',
    'payment',
    'received',
    'sent',
    'bank',
    'upi',
    'neft',
    'imps',
    'rtgs',
    'ref',
    'inr',
  };

  Future<void> rejectActivity(SmsActivity activity, String? reason) async {
    final isar = await _getIsar();

    await isar.writeTxn(() async {
      activity.status = ActivityStatus.rejected;
      activity.reviewNotes = reason;
      await isar.smsActivitys.put(activity);
    });

    _log.i('Activity rejected: ID ${activity.id}');
  }

  /// Marks a transfer activity (and its paired activity) as approved.
  Future<void> markTransferApproved(SmsActivity activity) async {
    final isar = await _getIsar();

    await isar.writeTxn(() async {
      activity.status = ActivityStatus.approved;
      await isar.smsActivitys.put(activity);

      // Also mark the paired activity if it exists
      if (activity.pairedActivityId != null) {
        final pair = await isar.smsActivitys.get(activity.pairedActivityId!);
        if (pair != null && pair.status != ActivityStatus.approved) {
          pair.status = ActivityStatus.approved;
          await isar.smsActivitys.put(pair);
        }
      }
    });

    _log.i(
      'Transfer activity approved: ID ${activity.id} (pair: ${activity.pairedActivityId})',
    );
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

  /// Finds a matching opposite-direction SMS that forms a transfer pair.
  /// e.g. A/c X9684 debited Rs.5000 + Card X1234 credited Rs.5000 within 15 min
  Future<SmsActivity?> _claimTransferPair(SmsActivity activity) async {
    if (activity.amount == null || activity.isIncome == null) return null;
    if (activity.account == null || activity.account!.isEmpty) return null;

    final isar = await _getIsar();

    return await isar.writeTxn(() async {
      final window = const Duration(days: 1);
      final startTime = activity.date.subtract(window);
      final endTime = activity.date.add(window);

      final candidate = await isar.smsActivitys
          .filter()
          .dateBetween(startTime, endTime)
          .and()
          .amountEqualTo(activity.amount)
          .and()
          .isIncomeEqualTo(!activity.isIncome!)
          .and()
          .not()
          .smsHashEqualTo(activity.smsHash)
          .and()
          .not()
          .accountEqualTo(activity.account)
          .and()
          .pairedActivityIdIsNull()
          .findFirst();

      if (candidate == null) return null;

      candidate.pairedActivityId = -1;
      await isar.smsActivitys.put(candidate);

      return candidate;
    });
  }

  Future<void> approveTransferPair(
    int activityId1,
    int activityId2,
    int transactionId,
  ) async {
    final isar = await _getIsar();
    await isar.writeTxn(() async {
      final a1 = await isar.smsActivitys.get(activityId1);
      final a2 = await isar.smsActivitys.get(activityId2);
      if (a1 != null) {
        a1.status = ActivityStatus.approved;
        a1.transactionId = transactionId;
        await isar.smsActivitys.put(a1);
      }
      if (a2 != null) {
        a2.status = ActivityStatus.approved;
        a2.transactionId = transactionId;
        await isar.smsActivitys.put(a2);
      }
    });
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
