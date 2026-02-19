import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/pending_transaction.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';
import 'package:mudra_manager/core/utils/app_logger.dart';
import 'package:mudra_manager/core/utils/string_util.dart';
import 'package:mudra_manager/core/utils/transaction_msg_util.dart';
import 'package:mudra_manager/features/transactions/data/transaction_matching_service.dart';

class SmsProcessorService {
  static final SmsProcessorService instance = SmsProcessorService._();

  SmsProcessorService._();

  Future<void> processSmsForSaving(TransactionInfo sms, int timestamp) async {
    final isar = await getIsarInstance();

    // Load accounts and categories for matching
    final accounts = await isar.accounts.where().findAll();
    final categories = await isar.categorys.where().findAll();

    AppLogger.info(
      'Matching attempt: ${accounts.length} accounts, ${categories.length} categories available',
      tag: 'SMS',
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
      // Try to match account and category
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

        AppLogger.info(
          'Transaction auto-added: ${matchResult.category.name} - ₹${pending.amount} (${matchResult.account.name})',
          tag: 'SMS',
        );
      } else {
        // Save to pending if no match
        await isar.writeTxn(() async {
          await isar.pendingTransactions.put(pending);
        });

        AppLogger.info(
          'Transaction saved to pending (no match), account: ${pending.account}, sender: ${sms.sender}, amount: ${sms.money}',
          tag: 'SMS',
        );
      }
    } catch (e) {
      AppLogger.error('Failed to process SMS transaction', error: e);
    }
  }

  void parseAndSaveTransaction({
    required String body,
    required String address,
    String? sender,
    required int timestamp,
  }) {
    if (!checkForTransactionalMessage(body)) {
      AppLogger.info(
        'SMS filtered out (not transactional) sender: $address',
        tag: 'SMS',
      );
      return;
    }

    final smsHash = generateSmsHash(address, timestamp, body);

    if (SharedPrefsUtil.instance.isAlreadyProcessed(smsHash)) {
      AppLogger.info(
        'SMS already processed, skipping... sender: $address hash: $smsHash',
        tag: 'SMS',
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
    AppLogger.info('SMS Parsed successfully, sender: $address', tag: 'SMS');

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
