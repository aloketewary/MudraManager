# Transfer

> **Purpose:** "Move money between my accounts."

---

## Key Files

| File | Role |
|---|---|
| `transfer_screen_new.dart` | Transfer form (from account → to account + amount) |

---

## Design Decisions

### 1. Separate from Add Transaction

Transfers are conceptually different — they don't change net worth, just move money. A separate screen avoids confusion with income/expense.

### 2. Dual-Entry Bookkeeping

One transfer creates two transactions: an expense from Account A and income to Account B. Linked internally so editing one updates both.

### 3. Account Balances Visible During Selection

When picking "from" and "to" accounts, current balances are shown inline to prevent overdraft confusion.

