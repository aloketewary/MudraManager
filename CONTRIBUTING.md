# Contributing to Mudra Manager

Thank you for your interest in contributing! This guide will help you get started.

---

## Getting Started

### Prerequisites

- Flutter SDK 3.7+
- Dart 3.0+
- Android Studio or VS Code with Flutter extension
- A connected Android device or emulator

### Setup

```bash
git clone <repository_url>
cd mudra_manager
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run --flavor dev
```

---

## Project Structure

```
lib/
├── core/          # Shared foundation (DB, theme, l10n, providers, router)
├── features/      # Feature modules (19 total, clean architecture)
│   └── feature/
│       ├── data/           # Services, providers, repositories
│       ├── domain/         # Models, entities, business logic
│       └── presentation/
│           ├── screens/    # Full-page screens
│           ├── widgets/    # Feature-specific widgets
│           └── providers/  # UI state providers
├── plugins/       # Plugin system extensions
└── shared/        # Reusable widgets & utilities
```

---

## Coding Rules

These are **strictly enforced**. PRs that violate these will be rejected.

### Spacing

```dart
// ✅ Always use spacingProvider
final spacing = ref.watch(spacingProvider);
SizedBox(height: spacing.elementGap);
EdgeInsets.all(spacing.cardInner);
BorderRadius.circular(spacing.radiusMedium);

// ❌ Never hardcode
SizedBox(height: 16);
EdgeInsets.all(12.0);
BorderRadius.circular(8);
```

### Localization

```dart
// ✅ Always use AppLocalizations
final ctxt = AppLocalizations.of(context)!;
Text(ctxt.budget_totalBudget);

// ❌ Never hardcode English
Text('Total Budget');
```

### Currency Display

```dart
// ✅ Use CurrencyText widget
CurrencyText(amount: 1500, fixedLength: 0, compact: true);

// ❌ Never use Text with formatCurrency
Text(formatCurrency(1500));

// ✅ Exception: tooltips, snackbars, string interpolation
SnackbarService.success('Added ${formatCurrency(amount)}');
```

### Icons

```dart
// ✅ LucideIcons only
Icon(LucideIcons.chartPie);

// ❌ Never Material Icons
Icon(Icons.pie_chart);
```

### Form Actions

```dart
// ✅ AppBar TextButton for save/create
AppBar(
  actions: [
    TextButton(onPressed: _save, child: Text('Create')),
  ],
);

// ❌ No sticky bottom buttons (exception: emotional CTA flows)
```

### Card Styling

```dart
// ✅ Standard cards
Container(
  color: color.surfaceContainerLow,
  border: Border.all(color: color.outlineVariant.withValues(alpha: 0.5)),
);

// ✅ Hero/summary cards only
Container(color: color.primaryContainer);

// ❌ Never primaryContainer for list items
```

### Dates

```dart
// ✅ Always pass locale
DateFormat('dd MMM yyyy', ctxt.localeName).format(date);

// ✅ Bengali safe pattern
safeDateFormat('dd MMM', ctxt.localeName).format(date);

// ❌ Never without locale
DateFormat('dd MMM').format(date);
```

---

## Translation Rules

### Core Principle

Translate **meaning**, not words. Ask: *"How would a real user say this?"*

### Mixed Language (Critical for India)

```
// ✅ Natural mixed language
"Budget बनाएं और खर्च control करें"

// ❌ Pure Hindi feels robotic
"बजट बनाएं और व्यय नियंत्रित करें"
```

### Keep It Short

```
// ❌ Too long
"आपको इस लक्ष्य को प्राप्त करने के लिए ₹500 बचाने की आवश्यकता है"

// ✅ Scannable
"₹500 रोज़ बचाना होगा"
```

### Placeholders

```json
// ✅ Use placeholders
"remaining": "{amount} बाकी है"

// ❌ Never inline amounts
"remaining": "₹500 बाकी है"
```

### Pluralization

```json
// ✅ ICU plural syntax
"budget_categoriesCount": "{count, plural, =1{1 category} other{{count} categories}}"
```

### ARB Key Naming

```
// ✅ Scoped, meaningful
goal_saved, budget_stepNote0, security_pinLock

// ❌ Generic
text1, label2, message
```

---

## Adding a New Feature

1. Create the feature folder under `lib/features/your_feature/`
2. Follow the `data/` → `domain/` → `presentation/` structure
3. Add Riverpod providers in `data/` (use `autoDispose`)
4. Add localization keys to all 3 ARB files (`intl_en.arb`, `intl_hi.arb`, `intl_bn.arb`)
5. Run `flutter gen-l10n` after adding ARB keys
6. Use `spacingProvider` for all spacing values
7. Use `CurrencyText` for all monetary amounts
8. Use `LucideIcons` for all icons
9. Test on small screens for text overflow (Hindi/Bengali text is longer)

---

## Adding Localization Keys

1. Add the key to `lib/core/l10n/intl_en.arb`
2. Add Hindi translation to `lib/core/l10n/intl_hi.arb`
3. Add Bengali translation to `lib/core/l10n/intl_bn.arb`
4. Run `flutter gen-l10n`
5. Use `AppLocalizations.of(context)!.your_key` in code

**Hindi style:** Semi-casual, mixed English naturally. "Budget बनाएं" not "बजट बनाएं"

**Bengali style:** Conversational, mixed English. "Budget-এর নাম দিন" not "বাজেটের নাম দিন"

---

## Performance Guidelines

### Startup

The app uses 3-tier initialization:

| Tier | When | Add here if... |
|---|---|---|
| **Critical** | Immediately | UI can't render without it (DB, seeds, entitlement) |
| **Deferred** | 3s after UI | Needed eventually but not for first screen (billing, gamification) |
| **Background** | Workmanager 6h | Periodic tasks (recurring txns, notifications, cleanup) |

**Never** add heavy operations to the critical tier.

### Providers

- Use `autoDispose` on all `FutureProvider` and `StreamProvider`
- Use `.family` for parameterized providers
- Invalidate providers explicitly after mutations

### Database

- Use direct Isar queries over `IsarLinks.load()` for reliability
- Always load `parentCategory` after fetching categories
- Filter `isSystemEqualTo(false)` on user-facing category queries

---

## Pull Request Checklist

- [ ] No hardcoded English strings in UI
- [ ] No hardcoded spacing values
- [ ] No Material Icons (`Icons.xxx`)
- [ ] All monetary amounts use `CurrencyText` widget
- [ ] All dates use locale-aware `DateFormat`
- [ ] ARB keys added in all 3 languages (EN, HI, BN)
- [ ] `flutter gen-l10n` runs without errors
- [ ] `flutter analyze` shows no errors
- [ ] Tested on small screen for text overflow
- [ ] No `print()` statements (use `AppLog` or `debugPrint`)
- [ ] Save/create actions in AppBar, not bottom buttons

---

## Questions?

Open an issue or reach out to the maintainer.

---

<div align="center">

**Built with ❤️ for India**

</div>
