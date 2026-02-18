import 'package:mudra_manager/core/providers/shared_preference_provider.dart';
import 'package:mudra_manager/core/utils/app_logger.dart';

class SmsHashCleanupService {
  static const int maxHashCount = 1000;
  static const int retentionDays = 90;

  /// Cleanup old SMS hashes to prevent unbounded growth
  static Future<void> cleanupOldHashes() async {
    try {
      final prefs = SharedPrefsUtil.instance;
      final hashes = prefs.getStringList('processed_sms_hashes') ?? [];

      if (hashes.length > maxHashCount) {
        final trimmed = hashes.sublist(hashes.length - maxHashCount);
        await prefs.setStringList('processed_sms_hashes', trimmed);

        AppLogger.info(
          'Cleaned up ${hashes.length - maxHashCount} old SMS hashes',
          tag: 'SMS_CLEANUP',
        );
      }
    } catch (e) {
      AppLogger.error('Failed to cleanup SMS hashes', error: e);
    }
  }

  /// Clear all processed hashes (for manual re-scan)
  static Future<void> clearAllHashes() async {
    try {
      final prefs = SharedPrefsUtil.instance;
      await prefs.setStringList('processed_sms_hashes', []);
      AppLogger.info('Cleared all SMS hashes', tag: 'SMS_CLEANUP');
    } catch (e) {
      AppLogger.error('Failed to clear SMS hashes', error: e);
    }
  }

  /// Get count of processed SMS
  static int getProcessedCount() {
    final prefs = SharedPrefsUtil.instance;
    return (prefs.getStringList('processed_sms_hashes') ?? []).length;
  }
}
