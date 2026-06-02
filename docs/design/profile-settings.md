# Profile & Settings

> **Purpose:** "Configure the app to work exactly how I want."

---

## Key Files

| File | Role |
|---|---|
| `profile_screen.dart` | Profile overview (name, avatar, stats) |
| `setting_screen.dart` | Settings hub (all configuration) |
| `app_settings_page.dart` | App behavior settings |
| `edit_user_profile_screen.dart` | Edit name, avatar |
| `manage_account_screen.dart` | Bank accounts CRUD |
| `manage_categories_screen.dart` | Category management |
| `add_edit_category_screen.dart` | Create/edit category |
| `currency_settings_screen.dart` | Default currency + multi-currency toggle |
| `exchange_rate_screen.dart` | Exchange rate viewer |
| `notification_settings_screen.dart` | Notification preferences |
| `backup_restore_screen.dart` | Full app backup/restore |
| `archived_transactions_screen.dart` | Soft-deleted transactions |
| `about_app.dart` | App info, version, credits |
| `help_screen.dart` | Help content + FAQ |
| `account_form.dart` | Account creation form widget |
| `profile_menu_item.dart` | Settings row item widget |
| `app_info_card.dart` | Version info card |
| `guest_mode_toggle.dart` | Hide amounts toggle |
| `pin_entry_dialog.dart` | PIN input dialog |
| `icon_picker_bottom_sheet.dart` | Icon selection for categories |

---

## Design Decisions

### 1. Profile is Minimal

User profile is just name + avatar. No email, no login, no cloud identity. This reinforces the offline-first philosophy.

### 2. Settings is a Flat List

No nested menus. All settings are visible in a scrollable list grouped by concern: General, Accounts, Categories, Security, Backup, About.

### 3. Account Management

Users manage bank/wallet/cash accounts here. Each account has: name, type, balance, currency, icon, color.

### 4. Category Management

System categories are non-deletable. User categories can be created, edited, archived. Categories have: name, icon, color, parent category (for hierarchy).

### 5. Backup is Prominent

Backup/restore is high in the settings list because data loss anxiety is real for offline-first apps. Auto-backup reminders are configurable.

---

## Interactions

- Tap any setting → navigates to detail screen
- "Create Account" → `account_form.dart` bottom sheet
- "Create Category" → `add_edit_category_screen.dart`
- "Backup Now" → generates Isar snapshot

