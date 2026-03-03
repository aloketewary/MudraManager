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
  final Map<String, SmsParserPlugin> _enabledParsers = {}; // Cache enabled parsers
  final _marketplaceService = MarketplaceService();
  DateTime? _lastEnabledCheck;
  static const _cacheTimeout = Duration(minutes: 5);
  
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
    final enabledParsers = await _getCachedEnabledParsers();
    
    // Early exit if no enabled parsers
    if (enabledParsers.isEmpty) return null;
    
    // Optimize: Check sender match first before parsing
    final matchingParsers = enabledParsers.where((parser) => parser.canParse(sender)).toList();
    
    for (final parser in matchingParsers) {
      final result = parser.parseSms(sender, body);
      if (result != null) return result;
    }
    return null;
  }

  Future<List<SmsParserPlugin>> _getCachedEnabledParsers() async {
    final now = DateTime.now();
    
    // Use cached enabled parsers if within timeout
    if (_lastEnabledCheck != null && 
        now.difference(_lastEnabledCheck!) < _cacheTimeout &&
        _enabledParsers.isNotEmpty) {
      return _enabledParsers.values.toList();
    }
    
    // Refresh cache
    _enabledParsers.clear();
    for (final entry in _allParsers.entries) {
      if (await _marketplaceService.isPluginEnabled(entry.key)) {
        _enabledParsers[entry.key] = entry.value;
      }
    }
    _lastEnabledCheck = now;
    
    return _enabledParsers.values.toList();
  }

  Future<List<String>> getSupportedBanks() async {
    final enabledParsers = await _getCachedEnabledParsers();
    return enabledParsers.map((p) => p.bankName).toList();
  }

  List<SmsParserPlugin> getAllParsers() {
    return List.unmodifiable(_allParsers.values);
  }

  Future<String?> getBankFromSender(String sender) async {
    final enabledParsers = await _getCachedEnabledParsers();
    final senderUpper = sender.toUpperCase(); // Cache uppercase conversion
    
    for (final parser in enabledParsers) {
      if (parser.senderNames.any((name) => senderUpper.contains(name.toUpperCase()))) {
        return parser.bankName;
      }
    }
    return null;
  }
}
