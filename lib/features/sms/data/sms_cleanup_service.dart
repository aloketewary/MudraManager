import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SmsHashCleanupService {
  static const int _maxHashCount = 500;
  static final AppLog _log = AppLog(getLogger(), 'SmsHashCleanupService');

  static Future<void> cleanupOldHashes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hashes = prefs.getStringList('processed_sms_hashes') ?? [];

      if (hashes.length > _maxHashCount) {
        final trimmed = hashes.sublist(hashes.length - _maxHashCount);
        await prefs.setStringList('processed_sms_hashes', trimmed);
        _log.i('Cleaned up ${hashes.length - _maxHashCount} old SMS hashes');
      }
    } catch (e) {
      _log.e('Failed to cleanup SMS hashes', e);
    }
  }

  static Future<void> clearAllHashes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('processed_sms_hashes', []);
      _log.i('Cleared all SMS hashes');
    } catch (e) {
      _log.e('Failed to clear SMS hashes', e);
    }
  }

  static Future<int> getProcessedCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return (prefs.getStringList('processed_sms_hashes') ?? []).length;
    } catch (_) {
      return 0;
    }
  }
}
