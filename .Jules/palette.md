## 2025-05-15 - [Tone System Consistency & Input Polish]
**Learning:** Shared UI components must use dynamic tokens (like spacingProvider) instead of hardcoded values to respect the app's 'Tone System' (Friendly vs Professional). Refactoring these to ConsumerStatefulWidget requires careful controller synchronization in didUpdateWidget.
**Action:** Always check for spacingProvider usage in new or modified UI components.

## 2025-05-24 - [Accessibility & Localization of Tooltips]
**Learning:** Icon-only buttons must have localized tooltips to be accessible for screen reader users across different languages. In this project, adding keys to `intl_en.arb` and updating `localization_extension.dart` is the correct way to ensure these strings are available via `AppLocalizations`.
**Action:** When adding or auditing icon buttons, ensure `tooltip` is assigned a localized string.

## 2025-05-25 - [Tactile Feedback & PR Hygiene]
**Learning:** Adding `HapticFeedback.mediumImpact()` to primary interactive elements (banners, dismiss buttons) significantly enhances the "feel" of the app. To maintain maintainable PRs under 50 lines, only the source `.arb` file should be committed; generated `.dart` localization files should be excluded to avoid cluttering the review with auto-generated code.
**Action:** Include haptics in new UI components and strictly exclude generated l10n/Isar files from commits.

## 2025-05-26 - [Material Ripple on Decorated Containers]
**Learning:** To correctly display Material ripple effects over components with custom decorations (gradients, borders), the `InkWell` must be a child of an `Ink` widget (which holds the decoration), all under a transparent `Material` widget. Otherwise, the decoration will obscure the ripple.
**Action:** Use the `Material -> Ink -> InkWell` hierarchy for all interactive cards with custom backgrounds.
