import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:mudra_plugin_sdk/mudra_plugin_sdk.dart';

class CategoryAlertPlugin extends MudraPlugin {
  @override
  String get id => 'com.mudra.category_alert';

  @override
  String get name => 'Category Alert';

  @override
  String get version => '1.1.0';

  @override
  Set<PluginPermission> get permissions => {
        PluginPermission.notifications,
      };

  @override
  void onLoad() {}

  @override
  void onStart() {
    // Declarative rules instead of hardcoded if/else
    ruleEngine.addRule(
      Rule(
        id: 'food_limit',
        event: 'expense',
        conditions: [
          RuleCondition(
            field: 'category',
            operator: RuleOperator.equals,
            value: 'Food',
          ),
          RuleCondition(
            field: 'amount',
            operator: RuleOperator.greaterThan,
            value: 5000,
          ),
        ],
        action: RuleAction.notify,
        actionParams: {'text': '🍔 High Food expense! Over ${BaseCurrency.symbol}5,000'},
      ),
    );

    ruleEngine.addRule(
      Rule(
        id: 'shopping_limit',
        event: 'expense',
        conditions: [
          RuleCondition(
            field: 'category',
            operator: RuleOperator.equals,
            value: 'Shopping',
          ),
          RuleCondition(
            field: 'amount',
            operator: RuleOperator.greaterThan,
            value: 3000,
          ),
        ],
        action: RuleAction.notify,
        actionParams: {'text': '🛍️ High Shopping expense! Over ${BaseCurrency.symbol}3,000'},
      ),
    );

    ruleEngine.addRule(
      Rule(
        id: 'entertainment_limit',
        event: 'expense',
        conditions: [
          RuleCondition(
            field: 'category',
            operator: RuleOperator.equals,
            value: 'Entertainment',
          ),
          RuleCondition(
            field: 'amount',
            operator: RuleOperator.greaterThan,
            value: 2000,
          ),
        ],
        action: RuleAction.notify,
        actionParams: {'text': '🎬 High Entertainment expense! Over ${BaseCurrency.symbol}2,000'},
      ),
    );
  }

  // No need for onExpense override — rules handle it automatically

  @override
  void onStop() {
    ruleEngine.clearRules();
  }
}
