# Upgrade (Pro)

> **Purpose:** "Show users what Pro offers — without being annoying."

---

## Key Files

| File | Role |
|---|---|
| `upgrade_screen.dart` | Pro tier feature showcase + purchase |
| `entitlement_provider.dart` | Current entitlement state (free/trial/pro) |
| `entitlement_service.dart` | Entitlement logic |
| `entitlement_feature.dart` | Feature-level pro gating |
| `billing_provider.dart` | RevenueCat billing state |
| `billing_service.dart` | Purchase flow management |

---

## Design Decisions

### 1. Free Tier is Complete

The free app is not crippled. Core functionality (transactions, budgets, goals, SMS) works fully. Pro adds enhancements, not essentials.

### 2. Pro Features

- Unlimited budgets (free: 2)
- Custom skins + skin editor
- Advanced analytics (personality, forecast, tax)
- Priority plugin access
- Excel/PDF export
- Multi-currency with live rates

### 3. No Nag Screens

The upgrade screen is accessible from settings. It never interrupts the user's flow. When a Pro feature is tapped, a subtle inline message says "Pro feature" with a link — not a modal.

### 4. Trial Period

New users get 7 days of Pro features. No credit card required. After trial, features gracefully degrade — data is never lost.

### 5. RevenueCat Integration

Billing is managed through RevenueCat for cross-platform subscription handling. The app caches entitlement state locally so Pro features work offline.

---

## Interactions

- Settings → "Upgrade to Pro" → upgrade screen
- Tapping locked feature → inline "Pro" badge + link to upgrade
- Purchase → RevenueCat flow → entitlement updated immediately
- Restore purchases → re-activates Pro if previously purchased

