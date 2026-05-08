import 'package:mudra_manager/plugins/sms_parsers/rbl_sms_parser.dart';
import 'package:mudra_manager/plugins/sms_parsers/federal_bank_sms_parser.dart';
import 'package:mudra_manager/plugins/sms_parsers/pnb_sms_parser.dart';
import 'package:mudra_manager/plugins/sms_parsers/bob_sms_parser.dart';
import 'package:mudra_manager/plugins/sms_parsers/canara_sms_parser.dart';
import 'package:mudra_manager/plugins/sms_parsers/union_sms_parser.dart';
import 'package:mudra_manager/plugins/sms_parsers/brazil_sms_parser.dart';
import 'package:mudra_manager/plugins/sms_parsers/indonesia_sms_parser.dart';
import 'package:mudra_manager/plugins/sms_parsers/mea_region_sms_parser.dart';
import 'package:mudra_manager/plugins/sms_parsers/latam_sms_parser.dart';
import 'package:mudra_manager/plugins/sms_parsers/europe_sms_parser.dart';
import 'package:mudra_manager/plugins/sms_parsers/generic_international_parser.dart';

import 'sms_parser_plugin.dart';
import 'sms_parsers/hdfc_sms_parser.dart';
import 'sms_parsers/icici_sms_parser.dart';
import 'sms_parsers/sbi_sms_parser.dart';
import 'sms_parsers/axis_sms_parser.dart';
import 'sms_parsers/kotak_sms_parser.dart';
import 'sms_parsers/upi_sms_parsers.dart';
import 'sms_parsers/other_banks_sms_parsers.dart';
import 'package:mudra_manager/features/marketplace/services/marketplace_service.dart';

class SmsParserManager {
  static final SmsParserManager _instance = SmsParserManager._();
  static SmsParserManager get instance => _instance;

  final Map<String, SmsParserPlugin> _allParsers = {};
  final _marketplace = MarketplaceService();

  SmsParserManager._() {
    _registerAllParsers();
  }

  void _registerAllParsers() {
    final parsers = [
      HdfcSmsParserPlugin(),
      IciciSmsParserPlugin(),
      SbiSmsParserPlugin(),
      AxisSmsParserPlugin(),
      KotakSmsParserPlugin(),
      PaytmSmsParserPlugin(),
      PhonePeSmsParserPlugin(),
      GpaySmsParserPlugin(),
      YesBankSmsParserPlugin(),
      IndusIndSmsParserPlugin(),
      IdfcSmsParserPlugin(),
      AuBankSmsParserPlugin(),
      RblSmsParserPlugin(),
      FederalBankSmsParserPlugin(),
      PnbSmsParserPlugin(),
      BobSmsParserPlugin(),
      CanaraSmsParserPlugin(),
      UnionBankSmsParserPlugin(),
      BrazilSmsParser(),
      IndonesiaSmsParser(),
      MeaRegionSmsParser(),
      LatamSmsParser(),
      EuropeSmsParser(),
      GenericInternationalSmsParser(),
    ];

    for (final parser in parsers) {
      _allParsers[parser.id] = parser;
      parser.onLoad();
      parser.onStart();
    }
  }

  void registerParser(SmsParserPlugin parser) {
    _allParsers[parser.id] = parser;
    parser.onLoad();
    parser.onStart();
  }

  Future<ParsedSms?> parseSms(String sender, String body) async {
    final enabledParsers = _getEnabledParsers();
    if (enabledParsers.isEmpty) return null;

    final matching = enabledParsers.where((p) => p.canParse(sender));
    for (final parser in matching) {
      final result = parser.parseSms(sender, body);
      if (result != null) return result;
    }
    return null;
  }

  List<SmsParserPlugin> _getEnabledParsers() {
    return _allParsers.entries
        .where((e) => _marketplace.isPluginEnabledSync(e.key))
        .map((e) => e.value)
        .toList();
  }

  Future<List<String>> getSupportedBanks() async {
    return _getEnabledParsers().map((p) => p.bankName).toList();
  }

  List<SmsParserPlugin> getAllParsers() {
    return List.unmodifiable(_allParsers.values);
  }

  Future<String?> getBankFromSender(String sender) async {
    final senderUpper = sender.toUpperCase();
    for (final parser in _getEnabledParsers()) {
      if (parser.senderNames
          .any((n) => senderUpper.contains(n.toUpperCase()))) {
        return parser.bankName;
      }
    }
    return null;
  }

  SmsParserPlugin? findPluginByBody(String body) {
    final bodyUpper = body.toUpperCase();
    for (final parser in _getEnabledParsers()) {
      if (parser.senderNames.any((n) => bodyUpper.contains(n.toUpperCase()))) {
        return parser;
      }
    }
    return null;
  }
}
