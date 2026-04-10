import 'package:mudra_manager/core/db/models/sms_activity.dart';
import 'package:mudra_manager/core/services/plugin_service.dart';
import 'package:mudra_manager/core/utils/utils.dart';
import 'package:mudra_manager/plugins/sms_parser_manager.dart';
import 'package:mudra_manager/plugins/sms_parser_plugin.dart';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';
import 'package:mudra_manager/core/utils/transaction_msg_util.dart';
import 'package:mudra_manager/features/sms/data/sms_activity_service.dart';

enum ParseResult { approved, pending, needsReview, duplicate, skipped, error }

class SmsProcessorService {
  static final SmsProcessorService instance = SmsProcessorService._();
  static final AppLog _log = AppLog(getLogger(), 'SmsProcessorService');

  SmsProcessorService._();

  Future<SmsActivity> processSmsForSaving(
    TransactionInfo sms,
    int timestamp,
  ) async {
    final notifTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    DateTime transactionDate;

    if (sms.transactionTime != null) {
      final parsed = sms.transactionTime!;
      // If parser got a date but time is midnight, it likely only parsed the date.
      // Use the notification timestamp's time instead.
      if (parsed.hour == 0 && parsed.minute == 0 && parsed.second == 0) {
        transactionDate = DateTime(
          parsed.year,
          parsed.month,
          parsed.day,
          notifTime.hour,
          notifTime.minute,
          notifTime.second,
        );
      } else {
        transactionDate = parsed;
      }
    } else {
      transactionDate = notifTime;
    }

    try {
      final activity = await SmsActivityService.instance.addActivity(
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

      PluginService().emitSms(sms.sender, sms.body);
      _log.i(
        'Auto Import processed and added to activity, sender: ${sms.sender}',
      );
      return activity;
    } catch (e) {
      _log.e('Failed to process SMS transaction', e);
      rethrow;
    }
  }

  Future<ParseResult> parseAndSaveTransaction({
    required String body,
    required String address,
    String? sender,
    required int timestamp,
  }) async {
    if (!checkForTransactionalMessage(body)) {
      _log.i('Message filtered out (not transactional) sender: $address, body: $body');
      return ParseResult.skipped;
    }

    final smsHash = generateSmsHash(address, timestamp, body);

    if (SharedPrefsUtil.instance.isAlreadyProcessed(smsHash)) {
      _log.i(
        'Message already processed, skipping... sender: $address hash: $smsHash',
      );
      return ParseResult.skipped;
    }

    SharedPrefsUtil.instance.storeProcessedHash(smsHash);

    try {
      SmsActivity activity;

      // Try plugin-based parsing first
      final parsedSms = await SmsParserManager.instance.parseSms(address, body);
      if (parsedSms != null) {
        _log.i('Auto Import parsed by plugin, sender: $address');
        activity = await _processPluginParsedSms(
          parsedSms,
          address,
          timestamp,
          smsHash,
          body,
        );
      } else {
        // Fallback to legacy parsing
        final transactionUtil = TransactionUtil();
        final transactionInfo = transactionUtil.getTransactionInfo(
          body,
          address,
          sender,
          smsHash,
        );
        _log.i('Auto Import Parsed by legacy parser, sender: $address');
        activity = await processSmsForSaving(transactionInfo, timestamp);
      }

      return switch (activity.status) {
        ActivityStatus.approved => ParseResult.approved,
        ActivityStatus.duplicate => ParseResult.duplicate,
        ActivityStatus.needsReview => ParseResult.needsReview,
        _ => ParseResult.pending,
      };
    } catch (e) {
      _log.e('Failed to parse and save transaction', e);
      return ParseResult.error;
    }
  }

  Future<SmsActivity> _processPluginParsedSms(
    ParsedSms parsedSms,
    String sender,
    int timestamp,
    String smsHash,
    String body,
  ) async {
    final transactionDate = DateTime.fromMillisecondsSinceEpoch(timestamp);

    try {
      final activity = await SmsActivityService.instance.addActivity(
        sender: sender,
        body: body,
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
      _log.i('Plugin-parsed Auto Import processed, sender: $sender');
      return activity;
    } catch (e) {
      _log.e('Failed to process plugin-parsed SMS', e);
      rethrow;
    }
  }

  String generateSmsHash(String address, int timestamp, String body) {
    final input = '$address|$timestamp|$body';
    return sha256.convert(utf8.encode(input)).toString();
  }
}
