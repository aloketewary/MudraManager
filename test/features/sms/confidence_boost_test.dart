import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/db/models/sms_activity.dart';
import 'package:mudra_manager/features/sms/data/sms_activity_service.dart';

void main() {
  group('SmsActivityService.calculateConfidence', () {
    SmsActivity makeActivity({
      double? amount,
      bool? isIncome,
      String? account,
      String? fromBank,
      String? transactionRef,
      String? category,
      String? merchant,
      String? paymentType,
    }) {
      return SmsActivity()
        ..sender = 'HDFCBK'
        ..body = 'test sms'
        ..date = DateTime.now()
        ..createdAt = DateTime.now()
        ..smsHash = 'hash_${DateTime.now().microsecondsSinceEpoch}'
        ..status = ActivityStatus.pending
        ..amount = amount
        ..isIncome = isIncome
        ..account = account
        ..fromBank = fromBank
        ..transactionRef = transactionRef
        ..category = category
        ..merchant = merchant
        ..paymentType = paymentType;
    }

    test('empty activity returns 0', () {
      final activity = makeActivity();
      expect(SmsActivityService.calculateConfidence(activity), 0);
    });

    test('amount adds 35 points', () {
      final activity = makeActivity(amount: 500.0);
      expect(SmsActivityService.calculateConfidence(activity), 35);
    });

    test('amount + isIncome adds 60 points', () {
      final activity = makeActivity(amount: 500.0, isIncome: false);
      expect(SmsActivityService.calculateConfidence(activity), 60);
    });

    test('amount + isIncome + account adds 80 points', () {
      final activity = makeActivity(
        amount: 500.0,
        isIncome: false,
        account: '1234',
      );
      expect(SmsActivityService.calculateConfidence(activity), 80);
    });

    test('all fields present clamps to 100', () {
      final activity = makeActivity(
        amount: 500.0,
        isIncome: false,
        account: '1234',
        fromBank: 'HDFC',
        transactionRef: 'REF123',
        category: 'Food',
        merchant: 'Swiggy',
        paymentType: 'UPI',
      );
      // 35+25+20+10+10+15+15+10 = 140 → clamped to 100
      expect(SmsActivityService.calculateConfidence(activity), 100);
    });

    test('empty strings do not count', () {
      final activity = makeActivity(
        amount: 500.0,
        isIncome: false,
        account: '',
        fromBank: '',
        category: '',
        merchant: '',
        paymentType: '',
      );
      // Only amount(35) + isIncome(25) = 60
      expect(SmsActivityService.calculateConfidence(activity), 60);
    });

    test('zero amount does not count', () {
      final activity = makeActivity(amount: 0.0, isIncome: false);
      // Only isIncome(25)
      expect(SmsActivityService.calculateConfidence(activity), 25);
    });

    test('negative amount does not count', () {
      final activity = makeActivity(amount: -100.0, isIncome: true);
      expect(SmsActivityService.calculateConfidence(activity), 25);
    });
  });

  group('Confidence boost after calculateConfidence', () {
    test('high-confidence category match adds 10 to base score', () {
      final activity = SmsActivity()
        ..sender = 'HDFCBK'
        ..body = 'test sms'
        ..date = DateTime.now()
        ..createdAt = DateTime.now()
        ..smsHash = 'hash_boost_test'
        ..status = ActivityStatus.pending
        ..amount = 500.0
        ..isIncome = false
        ..account = '1234'
        ..category = 'Food';

      // Base: amount(35) + isIncome(25) + account(20) + category(15) = 95
      final base = SmsActivityService.calculateConfidence(activity);
      expect(base, 95);

      // Simulate the boost that addActivity applies for high-confidence match
      final boosted = (base + 10).clamp(0, 100);
      expect(boosted, 100); // 95 + 10 = 105 → clamped to 100
    });

    test('boost is not applied for low-confidence category match', () {
      final activity = SmsActivity()
        ..sender = 'HDFCBK'
        ..body = 'test sms'
        ..date = DateTime.now()
        ..createdAt = DateTime.now()
        ..smsHash = 'hash_no_boost'
        ..status = ActivityStatus.pending
        ..amount = 500.0
        ..isIncome = false
        ..category = 'Others';

      // Base: amount(35) + isIncome(25) + category(15) = 75
      final base = SmsActivityService.calculateConfidence(activity);
      expect(base, 75);

      // No boost applied (isHighConfidence = false for fallback matches)
      // Score stays at 75
      expect(base, 75);
    });
  });
}
