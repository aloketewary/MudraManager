# Daily Briefing — Product Philosophy & Architecture

> This document captures the design decisions, tradeoffs, and product philosophy
> arrived at through rigorous cross-examination of the dashboard and briefing system.
> It is a living record of what we learned, what we chose, and what we deliberately refused.

---

## What We Started With

A dashboard with 11 widget plugins, smart ordering, AI insights, widget analytics,
spending drift detection, and a customization screen. Sophisticated architecture.
Unclear user value.

### The Core Problem Identified

The dashboard was **widget-management-first**, not **decision-first**.

Users don't wake up wanting AI Insights or Widget Rankings.
They wake up wanting answers:
- Am I overspending?
- Can I afford this purchase?
- What bill is due next?
- How much money is left?

The dashboard asked: "What widgets should we show?"
The product should ask: "What decision is the user trying to make right now?"

---

## Key Realizations (In Order of Discovery)

### 1. Dashboards are symptoms of insufficient trust

If the app reliably surfaces the right insight at the right moment,
users never need to "check" the dashboard. A dashboard exists because
users don't trust the app to tell them proactively.

### 2. A briefing is not a compressed dashboard

Early attempts at a "Daily Briefing Card" with observation/risk/recommendation
slots were just 4 widgets inside 1 widget. The real briefing is:
- One signal wins
- One story gets told
- Everything else disappears

### 3. Signals must compete, not coexist

Multiple insights displayed simultaneously = dashboard rebuilt.
Signals must rank against each other. One winner. One narrative.

### 4. Novelty alone is the wrong gate

"Would the user discover this without my app?" biases toward rare anomalies.
The correct question: "Would this change what the user considers important right now?"
The product creates **salience recalibration**, not just discovery.

### 5. Silence must be earned, not assumed

Pure silence from day 1 creates a cold-start interpretability problem.
Users need to experience the system working before silence becomes meaningful.
Solution: constant detection threshold, adaptive explanation depth.
Early messages are richer in context. Later messages are compressed.
Same signal, different density. Never different sensitivity.

### 6. Compression must preserve semantic completeness

Every message at any density must contain: what deviated, from what reference,
and what the consequence is. If any component is missing, the signal doesn't
fire — because incomplete stories erode trust faster than silence.

### 7. The system must never become less assertive — only more contextual

Once assertiveness becomes variable, users stop knowing whether to trust
the system in principle. Confidence is internal computation. It never
becomes user-facing language.

---

## Architecture Evolution

### What We Killed

| Component | Why |
|---|---|
| Smart Ordering | Users want spatial stability. Constant reordering = disorientation. |
| Widget Analytics (user-facing) | Internal tooling leaked into UX. Belongs in dev menu. |
| "AI Insights" branding | It's rules, not AI. Users eventually notice. |
| Multi-slot briefing (observation/risk/recommendation) | Three slots = three widgets in a trenchcoat. |
| Phase 1 / Phase 2 user modes | Two modes = inconsistent system. One invariant from day 1. |
| Adaptive thresholds | Changing what the system considers "important" breaks trust. |
| "Medium confidence" signals | Comfortable middle that trains dismissal. Everything becomes medium. |
| Acknowledgment loops for intent | Ritual compliance that degrades into noise. |
| "Frame validity" meta-layer | Second interpreter judging the first. Uncertainty never surfaces. |

### What We Built

| Component | Purpose |
|---|---|
| DailyBriefingCard | Single signal, one story, one action. Position zero. |
| DailyBriefingWidgetPlugin | Registered at order -1. Non-disablable. |
| Signal competition model | Signals rank by salience. One winner. |
| Spending drift detection | Behavioral pattern detection (Level 2 insight). |
| Equilibrium detection (designed) | Stability vs motion — not yet implemented. |
| Trajectory modeling (designed) | Net position direction + rate + runway. |

---

## The Product Philosophy

### What the system IS

> A short-horizon financial viability detector that assumes continuity of
> current lifestyle. It detects instability in spending patterns,
> unsustainability in cashflow trajectory, and structural shifts in
> spending composition.

### What the system IS NOT

- Not a financial planner
- Not a wealth optimizer
- Not a resilience assessor
- Not a goal-tracking system
- Not a comprehensive financial health proxy

### The Doctrine

> The system detects financial patterns that haven't reached equilibrium
> and trajectories approaching hard constraints. It doesn't judge spending
> levels. It doesn't infer intent. It observes whether behavior is stable
> or in motion — and surfaces patterns that are still moving or paths
> approaching exhaustion.

### The Ideology (Stated Explicitly)

The system encodes one value judgment:
**inability to sustain current life is worth alerting on.**

Everything above that threshold — optimization, growth, goal attainment,
wealth building — is explicitly out of scope.

The system is intentionally blind above the floor.
That blindness is a product choice, not a neutral consequence of math.

---

## Three Detection Layers

### Layer 1: Motion (Pattern Stability)

- Are individual spending patterns stable or still changing?
- Detects: settling vs continuous movement vs oscillation
- Flags: instability (patterns still in motion without equilibrium)
- Silent when: patterns have settled at any level

### Layer 2: Flow (Solvency Snapshot)

- Current income vs current spending
- Informational context, not standalone alarm
- Deficits can be planned, temporary, or funded by reserves

### Layer 3: Trajectory (Net Position Over Time)

- Direction and rate of net financial position change
- Proximity to hard constraints (reserve exhaustion)
- Computed under explicit, stated assumptions:
  - Reserve = liquid + savings (excludes investments, credit, locked funds)
  - Rate = 90-day smoothed net outflow
  - Runway = reserve ÷ rate
- All assumptions visible to user, overridable

---

## Communication Principles

### When the system speaks:
- Patterns are unsettled (Layer 1)
- Trajectory approaches constraint exhaustion (Layer 3)
- Structural composition of spending is materially shifting

### When the system is silent:
- Patterns are stable AND trajectory is sustainable
- Silence means: nothing is currently unstable or approaching exhaustion
- Silence does NOT mean: finances are robust, optimal, or resilient

### How the system speaks:
- Always decisive about observations
- Never expresses confidence gradients
- States comparators explicitly ("vs 3-month average", "vs declared budget")
- Never claims comparator validity — just states which one is used
- Semantic completeness at all density levels (deviation + reference + consequence)

### Adaptive explanation depth:
- Early interactions: full context, baseline shown, projection made
- Later interactions: compressed, assumes user understands system's language
- Detection threshold: CONSTANT (never changes)
- Explanation richness: ADAPTIVE (reduces as user demonstrates familiarity)

---

## Anti-Drift Guarantees

### Baseline Management
- Baselines never update automatically
- Only explicit user action redefines "normal"
- System monitors for evidence of structural life shifts
  (40%+ categories deviated OR 25%+ income change)
- When detected: system states comparator may be stale, offers review
- Does NOT soften signal strength during uncertainty

### Reinforcement Prevention
- If same category triggers 3+ consecutive months same direction
  AND user behavior unchanged: system shifts from "user deviation"
  framing to "model questioning" framing
- Signals that persist without behavioral response:
  system questions whether its own reference point needs updating
- Never auto-normalizes. Never suppresses. Offers user choice.

### Semantic Evolution of Persistent Signals
- Month 1: anomaly detected
- Month 2: pattern forming
- Month 3: structural assessment (persistent, unresolved)
- Month 4+: system offers baseline revision option
- Never goes silent on a real signal. Narrative evolves, truth persists.

---

## Tradeoffs Explicitly Accepted

### 1. Silence will be misread as safety
Users will interpret "no warning" as "no risk."
This is structural and unfixable within the product's philosophy.
Mitigation: periodic contextual reminders of scope. Not a fix. A reduction.

### 2. The system only understands collapse, not brittleness
A user who slowly accumulates fixed obligations without crossing into
deficit is building fragility the system cannot see. Accepted because
detecting brittleness requires prescribing "how much flexibility should
you have" — which is financial planning, not detection.

### 3. Users will optimize around the silence boundary
Like speed cameras creating clusters at the limit.
Cannot prevent. The boundary exists. People will find it.

### 4. Over-trust is entangled with value delivery
The system is useful because it's quiet. Its quietness creates false
comprehensiveness. That false comprehensiveness is part of why users
trust it. And that trust is why the rare signal lands with authority.
Authority and illusion are the same property from different angles.

### 5. Intent is unobservable
The system cannot distinguish "intentional but unlogged change" from
"unconscious drift." It treats both as potentially unconscious until
equilibrium is detected. False positives on intentional changes are
accepted as the cost of catching real drift.

---

## The Uncomfortable Truths (Documented for Accountability)

1. This is a **selective-risk signaling system that knowingly induces a
   completeness illusion** in exchange for interpretability and low cognitive load.

2. The system's primary cognitive effect on users is shaped as much by
   what it refuses to show as by what it shows.

3. Behavioral authority + semantic silence = sacrifice of epistemic humility
   in practice. The system claims humility in documentation. Users will feel
   comprehensively monitored. They aren't.

4. The system is **incomplete by design**. A user who follows it for 10 years
   and never sees a warning may become extremely fragile to shock. The system
   did its job perfectly AND failed the user. Both are true simultaneously.

5. The final honest description:
   > "A high-authority, low-frequency warning system that will be interpreted
   > as a general financial health proxy despite being designed only for
   > tail-risk detection."

---

## Falsification Criteria

The system should be killed (not fixed) if evidence shows:

> Users who relied on this system and experienced financial crisis that a
> broader system would have caught EXCEEDS users who avoided crisis because
> of this system's warnings.

Net harm > net prevention = kill the product.

---

## What Ships Today

- `daily_briefing_card.dart` — Provider + UI. Single signal wins. Returns null (card absent) when no signal is regime-admissible and active.
- `daily_briefing_widget_plugin.dart` — Position -1. Disablable by user.
- `dashboard_widget_registry.dart` — Briefing registered above all widgets.
- `financial_regime_provider.dart` — Computes structural properties of user's financial data. Gates signal admissibility.

Current signals available (from existing infrastructure):
- Spending drift (behavioral instability) — regime: spending depth ≥ 3 months
- Bill due urgency (constraint proximity) — no regime gate
- Budget breach (declared target exceeded) — no regime gate
- Income vs expense gap (overspending) — regime: regular income
- Month-over-month improvement (comparison) — regime: spending depth ≥ 2 months

### System Identity (revised)

> A deterministic, editorially curated precision alerting system for personal finance
> that speaks only when a concrete financial state crosses a concrete threshold,
> presents with full authority, and is silent otherwise.
>
> It does not model financial life. It does not predict. It does not reflect.
> It notices specific things and says them clearly.

### Architectural Decisions (locked)

| Property | Decision |
|---|---|
| System identity | Precision alerting layer |
| Signal admission | Design-time structural rigor |
| Regime gating | Binary admissibility, recomputed continuously |
| Competition | One winner, urgency-ranked |
| Presentation | Full authority, no confidence gradient |
| Silence | Structural absence — no "all clear" message |
| Feedback loops | None for signal quality |
| Signal pool | Small, curated (currently 5 types) |
| Interpretive richness | Not a goal — system converges toward most-frequently-urgent |

Future layers (designed, not validated — remain unbuilt until empirically justified):
- Equilibrium detection (settling vs motion)
- Net position trajectory + runway
- Structural composition shift monitoring
- Adaptive explanation depth
- Monthly prediction reconciliation (self-audit loop)

---

## Instrumentation (Minimal, Outcome-Focused)

### What to measure:
1. **Signal type + user response** — acted / ignored / dismissed
2. **Action without scrolling** — did user act on briefing without
   exploring dashboard below? (trust proxy)
3. **Attribution (every ~10 actions):** "Did this change what you'll
   pay attention to?" — Yes / No (single tap, dismissible)

### What NOT to measure:
- Scroll depth, time on screen, widget impressions, CTR, session duration
- All optimize for engagement. We optimize for trust and certainty.

### Success indicators:
- Users act without scrolling → interpretation replacing exploration
- Users open less but feel more in control → system working invisibly
- Signal types that repeatedly get ignored → kill list candidates

---

## Design Principles (Permanent Reference)

1. **One signal wins.** Never multiple insights competing for attention.
2. **Silence is the default.** Speech is earned by crossing detection threshold.
3. **Detection is constant.** Thresholds never change. Explanation depth adapts.
4. **Comparators are explicit.** Never claim a comparison is "correct" — state which one is used.
5. **Never infer intent.** Observe stability. Observe trajectory. Never guess motivation.
6. **Authority through restraint.** The system earns trust by how rarely it speaks.
7. **Semantic completeness always.** Every message: what changed + from what reference + consequence.
8. **The floor is the boundary.** Above it = user's domain. Approaching it = system speaks.
9. **Incomplete by design.** Stated honestly. Never disguised as comprehensiveness.
10. **Ship, then watch.** Don't optimize before users vote with behavior.

---

*Last updated: Session where we dismantled the dashboard and rebuilt the product philosophy from first principles.*
