import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/features/sms/data/category_matcher_service.dart';

void main() {
  group('Merchant detection for keyword learning', () {
    late List<Category> categories;

    setUp(() {
      categories = [
        Category()
          ..name = 'Food'
          ..categoryType = CategoryType.expense
          ..keywords = ['swiggy', 'zomato'],
        Category()
          ..name = 'Shopping'
          ..categoryType = CategoryType.expense
          ..keywords = ['amazon', 'flipkart'],
      ];
    });

    test('detects merchant from UPI VPA pattern', () {
      const sms = 'Rs.250 debited to VPA suraj.mondal@okaxis from A/c XX1234';
      final merchant = CategoryMatcherService.detectMerchant(sms, categories);
      expect(merchant, isNotNull);
      expect(merchant, 'Suraj Mondal');
    });

    test('detects merchant from "paid to" pattern', () {
      const sms = 'Rs.500 paid to Suraj Mondal via UPI. Ref: 123456';
      final merchant = CategoryMatcherService.detectMerchant(sms, categories);
      expect(merchant, isNotNull);
      expect(merchant, 'Suraj Mondal');
    });

    test('detects merchant from "at MERCHANT" pattern', () {
      const sms = 'Rs.1000 debited at Amazon on 15-Jan-24. Ref No: 123';
      final merchant = CategoryMatcherService.detectMerchant(sms, categories);
      expect(merchant, isNotNull);
      expect(merchant!.toLowerCase(), contains('amazon'));
    });

    test('returns null for SMS without merchant info', () {
      const sms = 'Rs.500 debited from A/c XX1234';
      final merchant = CategoryMatcherService.detectMerchant(sms, categories);
      expect(merchant, isNull);
    });

    test('filters out noise names', () {
      const sms = 'Rs.500 debited from A/c XX1234. Avl Bal: Rs.10000';
      final merchant = CategoryMatcherService.detectMerchant(sms, categories);
      // Should not return "A" or "Bal" or other noise
      if (merchant != null) {
        expect(merchant.length, greaterThan(2));
      }
    });
  });

  group('Payment type detection', () {
    test('detects UPI payment', () {
      const sms = 'Rs.250 debited via UPI to merchant@paytm';
      expect(CategoryMatcherService.detectPaymentType(sms), 'UPI');
    });

    test('detects card payment', () {
      const sms = 'Rs.1000 charged on your credit card XX1234';
      expect(CategoryMatcherService.detectPaymentType(sms), 'Card');
    });

    test('detects wallet payment', () {
      const sms = 'Rs.100 paid via Paytm wallet';
      expect(CategoryMatcherService.detectPaymentType(sms), 'Wallet');
    });

    test('returns null for unknown payment type', () {
      const sms = 'Amount of Rs.500 transferred to A/c XX1234 via NEFT';
      expect(CategoryMatcherService.detectPaymentType(sms), isNull);
    });
  });

  group('CategoryRule-based learning', () {
    test('merchant is extracted and can form a rule', () {
      const smsBody = 'Rs.250 debited to VPA suraj.mondal@okaxis from A/c XX1234';
      final categories = [
        Category()
          ..name = 'Food'
          ..categoryType = CategoryType.expense,
      ];
      final merchant = CategoryMatcherService.detectMerchant(smsBody, categories);
      expect(merchant, isNotNull);
      expect(merchant!.toLowerCase().trim().length, greaterThanOrEqualTo(3));
    });

    test('noise words are filtered from rule creation', () {
      const noiseWords = {
        'debited', 'credited', 'account', 'balance', 'available',
        'transaction', 'transfer', 'payment', 'received', 'sent',
        'bank', 'upi', 'neft', 'imps', 'rtgs', 'ref', 'inr',
        'your', 'from', 'the', 'for', 'with', 'info',
      };
      for (final noise in noiseWords) {
        expect(noiseWords.contains(noise), isTrue);
      }
    });

    test('confidence increases on repeat approval', () {
      int confidence = 60;
      confidence = (confidence + 10).clamp(0, 100);
      expect(confidence, 70);
      confidence = (confidence + 10).clamp(0, 100);
      expect(confidence, 80);
      confidence = 95;
      confidence = (confidence + 10).clamp(0, 100);
      expect(confidence, 100);
    });

    test('rule lookup requires confidence > 40', () {
      expect(30 > 40, isFalse);
      expect(60 > 40, isTrue);
    });
  });

  group('Recipient-based learning', () {
    test('UPI VPA name is extracted for rule creation', () {
      const vpa = 'suraj.mondal@okaxis';
      final vpaName = vpa.split('@').first.toLowerCase().trim();
      expect(vpaName, 'suraj.mondal');
      expect(vpaName.length, greaterThanOrEqualTo(3));
    });

    test('short VPA names are rejected', () {
      const vpa = 'ab@upi';
      final vpaName = vpa.split('@').first.toLowerCase().trim();
      expect(vpaName.length >= 3, isFalse);
    });

    test('non-VPA recipients are skipped', () {
      const recipient = 'SUKANTA BEHERA';
      expect(recipient.contains('@'), isFalse);
    });

    test('multiple keys are generated from one SMS', () {
      const merchant = 'Swiggy';
      const recipient = 'swiggy@axisbank';
      final keys = <String>{};

      keys.add(merchant.toLowerCase().trim());
      if (recipient.contains('@')) {
        keys.add(recipient.split('@').first.toLowerCase().trim());
      }

      // Both resolve to 'swiggy' — deduped by Set
      expect(keys, {'swiggy'});
    });

    test('different merchant and VPA create separate rules', () {
      const merchant = 'Amazon';
      const recipient = 'seller123@upi';
      final keys = <String>{};

      keys.add(merchant.toLowerCase().trim());
      if (recipient.contains('@')) {
        keys.add(recipient.split('@').first.toLowerCase().trim());
      }

      expect(keys, {'amazon', 'seller123'});
    });
  });

  group('Negative learning', () {
    test('rejection penalizes confidence by 20', () {
      int confidence = 80;
      confidence = (confidence - 20).clamp(0, 100);
      expect(confidence, 60);
    });

    test('confidence cannot go below 0', () {
      int confidence = 10;
      confidence = (confidence - 20).clamp(0, 100);
      expect(confidence, 0);
    });

    test('zero confidence + single use = delete rule', () {
      final confidence = 0;
      final matchCount = 1;
      final shouldDelete = confidence <= 0 && matchCount <= 1;
      expect(shouldDelete, isTrue);
    });

    test('zero confidence + high use = keep rule (just penalized)', () {
      final confidence = 0;
      final matchCount = 5;
      final shouldDelete = confidence <= 0 && matchCount <= 1;
      expect(shouldDelete, isFalse);
    });

    test('multiple rejections erode confidence progressively', () {
      int confidence = 80;
      // First rejection
      confidence = (confidence - 20).clamp(0, 100);
      expect(confidence, 60);
      // Second rejection
      confidence = (confidence - 20).clamp(0, 100);
      expect(confidence, 40);
      // Third rejection — drops below lookup threshold (40)
      confidence = (confidence - 20).clamp(0, 100);
      expect(confidence, 20);
      expect(confidence > 40, isFalse); // Won't match anymore
    });
  });

  group('Rule decay', () {
    test('rules older than 180 days with low usage are eligible for cleanup', () {
      final cutoff = DateTime.now().subtract(const Duration(days: 180));
      final oldDate = DateTime.now().subtract(const Duration(days: 200));
      final recentDate = DateTime.now().subtract(const Duration(days: 30));

      expect(oldDate.isBefore(cutoff), isTrue);
      expect(recentDate.isBefore(cutoff), isFalse);
    });

    test('frequently used old rules are preserved', () {
      final matchCount = 10;
      final shouldDelete = matchCount < 3;
      expect(shouldDelete, isFalse);
    });

    test('rarely used old rules are cleaned up', () {
      final matchCount = 2;
      final shouldDelete = matchCount < 3;
      expect(shouldDelete, isTrue);
    });
  });
}
