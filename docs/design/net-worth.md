# Net Worth

> **Purpose:** "What's my total financial position — assets minus liabilities?"

---

## Key Files

| File | Role |
|---|---|
| `net_worth_screen.dart` | Full net worth breakdown |
| `net_worth_card.dart` | Dashboard summary card |
| `net_worth_mini_card.dart` | Compact dashboard variant |
| `balance_history_screen.dart` | Historical balance over time |
| `balance_history_chart.dart` | Line chart of net worth progression |
| `investment_portfolio_screen.dart` | Investment holdings view |
| `reconciliation_screen.dart` | Balance reconciliation tool |

---

## Design Decisions

### 1. Accounts = Assets & Liabilities

Net worth is computed from account balances:
- Savings/checking/cash/wallet = assets
- Credit cards/loans = liabilities
- Net worth = assets − liabilities

### 2. Balance Snapshots

`balance_snapshot` model stores periodic balance snapshots to show historical net worth trend. Updated daily via background task.

### 3. Reconciliation

`reconciliation_screen.dart` lets users manually correct account balances when they drift from reality (common with cash accounts).

### 4. Investment Tracking (Basic)

`investment_portfolio_screen.dart` shows manually entered investment holdings. Not a portfolio tracker — just awareness of total position.

---

## Interactions

- Dashboard card tap → full net worth screen
- Tap account → balance history for that account
- "Reconcile" → adjustment transaction created

