# Dashboard V2 — Design & Implementation Record

> This document captures the product decisions, architectural choices, and implementation
> details for the Dashboard V2 redesign. It is the authoritative reference for what was
> built, why, and what comes next.

---

## Problem Statement

The original dashboard was **widget-management-first**, not **decision-first**.

Users open a finance app asking:

1. Am I safe?
2. What needs attention?
3. How much freedom do I have?

The old dashboard answered: "Here is your financial data."

That distinction separates a reporting dashboard from a financial operating system.

---

## Design Principles

### One Signal Wins
Multiple insights displayed simultaneously = cognitive overload. Signals compete. One winner. Everything else disappears.

### Silence Is Earned, Not Absent
No signal ≠ no presence. The system always renders. Healthy state = "No action required." Users must be able to distinguish "everything healthy" from "system failed to evaluate."

### Prioritization Over Information
Adding pace, bills, residual capacity, constraint strips, utilization, trends, and goals simultaneously creates a worse dashboard. Reduce cognitive load. Answer three questions only.

### Trust Through Transparency
Every derived number must be auditable. "Remaining After Upcoming Bills" shows its decomposition: `₹78,000 balance · ₹35,700 upcoming bills`. Users can verify.

### No Interpretation
No "Safe to spend" (permission language). No "Great job!" (motivational). No tone variation in the decision layer. Deterministic phrasing only.

### Evidence-Driven Expansion
Ship one change. Measure. Validate. Then expand. Never ship multiple layers simultaneously — you won't know what worked.

---

## Architecture

### Phase 1A: Permanent Today Card

**Shipped.** Replaces the disappearing briefing with a card that always renders.

#### File: `lib/features/dashboard/presentation/widgets/daily_briefing_card.dart`

**Provider:** `todayCardProvider` → `TodayCardState`

Computes:
- Maturity gate (stage 0 = no bills, stage 1 = has bills)
- Balance and upcoming bills total (rolling 30-day window)
- "Remaining After Upcoming Bills" = balance - sum(upcoming bills next 30 days)
- Next bill name + days until due
- Signal competition (reuses existing urgency model)

**Widget:** `TodayCard` (always renders via `UnifiedBriefingCard`)

Three visual states:

```
HEALTHY (stage 1):
┌─────────────────────────────┐
│ TODAY                       │
│ No action required          │
│                             │
│ ₹42,300                     │
│ Remaining After Upcoming    │
│ Bills                       │
│                             │
│ ₹78,000 balance ·          │
│ ₹35,700 upcoming bills     │
│                             │
│ 🕐 Electricity • 8 days    │
└─────────────────────────────┘

WARNING:
┌─────────────────────────────┐
│ TODAY                       │
│ Attention required          │
│                             │
│ Fuel budget exceeded by     │
│ ₹1,400                     │
│                             │
│ ₹42,300                     │
│ Remaining After Upcoming    │
│ Bills                       │
│                             │
│ ₹78,000 balance ·          │
│ ₹35,700 upcoming bills     │
│                             │
│            Review Budget →  │
└─────────────────────────────┘

STAGE 0 (no bills):
┌─────────────────────────────┐
│ TODAY                       │
│ No action required          │
│                             │
│ ₹42,300                     │
│ Balance                     │
│                             │
│ + Add recurring bills for   │
│   accurate capacity         │
└─────────────────────────────┘
```

#### Signal Competition (unchanged from v1)

| Signal | Urgency |
|--------|---------|
| Bill due today | 100 |
| Budget exceeded | 80 |
| Spending drift | 70 |
| Bill due soon (≤3 days) | 60 |
| Overspending vs income | 50 |
| Month-over-month improvement | 20 |

One winner. Winner gets narrative + CTA. Healthy = no winner.

#### Key Decisions

| Decision | Resolution |
|----------|-----------|
| Greeting in card? | No. Removed from decision layer. |
| "Safe to spend"? | No. "Remaining After Upcoming Bills" — exposes calculation, no judgment. |
| Billing cycle? | Rolling 30-day window from today. Not calendar month. Not statement cycle. |
| New users (no bills)? | Stage 0: show balance only + setup prompt. |
| Warning visual? | Content communicates severity, not background color. No red cards. |
| CTA on healthy state? | No. Only on warning state. |
| Tone variation? | None. Deterministic phrasing. |

---

### Phase 1B: Health Strip

**Shipped.** Horizontal chip row showing only domains needing attention.

#### File: `lib/features/dashboard/presentation/widgets/health_strip.dart`

**Provider:** `healthStripProvider` → `HealthStripState`

Computes attention count per domain:

| Domain | Attention Condition | Route |
|--------|-------------------|-------|
| Budgets | `spent > budget.amount` (breached) | `/budget-dashboard` |
| Bills | Non-credit-card recurring due ≤7 days | `/recurring-transactions` |
| Cards | CC due ≤7 days OR utilization >80% | `/manage-accounts` |
| Goals | Active + pace <70% of needed (can't reach target) | `/goal-screen` |

**Domain Ownership (no overlap):**
- Bills = utilities, rent, subscriptions, EMIs (non-credit-card recurring)
- Cards = utilization, due date, statement cycle (credit-card-specific)
- A credit card payment due never appears in both Bills and Cards

**Goal Attention Gate (conservative):**
- Only active goals with target dates
- Only when 90-day rolling pace < 70% of needed monthly pace
- Paused/dormant goals never trigger
- No-deadline goals never trigger

#### Widget Behavior

```
ALL CLEAR:
(nothing renders — strip hidden)

ATTENTION NEEDED:
[📊 Budgets 2] [📋 Bills 1]
```

- Only domains with count > 0 are shown
- Each chip tappable → navigates to domain screen
- Uses `errorContainer` + `error` accent for visual urgency
- `Wrap` layout for narrow screens

#### Plugin Registration

```
Order -1: Today Card
Order  0: Health Strip  ← (hidden when all clear)
Order  1: Accounts
Order  2: Quick Actions
...
```

---

## Analytics Instrumentation

### File: `lib/features/dashboard/data/today_card_analytics.dart`

Lightweight SharedPrefs-based event tracking. No Isar schema changes. Rolling 30-day window, 200 event cap.

#### Events

| Event | Purpose | Where Fired |
|-------|---------|-------------|
| `cardShownHealthy` | Baseline: how often is system quiet? | Today Card first build |
| `cardShownAlert` + metadata | Which alerts fire? With what params? | Today Card first build |
| `alertDismissedNaturally` | Was alert self-resolving or ignored? | Healthy build after unacted alert |
| `ctaTapped` | Direct action from card | CTA button press |
| `destinationOpened` | Did user visit relevant screen? | Budget/Bills screen `initState` |
| `accountsOpened` | Trust proxy: still verifying balance? | Net Worth link tap |
| `billResolved` | Outcome: bill paid after alert | Hook ready (wire to payment flow) |
| `budgetResolved` | Outcome: budget adjusted after alert | Hook ready (wire to edit flow) |

#### Query Methods

- `getEvents()` — raw event list
- `alertsShownInRange(start, end)` — count alerts in window
- `destinationVisitsAfterAlert()` — correlation: alert → visit within 24h
- `weeklyEngagement()` — 4-week decay curve
- `getLastAlertSignal()` / `hasInteractionAfterLastAlert()` — dismissal detection

#### Destination Tracking Points

| Screen | Event |
|--------|-------|
| `AdaptiveBudgetDashboard` | `destinationOpened(destination: 'budget')` |
| `RecurringExpensesScreen` | `destinationOpened(destination: 'bills')` |
| Account card → Net Worth | `accountsOpened()` |

---

## Validation Plan

### Metrics That Matter

| Metric | What It Measures |
|--------|-----------------|
| Alert → destination visit within 24h | Behavioral response |
| Bill resolution rate | Alert drove action? |
| Time-to-resolution (before vs after) | Trust → faster action? |
| Accounts verification frequency | Do users still double-check balance? |
| Week 1 vs Week 3 engagement | Decay curve |
| Resolution rate by alert type | Which alerts drive action? |

### What NOT to Measure
- Impression rate (meaningless — position zero)
- Raw CTA click rate (low clicks ≠ failure)
- Session duration (short = successful for finance apps)

### Success Criteria (4 weeks)

**Strong Success:**
- Accounts verification decreases
- Destination visits increase
- Resolution rate improves

**Partial Success:**
- Destination visits increase, resolution unchanged
- Problem is downstream UX, not Today Card

**Failure:**
- Accounts verification unchanged
- Alert interaction near zero
- Today Card became decoration → fix before expanding

---

## Localization

Keys added for EN, HI, BN:

### Today Card
| Key | EN | HI | BN |
|-----|----|----|-----|
| `today_label` | TODAY | TODAY | TODAY |
| `today_noActionRequired` | No action required | कोई action ज़रूरी नहीं | কোনো action দরকার নেই |
| `today_attentionRequired` | Attention required | ध्यान दें | মনোযোগ দিন |
| `today_remainingAfterBills` | Remaining after upcoming bills | Upcoming bills के बाद बचा | Upcoming bills এর পর বাকি |
| `today_balance` | Balance | Balance | Balance |
| `today_breakdown` | {balance} balance · {bills} upcoming bills | (same) | (same) |
| `today_billContext` | {name} • {days} days | {name} • {days} दिन | {name} • {days} দিন |
| `today_billDueToday` | {name} • due today | {name} • आज due है | {name} • আজ due |
| `today_addBillPrompt` | Add recurring bills for accurate capacity | Recurring bills add करें... | সঠিক capacity জানতে... |

### Health Strip
| Key | EN |
|-----|-----|
| `health_budgets` | Budgets |
| `health_bills` | Bills |
| `health_goals` | Goals |
| `health_cards` | Cards |

---

## What Didn't Change

- All other dashboard widgets (accounts, quick actions, cash flow, budget, goals, bills, transactions)
- Widget ordering system and customization screen
- Plugin architecture
- Signal competition logic (reused)
- Dashboard animation system
- Banner priority system
- Widget analytics (Isar-based impression/click tracking)

---

## Future Phases (Design Only — Not Implemented)

---

### Phase 2: Action Queue

**Purpose:** Execution layer. Answers "What exactly do I do?"

**Relationship to Health Strip:**
- Health Strip = map ("where are problems?")
- Action Queue = directions ("what specific action resolves this?")
- Not redundant. Different altitudes.

**Rules:**
- Maximum 3 items. Hard cap. Never more.
- If >3 exist: show `+N additional items` overflow
- Each item taps to resolution screen (not list screen)
- Items disappear when resolved

**Item Sources:**
- Bills due within 3 days (specific bill name + amount)
- Budgets breached (specific budget + amount over)
- Credit cards due within 5 days (specific card + amount)
- Goals significantly behind (only if pace <50% of needed)

**Priority Order:**
1. Time-bound items (bills/cards due soonest first)
2. Magnitude (largest breach/overage)
3. Recency (newest problem)

**Visual:**
```
┌─────────────────────────────────┐
│ Needs Attention (2)             │
│                                 │
│ • Airtel Fiber ₹899 — tomorrow │
│ • Dining budget exceeded ₹1,400│
│                                 │
│ +1 additional item              │
└─────────────────────────────────┘
```

**Gating:**
- Only renders when items > 0
- Hidden when all clear (same as Health Strip)
- If Health Strip shows `[Bills 1]` and Queue shows "Airtel Fiber tomorrow" — that's intentional. Strip = count, Queue = specifics.

**Implementation Notes:**
- New provider: `actionQueueProvider` → `List<ActionItem>` (max 3)
- New widget: `ActionQueue`
- New plugin: `ActionQueueWidgetPlugin` (order between Accounts and Quick Actions — TBD based on Phase 1 placement data)
- Reuses same data sources as Health Strip but at item-level granularity

**Prerequisites:**
- Phase 1A validated (Today Card trusted)
- Phase 1B validated (Health Strip not redundant with Queue)

---

### Phase 3: Accounts Evolution

**Purpose:** Reduce visual weight of accounts without removing them.

**Current Problem:**
- Accounts dominate 40% of above-the-fold space
- Three display modes (carousel/stack/bento) compete with Today Card for attention
- Balance is shown as hero, but Today Card now provides "Remaining After Bills" which is more actionable

**Proposed Change:**

Compact default:
```
┌─────────────────────────────────┐
│ Accounts                        │
│ ₹78,000            +₹4,500/mo  │
│                    ↗ trending   │
└─────────────────────────────────┘
```

One tap → expand to current carousel/stack/bento.

**Decision Gate:**
- Only proceed if Phase 1A analytics show users do NOT immediately scroll to accounts on every open
- If `accountsOpened` events decrease after Today Card ships → users trust "Remaining After Bills" → safe to compact
- If `accountsOpened` events stay constant → users still need full balance view → do NOT compact

**Alternative (if compaction is rejected):**
- Keep current accounts widget unchanged
- Move it below Health Strip (order 2 instead of 1)
- Let data decide placement: `Today → Health Strip → Accounts` vs `Today → Accounts → Health Strip`

**Implementation Notes:**
- Modify `AnimatedSwipeableAccountCards` to support a `compact` mode
- New `accountDisplayModeProvider` that auto-selects compact vs expanded based on user preference or first-open behavior
- No new files needed — modification of existing widget

**Prerequisites:**
- Phase 1A analytics (accountsOpened trend)
- Minimum 500 sessions of data

---

### Phase 4: Adaptive Dashboard Maturity

**Purpose:** Dashboard evolves with data maturity. Dramatically increases perceived intelligence.

**Core Insight:**
A user with 1 month of data sees the same card structure as one with 12 months. The `financialRegimeProvider` already gates briefing signals — extend it to gate layout.

**Maturity Stages:**

#### Stage 1: New User (0-30 days)

**Focus:** Data collection. Build the foundation.

**Dashboard shows:**
- Today Card (stage 0 — balance only, setup prompts)
- Accounts (full)
- Quick Actions (prominent)
- First Transaction Nudge
- "Add Bill" prompts

**Dashboard hides:**
- Health Strip (no data to compute attention)
- Budget Overview (no budgets likely)
- Goals (premature)
- Cash Flow trends (insufficient data)

**Transition trigger:** ≥1 recurring bill + ≥10 transactions

#### Stage 2: Active User (1-3 months)

**Focus:** Pattern recognition. Show trends.

**Dashboard shows:**
- Today Card (stage 1 — remaining after bills)
- Health Strip (budgets + bills domains)
- Accounts
- Cash Flow (income vs expense)
- Budget Overview
- Recent Transactions

**Dashboard hides:**
- Spending drift signals (need 3 months)
- Goal pace analysis (need contribution history)
- Forecast breach on budgets (need 7+ days of data per period)

**Transition trigger:** `spendingDepthMonths >= 3`

#### Stage 3: Mature User (3-6 months)

**Focus:** Forecasting. Pace analysis. Pattern detection.

**Dashboard unlocks:**
- Spending drift in Today Card signals
- Goal attention in Health Strip
- Pace-based budget warnings
- Month-over-month improvement signals
- Category trend detection

**Transition trigger:** `spendingDepthMonths >= 6`

#### Stage 4: Power User (6+ months)

**Focus:** Long-term trajectory. Seasonality.

**Dashboard unlocks:**
- Seasonal spending predictions ("December typically 40% higher")
- Year-over-year comparisons
- Net worth trajectory
- Financial personality evolution
- Burn-rate prediction under current lifestyle

**Implementation Notes:**
- New provider: `dashboardMaturityProvider` → `DashboardMaturity` enum (stage1/2/3/4)
- Uses existing `financialRegimeProvider.spendingDepthMonths` as primary input
- `orderedDashboardWidgetsProvider` filters widgets based on maturity stage
- Each plugin gets optional `minMaturity` field — widget hidden until stage reached
- No layout changes per stage — only widget visibility changes

**Prerequisites:**
- All previous phases validated
- Clear evidence that information density correlates with data maturity

---

### Phase 5: Freedom Card V2

**Purpose:** Evolve "Remaining After Bills" into a full capacity model.

**Why Deferred:**
V1 only subtracts upcoming bills from balance. This is trustworthy because it's pure arithmetic. Adding goals and buffer requires interpretation — which erodes trust if done wrong.

**Staged Expansion:**

```
V1 (shipped):     Balance - Upcoming Bills = Remaining
V2 (this phase):  Balance - Bills - Goal Commitments = Remaining
V3 (future):      Balance - Bills - Goals - Buffer = Remaining
```

**V2 Design:**
```
₹42,300
Remaining After Upcoming Bills

₹78,000 balance
₹35,700 upcoming bills

▼ After goal commitments: ₹34,300
```

- Expandable section (collapsed by default)
- Only shows if user has active goals with committed monthly deposits
- "Committed" = user explicitly set a monthly contribution amount (not system-calculated "needed pace")
- Never auto-subtract goal amounts without user opt-in

**V3 Design (much later):**
- User-defined buffer amount in settings
- Optional, never auto-calculated
- Appears as third tier in expandable breakdown

**Key Principle:**
Balance - Bills = fact (system computes)
Balance - Bills - Goals = opt-in (user commits amounts)
Balance - Bills - Goals - Buffer = preference (user sets threshold)

Each tier adds user agency. Never system judgment.

**Prerequisites:**
- Phase 1A validated (users trust "Remaining After Bills")
- Goal contribution model supports explicit monthly commitment amounts
- Clear UI for user to "commit" a monthly goal deposit vs aspirational target

---

### Phase 6: Monthly Pace Card

**Purpose:** Replace current Cash Flow card with decision-enabling pace information.

**Current Problem:**
Cash Flow shows Income vs Expense with trend arrow. This is accounting. Users care about runway.

**Proposed Replacement:**
```
┌─────────────────────────────────┐
│ Month Progress                  │
│                                 │
│ Day 12 of 30                    │
│                                 │
│ Current pace    ₹2,583/day      │
│ Sustainable     ₹1,900/day      │
│                                 │
│ ₹7,000 ahead of sustainable     │
│ pace                            │
│                                 │
│ ──────────── 40%                │
└─────────────────────────────────┘
```

**Calculation:**
```dart
currentPace = totalExpenseThisMonth / daysPassed
sustainablePace = totalIncomeThisMonth / totalDaysInMonth
// OR if no income data:
sustainablePace = (balance - reservedBills) / daysRemaining
```

**Gating:**
- Only show if `spendingDepthMonths >= 1` (need baseline)
- Only show if income is recorded OR budget exists (need reference)
- If no reference available: don't show pace, show simple spent/remaining

**Prerequisites:**
- Phase 1A trusted
- Phase 4 maturity system (pace card only appears at stage 2+)
- Cash Flow card usage analytics (do users tap it? do they act on it?)

---

### Phase 7: Credit Card Treatment

**Purpose:** Credit cards behave differently from accounts. Give them dedicated surface area.

**Current Problem:**
Credit cards are buried inside the Accounts widget alongside bank accounts and wallets. Due dates, utilization, and minimum payments aren't first-class information.

**Proposed:**
Compact card (only when user has credit cards + attention needed):
```
┌─────────────────────────────────┐
│ Credit Cards                    │
│                                 │
│ ₹18,400 Due     5 days left    │
│ Utilization 67%                 │
└─────────────────────────────────┘
```

**Rules:**
- Only renders when credit card attention > 0 (same as Health Strip logic)
- Shows aggregate across all cards, not per-card
- Tap → manage accounts (filtered to credit cards)
- Neutral when within limits, warning accent only when due ≤3 days or utilization >90%

**Alternative:**
May not be needed if Health Strip `[Cards 1]` chip + Action Queue specifics provide sufficient visibility. Evaluate after Phase 2 data.

**Prerequisites:**
- Phase 2 (Action Queue) evaluated
- Evidence that credit card alerts in Today Card/Health Strip are insufficient

---

## Sequencing Summary

```
Phase 1A  ✅  Today Card (shipped)
Phase 1B  ✅  Health Strip (shipped)
          ⏸   VALIDATE (2-4 weeks / 500+ sessions)
Phase 2   ⏳  Action Queue
          ⏸   VALIDATE
Phase 3   ⏳  Accounts Evolution
Phase 4   ⏳  Adaptive Maturity
Phase 5   ⏳  Freedom Card V2
Phase 6   ⏳  Monthly Pace Card
Phase 7   ⏳  Credit Card Treatment
```

**Rule:** Never start phase N+1 until phase N is validated.

**Kill criteria:** If Today Card (Phase 1A) fails validation, do not proceed. Fix the foundation. Health Strip, Action Queue, and everything else inherits the failure.

---

## Long-Term Vision

The dashboard evolves from:

```
Widget list (v1)
→ Decision engine (v2, current)
→ Adaptive financial OS (v3, future)
```

The end state is a dashboard where:
1. Users open the app and know within 2 seconds if action is needed
2. The system earns trust through restraint (silence when healthy)
3. Information density matches data maturity (grows with the user)
4. Every number is auditable (no black-box metrics)
5. The dashboard becomes less needed over time (proactive notifications replace checking)

Success metric for the long-term vision:
> Users who relied on this system resolve financial problems faster than those who manually check multiple screens.

If that cannot be demonstrated after 6 months of iteration, the architecture should be questioned at its foundation.

---

## File Reference

```
lib/features/dashboard/
├── data/
│   ├── today_card_analytics.dart          ← Phase 1A analytics
│   ├── ...
├── plugin/
│   ├── daily_briefing_widget_plugin.dart   ← Today Card plugin (order -1)
│   ├── health_strip_widget_plugin.dart     ← Health Strip plugin (order 0)
│   ├── ...
├── presentation/
│   ├── widgets/
│   │   ├── daily_briefing_card.dart        ← Today Card (provider + UI)
│   │   ├── health_strip.dart              ← Health Strip (provider + UI)
│   │   ├── ...

lib/core/widgets/
├── dashboard_widget_registry.dart          ← Registry (both plugins added)
```

---

## Anti-Patterns Explicitly Avoided

| Anti-Pattern | Why Rejected |
|---|---|
| Showing all domains (0/0/0/0) | Banner blindness — wallpaper after day 3 |
| "Safe to spend" label | Permission language — app shouldn't advise |
| Greeting in decision card | Personal assistant ≠ financial operating system |
| Tone variation on Today Card | Trust comes from consistency, not personality |
| Shipping Health Strip with Today Card simultaneously | Can't measure what worked |
| Red/amber card backgrounds for warnings | Content communicates severity, not color explosions |
| Goal attention on paused goals | Noise — trust decreases |
| Bills/Cards domain overlap | Double-counting creates phantom problems |
| Total counts in Health Strip | "Budgets 8" is database metadata, not orientation |

---

*Last updated: Phase 1B implementation complete.*
