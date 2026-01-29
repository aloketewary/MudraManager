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
    } catch (e) {
      // Log for background — no context
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
      return;
    }

    // Generate hash to prevent duplicates
    final smsHash = generateSmsHash(address, timestamp, body);

    // Check if already processed
    if (SharedPrefsUtil.instance.isAlreadyProcessed(smsHash)) {
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
