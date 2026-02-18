import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';
import 'package:mudra_manager/features/sms/data/sms_cleanup_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SmsHashCleanupService', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      SharedPrefsUtil.init(prefs);
    });

    test('cleanupOldHashes trims excess hashes', () async {
      // Create more than maxHashCount hashes
      final hashes = List.generate(1500, (i) => 'hash_$i');
      await SharedPrefsUtil.instance.setStringList(
        'processed_sms_hashes',
        hashes,
      );

      await SmsHashCleanupService.cleanupOldHashes();

      final remaining =
          SharedPrefsUtil.instance.getStringList('processed_sms_hashes') ?? [];
      expect(remaining.length, SmsHashCleanupService.maxHashCount);
      expect(remaining.first, 'hash_500'); // Should keep last 1000
    });

    test('cleanupOldHashes does nothing when under limit', () async {
      final hashes = List.generate(500, (i) => 'hash_$i');
      await SharedPrefsUtil.instance.setStringList(
        'processed_sms_hashes',
        hashes,
      );

      await SmsHashCleanupService.cleanupOldHashes();

      final remaining =
          SharedPrefsUtil.instance.getStringList('processed_sms_hashes') ?? [];
      expect(remaining.length, 500);
    });

    test('clearAllHashes removes all hashes', () async {
      final hashes = List.generate(100, (i) => 'hash_$i');
      await SharedPrefsUtil.instance.setStringList(
        'processed_sms_hashes',
        hashes,
      );

      await SmsHashCleanupService.clearAllHashes();

      final remaining =
          SharedPrefsUtil.instance.getStringList('processed_sms_hashes') ?? [];
      expect(remaining.length, 0);
    });

    test('getProcessedCount returns correct count', () {
      final hashes = List.generate(50, (i) => 'hash_$i');
      SharedPrefsUtil.instance.setStringList('processed_sms_hashes', hashes);

      final count = SmsHashCleanupService.getProcessedCount();
      expect(count, 50);
    });
  });
}
