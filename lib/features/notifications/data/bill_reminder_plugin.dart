import 'package:mudra_plugin_sdk/mudra_plugin_sdk.dart';

class BillReminderPlugin extends MudraPlugin {
  @override
  String get id => 'com.mudra.bill_reminder';

  @override
  String get name => 'Bill Reminder';

  @override
  String get version => '1.0.0';

  @override
  void onExpense(ExpenseEvent event) {
    // Check for recurring bills
  }

  @override
  void onLoad() {}

  @override
  void onStart() {}

  @override
  Set<PluginPermission> get permissions => {};
}
