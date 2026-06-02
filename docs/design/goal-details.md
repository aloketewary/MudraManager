# Goal Details

> **Purpose:** "How is my saving going? Am I on pace?"

---

## Key Files

| File | Role |
|---|---|
| `goal_details_screen.dart` | Full goal view with progress, deposits, projections |

---

## Design Decisions

### 1. Progress Ring as Hero

A large animated progress ring dominates the top. It's the emotional anchor — you feel progress.

### 2. Deposit History

All deposits are listed chronologically below the ring. Users see their saving discipline as a visible trail.

### 3. Pace Projection

"At your current pace, you'll reach this goal by [date]" — updated dynamically after each deposit.

### 4. Milestone Celebrations

When crossing 25%/50%/75%/100% thresholds, the screen triggers celebrations (confetti, haptics, tone-aware messages).

### 5. Quick Deposit Action

A prominent "Add Deposit" button at the bottom makes the primary action obvious and one-tap accessible.

