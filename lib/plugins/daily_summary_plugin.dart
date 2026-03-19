import 'package:mudra_plugin_sdk/mudra_plugin_sdk.dart';
import 'package:mudra_manager/core/services/notification_service.dart';

class DailySummaryPlugin extends MudraPlugin {
  @override
  String get id => 'com.mudra.daily_summary';

  @override
  String get name => 'Daily Summary';

  @override
  String get version => '1.1.0';

  @override
  void onDailySummary(DailySummaryEvent event) {
    NotificationService.showDailySummary();
  }

  @override
  void onLoad() {}

  @override
  void onStart() {}
}
