import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/pending_transaction.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';
import 'package:mudra_manager/core/utils/string_util.dart';
import 'package:mudra_manager/core/utils/transaction_msg_util.dart';
import 'package:mudra_manager/features/transactions/data/transaction_matching_service.dart';

class SmsProcessorService {
  static final SmsProcessorService instance = SmsProcessorService._();
  static final AppLog _log = AppLog(getLogger(), 'SmsProcessorService');
  
  bool _autoApprovalEnabled = true;

  SmsProcessorService._();

  void setAutoApproval(bool enabled) {
    _autoApprovalEnabled = enabled;
    _log.i('Auto-approval ${enabled ? "enabled" : "disabled"}');
  }

  bool get isAutoApprovalEnabled => _autoApprovalEnabled;

  Future<void> processSmsForSaving(TransactionInfo sms, int timestamp) async {
    final isar = await getIsarInstance();

    // Load accounts and categories for matching
    final accounts = await isar.accounts.where().findAll();
    final categories = await isar.categorys.where().findAll();

    _log.i(
      'Matching attempt: ${accounts.length} accounts, ${categories.length} categories available',
    );

    // Use parsed date from SMS, fallback to SMS timestamp
    final transactionDate =
        sms.transactionTime ?? DateTime.fromMillisecondsSinceEpoch(timestamp);

    final pending = PendingTransaction()
      ..date = transactionDate
      ..account = sms.account?.no
      ..amount = sms.money?.toDouble()
      ..isIncome = sms.typeOfTransaction == TransactionType.credited
      ..body = sms.body
      ..sender = sms.sender
      ..transactionRef = sms.account?.refNo
      ..category = sms.typeOfTransaction?.name
      ..smsHash = sms.smsHash
      ..toAccount = sms.account?.sendTo
      ..fromBank = sms.account?.bankName;

    try {
      if (_autoApprovalEnabled) {
        // Try to match account and category for auto-approval
        final matchResult = TransactionMatchingService.matchTransaction(
          pending: pending,
          accounts: accounts,
          categories: categories,
        );

        if (matchResult != null) {
          // Auto-add transaction if both account and category matched
          final transaction = Transaction()
            ..amount = pending.amount ?? 0
            ..date = transactionDate
            ..description = pending.body
            ..isExpense = !(pending.isIncome == true)
            ..isTransfer = false;

          transaction.account.value = matchResult.account;
          transaction.category.value = matchResult.category;

          await isar.writeTxn(() async {
            await isar.transactions.put(transaction);
            await transaction.account.save();
            await transaction.category.save();
          });

          _log.i(
            'Transaction auto-added: ${matchResult.category.name} - ₹${pending.amount} (${matchResult.account.name})',
          );
          return;
        }
      }

      // Save to pending if auto-approval disabled or no match
      await isar.writeTxn(() async {
        await isar.pendingTransactions.put(pending);
      });

      _log.i(
        'Transaction saved to pending${_autoApprovalEnabled ? " (no match)" : " (manual approval mode)"}, sender: ${sms.sender}, amount: ${sms.money}',
      );
    } catch (e) {
      _log.e('Failed to process SMS transaction', e);
    }
  }

  void parseAndSaveTransaction({
    required String body,
    required String address,
    String? sender,
    required int timestamp,
  }) {
    if (!checkForTransactionalMessage(body)) {
      _log.i('SMS filtered out (not transactional) sender: $address');
      return;
    }

    final smsHash = generateSmsHash(address, timestamp, body);

    if (SharedPrefsUtil.instance.isAlreadyProcessed(smsHash)) {
      _log.i(
        'SMS already processed, skipping... sender: $address hash: $smsHash',
      );
      return;
    }

    SharedPrefsUtil.instance.storeProcessedHash(smsHash);

    final transactionUtil = TransactionUtil();
    final transactionInfo = transactionUtil.getTransactionInfo(
      body,
      address,
      sender,
      smsHash,
    );
    _log.i('SMS Parsed successfully, sender: $address');

    processSmsForSaving(transactionInfo, timestamp);
  }

  String generateSmsHash(String address, int timestamp, String body) {
    final input = '$address|$timestamp|$body';
    return sha256.convert(utf8.encode(input)).toString();
  }

  Future<Isar> getIsarInstance() async {
    if (Isar.instanceNames.isEmpty) {
      return await IsarService.initIsar();
    }
    return Isar.getInstance()!;
  }
}
