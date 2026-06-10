# Dashboard Migration Inventory

## Query State (Screen Local)
- `_hasAnimatedOnce` (static): Track if animation has run across rebuilds.
- `_revealedCount`: Number of widgets revealed in stagger.
- `_allRevealed`: Flag if all widgets are revealed.

## Domain Logic (To be migrated/extracted)
- **Banner Prioritization**: `_PrioritizedBanner` class handles:
  - Background health (`backgroundTaskUnhealthyProvider`)
  - Budget alerts (`budgetAlertsProvider`)
  - SMS Auto-import status (`smsPermissionGrantedProvider`, `pendingCountProvider`, `SharedPrefsUtil`)
  - Help guide status (`hasSeenHelpGuideProvider`)
- **Metric Calculations**: Mostly handled by `dashboardDataProvider` currently, but `DashboardHome` checks for `hasTransactions`.
- **Zero-state detection**: `!hasTransactions && !nudgeDismissed` logic in `build`.
- **New user detection**: `onboardedAt < 24h` logic in `build`.

## Side-Effects (milestone workflows)
- **Daily Check-In**: `_performDailyCheckIn()`
  - Cancels streak reminder.
  - Updates daily check-in via `gamificationServiceInitProvider`.
  - Shows `StreakSavedCelebrationSheet` or success snackbar.
- **Uncategorized Transaction Patching**: `reconciliationServiceProvider.patchUncategorizedTransactions()` in `initState`.
- **SMS First Import Celebration**: `_checkSmsFirstImportCelebration()`
  - Checks `SharedPrefsUtil` and shows `SmsSuccessCelebrationSheet`.

## Interaction State
- **Staggered Animation**: Managed via `_revealNext`, `_revealedCount`, `_allRevealed` and `flutter_animate`.
- **Scroll Position**: `PageStorageKey('dashboard_scroll')`.
- **Refresh Logic**: `RefreshIndicator` with `RefreshHelper.withMinDuration`.
- **Widget Analytics**: `widgetAnalyticsServiceProvider` records impressions and clicks.
- **Error Handling**: `_WidgetErrorBoundary` and `try-catch` in `_buildTrackedWidget`.

## Provider Usage (Current)
- `toneProvider` (via `Tone.current`)
- `spacingProvider`
- `dashboardDataProvider`
- `orderedDashboardWidgetsProvider`
- `budgetAlertsProvider`
- `hasSeenHelpGuideProvider`
- `isarServiceProvider`
- `sharedPreferenceProvider`
- `gamificationServiceInitProvider`
- `reconciliationServiceProvider`
- `widgetAnalyticsServiceProvider`
- `backgroundTaskUnhealthyProvider`
- `smsPermissionGrantedProvider`
- `pendingCountProvider`

## UI Elements
- FAB: Quick Add Transaction.
- "Customize Dashboard" button (at the bottom).
- Ambient Brand Section (at the bottom).
- SliverList for widgets.
- Loading skeletons.
