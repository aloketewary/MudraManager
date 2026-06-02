# Analytics Hub

> **Purpose:** "Give me the big picture — how healthy are my finances?"

---

## Key Files

| File | Role |
|---|---|
| `analytics_screen.dart` | Hub linking to all analytics sub-screens |
| `financial_health_screen.dart` | Composite health score |
| `spending_personality_screen.dart` | Spending archetype analysis |
| `spending_trends_screen.dart` | Multi-month trend visualization |
| `cash_flow_forecast_screen.dart` | Projected cash flow |
| `net_worth_screen.dart` | Asset vs liability tracking |
| `tax_estimation_screen.dart` | Basic tax projection (India) |

---

## Design Decisions

### 1. Financial Health Score

A 0-100 composite score based on:
- Budget adherence
- Savings rate
- Expense stability
- Debt-to-income ratio (if applicable)

Displayed as a prominent gauge with color-coded zones (red/yellow/green).

### 2. Spending Personality

Users are assigned an archetype based on spending patterns:
- "The Planner" — consistent, within budgets
- "The Impulse Buyer" — spikes in discretionary categories
- "The Minimalist" — consistently under budget
- etc.

This gamifies self-awareness without being judgmental.

### 3. Cash Flow Forecast

Projects 30/60/90 day cash position based on:
- Historical income patterns
- Known recurring bills
- Average discretionary spending

### 4. FL Chart Visualizations

All charts use FL Chart library for:
- Line charts (trends over time)
- Pie charts (category distribution)
- Bar charts (monthly comparisons)

### 5. Tax Estimation (India-Specific)

Basic income tax projection based on logged income. Not a replacement for CA advice — just a rough awareness tool.

---

## Interactions

- Hub screen → tap any card to deep-dive
- Health score card also appears on dashboard
- Spending personality card on dashboard links here

