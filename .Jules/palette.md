## 2025-05-15 - [Tone System Consistency & Input Polish]
**Learning:** Shared UI components must use dynamic tokens (like spacingProvider) instead of hardcoded values to respect the app's 'Tone System' (Friendly vs Professional). Refactoring these to ConsumerStatefulWidget requires careful controller synchronization in didUpdateWidget.
**Action:** Always check for spacingProvider usage in new or modified UI components.

## 2025-05-24 - [Accessibility & Localization of Tooltips]
**Learning:** Icon-only buttons must have localized tooltips to be accessible for screen reader users across different languages. In this project, adding keys to `intl_en.arb` and updating `localization_extension.dart` is the correct way to ensure these strings are available via `AppLocalizations`.
**Action:** When adding or auditing icon buttons, ensure `tooltip` is assigned a localized string.
