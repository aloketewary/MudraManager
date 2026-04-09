# Changelog

All notable changes to Mudra Manager will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [3.5.1] - 2025-04-09

### Added
- **Stepper-based budget creation** — 4-step guided flow (Name → Period → Categories → Review)
- **Budget dashboard UX overhaul** — highlight card for most critical budget, grouped sections (over-budget / on-track), emotional headlines
- **Budget details redesign** — gradient hero, budget period display, spending pace comparison card
- **Category search** in budget creation with parent-child exclusion logic
- **Budget type localization** — all 5 types (Category-wise, Tag-wise, Daily, Festival, Travel) fully localized in EN/HI/BN
- **Travel budget validation** — disabled when no active trip, shows lock icon with explanation
- **Category deletion protection** — warns if category is used in budgets, cleans up allocations on delete
- **Invalid budget detection** — `hasInvalidCategories` flag on `BudgetWithProgress`, warning banner in details screen
- **Step notes** with lightbulb info cards on each budget creation step
- **Interactive review screen** — tappable cards to jump back to any step, per-category allocation breakdown with auto-distribution indicator
- **System category filtering** — `isSystemEqualTo(false)` on all user-facing category providers
- **System category migration** — seeder now fixes old categories missing `isSystem` flag
- **`common_next`**, **`common_back`** localization keys (EN/HI/BN)
- **20+ new budget ARB keys** — step notes, emotion lines, type names/descriptions, pluralized counts, pace strings
- **15+ new goal ARB keys** — emotion lines, pace daily, days remaining, start saving, exceeded target
- **`circle` icon** added to IconHelper for fallback category icons

### Fixed
- **Budget allocation save bug** — `IsarLinks.toList()` returned empty after `.clear()` + `.add()`. Allocations now passed as explicit list to `service.save()`
- **Edit budget categories not loading** — `budget.allocations.load()` returned empty for old budgets. Replaced with direct backlink query
- **Category deselection on edit** — `List.remove()` used object identity instead of ID comparison. Fixed with `removeWhere`
- **Duplicate category selection** — guard against double-add when category already in selection
- **Parent auto-expand on edit** — subcategory parents now auto-expanded when loading existing allocations
- **`alloc.category.value!` null crash** — budget service now safely skips deleted categories
- **Import preview unmounted context crash** — added `mounted` check before `context.pop()` in result dialog
- **`DropdownButtonFormField.initialValue`** — invalid parameter in bills screen (file since removed)
- **`IconHelper: missing icon "circle"`** — fallback icon from category resolver now mapped

### Changed
- **Budget dashboard** — `ListView` → `CustomScrollView` with slivers, `primaryContainer` hero matching goal screen pattern
- **Budget add/edit** — single long form → 4-step stepper with animated pill indicators, fade+slide transitions
- **Category selector** — heavy card-based → compact colored chips with actual category icons and colors
- **Budget type selector** — dropdown → visual cards with name + description
- **Goal add/edit** — save action moved from sticky bottom button to AppBar `TextButton` (coding rules)
- **Category providers** — `expenseCategoriesProvider`, `incomeCategoriesProvider`, `frequencySortedCategoriesProvider` now filter `isSystem` categories
- **Budget category picker** — uses `expenseCategoriesProvider` instead of `categoryListProvider` (no income categories in budgets)

### Performance
- **3-tier startup** — critical (Isar + seeds + entitlement) → deferred 3s (billing, gamification, icons, migrations) → background only (workmanager 6h)
- **Recurring processing removed from startup** — only runs via workmanager or on-demand when user opens bill screen
- **`BackgroundTaskManager.initialize()`** no longer calls `_runAllTasks()` — just schedules workmanager
- **Entitlement init consolidated** — was 3 separate `safeExecute` blocks creating 3 `EntitlementService` instances, now 1

### Removed
- 17 dead files cleaned up:
  - `budget_dashboard.dart`, `budget_chart_screen.dart`, `budget_summary_card.dart`
  - `budget_category_mini_card.dart`, `budget_form_provider.dart`, `budget_mini_card.dart`, `chart_legend.dart`
  - `bills_screen.dart`, `cash_flow_screen.dart`, `debug_cleanup_screen.dart`, `marketplace_screen.dart`
  - `missing_transaction_screen.dart`, `recurring_transactions_screen.dart`
  - `goal_card.dart`, `goal_circular_card.dart`, `goal_mini_card.dart`
  - `recurring_transaction_scheduler.dart`
- Old `_buildCategoryCard` method (~135 lines) replaced by chip-based selector
- `_buildStickyButton` from goal add/edit screen

---

## [3.5.0] - 2025-03-15

### Added
- Monthly recap stories with spending personality
- Financial health score with detailed breakdown
- Net worth tracking across accounts
- Spending personality analysis (5 personality types)
- Advanced analytics with FL Chart visualizations

### Changed
- Dashboard widget system with customizable layout
- Improved transaction list with swipe actions
- Enhanced SMS parser with 50+ bank support

---

## [3.2.0] - 2024-12-19

### Added
- Enhanced Credit Card Reminder Plugin with account selection UI
- Comprehensive backup and sync system with offline-first approach
- Business and regional category plugins with subcategory support
- SMS parser optimization for IndusInd Bank
- Category keywords enhancement with Indian brands and services
- Plugin system optimization with caching and autoDispose

### Fixed
- Fixed slow list animations in profile screen
- Resolved Flutter deprecation warnings for RadioListTile and Radio widgets
- Fixed IndusInd Bank SMS parsing with "A/C *XX6988" format
- Fixed LowBalancePlugin constructor error
- Fixed incomplete contentPadding in credit card configuration dialog

### Changed
- Migrated from Material Icons to Lucide icons for consistent design
- Simplified backup system from complex cloud sync to offline-first approach
- Disabled automatic keyword learning from SMS to prevent unwanted keywords
- Applied autoDispose to providers for better memory management

### Performance
- Optimized plugin loading with caching and early exits
- Reduced animation duration to 300ms for better performance
- Improved list rendering with addPostFrameCallback

---

## [3.1.0] - 2024-11-01

### Added
- Plugin marketplace system
- Gamification with achievements and streaks
- Trip expense tracking with group splits
- Recurring transaction management
- Multi-currency support with live exchange rates

---

## [3.0.0] - 2024-09-15

### Added
- Complete app rewrite with clean architecture
- Riverpod state management (replacing Provider)
- Isar database (replacing SQLite)
- GoRouter navigation with auth gate
- Material You dynamic theming
- Hindi and Bengali localization
- Tone system (Friendly / Professional)
- SMS auto-import engine
- Budget and goal tracking

---

<div align="center">

*For detailed commit history, see the git log.*

</div>
