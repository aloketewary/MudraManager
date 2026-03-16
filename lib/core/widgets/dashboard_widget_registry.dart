import 'package:mudra_manager/core/widgets/dashboard_widget_plugin.dart';
import 'package:mudra_manager/features/dashboard/plugin/accounts_widget_plugin.dart';
import 'package:mudra_manager/features/dashboard/plugin/ai_insight_widget_plugin.dart';
import 'package:mudra_manager/features/dashboard/plugin/budget_overview_widget_plugin.dart';
import 'package:mudra_manager/features/dashboard/plugin/cash_flow_widget_plugin.dart';
import 'package:mudra_manager/features/dashboard/plugin/goals_widget_plugin.dart';
import 'package:mudra_manager/features/dashboard/plugin/net_worth_widget_plugin.dart';
import 'package:mudra_manager/features/dashboard/plugin/quick_actions_widget_plugin.dart';
import 'package:mudra_manager/features/dashboard/plugin/recent_transactions_widget_plugin.dart';
import 'package:mudra_manager/features/dashboard/plugin/recurring_expenses_widget_plugin.dart';

/// Central registry for all dashboard widgets
///
/// Widget Order Philosophy:
/// 1. AI Insights (0) - Contextual alerts at top
/// 2. Accounts (1) - Most important: current balance
/// 3. Quick Actions (2) - Easy access to common tasks
/// 4. Cash Flow (3) - Income vs Expense overview
/// 5. Budget Overview (4) - Budget health check
/// 6. Goals Progress (5) - Savings motivation
/// 7. Recurring Expenses (6) - Bill reminders
/// 8. Recent Transactions (7) - Latest activity
class DashboardWidgetRegistry {
  static final List<DashboardWidgetPlugin> _widgets = [
    // Essential widgets (always visible by default)
    AiInsightWidgetPlugin(), // Order 0 - Smart insights at top
    AccountsWidgetPlugin(), // Order 1 - Account balances
    QuickActionsWidgetPlugin(), // Order 2 - Quick access buttons
    CashFlowWidgetPlugin(), // Order 3 - Income/Expense overview

    // Finance tracking widgets
    BudgetOverviewWidgetPlugin(), // Order 4 - Budget status
    GoalsWidgetPlugin(), // Order 5 - Savings goals
    RecurringExpensesWidgetPlugin(), // Order 6 - Bill reminders

    // Activity widgets
    RecentTransactionsWidgetPlugin(), // Order 7 - Latest transactions
  ];

  /// Get all registered widgets
  static List<DashboardWidgetPlugin> get widgets => List.unmodifiable(_widgets);

  /// Register a new widget (for dynamic plugins)
  static void register(DashboardWidgetPlugin widget) {
    if (_widgets.any((w) => w.id == widget.id)) {
      throw Exception('Widget with id ${widget.id} already registered');
    }
    _widgets.add(widget);
  }

  /// Unregister a widget
  static void unregister(String widgetId) {
    _widgets.removeWhere((w) => w.id == widgetId);
  }

  /// Get widget by ID
  static DashboardWidgetPlugin? getWidget(String id) {
    try {
      return _widgets.firstWhere((w) => w.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get widgets by category
  static List<DashboardWidgetPlugin> getWidgetsByCategory(
    WidgetCategory category,
  ) {
    return _widgets.where((w) => w.category == category).toList();
  }

  /// Get essential widgets (high priority)
  static List<DashboardWidgetPlugin> get essentialWidgets {
    return _widgets
        .where((w) => w.category == WidgetCategory.essential)
        .toList();
  }

  /// Get finance widgets
  static List<DashboardWidgetPlugin> get financeWidgets {
    return _widgets.where((w) => w.category == WidgetCategory.finance).toList();
  }

  /// Get AI widgets
  static List<DashboardWidgetPlugin> get aiWidgets {
    return _widgets.where((w) => w.category == WidgetCategory.ai).toList();
  }
}
