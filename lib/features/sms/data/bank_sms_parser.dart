import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:mudra_manager/features/sms/data/sms_parser_manager.dart';
import 'package:mudra_manager/features/sms/data/sms_parser_plugin.dart';

class BankSmsParser {
  static final _log = AppLog(getLogger(), 'BankSmsParser');

  static Future<ParsedSms?> parse(String sender, String body) async {
    // Try plugin-based parsing first
    final pluginResult = await SmsParserManager.instance.parseSms(sender, body);
    if (pluginResult != null) {
      _log.i('SMS parsed by plugin for sender: $sender');
      return pluginResult;
    }

    // Fallback to legacy parsing
    _log.i('Using legacy parser for sender: $sender');
    return _parseLegacy(sender, body);
  }

  static ParsedSms? _parseLegacy(String sender, String body) {
    // If body has clear transaction signals, skip promo filter
    if (!_hasTransactionKeywords(body) && _isPromotionalSms(body)) {
      _log.i('Rejected promotional SMS from $sender');
      return null;
    }

    final bank = _detectBank(sender);
    _log.i('Legacy parsing SMS from $sender (Bank: ${bank ?? "Unknown"})');

    // Body-based bank detection fallback: when sender is a display name that
    // didn't match any plugin via canParse, try to find a plugin by scanning
    // the body for bank keywords.
    final bodyPlugin = _detectBankFromBody(body);
    if (bodyPlugin != null) {
      _log.i('Body-based bank detection matched plugin: ${bodyPlugin.bankName}');
      final result = bodyPlugin.parseSms(sender, body);
      if (result != null) return result;
    }

    return _parseGeneric(body);
  }

  static SmsParserPlugin? _detectBankFromBody(String body) {
    return SmsParserManager.instance.findPluginByBody(body);
  }

  // Promotional/marketing keywords that indicate non-transaction SMS
  static final _promotionalKeywords = [
    'shop for',
    'get best deals',
    'offer',
    'discount',
    'cashback',
    'sale',
    'buy now',
    'limited time',
    'hurry',
    'click here',
    'visit',
    'download',
    'install',
    'register',
    'sign up',
    'win',
    'prize',
    'congratulations',
    'free',
    'bonus',
    'loan facility',
    'has been enabled',
    'based on your',
    'eligible for',
    'pre-approved',
    'apply now',
    'avail',
  ];

  static bool _isPromotionalSms(String body) {
    final bodyLower = body.toLowerCase();
    return _promotionalKeywords.any((keyword) => bodyLower.contains(keyword));
  }

  static String? _detectBank(String sender) {
    final s = sender.toUpperCase();
    if (s.contains('HDFC')) return 'HDFC';
    if (s.contains('ICICI')) return 'ICICI';
    if (s.contains('SBI') || s.contains('SBIINB')) return 'SBI';
    if (s.contains('AXIS')) return 'AXIS';
    if (s.contains('KOTAK')) return 'KOTAK';
    if (s.contains('YESBNK') || s.contains('YESBANK')) return 'YES';
    if (s.contains('INDUS')) return 'INDUSIND';
    if (s.contains('IDFC')) return 'IDFC';
    if (s.contains('AUBANK')) return 'AU';
    if (s.contains('PAYTM')) return 'PAYTM';
    if (s.contains('PHONEPE') || s.contains('PHPEPE')) return 'PHONEPE';
    if (s.contains('GPAY') || s.contains('GOOGLE')) return 'GPAY';
    if (s.contains('RBL')) return 'RBL';
    return null;
  }

  static bool _hasTransactionKeywords(String body) {
    final bodyLower = body.toLowerCase();
    final transactionKeywords = [
      'debited',
      'credited',
      'charged',
      'spent',
      'received',
      'recieved',
      'paid',
      'withdrawn',
      'sent',
      'transferred',
      'added',
    ];
    return transactionKeywords.any((keyword) => bodyLower.contains(keyword));
  }

  static ParsedSms? _parseGeneric(String body) {
    // Generic fallback parser
    if (!_hasTransactionKeywords(body)) return null;

    final amountRegex = RegExp(
      r'(?:(USD|GBP|EUR|AED|SGD|JPY|HKD|CAD|AUD|CHF|\$|£|€|¥|Rs\.?(?:\s*INR)?|INR|₹)\s*)([\d,]+(?:\.\d{1,2})?)',
    );
    final accountRegex = RegExp(
      r'(?:A/c|account|card)\s*(?:ending\s*)?[xX]*([\dxX]{4})',
      caseSensitive: false,
    );

    // Check for transfer patterns (money going OUT)
    final transferOutRegex = RegExp(
      r'(?:rec(?:ei|ie)ved|transferred|sent).*from\s+(?:your\s+)?(?:A/c|a/c)',
      caseSensitive: false,
    );
    final transferInRegex = RegExp(
      r'(?:received|credited).*(?:to|in)\s+(?:your\s+)?(?:A/c|a/c)',
      caseSensitive: false,
    );

    // Standard debit/credit patterns
    final typeRegex = RegExp(
      r'(debited|credited|charged|spent|received|paid|withdrawn|added)',
      caseSensitive: false,
    );

    final amountMatch = amountRegex.firstMatch(body);
    final currency = amountMatch?.group(1);
    final amount = _extractAmountFromGroup(amountMatch, 2);
    final account = accountRegex.firstMatch(body)?.group(1);

    // Determine transaction direction
    bool isIncome;
    if (transferOutRegex.hasMatch(body)) {
      // "received from your A/c" = money going OUT (debit)
      isIncome = false;
    } else if (transferInRegex.hasMatch(body)) {
      // "received to your A/c" = money coming IN (credit)
      isIncome = true;
    } else {
      // Fall back to standard keywords
      final type = typeRegex.firstMatch(body)?.group(1)?.toLowerCase();
      isIncome = type == 'credited' || type == 'received' || type == 'added';
    }

    if (amount == null) return null;

    return ParsedSms(
      amount: amount,
      isIncome: isIncome,
      account: account,
      currency: currency,
    );
  }

  static double? _extractAmountFromGroup(RegExpMatch? match, int group) {
    if (match == null) return null;
    final amountStr = match.group(group)?.replaceAll(',', '');
    return double.tryParse(amountStr ?? '');
  }


}
