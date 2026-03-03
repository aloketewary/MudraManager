import 'package:mudra_plugin_sdk/mudra_plugin_sdk.dart';

class CategoryAlertPlugin extends MudraPlugin {
  @override
  String get id => 'com.mudra.category_alert';

  @override
  String get name => 'Category Alert';

  @override
  String get version => '1.0.0';

  final _categoryLimits = {
    'Food': 5000.0,
    'Shopping': 3000.0,
    'Entertainment': 2000.0,
  };

  @override
  void onExpense(ExpenseEvent event) {
    final limit = _categoryLimits[event.category];
    if (limit != null && event.amount > limit) {
      api.showNotification('High ${event.category} expense: ₹${event.amount.toStringAsFixed(0)}');
    }
  }

  @override
  void onLoad() {}
  
  @override
  void onStart() {}
}
