# Budget Dashboard

> **Purpose:** "Am I on track with my spending limits this month?"

---

## Key Files

| File | Role |
|---|---|
| `adaptive_budget_dashboard.dart` | Main budget overview (adapts to data density) |
| `budget_overview_card.dart` | Summary card with total spent/remaining |
| `budget_category_allocation.dart` | Per-category progress bars |

---

## Design Decisions

### 1. Adaptive Layout

The dashboard adapts based on how many budgets exist:
- **0 budgets** → CTA to create first budget
- **1 budget** → Full detail view with category breakdown
- **Multiple budgets** → Card list with summary per budget

### 2. Spending Pace Indicator

Instead of just "₹8,000 of ₹20,000 spent," the system shows **pace**: "You're spending faster than usual. At this rate, you'll exceed by the 22nd." This answers "can I sustain this?" not just "where am I?"

### 3. Category-Level Granularity

Each category allocation shows its own progress bar with color coding:
- Green → on track
- Yellow → approaching limit (>75%)
- Red → exceeded

---

## Interactions

- Tap budget card → `budget_details_screen.dart`
- FAB → `add_budget_screen.dart`
- Tap category → filtered transaction list for that category

