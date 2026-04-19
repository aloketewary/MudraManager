<div align="center">

<img src="assets/logo/logo.png" alt="Mudra Manager" width="120" />

# Mudra Manager

**Your money, your language, your rules.**

A powerful, local-first personal finance app built with Flutter — designed for India.

[![Flutter](https://img.shields.io/badge/Flutter-3.7+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Riverpod](https://img.shields.io/badge/Riverpod-State_Mgmt-00B4D8)](https://riverpod.dev)
[![Isar](https://img.shields.io/badge/Isar-Local_DB-8B5CF6)](https://isar.dev)
[![Version](https://img.shields.io/badge/v3.5.1-stable-green)]()
[![License](https://img.shields.io/badge/License-Private-red)]()

---

</div>

## Why Mudra Manager?

Most finance apps are cloud-dependent, English-only, and built for Western banking. **Mudra Manager** is different:

- 🇮🇳 **Built for India** — SMS parsing for 50+ Indian banks, UPI, wallets
- 🔒 **100% offline** — Your data never leaves your device. No accounts, no servers
- 🗣️ **Hindi, Bengali, English** — Real translations, not Google Translate
- ⚡ **Instant** — Isar DB loads in milliseconds, not seconds

---

## Features

<table>
<tr>
<td width="50%">

### 📊 Smart Dashboard
Personalized widgets, priority alerts, and AI-powered spending insights — all customizable.

### 📩 Auto SMS Import
Reads bank/wallet SMS and creates transactions automatically. Supports 50+ Indian banks.

### 💰 Step-by-Step Budgets
Guided 4-step budget creation with category allocation, smart feedback, and spending pace tracking.

### 🎯 Goal Tracking
Set savings goals with emotional milestones, progress rings, confetti celebrations, and smart deposits.

</td>
<td width="50%">

### ✈️ Trip & Split Expenses
Dedicated trip budgets, group expense splitting, settlement tracking with per-person balances.

### 🔄 Recurring Bills
Auto-creates transactions for recurring bills. SMS-matches payments to avoid duplicates.

### 📈 Analytics & Recap
Monthly comparisons, spending personality, financial health score, and beautiful FL Chart visualizations.

### 🏪 Plugin Marketplace
Extend with category packs, credit card reminders, budget guards, and community plugins.

</td>
</tr>
</table>

### And more...

| Feature | Details |
|---|---|
| 🎨 **Themes** | Dynamic Material You, 10+ color themes, AMOLED dark mode |
| 🔐 **Security** | Biometric lock, guest mode (hides amounts), PIN protection |
| 💱 **Multi-Currency** | 150+ currencies with live exchange rates |
| 📤 **Export** | Excel & PDF reports with full transaction history |
| 🏆 **Gamification** | Achievements, streaks, and milestones to build habits |
| 🔔 **Smart Alerts** | Budget warnings, unusual spending, savings opportunities |
| 🗣️ **Tone System** | Friendly or Professional — the app talks your way |

---

## Architecture

```
lib/
├── core/                    # Shared foundation
│   ├── db/                  # Isar models, seeders, migrations
│   ├── currency/            # Multi-currency engine + exchange rates
│   ├── entitlement/         # Pro/trial/billing system
│   ├── l10n/                # ARB localizations (EN, HI, BN)
│   ├── providers/           # Global Riverpod providers
│   ├── router/              # GoRouter with auth gate
│   ├── services/            # Background tasks, notifications
│   ├── theme/               # Material You + custom themes
│   └── tone/                # Tone packs (friendly/professional)
│
├── features/                # Feature modules (clean architecture)
│   ├── dashboard/           # Home screen + customizable widgets
│   ├── transactions/        # Add/edit/list + recurring bills
│   ├── budget/              # Stepper-based budget creation
│   ├── goal/                # Savings goals with milestones
│   ├── trip/                # Trip expenses + group splits
│   ├── analytics/           # Financial health + personality
│   ├── sms/                 # SMS parsing + auto-import
│   ├── marketplace/         # Plugin system
│   ├── recap/               # Monthly recap stories
│   └── ...                  # 19 feature modules total
│
└── shared/                  # Reusable widgets & utilities
    └── widgets/             # CurrencyText, cards, sheets
```

**Key patterns:**
- Feature-first folder structure with `data/`, `domain/`, `presentation/` layers
- Riverpod for all state management — `FutureProvider`, `StreamProvider`, `StateNotifier`
- Isar for local persistence — zero network dependency
- GoRouter with `ShellRoute` for tab navigation + auth gate
- ARB-based localization with ICU plural syntax
- Tone system for personality-aware copy

---

## Tech Stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter 3.7+ / Dart 3.0+ |
| **State** | Riverpod (autoDispose, family, future/stream) |
| **Database** | Isar Community (local NoSQL, zero-copy) |
| **Routing** | GoRouter with deep linking |
| **Charts** | FL Chart (pie, line, bar) |
| **Icons** | Lucide Icons |
| **Fonts** | Google Fonts |
| **Background** | Workmanager (periodic tasks every 6h) |
| **Notifications** | Flutter Local Notifications |
| **Auth** | Local Auth (biometrics) |
| **Billing** | In-App Purchase (RevenueCat) |
| **SMS** | Telephony + custom parser engine |

---

## Getting Started

### Prerequisites

- Flutter SDK 3.7+
- Android Studio / Xcode
- A connected device or emulator

### Setup

```bash
# Clone
git clone <repository_url>
cd mudra_manager

# Install dependencies
flutter pub get

# Generate Isar schemas
dart run build_runner build --delete-conflicting-outputs

# Run (dev flavor)
flutter run --flavor dev
```

### Build Flavors

| Flavor | Usage |
|---|---|
| `dev` | Development with debug tools |
| `prod` | Production release |

---

## Coding Rules

This project follows strict coding conventions enforced via `.amazonq/rules/`:

| Rule | Enforcement |
|---|---|
| **Spacing** | `ref.watch(spacingProvider)` — never hardcode `16.0` |
| **Localization** | `AppLocalizations.of(context)!` — never hardcode English |
| **Currency** | `CurrencyText` widget — never `Text(formatCurrency(...))` |
| **Icons** | `LucideIcons` only — never `Icons.xxx` |
| **Forms** | AppBar `TextButton` for save — not sticky bottom buttons |
| **Cards** | `surfaceContainerLow` + `outlineVariant` border for standard cards |
| **Dates** | Always pass locale to `DateFormat` |
| **Translations** | Mixed language (Hindi + English naturally), short, emotional |

---

## Localization

Three languages with real, human translations:

| Language | Status | Style |
|---|---|---|
| 🇬🇧 English | ✅ Complete | Clean, concise |
| 🇮🇳 Hindi | ✅ Complete | Semi-casual, mixed English ("Budget बनाएं") |
| 🇧🇩 Bengali | ✅ Complete | Conversational, mixed English |

All strings use ARB files with ICU plural syntax and `{placeholder}` patterns.

---

## Performance

Startup is optimized into 3 tiers:

| Tier | When | What |
|---|---|---|
| **Critical** | Immediately | Isar + category seeds + entitlement |
| **Deferred** | 3s after UI | Billing, gamification, icons, migrations |
| **Background** | Workmanager 6h | Recurring txns, bills, notifications, cleanup |

Recurring transaction processing is **lazy** — only runs when the user opens the bill screen or via background workmanager. Never blocks app startup.

**Background isolate note**: Workmanager's `callbackDispatcher` runs in a separate Dart isolate. Isar `watchLazy` streams only fire for writes in the same isolate. Background writes are picked up when the user opens the app (`autoDispose` providers restart with `fireImmediately: true`).

---

## License

This project is **private and proprietary**. All rights reserved.

---

<div align="center">

**Built with ❤️ for India**

*Because managing money shouldn't require an internet connection.*

</div>
