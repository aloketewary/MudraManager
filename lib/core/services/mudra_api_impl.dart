import 'package:mudra_plugin_sdk/mudra_plugin_sdk.dart';
import 'package:mudra_manager/core/services/notification_service.dart';

class MudraApiImpl implements MudraApi {
  @override
  void showNotification(String text) {
    NotificationService.showLocalNotification(
      id: DateTime.now().millisecondsSinceEpoch,
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
