import 'package:mudra_plugin_sdk/mudra_plugin_sdk.dart';
import 'package:mudra_manager/core/services/notification_service.dart';

class MudraApiImpl implements MudraApi {
  @override
  void showNotification(String text) {
    // Use a hash of the timestamp to keep it within 32-bit integer range
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final notificationId =
        timestamp.hashCode.abs() % 2147483647; // Max 32-bit int

    NotificationService.showLocalNotification(
      id: notificationId,
      title: 'Mudra Manager',
      body: text,
    );
  }

  @override
  void addExpense(double amount) {
    // Controlled expense creation through API
    // No direct DB access
  }
}
