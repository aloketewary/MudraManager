import 'package:mudra_manager/core/services/plugin_service.dart';
import 'package:mudra_manager/plugins/sms_parser_manager.dart';
import 'package:mudra_manager/plugins/sms_parser_plugin.dart';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';
import 'package:mudra_manager/core/utils/string_util.dart';
import 'package:mudra_manager/core/utils/transaction_msg_util.dart';
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

      // Emit SMS event to plugins
      PluginService().emitSms(sms.sender, sms.body);

      _log.i('SMS processed and added to activity, sender: ${sms.sender}');
    } catch (e) {
      _log.e('Failed to process SMS transaction', e);
    }
  }

  Future<void> parseAndSaveTransaction({
    required String body,
    required String address,
    String? sender,
    required int timestamp,
  }) async {
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

    // Try plugin-based parsing first
    final parsedSms = await SmsParserManager.instance.parseSms(address, body);
    if (parsedSms != null) {
      _log.i('SMS parsed by plugin, sender: $address');
      _processPluginParsedSms(parsedSms, address, timestamp, smsHash);
      return;
    }

    // Fallback to legacy parsing
    final transactionUtil = TransactionUtil();
    final transactionInfo = transactionUtil.getTransactionInfo(
      body,
      address,
      sender,
      smsHash,
    );
    _log.i('SMS Parsed by legacy parser, sender: $address');

    processSmsForSaving(transactionInfo, timestamp);
  }

  Future<void> _processPluginParsedSms(
    ParsedSms parsedSms,
    String sender,
    int timestamp,
    String smsHash,
  ) async {
    final transactionDate = DateTime.fromMillisecondsSinceEpoch(timestamp);

    try {
      await SmsActivityService.instance.addActivity(
        sender: sender,
        body: '',
        date: transactionDate,
        smsHash: smsHash,
        amount: parsedSms.amount,
        isIncome: parsedSms.isIncome,
        account: parsedSms.account,
        fromBank: await SmsParserManager.instance.getBankFromSender(sender),
        toAccount: parsedSms.merchant,
        transactionRef: null,
        category: parsedSms.transactionType,
      );

      PluginService().emitSms(sender, '');
      _log.i('Plugin-parsed SMS processed, sender: $sender');
    } catch (e) {
      _log.e('Failed to process plugin-parsed SMS', e);
    }
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
