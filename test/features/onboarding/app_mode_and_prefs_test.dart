import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/providers/app_mode_provider.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppMode enum', () {
    test('has simple and full values', () {
      expect(AppMode.values.length, 2);
      expect(AppMode.values, contains(AppMode.simple));
      expect(AppMode.values, contains(AppMode.full));
    });
  });

  group('SharedPrefsUtil app mode', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      SharedPrefsUtil.init(prefs);
    });

    test('defaults to simple', () {
      expect(SharedPrefsUtil.instance.getAppMode(), 'simple');
    });

    test('stores and retrieves full', () async {
      await SharedPrefsUtil.instance.setAppMode('full');
      expect(SharedPrefsUtil.instance.getAppMode(), 'full');
    });

    test('stores and retrieves simple', () async {
      await SharedPrefsUtil.instance.setAppMode('simple');
      expect(SharedPrefsUtil.instance.getAppMode(), 'simple');
    });
  });

  group('SharedPrefsUtil first txn nudge', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      SharedPrefsUtil.init(prefs);
    });

    test('defaults to not dismissed', () {
      expect(SharedPrefsUtil.instance.getFirstTxnNudgeDismissed(), false);
    });

    test('can be dismissed', () async {
      await SharedPrefsUtil.instance.setFirstTxnNudgeDismissed();
      expect(SharedPrefsUtil.instance.getFirstTxnNudgeDismissed(), true);
    });
  });

  group('SharedPrefsUtil starter txns', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      SharedPrefsUtil.init(prefs);
    });

    test('defaults to not offered', () {
      expect(SharedPrefsUtil.instance.getStarterTxnsOffered(), false);
    });

    test('can be marked as offered', () async {
      await SharedPrefsUtil.instance.setStarterTxnsOffered();
      expect(SharedPrefsUtil.instance.getStarterTxnsOffered(), true);
    });
  });

  group('SharedPrefsUtil onboarding timestamp', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      SharedPrefsUtil.init(prefs);
    });

    test('defaults to null', () {
      expect(SharedPrefsUtil.instance.getOnboardingCompletedAt(), isNull);
    });

    test('stores and retrieves timestamp', () async {
      final now = DateTime(2025, 6, 15, 10, 30);
      await SharedPrefsUtil.instance.setOnboardingCompletedAt(now);
      final retrieved = SharedPrefsUtil.instance.getOnboardingCompletedAt();
      expect(retrieved, isNotNull);
      expect(retrieved!.year, 2025);
      expect(retrieved.month, 6);
      expect(retrieved.day, 15);
      expect(retrieved.hour, 10);
      expect(retrieved.minute, 30);
    });

    test('isNewUser logic: within 24h', () async {
      final recent = DateTime.now().subtract(const Duration(hours: 12));
      await SharedPrefsUtil.instance.setOnboardingCompletedAt(recent);
      final onboardedAt = SharedPrefsUtil.instance.getOnboardingCompletedAt();
      final isNewUser = onboardedAt != null &&
          DateTime.now().difference(onboardedAt).inHours < 24;
      expect(isNewUser, true);
    });

    test('isNewUser logic: after 24h', () async {
      final old = DateTime.now().subtract(const Duration(hours: 25));
      await SharedPrefsUtil.instance.setOnboardingCompletedAt(old);
      final onboardedAt = SharedPrefsUtil.instance.getOnboardingCompletedAt();
      final isNewUser = onboardedAt != null &&
          DateTime.now().difference(onboardedAt).inHours < 24;
      expect(isNewUser, false);
    });
  });
}
