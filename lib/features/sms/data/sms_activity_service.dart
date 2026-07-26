import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/extensions/field_encryption_ext.dart';
import 'package:mudra_manager/core/db/models/sms_activity.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/category_rule.dart';
import 'package:mudra_manager/core/db/models/exchange_rate.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';
import 'package:mudra_manager/core/utils/robust_category_matcher.dart';
import 'package:mudra_manager/features/sms/data/bank_sms_parser.dart';
import 'package:mudra_manager/features/sms/data/category_matcher_service.dart';
import 'package:mudra_manager/features/sms/domain/detection_level.dart';
import 'package:mudra_manager/features/transactions/data/transaction_matching_service.dart';
import 'package:mudra_manager/features/transactions/data/models/pending_transaction_data.dart';
import 'package:mudra_manager/features/sms/data/recurring_detector_service.dart';

class SmsActivityService {
  static final SmsActivityService instance = SmsActivityService._();
  static final AppLog _log = AppLog(getLogger(), 'SmsActivityService');

  SmsActivityService._();

  Future<Isar> _getIsar() async {
    final existing = Isar.getInstance();
    if (existing != null && existing.isOpen) return existing;
    return await IsarService.initIsar();
  }

  double? _normalizeAmount(double? amount) {
    if (amount == null || amount <= 0) return null;
    return amount;
  }

  /// Calculate parsing confidence based on available data.
  /// Visible for testing.
  static int calculateConfidence(SmsActivity activity) {
    int score = 0;

    if (activity.amount != null && activity.amount! > 0) {
      score += 35; // Increased
    }
    if (activity.isIncome != null) score += 25; // Increased
    if (activity.account != null && activity.account!.isNotEmpty) score += 20;
    if (activity.fromBank != null && activity.fromBank!.isNotEmpty) score += 10;
    if (activity.transactionRef != null) score += 10;
    if (activity.category != null && activity.category!.isNotEmpty) score += 15;

    // Bonus for merchant detection
    if (activity.merchant != null && activity.merchant!.isNotEmpty) score += 15;

    // Bonus for payment type detection
    if (activity.paymentType != null && activity.paymentType!.isNotEmpty) {
      score += 10;
    }

    return score.clamp(0, 100);
  }

  // Detect potential duplicates within time window (check both SMS and manual transactions)
  Future<List<dynamic>> _findPotentialDuplicates(
    SmsActivity activity,
    Duration timeWindow,
  ) async {
    final isar = await _getIsar();

    if (activity.amount == null || activity.amount == 0) return [];

    final startTime = activity.date.subtract(timeWindow);
    final endTime = activity.date.add(timeWindow);

    // Check SMS activities (exclude self by hash, skip already-approved/rejected ones)
    final rawSmsDuplicates = await isar.smsActivitys
        .filter()
        .dateBetween(startTime, endTime)
        .and()
        .amountEqualTo(activity.amount)
        .and()
        .not()
        .smsHashEqualTo(activity.smsHash)
        .and()
        .not()
        .statusEqualTo(ActivityStatus.approved)
        .and()
        .not()
        .statusEqualTo(ActivityStatus.rejected)
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
    // If we don't know the SMS account, skip manual dupe check entirely
    // to avoid false positives
    final manualDuplicates =
        (activity.account == null || activity.account!.isEmpty)
            ? <Transaction>[]
            : rawManualDuplicates.where((txn) {
                final txnAccount = txn.account.value;
                if (txnAccount == null) return false;
                return txnAccount.matchesSuffix(activity.account!);
              }).toList();

    // Also check if any existing transaction was already created from this SMS
    // (handles the case where user edited the transaction's amount/date)
    // Only check if activity has been saved (id > 0)
    if (activity.id > 0) {
      final linkedTxn = await isar.transactions
          .filter()
          .smsActivityIdEqualTo(activity.id)
          .findFirst();
      if (linkedTxn != null && !manualDuplicates.contains(linkedTxn)) {
        return [...smsDuplicates, ...manualDuplicates, linkedTxn];
      }
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
    String corrId = '',
    bool isRcs = false,
    String? currencyCode,
  }) async {
    final isar = await _getIsar();
    // System categories (Shared Expense, Trip Expense, Settlement...) are
    // reserved for the trip/split-bill flow and must never be candidates
    // for general SMS auto-categorization.
    final categories =
        (await isar.categorys.where().findAll()).where((c) => !c.isSystem).toList();

    // Use bank parser for better extraction
    final parsed = await BankSmsParser.parse(sender, body);
    final existing =
        await isar.smsActivitys.filter().smsHashEqualTo(smsHash).findFirst();

    if (existing != null) {
      _log.w('[$corrId] Duplicate SMS at DB level: $smsHash');
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
      ..amount = _normalizeAmount(parsed?.amount ?? amount)
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
      ..paymentType = CategoryMatcherService.detectPaymentType(body)
      ..currencyCode = currencyCode;

    // If parser did not provide a category, try learned rules first, then robust matching
    bool categoryHighConfidence = false;
    if (activity.category == null) {
      // Strategy 0: Check learned merchant→category rules
      final learnedCategory = await _matchByLearnedRule(
        body,
        categories,
        isar,
        merchant: activity.merchant,
        recipient: activity.toAccount,
      );
      if (learnedCategory != null) {
        activity.category = learnedCategory.name;
        categoryHighConfidence = true;
        _log.d('[$corrId] Category from learned rule: ${activity.category}');
      } else {
        // Strategy 1-5: Robust category matching fallback
        final relevantCategories = categories
            .where(
              (c) =>
                  activity.isIncome == null ||
                  (activity.isIncome == true &&
                      c.categoryType == CategoryType.income) ||
                  (activity.isIncome == false &&
                      c.categoryType == CategoryType.expense),
            )
            .toList();

        final matchResult = RobustCategoryMatcher.match(
          text: body,
          allCategories: categories,
          relevantCategories: relevantCategories,
          amount: activity.amount,
          isIncome: activity.isIncome,
          merchant: activity.merchant, // Pass merchant for priority matching
        );

        activity.category = matchResult.category?.name;
        categoryHighConfidence = matchResult.isHighConfidence;

        _log.d(
          '[$corrId] Category matched: ${activity.category} (${matchResult.confidenceScore}% via ${matchResult.matchStrategy})',
        );
      }
    }

    // Calculate base confidence, then apply category match boost
    activity.confidence = calculateConfidence(activity);
    if (categoryHighConfidence) {
      activity.confidence = (activity.confidence! + 10).clamp(0, 100);
    }

    // RCS penalty: notification text may be truncated, lower confidence
    // so it's more likely to go to needsReview instead of auto-approve
    if (isRcs) {
      activity.confidence = (activity.confidence! - 15).clamp(0, 100);
      _log.d('[$corrId] RCS confidence penalty applied: ${activity.confidence}%');
    }

    // ── 1. Check for transfer pair (opposite direction, same amount, different account, within 15 min)
    final transferPair = await _claimTransferPair(activity);

    if (transferPair != null) {
      activity.isLikelyTransfer = true;
      activity.transactionType = 'Transfer';
      activity.status = ActivityStatus.pending;

      activity.encryptFields();
      await isar.writeTxn(() async {
        // Save activity first to get ID
        final activityId = await isar.smsActivitys.put(activity);

        // Finalize pairing
        transferPair.pairedActivityId = activityId;
        activity.pairedActivityId = transferPair.id;

        transferPair.encryptFields();
        await isar.smsActivitys.put(transferPair);
        await isar.smsActivitys.put(activity);
      });

      _log.i(
        '[$corrId] Transfer pair: ${activity.id} <-> ${transferPair.id}',
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
        '[$corrId] Potential duplicate: $smsCount SMS + $manualCount manual',
      );
    } else if (activity.confidence! < threshold) {
      activity.status = ActivityStatus.needsReview;
      _log.i(
        '[$corrId] Low confidence (${activity.confidence}%), needs review',
      );
    } else {
      // Try auto-approval — pass pre-matched category to avoid re-running matcher
      final accounts = await isar.accounts.where().findAll();

      // Resolve the pre-matched category by name if available
      Category? preMatchedCat;
      if (activity.category != null) {
        preMatchedCat = categories
            .where(
              (c) => c.name == activity.category,
            )
            .firstOrNull;
      }

      final matchResult = TransactionMatchingService.matchTransaction(
        pending: _activityToPending(activity),
        accounts: accounts,
        categories: categories,
        preMatchedCategory: preMatchedCat,
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

        activity.encryptFields();
        transaction.encryptFields();
        await isar.writeTxn(() async {
          // Save activity FIRST (with pending status to satisfy late field)
          activity.status = ActivityStatus.pending;
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
          '[$corrId] Auto-approved ${activity.confidence}% -> Txn ${transaction.id}',
        );

        // Learn merchant → category rule from auto-approved SMS
        await _learnFromApproval(
          body,
          matchResult.category,
          isar,
          merchant: activity.merchant,
          recipient: activity.toAccount,
        );

        return activity;
      } else {
        activity.status = ActivityStatus.pending;
        _log.i('[$corrId] Pending (no account match)');
      }
    }

    activity.encryptFields();
    await isar.writeTxn(() async {
      await isar.smsActivitys.put(activity);
    });

    _log.i(
      '[$corrId] ${activity.status.name} ${BaseCurrency.symbol}${activity.amount}',
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

    activity.encryptFields();
    transaction.encryptFields();
    await isar.writeTxn(() async {
      await isar.transactions.put(transaction);
      await transaction.account.save();
      await transaction.category.save();

      activity.status = ActivityStatus.approved;
      activity.transactionId = transaction.id;
      await isar.smsActivitys.put(activity);
    });

    // Learn merchant → category rule
    await _learnFromApproval(
      activity.body,
      category,
      isar,
      merchant: activity.merchant,
      recipient: activity.toAccount,
    );

    // Detect recurring patterns
    await RecurringDetectorService(IsarService()).detectAndTagRecurring(transaction);

    _log.i(
      'Activity approved: ID ${activity.id} -> Transaction ${transaction.id}',
    );
  }

  /// Learn merchant→category mapping when user manually approves.
  Future<void> learnKeywordsFromApproval(
    String smsBody,
    Category category, {
    String? merchant,
    String? recipient,
  }) async {
    final isar = await _getIsar();
    await _learnFromApproval(
      smsBody,
      category,
      isar,
      merchant: merchant,
      recipient: recipient,
    );
  }

  Future<void> _learnFromApproval(
    String smsBody,
    Category category,
    Isar isar, {
    String? merchant,
    String? recipient,
  }) async {
    final categories = await isar.categorys.where().findAll();
    final keys = <String>{};

    // 1. Merchant from regex extraction
    final detected = CategoryMatcherService.detectMerchant(smsBody, categories);
    if (detected != null) keys.add(detected.toLowerCase().trim());

    // 2. Pre-extracted merchant from parser (e.g., "Swiggy" from HDFC plugin)
    if (merchant != null && merchant.isNotEmpty) {
      keys.add(merchant.toLowerCase().trim());
    }

    // 3. UPI VPA recipient (e.g., "suraj@okaxis" → learn "suraj")
    if (recipient != null && recipient.contains('@')) {
      final vpaName = recipient.split('@').first.toLowerCase().trim();
      if (vpaName.length >= 3) keys.add(vpaName);
    }

    // Filter noise and upsert rules
    final validKeys = keys.where(
      (k) => k.length >= 3 && !_smsNoiseWords.contains(k),
    );

    if (validKeys.isNotEmpty) {
      final allRules = await isar.categoryRules.where().findAll().withDecryption();
      for (final key in validKeys) {
        await _upsertRule(key, category, isar, allRules);
      }
    }
  }

  Future<void> _upsertRule(
    String key,
    Category category,
    Isar isar,
    List<CategoryRule> existingRules,
  ) async {
    final existing = existingRules
        .where((r) => r.merchantName?.toLowerCase() == key.toLowerCase())
        .firstOrNull;

    await isar.writeTxn(() async {
      if (existing != null) {
        existing.categoryId = category.id.toString();
        existing.matchCount++;
        existing.confidence = (existing.confidence + 10).clamp(0, 100);
        existing.lastUsed = DateTime.now();
        existing.encryptFields();
        await isar.categoryRules.put(existing);
        _log.i(
          'Rule updated: $key → ${category.name} (confidence: ${existing.confidence}, matches: ${existing.matchCount})',
        );
      } else {
        final rule = CategoryRule(
          merchantName: key,
          categoryId: category.id.toString(),
          confidence: 60,
          matchCount: 1,
        );
        rule.encryptFields();
        await isar.categoryRules.put(rule);
        _log.i('Rule created: $key → ${category.name}');
      }
    });
  }

  /// Look up a learned merchant→category rule.
  /// Checks merchant name, then UPI VPA recipient as fallback.
  Future<Category?> _matchByLearnedRule(
    String smsBody,
    List<Category> categories,
    Isar isar, {
    String? merchant,
    String? recipient,
  }) async {
    // Collect all possible lookup keys
    final keys = <String>[];

    final detected = CategoryMatcherService.detectMerchant(smsBody, categories);
    if (detected != null) keys.add(detected.toLowerCase().trim());
    if (merchant != null && merchant.isNotEmpty) {
      keys.add(merchant.toLowerCase().trim());
    }
    if (recipient != null && recipient.contains('@')) {
      keys.add(recipient.split('@').first.toLowerCase().trim());
    }

    if (keys.isNotEmpty) {
      final allRules =
          await isar.categoryRules.where().findAll().withDecryption();
      for (final key in keys) {
        if (key.length < 3) continue;
        final rule = allRules
            .where((r) =>
                r.merchantName?.toLowerCase() == key.toLowerCase() &&
                r.confidence > 40,)
            .firstOrNull;

        if (rule == null) continue;

        final categoryId = int.tryParse(rule.categoryId);
        if (categoryId == null) continue;

        final matched = categories.where((c) => c.id == categoryId).firstOrNull;
        if (matched != null) {
          _log.i(
            'Learned rule matched: $key → ${matched.name} (confidence: ${rule.confidence})',
          );
          return matched;
        }
      }
    }
    return null;
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
    'your',
    'from',
    'the',
    'for',
    'with',
    'info',
  };

  Future<void> rejectActivity(SmsActivity activity, String? reason) async {
    final isar = await _getIsar();

    activity.status = ActivityStatus.rejected;
    activity.reviewNotes = reason;
    activity.encryptFields();
    await isar.writeTxn(() async {
      await isar.smsActivitys.put(activity);
    });

    // Negative learning: penalize the rule that led to wrong categorization
    if (activity.merchant != null || activity.toAccount != null) {
      final allRules = await isar.categoryRules.where().findAll().withDecryption();
      await _penalizeRules(activity, isar, allRules);
    }

    _log.i('Activity rejected: ID ${activity.id}');
  }

  /// Penalize rules when user rejects or corrects a categorization.
  Future<void> _penalizeRules(
    SmsActivity activity,
    Isar isar,
    List<CategoryRule> allRules,
  ) async {
    final keys = <String>[];
    if (activity.merchant != null) {
      keys.add(activity.merchant!.toLowerCase().trim());
    }
    if (activity.toAccount != null && activity.toAccount!.contains('@')) {
      keys.add(activity.toAccount!.split('@').first.toLowerCase().trim());
    }

    for (final key in keys) {
      if (key.length < 3) continue;
      final rule = allRules
          .where((r) => r.merchantName?.toLowerCase() == key.toLowerCase())
          .firstOrNull;

      if (rule == null) continue;

      await isar.writeTxn(() async {
        rule.confidence = (rule.confidence - 20).clamp(0, 100);
        rule.lastUsed = DateTime.now();
        if (rule.confidence <= 0 && rule.matchCount <= 1) {
          await isar.categoryRules.delete(rule.id);
          _log.i('Rule deleted (zero confidence): $key');
        } else {
          rule.encryptFields();
          await isar.categoryRules.put(rule);
          _log.i('Rule penalized: $key (confidence: ${rule.confidence})');
        }
      });
    }
  }

  /// Marks a transfer activity (and its paired activity) as approved.
  Future<void> markTransferApproved(SmsActivity activity) async {
    final isar = await _getIsar();

    activity.status = ActivityStatus.approved;
    activity.encryptFields();
    await isar.writeTxn(() async {
      await isar.smsActivitys.put(activity);

      // Also mark the paired activity if it exists
      if (activity.pairedActivityId != null) {
        final pair = await isar.smsActivitys.get(activity.pairedActivityId!);
        if (pair != null && pair.status != ActivityStatus.approved) {
          pair.status = ActivityStatus.approved;
          pair.encryptFields();
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

    activity.isPotentialDuplicate = false;
    activity.status = ActivityStatus.pending;
    activity.encryptFields();
    await isar.writeTxn(() async {
      await isar.smsActivitys.put(activity);
    });
  }

  Future<List<SmsActivity>> getAllActivities() async {
    final isar = await _getIsar();
    return await isar.smsActivitys
        .where()
        .sortByCreatedAtDesc()
        .findAll()
        .withDecryption();
  }

  Future<List<SmsActivity>> getActivitiesByStatus(ActivityStatus status) async {
    final isar = await _getIsar();
    return await isar.smsActivitys
        .filter()
        .statusEqualTo(status)
        .sortByCreatedAtDesc()
        .findAll()
        .withDecryption();
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

  PendingTransactionData _activityToPending(SmsActivity activity) {
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
      final window = const Duration(minutes: 30);
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
          .and()
          .statusEqualTo(ActivityStatus.pending)
          .findFirst();

      if (candidate == null) return null;

      candidate.pairedActivityId = -1;
      candidate.encryptFields();
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
        a1.encryptFields();
        await isar.smsActivitys.put(a1);
      }
      if (a2 != null) {
        a2.status = ActivityStatus.approved;
        a2.transactionId = transactionId;
        a2.encryptFields();
        await isar.smsActivitys.put(a2);
      }
    });
  }
}

// Adapter class to match transaction matching interface
class _PendingTransactionAdapter implements PendingTransactionData {
  @override
  final String? account;
  @override
  final double? amount;
  @override
  final bool? isIncome;
  @override
  final String body;
  final String sender;
  final String? transactionRef;
  final String? category;
  final String smsHash;
  @override
  final String? toAccount;
  @override
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
