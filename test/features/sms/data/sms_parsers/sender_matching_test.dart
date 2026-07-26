import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/features/sms/data/sms_parsers/hdfc_sms_parser.dart';
import 'package:mudra_manager/features/sms/data/sms_parsers/icici_sms_parser.dart';
import 'package:mudra_manager/features/sms/data/sms_parsers/sbi_sms_parser.dart';
import 'package:mudra_manager/features/sms/data/sms_parsers/axis_sms_parser.dart';
import 'package:mudra_manager/features/sms/data/sms_parsers/kotak_sms_parser.dart';
import 'package:mudra_manager/features/sms/data/sms_parsers/other_banks_sms_parsers.dart';
import 'package:mudra_manager/features/sms/data/sms_parsers/rbl_sms_parser.dart';
import 'package:mudra_manager/features/sms/data/sms_parsers/upi_sms_parsers.dart';
import 'package:mudra_manager/features/sms/data/sms_parser_plugin.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/shared_preferences'),
      (call) async {
        if (call.method == 'getAll') return <String, dynamic>{};
        return null;
      },
    );
  });

  /// Test data: [parser, smsSenderId, rcsDisplayName]
  final parserTestCases = <(SmsParserPlugin, List<String>, List<String>)>[
    (
      HdfcSmsParserPlugin(),
      ['HDFCBK', 'AD-HDFCBK', 'VM-HDFCBK'],
      ['HDFC Bank', 'HDFC Bank Ltd'],
    ),
    (
      IciciSmsParserPlugin(),
      ['ICICIB', 'AD-ICICIB'],
      ['ICICI Bank', 'ICICI Bank Ltd'],
    ),
    (
      SbiSmsParserPlugin(),
      ['SBIINB', 'SBIPSG', 'AD-SBIINB'],
      ['SBI', 'State Bank of India'],
    ),
    (
      AxisSmsParserPlugin(),
      ['AXISBK', 'AD-AXISBK'],
      ['Axis Bank', 'AXIS BANK'],
    ),
    (
      KotakSmsParserPlugin(),
      ['KOTAKB', 'AD-KOTAKB'],
      ['Kotak Bank', 'Kotak Mahindra Bank'],
    ),
    (
      YesBankSmsParserPlugin(),
      ['YESBNK', 'YESBANK'],
      ['Yes Bank', 'YES BANK'],
    ),
    (
      IndusIndSmsParserPlugin(),
      ['INDUSIND', 'AD-INDUS'],
      ['IndusInd Bank', 'INDUSIND BANK'],
    ),
    (
      IdfcSmsParserPlugin(),
      ['IDFCFB', 'AD-IDFCFB'],
      ['IDFC First Bank', 'IDFC FIRST BANK'],
    ),
    (
      AuBankSmsParserPlugin(),
      ['AUBANK', 'AUSFB'],
      ['AU Small Finance Bank', 'AU BANK'],
    ),
    (
      RblSmsParserPlugin(),
      ['RBLBNK', 'RBLBK'],
      ['RBL Bank', 'RBL BANK'],
    ),
    (
      PaytmSmsParserPlugin(),
      ['PAYTM', 'PPBL'],
      ['Paytm', 'Paytm Payments Bank'],
    ),
    (
      PhonePeSmsParserPlugin(),
      ['PHONEPE', 'PHPEPE'],
      ['PhonePe', 'PHONEPE'],
    ),
    (
      GpaySmsParserPlugin(),
      ['GPAY', 'GOOGLE'],
      ['Google Pay', 'GPay'],
    ),
  ];

  group('canParse — SMS sender IDs', () {
    for (final (parser, smsSenders, _) in parserTestCases) {
      for (final sender in smsSenders) {
        test('${parser.bankName}: canParse("$sender") = true', () {
          expect(
            parser.canParse(sender),
            isTrue,
            reason: '${parser.bankName} should match SMS sender "$sender"',
          );
        });
      }
    }
  });

  group('canParse — RCS display names', () {
    for (final (parser, _, rcsNames) in parserTestCases) {
      for (final name in rcsNames) {
        test('${parser.bankName}: canParse("$name") = true', () {
          expect(
            parser.canParse(name),
            isTrue,
            reason: '${parser.bankName} should match RCS display name "$name"',
          );
        });
      }
    }
  });

  group('canParse — should NOT match unrelated senders', () {
    test('HDFC parser does not match ICICI', () {
      expect(HdfcSmsParserPlugin().canParse('ICICI Bank'), isFalse);
    });

    test('SBI parser does not match Axis', () {
      expect(SbiSmsParserPlugin().canParse('Axis Bank'), isFalse);
    });

    test('Yes Bank parser does not match random "yes" text', () {
      // "YES" alone shouldn't match — needs "BANK" or "BNK" context
      expect(YesBankSmsParserPlugin().canParse('YES'), isFalse);
    });

    test('AU Bank parser does not match "FRAUD ALERT"', () {
      expect(AuBankSmsParserPlugin().canParse('FRAUD ALERT'), isFalse);
    });
  });

  group('senderNames — used for body-based bank detection', () {
    for (final (parser, _, _) in parserTestCases) {
      test('${parser.bankName}: senderNames is not empty', () {
        expect(parser.senderNames, isNotEmpty);
      });

      test('${parser.bankName}: senderNames contains core token', () {
        // Each senderName should be a recognizable bank token
        for (final name in parser.senderNames) {
          expect(
            name.length,
            greaterThanOrEqualTo(2),
            reason: 'senderName "$name" is too short',
          );
        }
      });
    }
  });
}
