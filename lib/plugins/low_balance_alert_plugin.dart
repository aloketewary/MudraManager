import 'package:mudra_plugin_sdk/mudra_plugin_sdk.dart';

class LowBalanceAlertPlugin extends MudraPlugin {
  @override
  String get id => 'com.mudra.low_balance_alert';

  @override
  String get name => 'Low Balance Alert';

  @override
  String get version => '1.0.0';

  @override
  void onLowBalance(LowBalanceEvent event) {
    api.showNotification('⚠️ ${event.accountName} balance low: ₹${event.balance.toStringAsFixed(0)}');
  }

  @override
  void onTransfer(TransferEvent event) {
    final trackTransfers = config?.get<bool>('track_transfers') ?? true;
    if (trackTransfers) {
      api.showNotification('🔄 Transfer: ${event.fromAccount} → ${event.toAccount}');
    }
  }

  @override
  void onLoad() {}
  
  @override
  void onStart() {}
}
