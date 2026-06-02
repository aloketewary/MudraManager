# Add/Edit Goal

> **Purpose:** "Set a savings target that actually motivates me."

---

## Key Files

| File | Role |
|---|---|
| `add_edit_goal_screen.dart` | Goal creation/editing form |

---

## Design Decisions

### 1. Target Amount + Deadline

Every goal has an amount and an optional deadline. The system uses both to compute daily/weekly saving pace.

### 2. Emoji + Name

Goals are personal. Users pick an emoji and name ("🏠 New Apartment" or "✈️ Goa Trip"). This makes the goal list scannable and emotionally resonant.

### 3. Initial Deposit Option

During creation, users can optionally log an initial deposit — acknowledging that many goals start with money already saved.

### 4. No Category Lock

Goals are not tied to spending categories. They're separate mental models — "save for X" is different from "spend less on Y."

