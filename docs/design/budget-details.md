# Budget Details

> **Purpose:** "How is this specific budget performing, category by category?"

---

## Key Files

| File | Role |
|---|---|
| `budget_details_screen.dart` | Detailed view of a single budget |
| `budget_category_allocation.dart` | Category progress breakdown |
| `budget_overview_card.dart` | Hero summary (total spent/remaining) |

---

## Design Decisions

### 1. Hero Card at Top

A `primaryContainer` hero card shows the headline numbers: total budget, spent, remaining, days left. This is the only card that uses `primaryContainer` — it earns the visual weight.

### 2. Per-Category Breakdown

Below the hero, each allocated category shows:
- Category name + icon
- Progress bar (spent / allocated)
- Amount spent + amount remaining
- Pace indicator if overspending

### 3. Transaction List per Category

Tapping a category reveals the actual transactions contributing to that category's spending. No navigation away — inline expansion.

### 4. Edit Accessible from AppBar

Budget modification (rename, adjust amounts) is an AppBar action, not buried in a menu.

