import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:isar/isar.dart';
import 'package:mudra_manager/db/isar_service.dart';
import 'package:mudra_manager/db/models/pending_transaction.dart'
    show
        GetPendingTransactionCollection,
        PendingTransaction,
        PendingTransactionSchema;
import 'package:mudra_manager/providers/shared_preference_provider.dart'
    show SharedPrefsUtil;
import 'package:mudra_manager/util/string_util.dart';
import 'package:mudra_manager/util/transaction_msg_util.dart';
import 'package:mudra_manager/util/app_logger.dart';

class SmsProcessorService {
  static final SmsProcessorService instance = SmsProcessorService._();

  SmsProcessorService._();

  Future<void> processSmsForSaving(TransactionInfo sms) async {
    final pending =
        PendingTransaction()
          ..date = sms.transactionTime ?? DateTime.now()
          ..account = sms.account?.no
          ..amount = sms.money?.toDouble()
          ..isIncome = sms.typeOfTransaction == TransactionType.credited
          ..body = sms.body
          ..sender = sms.sender
          ..transactionRef = sms.account?.refNo
          ..category = sms.typeOfTransaction?.name
          ..smsHash = sms.smsHash
          ..toAccount = sms.account?.sendTo;

    try {
      final isar =
          await getIsarInstance(); // Your function to return open Isar instance
      await isar.writeTxn(() async {
        await isar.pendingTransactions.put(pending);
      });
      
      AppLogger.logSMS('Transaction saved', details: {
        'sender': sms.sender,
        'amount': sms.money,
        'type': sms.typeOfTransaction?.name,
      });
    } catch (e) {
      AppLogger.error('Failed to save SMS transaction', error: e);
      print('Failed to save SMS transaction: $e');
    }
  }

  /// Process raw SMS data and save as pending transaction if it's financial
  void parseAndSaveTransaction({
    required String body,
    required String address,
    String? sender,
    required int timestamp,
  }) {
    // Check if this is a transactional message
    if (!checkForTransactionalMessage(body)) {
      AppLogger.logSMS('SMS filtered out (not transactional)', details: {
        'sender': address,
      });
      return;
    }

    // Generate hash to prevent duplicates
    final smsHash = generateSmsHash(address, timestamp, body);

    // Check if already processed
    if (SharedPrefsUtil.instance.isAlreadyProcessed(smsHash)) {
      AppLogger.logSMS('SMS already processed', details: {
        'sender': address,
        'hash': smsHash.substring(0, 8),
      });
      debugPrint("Skipping already processed SMS from $address");
      return;
    }

    // Mark as processed
    SharedPrefsUtil.instance.storeProcessedHash(smsHash);

    // Parse transaction info
    final transactionUtil = TransactionUtil();
    final transactionInfo = transactionUtil.getTransactionInfo(
      body,
      address,
      sender,
      smsHash,
    );

    AppLogger.logSMS('SMS parsed successfully', details: {
      'sender': address,
      'amount': transactionInfo.money,
      'account': transactionInfo.account?.no,
    });

    // Save to pending transactions
    processSmsForSaving(transactionInfo);
  }

  Future<Isar> getIsarInstance() async {
    if (Isar.instanceNames.isEmpty) {
      return await IsarService.initIsar();
    }
    return Isar.getInstance()!;
  }
}
