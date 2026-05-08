import 'package:flutter/services.dart';
import 'package:in_app_update/in_app_update.dart';

class AppUpdateService {
  static bool _checked = false;

  static Future<void> checkForUpdate() async {
    if (_checked) return;
    _checked = true;

    try {
      final info = await InAppUpdate.checkForUpdate();

      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        if (info.flexibleUpdateAllowed) {
          await InAppUpdate.startFlexibleUpdate();
          await InAppUpdate.completeFlexibleUpdate();
        } else if (info.immediateUpdateAllowed) {
          await InAppUpdate.performImmediateUpdate();
        }
      }
    } on MissingPluginException {
      // Ignore during hot reload/development
    } catch (_) {
      // Silently ignore update check failures
    }
  }
}
