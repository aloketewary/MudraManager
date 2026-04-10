/// Bug Condition Exploration Test — Property 1
///
/// **Validates: Requirements 1.1, 1.2, 1.5, 1.6**
///
/// CRITICAL: This test MUST FAIL on unfixed code — failure confirms the bug exists.
/// DO NOT attempt to fix the test or the code when it fails.
///
/// isBugCondition: canParse(sender) returns false for all enabled plugins
/// AND body contains a valid transaction pattern (amount + debit/credit keyword).
///
/// Expected behavior (post-fix): BankSmsParser.parse returns non-null ParsedSms
/// with non-zero amount and correct isIncome.
///
/// EXPECTED OUTCOME on unfixed code: FAIL
/// Counterexamples documented below.
library;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/features/sms/data/bank_sms_parser.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock SharedPreferences so MarketplaceService can initialise
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

  /// Property 1: Bug Condition — Body-Based Fallback Produces Valid Parse
  ///
  /// For any (sender, body) pair where isBugCondition is true:
  ///   - canParse(sender) returns false for ALL enabled plugins
  ///   - body contains a valid transaction pattern (amount + debit/credit keyword)
  ///
  /// The fixed BankSmsParser.parse SHALL return a non-null ParsedSms with:
  ///   - amount > 0
  ///   - isIncome correctly set (true for credited, false for debited/charged)
  ///
  /// Scoped to concrete failing cases for reproducibility.
  group('Property 1: Bug Condition — Body-Based Fallback Produces Valid Parse',
      () {
    /// Test case 1: Chase Bank (USD) — no Chase plugin registered.
    /// Sender "Chase Bank" does not match any canParse(sender).
    /// Body contains "charged" (debit keyword) and "USD 120.50".
    ///
    /// Counterexample on unfixed code:
    ///   parse("Chase Bank", "Your Chase account ending 5678 was charged USD 120.50 at AMAZON on 01-Jan-25")
    ///   → returns null  (bug: _parseGeneric only matches INR/Rs/₹ patterns)
    test(
        'parse("Chase Bank", USD debit body) — result != null, amount == 120.50, isIncome == false',
        () async {
      const sender = 'Chase Bank';
      const body =
          'Your Chase account ending 5678 was charged USD 120.50 at AMAZON on 01-Jan-25';

      final result = await BankSmsParser.parse(sender, body);

      // isBugCondition: no plugin matches "Chase Bank" AND body has valid transaction
      expect(
        result,
        isNotNull,
        reason:
            'BankSmsParser.parse must return non-null for a valid USD transaction body '
            'even when sender is a display name that no plugin canParse matches.',
      );
      expect(
        result!.amount,
        120.50,
        reason: 'Amount must be extracted as 120.50 from the USD body.',
      );
      expect(
        result.isIncome,
        false,
        reason: '"charged" indicates a debit — isIncome must be false.',
      );
    });

    /// Test case 2: Barclays (GBP) — no Barclays plugin registered.
    /// Sender "Barclays" does not match any canParse(sender).
    /// Body contains "debited" (debit keyword) and "£250.00".
    ///
    /// Counterexample on unfixed code:
    ///   parse("Barclays", "£250.00 debited from your Barclays account XX9012. Avail bal: £1,200.00")
    ///   → returns null  (bug: _parseGeneric only matches INR/Rs/₹ patterns)
    test(
        'parse("Barclays", GBP debit body) — result != null, amount == 250.00, isIncome == false',
        () async {
      const sender = 'Barclays';
      const body =
          '£250.00 debited from your Barclays account XX9012. Avail bal: £1,200.00';

      final result = await BankSmsParser.parse(sender, body);

      expect(
        result,
        isNotNull,
        reason:
            'BankSmsParser.parse must return non-null for a valid GBP transaction body '
            'even when sender is a display name that no plugin canParse matches.',
      );
      expect(
        result!.amount,
        250.00,
        reason: 'Amount must be extracted as 250.00 from the GBP body.',
      );
      expect(
        result.isIncome,
        false,
        reason: '"debited" indicates a debit — isIncome must be false.',
      );
    });

    /// Test case 3: Emirates NBD (AED) — no Emirates NBD plugin registered.
    /// Sender "Emirates NBD" does not match any canParse(sender).
    /// Body contains "credited" (credit keyword) and "AED 500.00".
    ///
    /// Counterexample on unfixed code:
    ///   parse("Emirates NBD", "AED 500.00 credited to your account XX3456 on 01-Jan-25")
    ///   → returns null  (bug: _parseGeneric only matches INR/Rs/₹ patterns)
    test(
        'parse("Emirates NBD", AED credit body) — result != null, amount == 500.00, isIncome == true',
        () async {
      const sender = 'Emirates NBD';
      const body =
          'AED 500.00 credited to your account XX3456 on 01-Jan-25';

      final result = await BankSmsParser.parse(sender, body);

      expect(
        result,
        isNotNull,
        reason:
            'BankSmsParser.parse must return non-null for a valid AED transaction body '
            'even when sender is a display name that no plugin canParse matches.',
      );
      expect(
        result!.amount,
        500.00,
        reason: 'Amount must be extracted as 500.00 from the AED body.',
      );
      expect(
        result.isIncome,
        true,
        reason: '"credited" indicates income — isIncome must be true.',
      );
    });

    /// Test case 4: Unknown bank (EUR) — no plugin registered for "My Bank".
    /// Sender "My Bank" does not match any canParse(sender).
    /// Body contains "debited" (debit keyword) and "EUR 75.00".
    ///
    /// Counterexample on unfixed code:
    ///   parse("My Bank", "EUR 75.00 debited from account XX7890 at STARBUCKS")
    ///   → returns null  (bug: _parseGeneric only matches INR/Rs/₹ patterns)
    test(
        'parse("My Bank", EUR debit body) — result != null, amount == 75.00, isIncome == false',
        () async {
      const sender = 'My Bank';
      const body = 'EUR 75.00 debited from account XX7890 at STARBUCKS';

      final result = await BankSmsParser.parse(sender, body);

      expect(
        result,
        isNotNull,
        reason:
            'BankSmsParser.parse must return non-null for a valid EUR transaction body '
            'even when sender is a display name that no plugin canParse matches. '
            'The generic parser must handle non-INR currencies.',
      );
      expect(
        result!.amount,
        75.00,
        reason: 'Amount must be extracted as 75.00 from the EUR body.',
      );
      expect(
        result.isIncome,
        false,
        reason: '"debited" indicates a debit — isIncome must be false.',
      );
    });
  });
}
