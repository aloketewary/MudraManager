# Add/Edit Transaction

> **Purpose:** "Let me record this expense in under 5 seconds."

Speed is everything. The most common action in the app must be the fastest.

---

## Key Files

| File | Role |
|---|---|
| `add_edit_transaction_screen.dart` | Full transaction form (create/edit) |
| `quick_add_transaction_sheet.dart` | Bottom sheet for rapid entry |
| `amount_input.dart` | Currency-aware amount field |
| `description_input.dart` | Merchant/note with suggestions |
| `date_time_picker.dart` | Date + time selection |
| `add_transaction_widgets.dart` | Shared form components |
| `utility_calculator_button.dart` | In-line calculator |
| `smart_defaults_provider.dart` | Pre-fills based on patterns |

---

## Design Decisions

### 1. Smart Defaults

`smart_defaults_provider.dart` pre-fills category, account, and type based on:
- Time of day (morning = transport, evening = food)
- Last used category
- Description keywords matching `category_rule_service.dart`

### 2. Quick Add vs Full Form

- **Quick Add Sheet** — Amount + category + done. 3 taps.
- **Full Form** — All fields: amount, type, category, account, date, description, tags, recurring, attachments.

Users graduate from quick add to full form as they want more control.

### 3. Save Action in AppBar

Save/Create is a `TextButton` in the AppBar, not a bottom button. This keeps the action anchored to a predictable position and avoids keyboard conflicts.

### 4. Calculator Built In

The `utility_calculator_button.dart` opens an inline calculator for split amounts ("₹450 dinner / 3 people = ₹150").

### 5. Transfer is a Separate Screen

`transfer_screen_new.dart` handles inter-account transfers as a distinct flow because the mental model differs (from → to vs spend/earn).

---

## Interactions

- Category picker → bottom sheet with recent + all categories
- Account selector → dropdown with account balances shown
- "Make recurring" toggle → opens frequency selector
- After save → returns to transaction list with new item visible

