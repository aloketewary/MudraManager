# Dashboard Home

> **Purpose:** "What's happening with my money right now?"

The dashboard is not a widget grid. It is a **command center** that answers the user's most urgent financial question before they scroll.

---

## Key Files

| File | Role |
|---|---|
| `dashboard_home.dart` | Main screen scaffold, widget list rendering |
| `dashboard_customize_screen.dart` | Widget visibility & ordering |
| `command_center_screen.dart` | Extended dashboard actions |
| `widget_analytics_screen.dart` | Internal analytics (dev tool) |
| `recurring_expenses_screen.dart` | Upcoming bills overview |
| `dashboard_data_provider.dart` | Aggregated financial data |
| `widget_preferences_provider.dart` | User's widget ordering/visibility |
| `smart_order_provider.dart` | Intelligent widget ranking |
| `dashboard_widget_registry.dart` | Plugin registration system |

---

## Design Decisions

### 1. Widget Plugin Architecture

Every dashboard card is a `DashboardWidgetPlugin` — self-contained, independently toggleable, position-aware. This enables:
- User reordering without code changes
- Feature flags via plugin registration
- A/B testing by swapping plugin priority

### 2. Daily Briefing at Position Zero

The `DailyBriefingCard` sits above all widgets (order: -1). It is the single most important signal. See [daily-briefing.md](./daily-briefing.md) for full philosophy.

### 3. Cards Available

| Card Widget | What It Shows |
|---|---|
| `daily_briefing_card.dart` | Single winning signal — alerting |
| `dashboard_account_card.dart` | Account balances (swipeable) |
| `modern_cashflow_card.dart` | Income vs expense this month |
| `budget_card.dart` | Active budget progress |
| `goal_card.dart` | Savings goal progress |
| `recent_transactions_card.dart` | Last 5 transactions |
| `recurring_expenses_card.dart` | Upcoming bills |
| `financial_health_card.dart` | Health score summary |
| `spending_personality_card.dart` | Spending archetype |
| `spending_prediction_card.dart` | Projected month-end |
| `net_worth_card.dart` | Total net worth |
| `net_worth_mini_card.dart` | Compact net worth |
| `hero_moment_card.dart` | Celebration of achievements |

### 4. No Auto-Reordering in Production

Smart ordering was killed. Users want **spatial stability** — knowing where to look. Constant reordering creates disorientation. Order is user-controlled, period.

### 5. Account Card is Swipeable

`swipeable_account_card.dart` lets users swipe between accounts without navigating away. This keeps the dashboard as the single source of truth for "how much do I have."

---

## Interactions

- Tapping budget card → `budget_details_screen.dart`
- Tapping goal card → `goal_details_screen.dart`
- Tapping transaction → `add_edit_transaction_screen.dart`
- Tapping briefing → context-dependent (bill, budget, or spending screen)
- FAB → Quick add transaction sheet

