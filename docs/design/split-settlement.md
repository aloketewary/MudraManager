# Split & Settlement

> **Purpose:** "Simplify who pays whom after a group expense."

---

## Key Files

| File | Role |
|---|---|
| `split_detail_screen.dart` | Detailed split view per expense |
| `split_amount_calculator.dart` | Split computation logic |
| `settlement_service.dart` | Settlement resolution & optimization |

---

## Design Decisions

### 1. Minimum Transactions Settlement

The system optimizes settlements to minimize the number of payments. If A owes B ₹100 and B owes C ₹100, the system suggests A pays C directly.

### 2. Split Types

- **Equal** — Total ÷ participants
- **Custom** — User-defined per person
- **Percentage** — Each person's share as %

### 3. Settlement is Manual

The app doesn't process payments. "Settle up" is a record-keeping action that marks a debt as resolved. This keeps the app offline-capable.

