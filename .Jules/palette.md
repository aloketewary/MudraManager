## 2025-05-15 - [Tone System Consistency & Input Polish]
**Learning:** Shared UI components must use dynamic tokens (like spacingProvider) instead of hardcoded values to respect the app's 'Tone System' (Friendly vs Professional). Refactoring these to ConsumerStatefulWidget requires careful controller synchronization in didUpdateWidget.
**Action:** Always check for spacingProvider usage in new or modified UI components.
