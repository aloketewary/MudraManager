# Dashboard Engine Migration — Task Tracker

## Status: PHASE 1–5 ✅ | WAVE 1–2 ✅ | STRUCTURE CONSOLIDATION ✅ | ENGINE CUTOVER ✅

---

## PHASE 0 — Safety Preparation ✅

- [x] Feature flag switchboard created (`core/config/feature_flags.dart`)
- [x] Old system untouched and still rendering
- [x] SMS pipeline not modified
- [x] Isar writes stable

---

## PHASE 1 — Core Truth Engine (NO UI CHANGES) ✅

### Domain Enums ✅
- [x] `core/domain/financial_states.dart` — BudgetState, BillState, CashflowState, DataValidityLevel, StateTransition, BriefingTrigger
- [x] `core/domain/metrics.dart` — netCashflow, burnRate, budgetRatio, daysUntilDue, classifyCashflow

### Pure Logic ✅
- [x] `core/logic/budget_state_machine.dart`
- [x] `core/logic/bill_state_machine.dart`
- [x] `core/logic/cashflow_engine.dart`
- [x] `core/logic/convergence_counter.dart`
- [x] `core/logic/state_transition_engine.dart`
- [x] `core/logic/briefing_selector.dart`
- [x] `core/logic/suppression_engine.dart`
- [x] `core/logic/data_validity_gate.dart`

### State Model ✅
- [x] `core/state/dashboard_state.dart` — single truth object for UI

### Engine ✅
- [x] `core/engine/dashboard_engine.dart` — pure static orchestrator
- [x] `core/contracts/display_contract.dart` — enforcement boundary

### Unit Tests ✅ (65 tests passing)
- [x] `test/core/logic/budget_state_machine_test.dart`
- [x] `test/core/logic/bill_state_machine_test.dart`
- [x] `test/core/logic/convergence_counter_test.dart`
- [x] `test/core/logic/state_transition_engine_test.dart`
- [x] `test/core/logic/briefing_selector_test.dart`
- [x] `test/core/logic/suppression_engine_test.dart`
- [x] `test/core/engine/dashboard_engine_test.dart`

---

## PHASE 2 — Riverpod Bridge (Parallel Run) ✅

- [x] `core/engine/dashboard_state_provider.dart` — V2 provider, reads dashboardDataProvider, outputs DashboardState
- [ ] Verify V2 provider outputs match old constraintSnapshotProvider at runtime
- [ ] Add logging to compare old vs new in debug builds

---

## PASS 2 — App-Wide State Contract ✅

- [x] `core/state/app_screen_state.dart` — universal screen state pattern
  - AppScreenState<T> with gate, data, constraint, alert, isLoading, error
  - ConstraintInfo, ScreenAlert, ScreenAction models
  - All screens map into this contract

---

## PASS 3 — Screen Templates ✅

- [x] `shared/templates/screen_shell.dart` — ScreenShell (chrome-only: Scaffold + AppBar mode + Refresh)
- [x] `shared/templates/core_overview_template.dart` — Template A (dashboard, accounts, net worth)
- [x] `shared/templates/list_state_template.dart` — Template B (budgets, goals, bills)
- [x] `shared/templates/setup_state_template.dart` — Template C (onboarding, empty states)
- [x] `shared/templates/detail_inspection_template.dart` — Template D (transaction/budget/account detail)
- [x] `shared/templates/analytics_view_template.dart` — Template E (charts, trends)
- [x] `shared/templates/templates.dart` — barrel export
- [x] `core/state/app_screen_state.dart` — SINGLE AUTHORITY for actions (ScreenAction with ActionPlacement)

### Authority Model (ENFORCED)
```
AppScreenState.actions → SINGLE source of UI intent
  ├── placement: appBar  → ScreenShell renders in AppBar
  ├── placement: fab     → ScreenShell renders as FAB
  └── placement: contextual → Template renders inline

ScreenShellConfig → chrome rendering hints ONLY (title, appBarMode, enableRefresh)
Template → layout composition ONLY (no decisions)
```

---

## PHASE 3 — UI Shadow Mode ✅

- [x] `core/engine/parity_checker.dart` — debug-only provider comparing old vs new outputs
- [x] Wired into `DashboardHome.build()` (kDebugMode only)
- [x] Compares: budgetState, billState, convergence, billCount, budgetSpent, gate, netCashflow
- [x] Logs ✅ Parity OK or ⚠️ MISMATCH with field-level diffs
- [x] Run app and verified parity output in debug console
- [x] 7+ consecutive clean runs confirmed — stable for cutover

---

## PHASE 4 — Enable State Machines ✅

- [x] `FeatureFlags.useValidityGate = true`
- [x] `FeatureFlags.useCoreStateMachines = true`
- [x] Parity verified for all state machines

---

## PHASE 5 — Dashboard Swap (Cutover) ✅

- [x] `FeatureFlags.useNewDashboardEngine = true`
- [x] DailyBriefingCard: silence = SizedBox (no HeroMoment fallback)
- [x] DashboardWidgetRegistry: AiInsightWidgetPlugin removed
- [x] smart_order_provider removed from widget_preferences_provider
- [x] smart order toggle disabled in dashboard_customize_screen
- [x] Parity checker removed (no longer needed)

---

## PHASE 6 — Cleanup (PARTIAL)

### Deleted:
- [x] `features/dashboard/data/constraint_engine.dart`
- [x] `features/dashboard/presentation/providers/smart_order_provider.dart`
- [x] `features/dashboard/plugin/ai_insight_widget_plugin.dart`
- [x] `features/dashboard/plugin/hero_moment_widget_plugin.dart`
- [x] `features/dashboard/presentation/widgets/hero_moment_card.dart`
- [x] `core/engine/parity_checker.dart`

### Still in code (have downstream consumers):
- [x] `features/dashboard/data/priority_alert_provider.dart` — replaced by `core/logic/attention/dashboard_alert_provider.dart` (utility screen migrated)
- [ ] `features/dashboard/presentation/providers/ai_insight_provider.dart` — `AiInsight` class used by `spending_drift_detector.dart` + `daily_briefing_card.dart`

### To fully remove these:
- ~~Extract `PriorityAlert` to standalone~~ — kept in place, `dashboard_alert_provider` imports it
- Extract `AiInsight` class to a standalone model file
- Refactor `spending_drift_detector` to return `BriefingSelection` instead of `AiInsight`
- ~~Rewrite `utility_screen.dart` priority alert section to use `dashboardStateV2Provider`~~ ✅ Done via `dashboardAlertProvider`

---

## PHASE 7 — SMS Pipeline Verification

- [ ] Confirm SMS parser outputs ONLY: transaction, confidence, metadata
- [ ] Confirm no budget/bill/alert logic in `sms_activity_service.dart`
- [ ] Confirm no dashboard priority computation in SMS layer

---

## PHASE 8 — Architecture Lock

- [ ] UI files cannot import `core/logic/*`
- [ ] UI only imports `dashboardStateV2Provider`
- [ ] Document final dependency graph
- [ ] Remove "V2" suffix (it's now the only system)

---

## File Inventory

### New files created:
```
lib/core/config/feature_flags.dart
lib/core/domain/financial_states.dart
lib/core/domain/metrics.dart
lib/core/logic/budget_state_machine.dart
lib/core/logic/bill_state_machine.dart
lib/core/logic/cashflow_engine.dart
lib/core/logic/convergence_counter.dart
lib/core/logic/state_transition_engine.dart
lib/core/logic/briefing_selector.dart
lib/core/logic/suppression_engine.dart
lib/core/logic/data_validity_gate.dart
lib/core/state/dashboard_state.dart
lib/core/engine/dashboard_engine.dart
lib/core/engine/dashboard_state_provider.dart
lib/core/contracts/display_contract.dart
test/core/logic/budget_state_machine_test.dart
test/core/logic/bill_state_machine_test.dart
test/core/logic/convergence_counter_test.dart
test/core/logic/state_transition_engine_test.dart
test/core/logic/briefing_selector_test.dart
test/core/logic/suppression_engine_test.dart
test/core/engine/dashboard_engine_test.dart
```

### Files to delete (PHASE 6 only):
```
lib/features/dashboard/data/constraint_engine.dart
lib/features/dashboard/data/priority_alert_provider.dart
lib/features/dashboard/presentation/providers/ai_insight_provider.dart
lib/features/dashboard/presentation/providers/smart_order_provider.dart
lib/features/dashboard/plugin/ai_insight_widget_plugin.dart
lib/features/dashboard/plugin/hero_moment_widget_plugin.dart
lib/features/dashboard/presentation/widgets/hero_moment_card.dart
```

---

## SCREEN-TO-TEMPLATE MAPPING

Every screen maps to exactly ONE template.

### Template A — Core Overview
| Screen | Primary Metric | Constraint |
|--------|---------------|------------|
| Dashboard | Balance | Budget + Bills strip |
| Accounts Home | Total Balance | — |
| Net Worth | Net Worth | — |

### Template B — List + State
| Screen | Items | State Badge |
|--------|-------|-------------|
| Transactions | Transaction list | Category tag |
| Bills | Recurring list | Due state badge |
| Notifications | Alert list | Severity |
| Goals | Goal list | Progress % |

### Template C — Setup State
| Screen | Trigger |
|--------|---------|
| Onboarding | First launch |
| Dashboard insufficient gate | No accounts/txns |
| SMS setup | Permission not granted |
| Empty budget | No budgets created |

### Template D — Detail Inspection
| Screen | Entity |
|--------|--------|
| Budget detail | Single budget |
| Goal detail | Single goal |
| Trip detail | Single trip |
| Expense detail | Single expense |
| Split detail | Single split |

### Template E — Analytics View
| Screen | Chart |
|--------|-------|
| Statistics | Category pie/bar |
| Cashflow analysis | Line chart |
| Budget trends | Comparison bars |
| Monthly recap | Story charts |

---

## SCREEN MIGRATION — WAVE 1 (Foundation) ✅

### Migrated to ScreenShell (16 screens):
| # | Screen | Feature | Actions | Pattern |
|---|--------|---------|---------|--------|
| 1 | SecuritySettingsScreen | profile | None | title-only |
| 2 | CurrencySettingsScreen | profile | None | title-only |
| 3 | BudgetDetailsScreen | budget | appBar: edit, overflow: delete | actions + overflow |
| 4 | AppearanceScreen | profile | None | title-only |
| 5 | ChooseLanguageScreen | profile | None | title-only |
| 6 | NotificationSettingsScreen | profile | None | title-only |
| 7 | BackupRestoreScreen | profile | None | title-only |
| 8 | EditUserProfileScreen | profile | None | title-only |
| 9 | AboutScreen | profile | None | title-only |
| 10 | ManageAccountScreen | account | appBar: add + info | multi-action |
| 11 | ManageCategoriesScreen | category | appBar: add | single action |
| 12 | HelpScreen | profile | appBar: toggle search | dynamic mode |
| 13 | AppSettingsPage | profile | None | title-only |
| 14 | ThemePickerScreen | profile | fab: apply theme | FAB action |
| 15 | ArchivedTransactionsScreen | profile | None | title-only |
| 16 | ExchangeRateScreen | profile | None | title-only |

### Account screens (already on ScreenShell):
| Screen | Actions |
|--------|--------|
| BalanceHistoryScreen | None |
| CreditCardBillsScreen | None |
| InvestmentPortfolioScreen | fab: add holding |

### Skipped (form screens — need TextButton action support):
- `AddEditAccountScreen` — TextButton save in AppBar
- `AddEditCategoryScreen` — TextButton save in AppBar
- `ReconciliationScreen` — TextButton confirm in AppBar
- `SmsImportSettingScreen` — nested Scaffolds (multi-step)

### Does NOT exist (removed from tracker):
- ~~Transaction detail~~ — no read-only detail screen exists; edit goes to AddEditTransactionScreen
- ~~Account detail~~ — no standalone detail; ManageAccountScreen + BalanceHistory cover this

---

## STRUCTURE CONSOLIDATION ✅

### Moved to proper feature folders:
| File | From | To |
|------|------|----|
| ManageAccountScreen | `profile/presentation/screens/` | `account/presentation/screens/` |
| AccountForm → AddEditAccountScreen | `profile/presentation/widgets/` | `account/presentation/screens/` |
| ManageCategoriesScreen | `profile/presentation/screens/` | `category/presentation/screens/` |
| AddEditCategoryScreen | `profile/presentation/screens/` | `category/presentation/screens/` |

### Current feature structure:
```
features/account/presentation/screens/
├── add_edit_account_screen.dart
├── manage_account_screen.dart       ✅ ScreenShell
├── balance_history_screen.dart      ✅ ScreenShell
├── credit_card_bills_screen.dart    ✅ ScreenShell
├── investment_portfolio_screen.dart  ✅ ScreenShell (FAB)
└── reconciliation_screen.dart       (form, pending)

features/category/presentation/screens/
├── add_edit_category_screen.dart    (form, pending)
└── manage_categories_screen.dart    ✅ ScreenShell
```

## SCREEN MIGRATION — WAVE 2 (Data Screens) ✅

| Screen | Actions | Pattern |
|--------|---------|--------|
| BillControlCenterScreen | appBar: add | ScreenShell |
| AdaptiveBudgetDashboard | appBar: add | ScreenShell |
| GoalScreen | appBar: add, onRefresh | ScreenShell (SliverAppBar flattened) |
| TransactionListScreen | N/A | Template X (custom — mode-switching AppBar, ExpandableFab, multi-select) |

### Wave 3 — Detail Screens (large, full rewrite)
- [ ] GoalDetailsScreen (1063 lines) → ScreenShell + body split
- [ ] TripDetailScreen (2188 lines) → ScreenShell + body split
- [ ] ExpenseDetailScreen (869 lines) → ScreenShell + body split
- [ ] SplitDetailScreen (2279 lines) → ScreenShell + body split

### Wave 4 — Analytics
- [x] Statistics → Template E + ScreenShell
- [x] Monthly comparison → ScreenShell + NarrativeFact
- [ ] Export options → ScreenShell

### Wave 5 — Core User Screens (CRITICAL)
- [ ] Dashboard → Template A + DashboardState
- [ ] Home shell → gate from DashboardState

### Wave 6 — Edge + Form Screens
- [ ] SMS setup → Template C
- [ ] Onboarding → Template C
- [ ] Marketplace → ScreenShell
- [ ] Import/Export → ScreenShell
- [ ] AddEditAccountScreen → ScreenShell (needs TextButton action support)
- [ ] AddEditCategoryScreen → ScreenShell (needs TextButton action support)
- [ ] AddEditTransactionScreen → ScreenShell (needs TextButton action support)
- [ ] AddEditGoalScreen → ScreenShell (needs TextButton action support)
- [ ] ReconciliationScreen → ScreenShell (needs TextButton action support)

---

## BUGFIXES DURING MIGRATION

- [x] Account number encryption leak fixed — `accountsProvider` and `allAccountsProvider` now call `decryptFields()` after loading from Isar

---

## Runtime Dependency Graph (Target)

```
Isar watchLazy streams
       ↓
dashboardDataProvider (raw data + debounce)
       ↓
dashboardStateV2Provider (calls DashboardEngine.compute)
       ↓
UI widgets (pure rendering)
```

One path. One truth. No branches.

---

## ROADMAP PRIORITY

### Tier 1 — Product-Critical (ship first)

These directly affect whether users understand and trust the app.

| # | Work | Status |
|---|------|--------|
| 1 | Dashboard V2 engine cutover | ✅ Done |
| 2 | Goal list redesign | In progress |
| 3 | Create Goal screen | Pending |
| 4 | Edit Goal screen | Pending |
| 5 | ScreenShell migration (remaining high-traffic) | Wave 3–6 |
| 6 | Briefing system (replaces priority alerts) | Phase 6 cleanup |
| 7 | Provider graph cleanup | Phase 8 |
| 8 | Remove old dashboard engine | Phase 6 partial |

### Tier 2 — Architecture Debt (fix before it spreads)

No immediate user value, but prevents future pain.

| # | Work | Status |
|---|------|--------|
| 1 | **TonePack ↔ SkinPack split** | Not started |
| 2 | Dashboard engine isolation (Phase 8) | Not started |
| 3 | AppScreenState authority enforcement | Enforced in new screens |
| 4 | Remove duplicate state computation (old providers) | Phase 6 partial |
| 5 | Feature flag cleanup after cutover | Not started |
| 6 | Tone simplification (3 tones: Professional, Calm, Minimal) | After split |

### Tier 3 — Optimization / Polish (last)

| Work |
|------|
| New tone variants / message rewrites |
| Additional skins |
| Animation system improvements |
| Advanced customization |
| Micro-interactions |

---

## ARCHITECTURE LAYERING RULE

```
Truth Layer (DashboardEngine, GoalEngine, etc.)
    ↓ computes facts
Presentation Layer (Templates, ScreenShell)
    ↓ renders structure
Tone Layer (TonePack)
    ↓ chooses words
Skin Layer (SkinPack)
    ↓ chooses appearance
```

None of these layers should know about the others.

If a layer owns two kinds of decisions → split it.

---

## TONE/SKIN SPLIT (Tier 2 — #1)

### Problem

TonePack currently owns both wording AND visual styling:

```dart
abstract class TonePack {
  // Wording (correct)
  String get txnAdded;
  String get budgetCreated;

  // Visual styling (WRONG — belongs in SkinPack)
  double get borderRadius;
  double get cardElevation;
  double get buttonRadius;
  double get inputRadius;
  double get borderOpacity;
  double get borderWidth;
  bool get useTransparentCards;
  String get dividerStyle;
  String? get numberFont;
  String? get pdfFont;
}
```

A user cannot independently choose:
- Tone: Professional + Skin: Glass
- Tone: Minimal + Skin: Material

### Solution

**Phase 1**: Extract visual properties into `SkinPack`. Make `UserSettings` expose `tone` and `skin` independently.

**Phase 2**: Reduce to 3 tones (Professional, Calm, Minimal). Deprecate Friendly/Motivational with migration map.

**Phase 3**: Rewrite Calm to be truly neutral (no philosophy, no metaphors). Add true Minimal (information compression).

### Tone Boundary Rule

Tone applies ONLY to:
- Success messages
- Empty states
- Confirmation text
- Helper copy

Tone NEVER applies to:
- Bill due alerts
- Budget exceeded warnings
- Goal behind pace
- Payment overdue

Critical information stays identical across all tones:
```
HDFC ₹2,500 due today.
```
Same for Professional, Calm, and Minimal. No softening. No personality.
