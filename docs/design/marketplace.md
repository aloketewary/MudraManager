# Plugin Marketplace

> **Purpose:** "Extend the app with optional features — category packs, reminders, guards."

---

## Key Files

| File | Role |
|---|---|
| `plugin_groups_screen.dart` | Browse plugins by group/category |
| `marketplace_service.dart` | Plugin install/uninstall logic |
| `offline_plugin_loader.dart` | Loads bundled plugins from assets |
| `plugin_metadata.dart` | Plugin model (name, description, type, config) |
| `plugin_service.dart` | Core plugin runtime |
| `plugin_analytics.dart` | Plugin usage tracking (internal) |
| `mudra_api_impl.dart` | API surface exposed to plugins |
| `permission_guarded_api.dart` | Sandboxed plugin permissions |

---

## Design Decisions

### 1. Offline-First Marketplace

Plugins are bundled with the app or downloaded once. No runtime network dependency. The marketplace works without internet.

### 2. Plugin Types

| Type | Example |
|---|---|
| Category Packs | "Indian Street Food" categories |
| Budget Guards | "Alert when weekend spending exceeds ₹2000" |
| Credit Card Reminders | Bill due date alerts |
| Dashboard Widgets | Custom cards on home screen |
| Tone Packs | Different personality voices |

### 3. Sandboxed API

Plugins interact through `mudra_api_impl.dart` — a restricted surface. They cannot access raw database, user profile, or other plugins' data directly.

### 4. Permission Model

Each plugin declares required permissions (read transactions, write categories, send notifications). Users approve on install.

### 5. Community Submissions

Plugin submission process documented in `docs/PLUGIN_SUBMISSION.md`. Community can build and submit plugins following the SDK spec (`mudra_plugin_sdk/`).

---

## Interactions

- Browse → tap plugin → see description + permissions → install
- Installed plugins appear in relevant contexts (dashboard, budget, etc.)
- Uninstall → removes all plugin data cleanly

