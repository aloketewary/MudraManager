# Mudra Manager — Design Philosophy & System Design

> This directory documents the design philosophy, product decisions, and screen-level architecture of Mudra Manager. It is both a reference for contributors and a record of what was built, why, and how.

---

## Core Design Philosophy

### The Product Belief

> Personal finance software should be **invisible infrastructure** — not a daily chore.

Mudra Manager exists to make money management feel like a natural extension of life, not a burden. Every design decision flows from one question:

**"Does this reduce the user's cognitive load, or add to it?"**

### Design Pillars

| Pillar | Meaning |
|---|---|
| **Local-first** | Data never leaves the device. No accounts. No sync anxiety. |
| **India-native** | SMS parsing, UPI, ₹ formatting, Hindi/Bengali — not bolted on, built in. |
| **Decision-first** | Every screen answers a question the user is asking right now. |
| **Quiet authority** | The app speaks rarely but with full confidence. Silence = stability. |
| **Emotional resonance** | Money is emotional. The app acknowledges that through celebrations, tone, and personality. |

### What We Refuse

- **Engagement optimization** — We don't want users spending more time in the app.
- **Data extraction** — No telemetry, no cloud, no "anonymous analytics."
- **Feature bloat** — Every feature earns its place by solving a real user need.
- **English-first localization** — Translations are written by humans who think in that language.

---

## Architecture Philosophy

### Feature-First, Not Layer-First

```
features/
└── budget/
    ├── data/           # Providers, services, repositories
    ├── domain/         # Models, business logic
    └── presentation/   # Screens, widgets, UI providers
```

Each feature is a self-contained module. Cross-feature communication happens through shared providers in `core/`, never through direct imports between features.

### State Management Doctrine

- **Riverpod everywhere** — No BLoC, no setState for anything beyond animation.
- **autoDispose by default** — Memory is precious on Indian budget phones.
- **family for parameterization** — Never pass IDs through widget trees.
- **Invalidate after mutation** — Explicit cache busting, not magic reactivity.

### Database Doctrine

- **Isar for everything** — Zero-copy reads, millisecond queries.
- **Direct queries over links** — `IsarLinks.load()` is unreliable; explicit queries always.
- **No network dependency** — The app works on an airplane, in a village, forever.

### UI Doctrine

- **spacingProvider** for all spacing — Consistency without magic numbers.
- **CurrencyText** for all money — Locale-aware, compact, accessible.
- **LucideIcons** exclusively — One icon language across the entire app.
- **surfaceContainerLow + outlineVariant** for cards — Visual hierarchy without noise.

---

## Screen Index

Each screen has its own design document explaining purpose, decisions, and file mapping.

### 🏠 Dashboard & Briefing
- [Dashboard Home](./dashboard.md) — The command center
- [Daily Briefing System](./daily-briefing.md) — Precision alerting philosophy

### 💳 Transactions
- [Transaction List](./transaction-list.md) — The financial ledger
- [Add/Edit Transaction](./add-edit-transaction.md) — Smart data entry
- [Bill Control Center](./bill-control-center.md) — Recurring bills management
- [Transfer](./transfer.md) — Inter-account transfers

### 📊 Budget
- [Budget Dashboard](./budget-dashboard.md) — Adaptive budget overview
- [Add Budget (Stepper)](./add-budget.md) — Guided budget creation
- [Budget Details](./budget-details.md) — Category-level tracking

### 🎯 Goals
- [Goals List](./goals.md) — Savings goals overview
- [Add/Edit Goal](./add-edit-goal.md) — Goal creation with emotional milestones
- [Goal Details](./goal-details.md) — Progress tracking & celebrations

### ✈️ Trips
- [Trips List](./trips.md) — Trip expense management
- [Trip Details](./trip-details.md) — Per-trip budget & splits
- [Split & Settlement](./split-settlement.md) — Group expense resolution

### 📈 Analytics & Statistics
- [Analytics Hub](./analytics.md) — Financial health & personality
- [Statistics](./statistics.md) — Charts, trends, comparisons
- [Monthly Recap](./monthly-recap.md) — Story-driven monthly review
- [Net Worth](./net-worth.md) — Asset tracking

### 📩 SMS & Import
- [SMS Activity](./sms-activity.md) — Auto-import management
- [Import/Export](./import-export.md) — Excel/PDF data flow

### 👤 Profile & Settings
- [Profile & Settings](./profile-settings.md) — App configuration hub
- [Appearance & Themes](./appearance.md) — Visual customization
- [Security](./security.md) — Biometric, PIN, guest mode

### 🏪 Marketplace & Plugins
- [Plugin Marketplace](./marketplace.md) — Extension ecosystem

### 🏆 Gamification
- [Achievements](./achievements.md) — Habit-building rewards

### 🎨 Skins
- [Skin System](./skins.md) — Visual personality packs

### 🚀 Onboarding & Upgrade
- [Onboarding](./onboarding.md) — First-run experience
- [Upgrade](./upgrade.md) — Pro tier conversion

---

## File Naming Convention

All design docs follow this pattern:
```
docs/design/{feature-name}.md
```

Each doc contains:
1. **Purpose** — What question does this screen answer?
2. **Key Files** — Dart files that implement it
3. **Design Decisions** — Why it works this way
4. **Interactions** — How it connects to other features

---

## Living Document

This documentation evolves with the product. When a major design decision is made, it gets recorded here — not in code comments, not in Slack, not in someone's memory.

---

<div align="center">

**Built with ❤️ for India**

</div>
