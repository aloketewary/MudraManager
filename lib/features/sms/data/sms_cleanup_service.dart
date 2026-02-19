import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';

class SmsHashCleanupService {
  static const int maxHashCount = 1000;
  static const int retentionDays = 90;
  static final AppLog _log = AppLog(getLogger(), 'SmsHashCleanupService');

  /// Cleanup old SMS hashes to prevent unbounded growth
  static Future<void> cleanupOldHashes() async {
    try {
      final prefs = SharedPrefsUtil.instance;
      final hashes = prefs.getStringList('processed_sms_hashes') ?? [];

      if (hashes.length > maxHashCount) {
        final trimmed = hashes.sublist(hashes.length - maxHashCount);
        await prefs.setStringList('processed_sms_hashes', trimmed);

        _log.i('Cleaned up ${hashes.length - maxHashCount} old SMS hashes');
      }
    } catch (e) {
      _log.e('Failed to cleanup SMS hashes', e);
    }
  }

  /// Clear all processed hashes (for manual re-scan)
  static Future<void> clearAllHashes() async {
    try {
      final prefs = SharedPrefsUtil.instance;
      await prefs.setStringList('processed_sms_hashes', []);
      _log.i('Cleared all SMS hashes');
    } catch (e) {
      _log.e('Failed to clear SMS hashes', e);
    }
  }

  /// Get count of processed SMS
  static int getProcessedCount() {
    final prefs = SharedPrefsUtil.instance;
    return (prefs.getStringList('processed_sms_hashes') ?? []).length;
  }
}
