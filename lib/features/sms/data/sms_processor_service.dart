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
import 'package:mudra_manager/features/sms/data/sms_activity_service.dart';

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
    final transactionDate =
        sms.transactionTime ?? DateTime.fromMillisecondsSinceEpoch(timestamp);

    try {
      // Add to SMS Activity for tracking
      await SmsActivityService.instance.addActivity(
        sender: sms.sender,
        body: sms.body,
        date: transactionDate,
        smsHash: sms.smsHash,
        amount: sms.money?.toDouble(),
        isIncome: sms.typeOfTransaction == TransactionType.credited,
        account: sms.account?.no,
        fromBank: sms.account?.bankName,
        toAccount: sms.account?.sendTo,
        transactionRef: sms.account?.refNo,
        category: sms.typeOfTransaction?.name,
      );

      _log.i('SMS processed and added to activity, sender: ${sms.sender}');
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
