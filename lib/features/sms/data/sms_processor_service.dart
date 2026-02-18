import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/pending_transaction.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';
import 'package:mudra_manager/core/utils/app_logger.dart';
import 'package:mudra_manager/core/utils/string_util.dart';
import 'package:mudra_manager/core/utils/transaction_msg_util.dart';

class SmsProcessorService {
  static final SmsProcessorService instance = SmsProcessorService._();

  SmsProcessorService._();

  Future<void> processSmsForSaving(TransactionInfo sms, int timestamp) async {
    final pending =
        PendingTransaction()
          ..date =
              sms.transactionTime ??
              DateTime.fromMillisecondsSinceEpoch(timestamp)
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
      final isar =
          await getIsarInstance(); // Your function to return open Isar instance
      await isar.writeTxn(() async {
        await isar.pendingTransactions.put(pending);
      });
      AppLogger.info(
        'Transaction saved, sender: ${sms.sender} amount: ${sms.money} type: ${sms.typeOfTransaction?.name}',
        tag: 'SMS',
      );
    } catch (e) {
      AppLogger.error('Failed to save SMS transaction', error: e);
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
