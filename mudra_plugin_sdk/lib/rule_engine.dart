/// Operator for rule conditions.
enum RuleOperator {
  equals,
  notEquals,
  greaterThan,
  lessThan,
  greaterOrEqual,
  lessOrEqual,
  contains,
  notContains,
}

/// Action to execute when a rule matches.
enum RuleAction { notify, log, addExpense, addIncome, custom }

/// A single condition that evaluates against event data.
class RuleCondition {
  final String field;
  final RuleOperator operator;
  final dynamic value;

  RuleCondition({
    required this.field,
    required this.operator,
    required this.value,
  });

  bool evaluate(Map<String, dynamic> data) {
    final fieldValue = data[field];
    if (fieldValue == null) return false;

    switch (operator) {
      case RuleOperator.equals:
        return fieldValue == value;
      case RuleOperator.notEquals:
        return fieldValue != value;
      case RuleOperator.greaterThan:
        return _toNum(fieldValue) > _toNum(value);
      case RuleOperator.lessThan:
        return _toNum(fieldValue) < _toNum(value);
      case RuleOperator.greaterOrEqual:
        return _toNum(fieldValue) >= _toNum(value);
      case RuleOperator.lessOrEqual:
        return _toNum(fieldValue) <= _toNum(value);
      case RuleOperator.contains:
        return fieldValue.toString().toLowerCase().contains(
          value.toString().toLowerCase(),
        );
      case RuleOperator.notContains:
        return !fieldValue.toString().toLowerCase().contains(
          value.toString().toLowerCase(),
        );
    }
  }

  double _toNum(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  factory RuleCondition.fromJson(Map<String, dynamic> json) => RuleCondition(
    field: json['field'],
    operator: RuleOperator.values.byName(json['operator']),
    value: json['value'],
  );

  Map<String, dynamic> toJson() => {
    'field': field,
    'operator': operator.name,
    'value': value,
  };
}

/// A rule that matches an event type, evaluates conditions, and triggers an action.
class Rule {
  final String id;
  final String event;
  final List<RuleCondition> conditions;
  final RuleAction action;
  final Map<String, dynamic> actionParams;
  final bool matchAll; // true = AND, false = OR

  Rule({
    required this.id,
    required this.event,
    required this.conditions,
    required this.action,
    this.actionParams = const {},
    this.matchAll = true,
  });

  bool matches(String eventType, Map<String, dynamic> data) {
    if (event != eventType) return false;
    if (conditions.isEmpty) return true;

    return matchAll
        ? conditions.every((c) => c.evaluate(data))
        : conditions.any((c) => c.evaluate(data));
  }

  factory Rule.fromJson(Map<String, dynamic> json) => Rule(
    id: json['id'],
    event: json['event'],
    conditions: (json['conditions'] as List)
        .map((c) => RuleCondition.fromJson(c))
        .toList(),
    action: RuleAction.values.byName(json['action']),
    actionParams: json['actionParams'] ?? {},
    matchAll: json['matchAll'] ?? true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'event': event,
    'conditions': conditions.map((c) => c.toJson()).toList(),
    'action': action.name,
    'actionParams': actionParams,
    'matchAll': matchAll,
  };
}

/// Callback for executing rule actions.
typedef RuleActionHandler =
    void Function(
      RuleAction action,
      Map<String, dynamic> params,
      Map<String, dynamic> eventData,
    );

/// Evaluates rules against events and dispatches actions.
class RuleEngine {
  final List<Rule> _rules = [];
  RuleActionHandler? onAction;

  List<Rule> get rules => List.unmodifiable(_rules);

  void addRule(Rule rule) {
    _rules.removeWhere((r) => r.id == rule.id); // upsert
    _rules.add(rule);
  }

  void removeRule(String ruleId) {
    _rules.removeWhere((r) => r.id == ruleId);
  }

  void clearRules() => _rules.clear();

  /// Process an event. Returns list of matched rule IDs.
  List<String> process(String eventType, Map<String, dynamic> data) {
    final matched = <String>[];
    for (final rule in _rules) {
      if (rule.matches(eventType, data)) {
        matched.add(rule.id);
        onAction?.call(rule.action, rule.actionParams, data);
      }
    }
    return matched;
  }
}
