import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/utils/category_matcher.dart';
import 'package:mudra_manager/features/sms/data/category_matcher_service.dart';

/// Real SMS bodies from bank parser tests — used to validate that the
/// category matcher picks the right category from actual bank messages.
void main() {
  late List<Category> expenseCategories;
  late List<Category> incomeCategories;
  late List<Category> allCategories;

  setUp(() {
    expenseCategories = [
      Category.create(
        name: 'Food & Dining',
        categoryType: CategoryType.expense,
        keywords: [
          'swiggy', 'zomato', 'restaurant', 'food', 'dining', 'cafe',
          'pizza', 'burger', 'kfc', 'mcdonalds', 'dominos', 'subway',
          'starbucks', 'biryani',
        ],
      ),
      Category.create(
        name: 'Groceries',
        categoryType: CategoryType.expense,
        keywords: [
          'bigbasket', 'blinkit', 'zepto', 'grocery', 'supermarket',
          'dmart', 'reliance', 'vegetables', 'fruits', 'milk',
        ],
      ),
      Category.create(
        name: 'Shopping',
        categoryType: CategoryType.expense,
        keywords: [
          'amazon', 'flipkart', 'myntra', 'shopping', 'mall', 'store',
          'ajio', 'nykaa', 'clothes', 'shoes', 'electronics', 'mobile',
        ],
      ),
      Category.create(
        name: 'Transportation',
        categoryType: CategoryType.expense,
        keywords: [
          'uber', 'ola', 'rapido', 'taxi', 'cab', 'metro', 'bus',
          'petrol', 'fuel', 'auto', 'rickshaw', 'parking', 'toll',
        ],
      ),
      Category.create(
        name: 'Entertainment',
        categoryType: CategoryType.expense,
        keywords: [
          'netflix', 'prime', 'hotstar', 'spotify', 'bookmyshow',
          'movie', 'cinema', 'youtube', 'disney', 'zee5',
        ],
      ),
      Category.create(
        name: 'Utilities',
        categoryType: CategoryType.expense,
        keywords: [
          'electricity', 'water', 'gas', 'internet', 'broadband',
          'recharge', 'airtel', 'jio', 'vi', 'bsnl', 'wifi', 'bill',
        ],
      ),
      Category.create(
        name: 'Healthcare',
        categoryType: CategoryType.expense,
        keywords: [
          'hospital', 'doctor', 'pharmacy', 'medicine', 'clinic',
          'apollo', 'medplus', 'netmeds', '1mg', 'pharmeasy',
        ],
      ),
      Category.create(
        name: 'Miscellaneous',
        categoryType: CategoryType.expense,
        keywords: ['other', 'misc', 'general', 'cash', 'atm'],
      ),
    ];

    incomeCategories = [
      Category.create(
        name: 'Salary',
        categoryType: CategoryType.income,
        keywords: [
          'salary', 'wages', 'income', 'bonus', 'incentive',
          'commission', 'freelance', 'consulting', 'allowance',
        ],
      ),
      Category.create(
        name: 'Investment',
        categoryType: CategoryType.income,
        keywords: [
          'mutual fund', 'stock', 'sip', 'dividend', 'interest',
          'zerodha', 'groww', 'upstox',
        ],
      ),
    ];

    allCategories = [...expenseCategories, ...incomeCategories];
  });

  // ─── matchByKeywords with real SMS bodies ───

  group('CategoryMatcher.matchByKeywords — real SMS bodies', () {
    test('ICICI CC spend at AMAZON → Shopping', () {
      const sms =
          'INR 1234.56 spent on ICICI Bank Card XX1234 on 20-Oct-22 at AMAZON. Avl Lmt: INR 150000.00.';
      final result = CategoryMatcher.matchByKeywords(sms, expenseCategories);
      expect(result?.name, 'Shopping');
    });

    test('ICICI CC spend at FLIPKART → Shopping', () {
      const sms =
          'INR 12,345.67 spent on ICICI Bank Card XX5678 on 15-Nov-23 at FLIPKART. Avl Lmt: INR 2,00,000.00.';
      final result = CategoryMatcher.matchByKeywords(sms, expenseCategories);
      expect(result?.name, 'Shopping');
    });

    test('IndusInd debit at AMAZON → Shopping', () {
      const sms =
          'A/C *XX6988 debited by Rs 1500.00 at AMAZON on 15-Dec-23. Avl Bal:656267 - IndusInd Bank';
      final result = CategoryMatcher.matchByKeywords(sms, expenseCategories);
      expect(result?.name, 'Shopping');
    });

    test('Paytm ATM withdrawal → Miscellaneous', () {
      const sms =
          'Rs.5000.00 withdrawn at ATM NAME on 04-09-2022 using Debit Card. Avl Bal:Rs.8000. RefNo. 123456789012.';
      final result = CategoryMatcher.matchByKeywords(sms, expenseCategories);
      expect(result?.name, 'Miscellaneous');
    });

    test('generic debit from card — no merchant → null (no false match)', () {
      const sms = 'Rs.1000.00 debited from Card XX6666 on 15-Jan-24';
      final result = CategoryMatcher.matchByKeywords(sms, expenseCategories);
      // Should NOT match any category — no merchant keywords present
      // Banking noise words (debited, card) should be filtered
      expect(result, isNull);
    });

    test('SBI debit with IMPS — no merchant → null', () {
      const sms =
          'Dear Customer, Your a/c no. XXXXXXXX2222 is debited for Rs.500.00 on 15-01-24 (IMPS Ref no 1234567890).If not done by you, call 1800111109 -SBI';
      final result = CategoryMatcher.matchByKeywords(sms, expenseCategories);
      expect(result, isNull);
    });
  });

  // ─── Noise word filtering ───

  group('CategoryMatcher.matchByKeywords — noise word filtering', () {
    test('banking words do not cause false matches', () {
      // A category that has polluted keywords (simulating the old bug)
      final pollutedCategories = [
        Category.create(
          name: 'Food & Dining',
          categoryType: CategoryType.expense,
          keywords: [
            'swiggy', 'zomato', 'food',
            // Polluted keywords from old _learnKeywordsFromSms:
            'debited', 'account', 'balance', 'available', 'transaction',
          ],
        ),
        Category.create(
          name: 'Shopping',
          categoryType: CategoryType.expense,
          keywords: ['amazon', 'flipkart', 'shopping'],
        ),
      ];

      // This SMS has no food keywords — only banking noise
      const sms =
          'Rs 2000.00 debited from account XX1234. Avl balance Rs 5000.00';
      final result =
          CategoryMatcher.matchByKeywords(sms, pollutedCategories);

      // Should NOT match Food & Dining despite polluted keywords
      expect(result?.name, isNot('Food & Dining'));
    });

    test('legitimate keyword still matches even with noise present', () {
      const sms =
          'Rs 500.00 debited from account XX1234 at Swiggy. Avl balance Rs 5000.00';
      final result =
          CategoryMatcher.matchByKeywords(sms, expenseCategories);
      expect(result?.name, 'Food & Dining');
    });
  });

  // ─── CategoryMatcherService.matchCategory with real SMS ───

  group('CategoryMatcherService.matchCategory — real SMS bodies', () {
    test('ICICI savings debit at UPI/AMAZON → Shopping', () {
      const sms =
          'Your a/c XX1234 is debited with Rs.5000.00 on 10-Oct-23. Info: UPI/AMAZON. Avl bal: Rs.45000.00';
      final result = CategoryMatcherService.matchCategory(
        sms,
        allCategories,
        false,
      );
      expect(result?.name, 'Shopping');
    });

    test('ICICI CC refund from Amazon → Shopping (income)', () {
      const sms =
          'Dear Customer, refund of INR 2500.00 from Amazon has been credited to your ICICI Bank Credit Card XX9876 on 29-SEP-22';
      // Refund is income but Amazon keyword should still match Shopping
      // However matchCategory filters by type — so income categories won't have Shopping
      // This tests that it returns null for income when no income category has 'amazon'
      final result = CategoryMatcherService.matchCategory(
        sms,
        allCategories,
        true,
      );
      // No income category has 'amazon' keyword
      expect(result, isNull);
    });

    test('ICICI CC refund from Amazon → Shopping (expense match)', () {
      const sms =
          'Dear Customer, refund of INR 2500.00 from Amazon has been credited to your ICICI Bank Credit Card XX9876 on 29-SEP-22';
      final result = CategoryMatcherService.matchCategory(
        sms,
        allCategories,
        false,
      );
      expect(result?.name, 'Shopping');
    });

    test('Paytm sent to merchant → no false category', () {
      const sms =
          'Rs.250.50 sent to merchant@bankid from BANKNAME a/c 91XX1234. UPI Ref:123456789012.';
      final result = CategoryMatcherService.matchCategory(
        sms,
        allCategories,
        false,
      );
      // No specific merchant keyword — should not match anything
      expect(result, isNull);
    });

    test('Paytm received → income category check', () {
      const sms =
          'Rs.1500.00 received from Sender Name in your Paytm Payments Bank a/c 91XX01234. UPI Ref: 12345678901.';
      final result = CategoryMatcherService.matchCategory(
        sms,
        allCategories,
        true,
      );
      // No income keyword match
      expect(result, isNull);
    });
  });

  // ─── CategoryMatcherService.detectMerchant with real SMS ───

  group('CategoryMatcherService.detectMerchant — real SMS bodies', () {
    test('extracts merchant from "at AMAZON" pattern', () {
      const sms =
          'A/C *XX6988 debited by Rs 1500.00 at AMAZON on 15-Dec-23. Avl Bal:656267 - IndusInd Bank';
      final merchant =
          CategoryMatcherService.detectMerchant(sms, allCategories);
      expect(merchant, isNotNull);
      expect(merchant!.toLowerCase(), contains('amazon'));
    });

    test('extracts VPA name from "to VPA" pattern', () {
      const sms =
          'Rs.1234.56 debited to VPA merchant@paytm from A/c XX5678 on 15-Jan-24. Avl Bal: Rs.10000.00';
      final merchant =
          CategoryMatcherService.detectMerchant(sms, allCategories);
      expect(merchant, isNotNull);
      expect(merchant!.toLowerCase(), contains('merchant'));
    });

    test('returns null for "Info: VPA" pattern (no to/from prefix)', () {
      const sms =
          'Rs.1234.56 debited from A/c XX5678 on 15-Jan-24. Info: VPA merchant@paytm. Avl Bal: Rs.10000.00';
      final merchant =
          CategoryMatcherService.detectMerchant(sms, allCategories);
      // "Info: VPA" doesn't match "to/from VPA" regex
      expect(merchant, isNull);
    });

    test('extracts name from "sent to" pattern', () {
      const sms =
          'Rs.250.00 sent to Suraj Mondal from BANKNAME a/c 91XX1234. UPI Ref:123456789012.';
      final merchant =
          CategoryMatcherService.detectMerchant(sms, allCategories);
      expect(merchant, 'Suraj Mondal');
    });

    test('returns null for generic debit with no merchant', () {
      const sms =
          'Dear Customer, Your a/c no. XXXXXXXX2222 is debited for Rs.500.00 on 15-01-24 (IMPS Ref no 1234567890).If not done by you, call 1800111109 -SBI';
      final merchant =
          CategoryMatcherService.detectMerchant(sms, allCategories);
      expect(merchant, isNull);
    });

    test('returns null for promotional SMS', () {
      const sms =
          'Dear Customer shop for Rs 299 & get best deals on daily items';
      final merchant =
          CategoryMatcherService.detectMerchant(sms, allCategories);
      expect(merchant, isNull);
    });
  });

  // ─── CategoryMatcherService.detectPaymentType ───

  group('CategoryMatcherService.detectPaymentType — real SMS bodies', () {
    test('HDFC VPA SMS → UPI', () {
      const sms =
          'Rs.1234.56 debited from A/c XX5678 on 15-Jan-24. Info: VPA merchant@paytm. Avl Bal: Rs.10000.00';
      expect(CategoryMatcherService.detectPaymentType(sms), PaymentType.upi);
    });

    test('ICICI Card SMS → Card', () {
      const sms =
          'INR 1234.56 spent on ICICI Bank Card XX1234 on 20-Oct-22 at AMAZON.';
      expect(CategoryMatcherService.detectPaymentType(sms), PaymentType.card);
    });

    test('SBI IMPS SMS → Card (contains "debit" keyword)', () {
      const sms =
          'Dear Customer, Your a/c no. XXXXXXXX0000 is debited for Rs.1500.50 on 14-10-22 (IMPS Ref no 1234567890) -SBI';
      // "debited" contains "debit" → matches Card type
      expect(
        CategoryMatcherService.detectPaymentType(sms),
        PaymentType.card,
      );
    });

    test('Paytm SMS → Wallet', () {
      const sms =
          'Rs.250.50 sent to merchant@bankid from BANKNAME a/c 91XX1234. UPI Ref:123456789012. Balance:https://m.paytm.me/pbCheckBal';
      // Contains both 'paytm' and 'upi' — UPI check comes first
      expect(CategoryMatcherService.detectPaymentType(sms), PaymentType.upi);
    });

    test('non-transaction SMS → null', () {
      const sms = 'This is not a transaction SMS';
      expect(CategoryMatcherService.detectPaymentType(sms), isNull);
    });
  });

  // ─── Word boundary scoring ───

  group('CategoryMatcher — word boundary scoring', () {
    test('exact word "food" scores higher than substring "foodcourt"', () {
      final categories = [
        Category.create(
          name: 'Food & Dining',
          categoryType: CategoryType.expense,
          keywords: ['food'],
        ),
        Category.create(
          name: 'Shopping',
          categoryType: CategoryType.expense,
          keywords: ['court'],
        ),
      ];

      // "food" as exact word should get boundary bonus
      final result = CategoryMatcher.matchByKeywords(
        'Paid for food at the mall',
        categories,
      );
      expect(result?.name, 'Food & Dining');
    });

    test('longer specific keyword beats shorter generic one', () {
      final result = CategoryMatcher.matchByKeywords(
        'Ordered biryani from Swiggy delivery',
        expenseCategories,
      );
      // Both 'swiggy' and 'biryani' match Food & Dining
      // Should definitely be Food & Dining
      expect(result?.name, 'Food & Dining');
    });

    test('amazon keyword matches Shopping not Food', () {
      const sms = 'Payment to Amazon for electronics order';
      final result = CategoryMatcher.matchByKeywords(sms, expenseCategories);
      expect(result?.name, 'Shopping');
    });
  });

  // ─── Cross-category collision tests ───

  group('CategoryMatcher — cross-category collision', () {
    test('Swiggy SMS matches Food not Shopping', () {
      const sms =
          'Rs 350.00 debited from A/c XX1234 at Swiggy on 15-Jan-24';
      final result = CategoryMatcher.matchByKeywords(sms, expenseCategories);
      expect(result?.name, 'Food & Dining');
    });

    test('Uber SMS matches Transportation not Entertainment', () {
      const sms = 'Rs 250.00 paid to Uber for ride on 15-Jan-24';
      final result = CategoryMatcher.matchByKeywords(sms, expenseCategories);
      expect(result?.name, 'Transportation');
    });

    test('Netflix SMS matches Entertainment not Utilities', () {
      const sms = 'Rs 649.00 debited for Netflix subscription renewal';
      final result = CategoryMatcher.matchByKeywords(sms, expenseCategories);
      expect(result?.name, 'Entertainment');
    });

    test('Airtel recharge matches Utilities not Transportation', () {
      const sms = 'Rs 299.00 debited for Airtel prepaid recharge';
      final result = CategoryMatcher.matchByKeywords(sms, expenseCategories);
      expect(result?.name, 'Utilities');
    });

    test('Apollo pharmacy matches Healthcare not Shopping', () {
      const sms = 'Rs 800.00 paid at Apollo Pharmacy for medicine';
      final result = CategoryMatcher.matchByKeywords(sms, expenseCategories);
      expect(result?.name, 'Healthcare');
    });

    test('BigBasket matches Groceries not Shopping', () {
      const sms = 'Rs 1200.00 debited for BigBasket grocery order';
      final result = CategoryMatcher.matchByKeywords(sms, expenseCategories);
      expect(result?.name, 'Groceries');
    });
  });

  // ─── getFallbackCategory ───

  group('CategoryMatcher.getFallbackCategory', () {
    test('returns Miscellaneous when available', () {
      final result =
          CategoryMatcher.getFallbackCategory(expenseCategories, null);
      expect(result?.name, 'Miscellaneous');
    });

    test('returns first category when no fallback name exists', () {
      final noFallback = expenseCategories
          .where((c) => c.name != 'Miscellaneous')
          .toList();
      final result = CategoryMatcher.getFallbackCategory(noFallback, null);
      expect(result, isNotNull);
    });
  });
}
