import 'package:mudra_manager/core/widgets/dashboard_widget_plugin.dart';
import 'package:mudra_manager/features/dashboard/plugin/accounts_widget_plugin.dart';
import 'package:mudra_manager/features/dashboard/plugin/budget_overview_widget_plugin.dart';
import 'package:mudra_manager/features/dashboard/plugin/cash_flow_widget_plugin.dart';
import 'package:mudra_manager/features/dashboard/plugin/daily_briefing_widget_plugin.dart';
import 'package:mudra_manager/features/dashboard/plugin/goals_widget_plugin.dart';
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
    // Unified Briefing — the primary experience
    DailyBriefingWidgetPlugin(),

    // Essential widgets
    AccountsWidgetPlugin(),
    QuickActionsWidgetPlugin(),
    CashFlowWidgetPlugin(),

    // Finance tracking widgets
    BudgetOverviewWidgetPlugin(),
    GoalsWidgetPlugin(),
    RecurringExpensesWidgetPlugin(),

    // Activity widgets
    RecentTransactionsWidgetPlugin(),
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
