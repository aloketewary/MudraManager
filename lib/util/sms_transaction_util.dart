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
          ..account = sms.account?.sendTo
          ..amount = sms.money?.toDouble()
          ..isIncome = sms.typeOfTransaction == TransactionType.credited
          ..body = sms.body
          ..sender = sms.sender
          ..transactionRef = sms.account?.refNo
          ..category = sms.typeOfTransaction?.name
          ..smsHash = sms.smsHash
          ..toAccount = sms.account?.type == 'UPI' ? sms.account?.sendTo : '';

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

  void parseAndSaveTransaction(String sms) {
    var transactionalMessage = checkForTransactionalMessage(sms);
    if (transactionalMessage) {
      var smsMessage = parseSms(sms);
      checkForDuplicateEntryAndProcess(smsMessage);
    }
  }

  parseSms(String sms) {
    var smsMessage = SmsMessage.fromJson(json.decode(sms));
    return smsMessage;
  }

  void checkForDuplicateEntryAndProcess(SmsMessage sms) {
    TransactionUtil transactionUtil = TransactionUtil();
    var smsHash = generateSmsHash(
      sms.address ?? '',
      sms.date?.millisecondsSinceEpoch,
      sms.body ?? '',
    );
    var alreadyProcessed = SharedPrefsUtil.instance.isAlreadyProcessed(smsHash);
    if (!alreadyProcessed) {
      SharedPrefsUtil.instance.storeProcessedHash(smsHash);
      var transactionInfo = transactionUtil.getTransactionInfo(
        sms.body,
        sms.address,
        sms.sender,
        smsHash,
      );
      processSmsForSaving(transactionInfo);
    } else {
      debugPrint("Skipping already processed SMS from ${sms.address}");
    }
  }

  Future<Isar> getIsarInstance() async {
    if (Isar.instanceNames.isEmpty) {
      return await IsarService.initIsar();
    }
    return Isar.getInstance()!;
  }
}
