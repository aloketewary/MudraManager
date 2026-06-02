# Goals List

> **Purpose:** "What am I saving for, and how close am I?"

---

## Key Files

| File | Role |
|---|---|
| `goal_screen.dart` | Grid/list of all savings goals |
| `add_edit_goal_screen.dart` | Create/edit goal form |
| `goal_details_screen.dart` | Single goal progress + deposits |

---

## Design Decisions

### 1. Visual Progress Rings

Each goal shows a circular progress ring — not a horizontal bar. Rings feel more like achievements, aligning with the emotional design of saving money.

### 2. Emotional Milestones

Goals aren't just "50% complete." They have named milestones:
- 25% → "Getting started 🌱"
- 50% → "Halfway there 🔥"
- 75% → "Almost! 💪"
- 100% → Confetti celebration 🎉

### 3. Smart Deposit Suggestions

The system calculates "to reach your goal by [date], save ₹X per day/week/month" and presents it as a gentle nudge, not a command.

### 4. Goal Cards on Dashboard

Active goals surface on the dashboard via `goal_card.dart` so progress is always visible without navigating.

---

## Interactions

- Tap goal card → `goal_details_screen.dart`
- "Add deposit" → quick deposit sheet
- Goal reached → full-screen celebration with confetti
- FAB → `add_edit_goal_screen.dart`

