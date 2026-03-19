import 'package:mudra_plugin_sdk/mudra_plugin_sdk.dart';

class LowBalanceAlertPlugin extends MudraPlugin {
  @override
  String get id => 'com.mudra.low_balance_alert';

  @override
  String get name => 'Low Balance Alert';

  @override
  String get version => '1.1.0';

  @override
  void onLowBalance(LowBalanceEvent event) {
    api.showNotification(
      '⚠️ ${event.accountName} balance low: ₹${event.balance.toStringAsFixed(0)}',
    );
  }

  @override
  void onTransfer(TransferEvent event) {
    final trackTransfers = config?.get<bool>('track_transfers') ?? true;
    if (trackTransfers) {
      api.showNotification(
        '🔄 Transfer: ${event.fromAccount} → ${event.toAccount}',
      );
    }
  }

  @override
  PluginNotification? onTransactionSaved(TransactionSavedEvent event) {
    if (!event.isExpense || event.account == null) return null;
    return PluginNotification(
      title: 'Might want to check your balance',
      body: '${event.account} balance may be low. Check your account.',
      priority: 5,
    );
  }

  @override
  void onLoad() {}

  @override
  void onStart() {}

  @override
  Set<PluginPermission> get permissions => {
        PluginPermission.notifications,
      };
}
