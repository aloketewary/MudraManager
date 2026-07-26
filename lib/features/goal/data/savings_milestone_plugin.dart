import 'package:mudra_plugin_sdk/mudra_plugin_sdk.dart';

class SavingsMilestonePlugin extends MudraPlugin {
  @override
  String get id => 'com.mudra.savings_milestone';

  @override
  String get name => 'Savings Milestone';

  @override
  String get version => '1.1.0';

  @override
  void onGoal(GoalEvent event) {
    if (event.achieved) {
      api.showNotification('🎉 Savings milestone reached!');
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
