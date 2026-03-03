import 'rule.dart';

class RuleEngine {
  final List<Rule> rules = [];

  void process(String event, Map<String, dynamic> data) {
    for (final rule in rules) {
      if (rule.event == event && _match(rule.condition, data)) {
        _execute(rule.action, data);
      }
    }
  }

  bool _match(String cond, Map<String, dynamic> data) {
    return data['body']?.toString().contains(cond) ?? false;
  }

  void _execute(String action, Map<String, dynamic> data) {
    print('Action: $action');
  }
}
