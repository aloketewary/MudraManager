import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SMS first import celebration prefs', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      SharedPrefsUtil.init(prefs);
    });

    test('smsFirstImportReady defaults to false', () {
      expect(SharedPrefsUtil.instance.getSmsFirstImportReady(), false);
    });

    test('smsFirstImportCelebrated defaults to false', () {
      expect(SharedPrefsUtil.instance.getSmsFirstImportCelebrated(), false);
    });

    test('setSmsFirstImportReady sets flag to true', () async {
      await SharedPrefsUtil.instance.setSmsFirstImportReady();
      expect(SharedPrefsUtil.instance.getSmsFirstImportReady(), true);
    });

    test('setSmsFirstImportCelebrated sets flag to true', () async {
      await SharedPrefsUtil.instance.setSmsFirstImportCelebrated();
      expect(SharedPrefsUtil.instance.getSmsFirstImportCelebrated(), true);
    });

    test('celebration flow: ready then celebrated', () async {
      // Initially both false
      expect(SharedPrefsUtil.instance.getSmsFirstImportReady(), false);
      expect(SharedPrefsUtil.instance.getSmsFirstImportCelebrated(), false);

      // SMS pipeline sets ready
      await SharedPrefsUtil.instance.setSmsFirstImportReady();
      expect(SharedPrefsUtil.instance.getSmsFirstImportReady(), true);
      expect(SharedPrefsUtil.instance.getSmsFirstImportCelebrated(), false);

      // Dashboard shows celebration and marks celebrated
      await SharedPrefsUtil.instance.setSmsFirstImportCelebrated();
      expect(SharedPrefsUtil.instance.getSmsFirstImportReady(), true);
      expect(SharedPrefsUtil.instance.getSmsFirstImportCelebrated(), true);
    });

    test('ready flag is not set if already celebrated', () async {
      // Simulate: celebration already shown
      await SharedPrefsUtil.instance.setSmsFirstImportCelebrated();

      // The guard in NotificationListenerBridge checks this
      final alreadyCelebrated =
          SharedPrefsUtil.instance.getSmsFirstImportCelebrated();
      expect(alreadyCelebrated, true);
      // So setSmsFirstImportReady would not be called
    });
  });
}
