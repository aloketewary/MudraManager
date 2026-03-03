import 'package:mudra_plugin_sdk/plugin.dart';
import 'package:mudra_plugin_sdk/events.dart';

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

  ParsedSms({
    required this.amount,
    required this.isIncome,
    this.account,
    this.transactionType,
    this.merchant,
    this.balance,
  });
}