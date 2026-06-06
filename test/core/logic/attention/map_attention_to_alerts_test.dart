import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/logic/attention/attention_item.dart';
import 'package:mudra_manager/core/logic/attention/map_attention_to_alerts.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/features/dashboard/data/priority_alert_provider.dart';

void main() {
  group('mapAttentionItemsToAlerts', () {
    test('empty items produces empty alerts', () {
      final result = mapAttentionItemsToAlerts([]);
      expect(result, isEmpty);
    });

    test('BillDueTomorrow maps to urgent alert with bills route', () {
      final items = [const BillDueTomorrow(count: 2, billName: 'Netflix')];
      final result = mapAttentionItemsToAlerts(items);

      expect(result, hasLength(1));
      expect(result.first.type, AlertType.urgent);
      expect(result.first.route, AppRoutes.recurringTransactions);
      expect(result.first.message, contains('2'));
      expect(result.first.message, contains('tomorrow'));
    });

    test('BillDueSoon maps to warning alert', () {
      final items = [const BillDueSoon(count: 1, daysUntil: 3)];
      final result = mapAttentionItemsToAlerts(items);

      expect(result.first.type, AlertType.warning);
      expect(result.first.route, AppRoutes.recurringTransactions);
    });

    test('BudgetOverLimit maps to urgent alert with budget route', () {
      final items = [
        const BudgetOverLimit(budgetName: 'Food', overCount: 2),
      ];
      final result = mapAttentionItemsToAlerts(items);

      expect(result.first.type, AlertType.urgent);
      expect(result.first.route, AppRoutes.budgetDashboard);
      expect(result.first.message, contains('2'));
    });

    test('BudgetNearLimit maps to warning alert', () {
      final items = [
        const BudgetNearLimit(budgetName: 'Shopping', nearCount: 1),
      ];
      final result = mapAttentionItemsToAlerts(items);

      expect(result.first.type, AlertType.warning);
    });

    test('GoalNearCompletion maps to info alert with goal route', () {
      final items = [const GoalNearCompletion(count: 3)];
      final result = mapAttentionItemsToAlerts(items);

      expect(result.first.type, AlertType.info);
      expect(result.first.route, AppRoutes.goalScreen);
    });

    test('alerts sorted by severity: urgent > warning > info', () {
      final items = [
        const GoalNearCompletion(count: 1), // info
        const BillDueSoon(count: 1, daysUntil: 2), // warning
        const BudgetOverLimit(budgetName: 'X', overCount: 1), // urgent
      ];

      final result = mapAttentionItemsToAlerts(items);

      expect(result[0].type, AlertType.urgent);
      expect(result[1].type, AlertType.warning);
      expect(result[2].type, AlertType.info);
    });

    test('capped to maxAlerts (default 3)', () {
      final items = [
        const BudgetOverLimit(budgetName: 'A', overCount: 1),
        const BillDueTomorrow(count: 1),
        const BudgetNearLimit(budgetName: 'B', nearCount: 1),
        const GoalNearCompletion(count: 2),
      ];

      final result = mapAttentionItemsToAlerts(items);
      expect(result, hasLength(3));
    });

    test('custom maxAlerts respected', () {
      final items = [
        const BudgetOverLimit(budgetName: 'A', overCount: 1),
        const BillDueTomorrow(count: 1),
        const BudgetNearLimit(budgetName: 'B', nearCount: 1),
        const GoalNearCompletion(count: 2),
      ];

      final result = mapAttentionItemsToAlerts(items, maxAlerts: 5);
      expect(result, hasLength(4)); // all 4 fit within cap of 5
    });
  });
}
