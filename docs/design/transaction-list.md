# Transaction List

> **Purpose:** "Where did my money go? Show me everything."

The financial ledger — the most-visited screen after the dashboard.

---

## Key Files

| File | Role |
|---|---|
| `transaction_list_screen.dart` | Main list with grouping, search, filters |
| `transaction_card.dart` | Individual transaction row |
| `transaction_group.dart` | Date-grouped transaction section |
| `transaction_search_bar.dart` | Fuzzy search with debounce |
| `transaction_search_bar_widget.dart` | Search bar UI component |
| `transaction_filter_chips.dart` | Filter logic (type, category, account) |
| `transaction_filter_chips_widget.dart` | Filter chip UI |
| `transaction_month_picker.dart` | Month navigation |
| `transaction_calendar_header.dart` | Calendar-style date header |
| `date_range_selector.dart` | Custom date range picker |
| `transaction_tag_chip.dart` | Tag display on transactions |

---

## Design Decisions

### 1. Grouped by Date, Not Category

Users think in time ("what did I spend yesterday?"), not taxonomies. Transactions are grouped by date with running totals per group.

### 2. Search + Filter as Complementary

Search is fuzzy text matching (description, amount, merchant). Filters are structured (category, account, type). Both can be active simultaneously.

### 3. Month Picker for Navigation

Users don't want infinite scroll. The month picker gives direct access to any month. Current month is default with easy prev/next navigation.

### 4. Swipe Actions

Swipe-to-delete and swipe-to-edit are available but not the primary interaction. Tap opens detail/edit view.

### 5. SMS-Imported Transactions are Visually Distinct

Auto-imported transactions show a subtle indicator so users know which were manual vs automatic.

---

## Interactions

- Tap transaction → `add_edit_transaction_screen.dart` (edit mode)
- FAB → `add_edit_transaction_screen.dart` (create mode)
- Filter chip "Recurring" → `bill_control_center_screen.dart`
- Long press → multi-select for bulk operations

