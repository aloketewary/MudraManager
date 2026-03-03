import 'package:mudra_plugin_sdk/mudra_plugin_sdk.dart';

class SmsAlertPlugin extends MudraPlugin {
  @override
  String get id => 'com.mudra.sms_alert';

  @override
  String get name => 'SMS Alert';

  @override
  String get version => '1.1.0';

  @override
  void onSms(SmsEvent event) {
    if (event.body.toLowerCase().contains('credited')) {
      api.showNotification('💰 Money credited!');
    }
  }

  @override
  void onIncome(IncomeEvent event) {
    final threshold = config?.get<double>('min_amount') ?? 0.0;
    if (event.amount > threshold) {
      api.showNotification('💵 Income received: ₹${event.amount.toStringAsFixed(0)}');
    }
  }

  @override
  void onLoad() {}
  
  @override
  void onStart() {}
}
