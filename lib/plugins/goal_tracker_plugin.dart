import 'package:mudra_plugin_sdk/mudra_plugin_sdk.dart';

class GoalTrackerPlugin extends MudraPlugin {
  @override
  String get id => 'com.mudra.goal_tracker';

  @override
  String get name => 'Goal Tracker';

  @override
  String get version => '1.1.0';

  @override
  void onGoal(GoalEvent e) {
    if (e.achieved) {
      api.showNotification('🎉 Goal achieved! Keep it up!');
    }
  }

  @override
  void onIncome(IncomeEvent e) {
    final trackSavings = config?.get<bool>('track_savings') ?? true;
    if (trackSavings && e.source.toLowerCase().contains('savings')) {
      api.showNotification('💰 Savings added: ₹${e.amount.toStringAsFixed(0)}');
    }
  }

  @override
  void onLoad() {}
  
  @override
  void onStart() {}
}
