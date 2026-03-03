import 'package:mudra_plugin_sdk/mudra_plugin_sdk.dart';

class DailySummaryPlugin extends MudraPlugin {
  @override
  String get id => 'com.mudra.daily_summary';

  @override
  String get name => 'Daily Summary';

  @override
  String get version => '1.0.0';

  @override
  void onExpense(ExpenseEvent e) {
    // Track daily expenses for summary
  }

  @override
  void onLoad() {}
  
  @override
  void onStart() {}
}
