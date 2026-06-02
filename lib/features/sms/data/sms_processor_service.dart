import 'package:mudra_manager/core/db/models/sms_activity.dart';
import 'package:mudra_manager/core/services/plugin_service.dart';
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

typedef ParseOutput = ({ParseResult result, double? amount});

class SmsProcessorService {
  static final SmsProcessorService instance = SmsProcessorService._();
  static final AppLog _log = AppLog(getLogger(), 'SmsProcessorService');

  SmsProcessorService._();

  Future<SmsActivity> processSmsForSaving(
    TransactionInfo sms,
    int timestamp, [
    String corrId = '',
    bool isRcs = false,
  ]) async {
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
      final rawMoney = sms.money?.trim();
      final amount = (rawMoney != null && rawMoney.isNotEmpty)
          ? double.tryParse(rawMoney.replaceAll(',', ''))
          : null;
      final activity = await SmsActivityService.instance.addActivity(
        sender: sms.sender,
        body: sms.body,
        date: transactionDate,
        smsHash: sms.smsHash,
        amount: amount == 0 ? null : amount,
        isIncome: sms.typeOfTransaction == TransactionType.credited,
        account: sms.account?.no,
        fromBank: sms.account?.bankName,
        toAccount: sms.account?.sendTo,
        transactionRef: sms.account?.refNo,
        category: sms.typeOfTransaction?.name,
        corrId: corrId,
        isRcs: isRcs,
      );

      PluginService().emitSms(sms.sender, sms.body);
      _log.i('[$corrId] Processed sender: ${sms.sender.length > 4 ? '${sms.sender.substring(0, 4)}***' : sms.sender}, hasAmount: ${amount != null}');
      return activity;
    } catch (e) {
      _log.e('[$corrId] Failed to process SMS transaction', e);
      rethrow;
    }
  }

  Future<ParseOutput> parseAndSaveTransaction({
    required String body,
    required String address,
    String? sender,
    required int timestamp,
    String corrId = '',
    bool isRcs = false,
  }) async {
    final smsHash = generateSmsHash(address, timestamp, body);

    if (SharedPrefsUtil.instance.isAlreadyProcessed(smsHash)) {
      _log.i('[$corrId] Already processed, skipping sender: $address');
      return (result: ParseResult.skipped, amount: null);
    }

    try {
      SmsActivity activity;

      // 1. Try plugin parsers FIRST — they know their bank's formats
      //    and can handle messages that don't have standard keywords.
      final parsedSms = await SmsParserManager.instance.parseSms(address, body);
      if (parsedSms != null) {
        _log.i('[$corrId] Parsed by plugin, sender: $address');
        activity = await _processPluginParsedSms(
          parsedSms, address, timestamp, smsHash, body, corrId, isRcs,
        );
      } else {
        // 2. No plugin matched — apply keyword filter before legacy parser.
        //    This prevents personal messages / promos from reaching the
        //    generic parser which would create low-quality activities.
        if (!checkForTransactionalMessage(body)) {
          _log.i('[$corrId] Filtered (not transactional) sender: $address');
          return (result: ParseResult.skipped, amount: null);
        }

        // 3. Legacy parser fallback
        final transactionUtil = TransactionUtil();
        final transactionInfo = transactionUtil.getTransactionInfo(
          body, address, sender, smsHash,
        );
        _log.i('[$corrId] Parsed by legacy parser, sender: $address');
        activity = await processSmsForSaving(transactionInfo, timestamp, corrId, isRcs);
      }

      // Only store hash after successful processing
      SharedPrefsUtil.instance.storeProcessedHash(smsHash);

      final parsedResult = switch (activity.status) {
        ActivityStatus.approved => ParseResult.approved,
        ActivityStatus.duplicate => ParseResult.duplicate,
        ActivityStatus.needsReview => ParseResult.needsReview,
        _ => ParseResult.pending,
      };
      return (result: parsedResult, amount: activity.amount);
    } catch (e) {
      _log.e('Failed to parse and save transaction', e);
      return (result: ParseResult.error, amount: null);
    }
  }

  Future<SmsActivity> _processPluginParsedSms(
    ParsedSms parsedSms,
    String sender,
    int timestamp,
    String smsHash,
    String body,
    String corrId, [
    bool isRcs = false,
  ]) async {
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
        corrId: corrId,
        isRcs: isRcs,
        currencyCode: parsedSms.currency,
      );

      PluginService().emitSms(sender, '');
      _log.i('[$corrId] Plugin-parsed, sender: ${sender.length > 4 ? '${sender.substring(0, 4)}***' : sender}, amount: ***');
      return activity;
    } catch (e) {
      _log.e('[$corrId] Failed to process plugin-parsed SMS', e);
      rethrow;
    }
  }

  String generateSmsHash(String address, int timestamp, String body) {
    final input = '$address|$timestamp|$body';
    return sha256.convert(utf8.encode(input)).toString();
  }
}
