import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:mudra_plugin_sdk/mudra_plugin_sdk.dart';

class GoalTrackerPlugin extends MudraPlugin {
  @override
  String get id => 'com.mudra.goal_tracker';

  @override
  String get name => 'Goal Tracker';

  @override
  String get version => '1.1.0';

  @override
  void onGoal(GoalEvent event) {
    if (event.achieved) {
      api.showNotification('🎉 Goal achieved! Keep it up!');
    }
  }

  @override
  void onIncome(IncomeEvent event) {
    final trackSavings = config?.get<bool>('track_savings') ?? true;
    if (trackSavings && event.source.toLowerCase().contains('savings')) {
      api.showNotification(
        '💰 Savings added: ${formatCurrency(event.amount, code: BaseCurrency.code, decimals: 0)}',
      );
    }
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
