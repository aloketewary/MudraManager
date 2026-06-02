# Add Budget (Stepper)

> **Purpose:** "Guide me through creating a realistic budget — don't make me guess."

---

## Key Files

| File | Role |
|---|---|
| `add_budget_screen.dart` | 4-step guided budget creation |
| `budget_amount_input.dart` | Total budget amount input with context |
| `budget_category_allocation.dart` | Category-wise allocation step |

---

## Design Decisions

### 1. Four-Step Stepper

Budget creation is a guided 4-step process:
1. **Name & Period** — Monthly/weekly/custom, date range
2. **Total Amount** — How much can you spend?
3. **Category Allocation** — Distribute across categories
4. **Review & Create** — Smart feedback before confirming

This prevents the overwhelm of a single form with 15 fields.

### 2. Smart Feedback at Review

Before creation, the system provides contextual feedback:
- "Your food budget is 40% lower than last month's actual spending"
- "Transport allocation seems high based on your history"

This isn't prescriptive — it's informational. The user always decides.

### 3. Past Spending as Reference

During category allocation, the system shows "last month you spent ₹X on this category" as a reference anchor. Users can match, exceed, or reduce.

### 4. Save in AppBar

The final "Create" action is in the AppBar as a `TextButton`, consistent with all other creation flows.

---

## Interactions

- Back button on step 1 → exits flow
- Back button on steps 2-4 → previous step
- "Create" → saves budget, navigates to budget details

