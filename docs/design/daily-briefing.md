# Daily Briefing System

> **Purpose:** "What is the single most important financial thing I need to know right now?"

The full product philosophy is documented in [`lib/features/dashboard/DESIGN_PHILOSOPHY.md`](../../lib/features/dashboard/DESIGN_PHILOSOPHY.md). This is the architectural summary.

---

## Key Files

| File | Role |
|---|---|
| `daily_briefing_card.dart` | UI — single signal, one story, one action |
| `daily_briefing_widget_plugin.dart` | Plugin registration (order: -1) |
| `financial_regime_provider.dart` | Gates signal admissibility |
| `ai_insight_provider.dart` | Signal competition & ranking |

---

## Design Decisions

### 1. One Signal Wins

Multiple insights displayed simultaneously = a dashboard rebuilt inside a card. Signals compete. One winner. Everything else disappears.

### 2. Silence is Structural

When no signal crosses the detection threshold, the card is **absent** — not "all clear." Silence means nothing is unstable. It does NOT mean finances are healthy.

### 3. Regime Gating

Not all signals are valid for all users. A "spending drift" signal requires 3+ months of data. A "month-over-month improvement" requires 2+ months. The `financial_regime_provider` computes what's admissible.

### 4. Signal Types (Current)

| Signal | Regime Gate | Trigger |
|---|---|---|
| Spending drift | ≥ 3 months data | Behavioral instability detected |
| Bill due urgency | None | Bill due within 3 days |
| Budget breach | None | Category/total budget exceeded |
| Overspending | Regular income | Expenses > income this month |
| Month improvement | ≥ 2 months data | Spending reduced vs last month |

### 5. Authority Through Restraint

The system earns trust by how rarely it speaks. Every message contains: what deviated + from what reference + what the consequence is. Incomplete stories never fire.

---

## What Was Killed

- Multi-slot briefing (observation/risk/recommendation) — just widgets in a trenchcoat
- Adaptive thresholds — changing what's "important" breaks trust
- "AI Insights" branding — it's rules, not AI
- User-facing confidence levels — comfortable middle trains dismissal

