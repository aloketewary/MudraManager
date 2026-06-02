# Trips

> **Purpose:** "Track trip expenses separately and split costs with friends."

---

## Key Files

| File | Role |
|---|---|
| `trips_screen.dart` | List of all trips (active + past) |
| `trip_detail_screen.dart` | Single trip: expenses, budget, splits |
| `edit_trip_screen.dart` | Create/edit trip details |
| `add_trip_transaction_screen.dart` | Add expense to a trip |
| `expense_detail_screen.dart` | Individual trip expense view |
| `split_detail_screen.dart` | Split breakdown per person |
| `group_detail_dispatcher.dart` | Group-level expense routing |
| `active_trip_mini_card.dart` | Dashboard card for active trip |
| `trip_expense_item.dart` | Expense row in trip list |
| `trip_participant_card.dart` | Participant balance card |
| `split_amount_calculator.dart` | Split math logic |

---

## Design Decisions

### 1. Trip as a Separate Ledger

Trip expenses live in a separate context from daily transactions. Users don't want vacation spending to distort their monthly budget analytics.

### 2. Group Expense Splitting

Each trip expense can be split among participants:
- Equal split (default)
- Custom amounts per person
- "I paid" / "X paid" attribution

### 3. Settlement Tracking

The system maintains a per-person balance sheet. "Rahul owes you ₹1,200. Priya owes Rahul ₹800." Settlement is tracked when marked as resolved.

### 4. Active Trip on Dashboard

When a trip is active, `active_trip_mini_card.dart` appears on the dashboard showing trip budget remaining and days left.

### 5. Trip Budget is Optional

Not all trips have budgets. Some users just want to track and split. Budget is an enhancement, not a requirement.

---

## Interactions

- Tap trip → `trip_detail_screen.dart`
- "Add expense" → `add_trip_transaction_screen.dart`
- Tap participant → shows their balance + what they owe/are owed
- "Settle up" → marks debts as resolved

