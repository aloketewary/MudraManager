/// Preservation Property Tests — Property 2
///
/// **Validates: Requirements 3.1, 3.2, 3.4, 3.6, 3.7**
///
/// IMPORTANT: These tests run on UNFIXED code and MUST PASS.
/// They capture the baseline behavior that the fix must preserve.
///
/// Observation-first methodology: each test group first documents the
/// observed behavior on unfixed code, then asserts it as a property.
///
/// isBugCondition is FALSE for all inputs in this file — meaning either:
///   (a) canParse(sender) is true for some enabled plugin, OR
///   (b) the body has no valid transaction pattern (no amount / no keyword)
///
/// EXPECTED OUTCOME on unfixed code: ALL PASS
library;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/features/sms/data/bank_sms_parser.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock SharedPreferences so MarketplaceService can initialise.
  // Returning an empty map causes _resolveDefault to fall back to the
  // _smsParserIds set, which enables all SMS parser plugins by default.
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

  // ─────────────────────────────────────────────────────────────────────────
  // Property 2a: Classic raw sender IDs — result is non-null with correct amount
  //
  // Observed on unfixed code:
  //   parse("HDFCBK", "Rs.5000.00 debited from A/c XX1234 on 01-Jan-25")
  //   → non-null ParsedSms, amount == 5000.00, isIncome == false
  //
  // The fix must not change this result.
  // ─────────────────────────────────────────────────────────────────────────
  group(
      'Property 2a: Classic raw sender IDs — non-null result with correct amount',
      () {
    /// HDFCBK is a raw sender ID that canParse matches ("HDFC" in sender).
    /// Observed: parse returns non-null with amount=5000.00, isIncome=false.
    test(
        'parse("HDFCBK", INR debit body) — result != null, amount == 5000.00, isIncome == false',
        () async {
      const sender = 'HDFCBK';
      const body = 'Rs.5000.00 debited from A/c XX1234 on 01-Jan-25';

      final result = await BankSmsParser.parse(sender, body);

      expect(
        result,
        isNotNull,
        reason:
            'Classic raw sender "HDFCBK" with a valid INR debit body must '
            'always produce a non-null ParsedSms.',
      );
      expect(
        result!.amount,
        5000.00,
        reason: 'Amount must be extracted as 5000.00.',
      );
      expect(
        result.isIncome,
        false,
        reason: '"debited" indicates a debit — isIncome must be false.',
      );
    });

    /// ICICIBK is a raw sender ID that canParse matches ("ICICI" in sender).
    /// Observed: parse returns non-null with amount=2500.00, isIncome=false.
    test(
        'parse("ICICIBK", INR debit body) — result != null, amount == 2500.00, isIncome == false',
        () async {
      const sender = 'ICICIBK';
      const body =
          'Rs 2,500.00 debited from a/c XX9876 on 15-Jan-25. Info: AMAZON. Avl bal: Rs 8,500.00';

      final result = await BankSmsParser.parse(sender, body);

      expect(
        result,
        isNotNull,
        reason:
            'Classic raw sender "ICICIBK" with a valid INR debit body must '
            'always produce a non-null ParsedSms.',
      );
      expect(
        result!.amount,
        2500.00,
        reason: 'Amount must be extracted as 2500.00.',
      );
      expect(
        result.isIncome,
        false,
        reason: '"debited" indicates a debit — isIncome must be false.',
      );
    });

    /// SBIINB is a raw sender ID that canParse matches ("SBI" in sender).
    /// Observed: parse returns non-null with amount=500.00, isIncome=false.
    test(
        'parse("SBIINB", INR debit body) — result != null, amount == 500.00, isIncome == false',
        () async {
      const sender = 'SBIINB';
      const body =
          'Dear Customer, Your a/c no. XXXXXXXX2222 is debited for Rs.500.00 on 15-01-25 (IMPS Ref no 1234567890).';

      final result = await BankSmsParser.parse(sender, body);

      expect(
        result,
        isNotNull,
        reason:
            'Classic raw sender "SBIINB" with a valid INR debit body must '
            'always produce a non-null ParsedSms.',
      );
      expect(
        result!.amount,
        500.00,
        reason: 'Amount must be extracted as 500.00.',
      );
      expect(
        result.isIncome,
        false,
        reason: '"debited" indicates a debit — isIncome must be false.',
      );
    });

    /// HDFCBK credit — Observed: parse returns non-null with amount=15000.00, isIncome=true.
    test(
        'parse("HDFCBK", INR credit body) — result != null, amount == 15000.00, isIncome == true',
        () async {
      const sender = 'HDFCBK';
      const body =
          'Rs.15000.00 credited to A/c XX1234 on 15-Jan-25. Avl Bal: Rs.25000.00';

      final result = await BankSmsParser.parse(sender, body);

      expect(result, isNotNull);
      expect(result!.amount, 15000.00);
      expect(
        result.isIncome,
        true,
        reason: '"credited" indicates income — isIncome must be true.',
      );
    });

    /// AXISBK is a raw sender ID that canParse matches ("AXIS" in sender).
    test(
        'parse("AXISBK", INR debit body) — result != null, amount == 1200.00, isIncome == false',
        () async {
      const sender = 'AXISBK';
      const body = 'Rs.1200.00 debited from A/c XX5678 on 01-Jan-25';

      final result = await BankSmsParser.parse(sender, body);

      expect(result, isNotNull);
      expect(result!.amount, 1200.00);
      expect(result.isIncome, false);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Property 2b: Promotional / non-transactional bodies — parse returns null
  //
  // Observed on unfixed code:
  //   parse("ICICIBK", promoBody) → null  (promotional filter)
  //   parse("HDFCBK", promoBody) → null
  //   parse("UNKNOWN", promoBody) → null
  //
  // The fix must not change this result.
  // ─────────────────────────────────────────────────────────────────────────
  group(
      'Property 2b: Promotional / non-transactional bodies — parse returns null',
      () {
    /// Observed: "shop for" triggers promotional filter → null.
    test(
        'parse(any sender, "shop for" promo body) — result == null',
        () async {
      const body =
          'Dear Customer shop for Rs 299 & get best deals on daily items';

      for (final sender in ['ICICIBK', 'HDFCBK', 'SBIINB', 'UNKNOWN']) {
        final result = await BankSmsParser.parse(sender, body);
        expect(
          result,
          isNull,
          reason:
              'Promotional body containing "shop for" must return null for sender "$sender".',
        );
      }
    });

    /// Observed: "loan facility has been enabled" triggers promotional filter → null.
    test(
        'parse(any sender, loan facility promo body) — result == null',
        () async {
      const body =
          'Dear customer based on your HDFC bank Credit card usage loan facility has been enabled';

      for (final sender in ['HDFCBK', 'ICICIBK', 'UNKNOWN']) {
        final result = await BankSmsParser.parse(sender, body);
        expect(
          result,
          isNull,
          reason:
              'Promotional body containing "loan facility has been enabled" must return null for sender "$sender".',
        );
      }
    });

    /// Observed: "cashback offer" triggers promotional filter → null.
    test(
        'parse(any sender, cashback offer body) — result == null',
        () async {
      const body =
          'Get 50% cashback offer on your next purchase. Limited time only!';

      for (final sender in ['HDFCBK', 'SBIINB', 'UNKNOWN']) {
        final result = await BankSmsParser.parse(sender, body);
        expect(
          result,
          isNull,
          reason:
              'Promotional body containing "cashback" and "offer" must return null for sender "$sender".',
        );
      }
    });

    /// Observed: "pre-approved" triggers promotional filter → null.
    test(
        'parse(any sender, pre-approved loan body) — result == null',
        () async {
      const body =
          'You are eligible for pre-approved loan of Rs 50000. Apply now!';

      for (final sender in ['HDFCBK', 'UNKNOWN']) {
        final result = await BankSmsParser.parse(sender, body);
        expect(
          result,
          isNull,
          reason:
              'Promotional body containing "pre-approved" must return null for sender "$sender".',
        );
      }
    });

    /// Observed: "avail" triggers promotional filter → null.
    test(
        'parse(any sender, avail offer body) — result == null',
        () async {
      const body =
          'Avail exclusive offers on your HDFC credit card. Visit our website.';

      for (final sender in ['HDFCBK', 'UNKNOWN']) {
        final result = await BankSmsParser.parse(sender, body);
        expect(
          result,
          isNull,
          reason:
              'Promotional body containing "avail" must return null for sender "$sender".',
        );
      }
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Property 2c: Bodies with no recognisable amount or transaction keyword
  //              — parse returns null
  //
  // Observed on unfixed code:
  //   parse("SBIINB", "Your OTP is 123456") → null
  //   parse("HDFCBK", "Your account statement is ready") → null
  //
  // The fix must not change this result.
  // ─────────────────────────────────────────────────────────────────────────
  group(
      'Property 2c: Bodies with no amount or transaction keyword — parse returns null',
      () {
    /// Observed: OTP body has no transaction keyword → null.
    test(
        'parse(any sender, OTP body) — result == null',
        () async {
      const body = 'Your OTP for login is 123456. Valid for 10 minutes.';

      for (final sender in ['SBIINB', 'HDFCBK', 'UNKNOWN']) {
        final result = await BankSmsParser.parse(sender, body);
        expect(
          result,
          isNull,
          reason:
              'OTP body with no transaction keyword must return null for sender "$sender".',
        );
      }
    });

    /// Observed: account statement ready body has no transaction keyword → null.
    test(
        'parse(any sender, account statement notification body) — result == null',
        () async {
      const body =
          'Your HDFC Bank account statement for January 2025 is now ready. Login to NetBanking to view.';

      for (final sender in ['HDFCBK', 'UNKNOWN']) {
        final result = await BankSmsParser.parse(sender, body);
        expect(
          result,
          isNull,
          reason:
              'Account statement notification body with no transaction keyword must return null.',
        );
      }
    });

    /// Observed: data alert body has no transaction keyword → null.
    test(
        'parse(any sender, data usage alert body) — result == null',
        () async {
      const body =
          'Alert: You have used 80% of your 2GB data plan. Recharge now to avoid interruption.';

      for (final sender in ['UNKNOWN', 'HDFCBK']) {
        final result = await BankSmsParser.parse(sender, body);
        expect(
          result,
          isNull,
          reason:
              'Data usage alert body with no transaction keyword must return null.',
        );
      }
    });

    /// Observed: body with amount but no transaction keyword → null.
    test(
        'parse(any sender, body with amount but no debit/credit keyword) — result == null',
        () async {
      const body =
          'Your balance is Rs.10000.00. Thank you for banking with us.';

      for (final sender in ['HDFCBK', 'UNKNOWN']) {
        final result = await BankSmsParser.parse(sender, body);
        expect(
          result,
          isNull,
          reason:
              'Body with an amount but no debit/credit/spent/received keyword must return null.',
        );
      }
    });

    /// Observed: completely empty-like body → null.
    test(
        'parse(any sender, non-transactional plain text body) — result == null',
        () async {
      const body = 'This is not a transaction SMS';

      for (final sender in ['HDFCBK', 'SBIINB', 'UNKNOWN']) {
        final result = await BankSmsParser.parse(sender, body);
        expect(
          result,
          isNull,
          reason:
              'Plain non-transactional body must return null for sender "$sender".',
        );
      }
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Property 2d: Disabled plugins — body-based fallback does NOT activate them
  //
  // Observed on unfixed code:
  //   When a plugin is disabled (isPluginEnabledSync returns false),
  //   parseSms skips it. The legacy path (_parseLegacy) does not re-enable it.
  //   A body that contains a bank's senderName keyword but whose plugin is
  //   disabled must NOT produce a result via the plugin path.
  //
  // In the test environment, _cacheLoaded is false so isPluginEnabledSync
  // returns false for all plugins — they are all effectively disabled.
  // The only results come from _parseLegacy / _parseGeneric.
  //
  // After the fix, body-based fallback must also respect disabled plugins.
  // This test verifies the baseline: disabled plugins produce no plugin result.
  // ─────────────────────────────────────────────────────────────────────────
  group(
      'Property 2d: Disabled plugins — plugin path is not activated for disabled parsers',
      () {
    /// When all plugins are disabled (default test env), a body that would
    /// normally be handled by the HDFC plugin falls through to _parseGeneric.
    /// The result (if any) comes from the generic path, not the plugin.
    ///
    /// Observed: parse("HDFCBK", hdfcBody) still returns non-null via
    /// _parseGeneric (INR regex), but the plugin-specific fields (balance,
    /// merchant via VPA) are absent because the plugin didn't run.
    ///
    /// This test asserts that the result is produced by the generic path
    /// (no plugin-specific enrichment) when plugins are disabled.
    test(
        'parse("HDFCBK", HDFC body) with disabled plugins — result comes from generic path, not plugin',
        () async {
      const sender = 'HDFCBK';
      // Body with HDFC-specific VPA pattern that only the HDFC plugin extracts
      const body =
          'Rs.3000.00 debited from A/c XX1234 on 01-Jan-25. Info: VPA merchant@paytm. Avl Bal: Rs.7000.00';

      // In test env, plugins are disabled (cache not loaded).
      // _parseGeneric handles this and returns a result.
      final result = await BankSmsParser.parse(sender, body);

      // The generic path can parse this (INR amount + "debited" keyword).
      expect(
        result,
        isNotNull,
        reason:
            'Even with plugins disabled, _parseGeneric handles INR debit bodies.',
      );
      expect(result!.amount, 3000.00);
      expect(result.isIncome, false);
      // Plugin-specific field: balance is NOT extracted by _parseGeneric
      // (it has no balance regex), confirming the generic path ran.
      expect(
        result.balance,
        isNull,
        reason:
            'balance is null because the HDFC plugin (which extracts Avl Bal) '
            'is disabled — only _parseGeneric ran.',
      );
    });

    /// A body that contains "HDFC" keyword but sender is unknown.
    /// With plugins disabled, no plugin runs. _parseGeneric handles it if
    /// it has a valid INR transaction pattern.
    test(
        'parse("UNKNOWN", body containing HDFC keyword) with disabled plugins — generic path only',
        () async {
      const sender = 'UNKNOWN';
      const body =
          'Rs.1500.00 debited from HDFC A/c XX5678 on 01-Jan-25';

      final result = await BankSmsParser.parse(sender, body);

      // _parseGeneric handles INR debit bodies regardless of sender.
      expect(result, isNotNull);
      expect(result!.amount, 1500.00);
      expect(result.isIncome, false);
      // No plugin ran, so no plugin-specific enrichment.
      expect(result.balance, isNull);
    });

    /// A body that would match a disabled plugin but has no INR amount.
    /// With plugins disabled, no plugin runs. _parseGeneric handles it if
    /// it has a valid transaction pattern — after the fix, multi-currency
    /// regex matches USD amounts, so this now returns a non-null result.
    test(
        'parse("HDFCBK", non-INR body) with disabled plugins — generic parser extracts USD amount',
        () async {
      const sender = 'HDFCBK';
      const body =
          'USD 200.00 debited from your HDFC account XX1234 on 01-Jan-25';

      final result = await BankSmsParser.parse(sender, body);

      // After fix: _parseGeneric multi-currency regex matches USD → non-null.
      // Disabled plugins are still not activated — result comes from generic path.
      expect(
        result,
        isNotNull,
        reason:
            'After the multi-currency fix, _parseGeneric matches USD amounts. '
            'Disabled plugins are not activated — result comes from generic path.',
      );
      expect(result!.amount, 200.00);
      expect(result.isIncome, false);
      expect(result.currency, 'USD');
      // No plugin ran, so no plugin-specific enrichment.
      expect(result.balance, isNull);
    });
  });
}
