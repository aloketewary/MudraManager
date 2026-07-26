import 'package:mudra_plugin_sdk/plugin.dart';

abstract class SmsParserPlugin extends MudraPlugin {
  ParsedSms? parseSms(String sender, String body);
  bool canParse(String sender);
  String get bankName;
  List<String> get senderNames;
  String get iconPath;
}

class ParsedSms {
  final double amount;
  final bool isIncome;
  final String? account;
  final String? transactionType;
  final String? merchant;
  final double? balance;
  final bool isLikelyTransfer;
  final String? currency;

  ParsedSms({
    required this.amount,
    required this.isIncome,
    this.account,
    this.transactionType,
    this.merchant,
    this.balance,
    this.isLikelyTransfer = false,
    this.currency,
  });

  /// Detects "[someone] has received ... from your A/c" pattern — this is a
  /// debit (money left the user's account), NOT income.
  static final _receivedFromAccountRegex = RegExp(
    r'rec(?:ei|ie)ved.*from\s+(?:your\s+)?(?:a/c|account)',
    caseSensitive: false,
  );

  /// Returns true only if "received" genuinely means money coming IN to the
  /// user's account. Returns false for "X received from your A/c" (debit).
  static bool isReceivedCredit(String body) {
    final b = body.toLowerCase();
    if (!b.contains('received') && !b.contains('recieved')) return false;
    return !_receivedFromAccountRegex.hasMatch(body);
  }
}
