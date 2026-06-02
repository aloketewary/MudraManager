# Trip Details

> **Purpose:** "Everything about this trip — expenses, budget, and who owes whom."

---

## Key Files

| File | Role |
|---|---|
| `trip_detail_screen.dart` | Master view: expenses list, budget progress, participants |
| `trip_expense_item.dart` | Expense row with payer + split info |
| `trip_participant_card.dart` | Per-person balance summary |

---

## Design Decisions

### 1. Three Sections

The trip detail screen has three logical sections:
1. **Budget progress** (if set) — hero card with remaining amount
2. **Expenses** — chronological list with payer attribution
3. **Balances** — who owes whom, net settlement amounts

### 2. Payer Attribution is Prominent

Every expense shows who paid. This is critical for split calculation accuracy.

### 3. Running Balance Updates

As expenses are added, participant balances update in real-time. No need to "calculate" — it's always current.

