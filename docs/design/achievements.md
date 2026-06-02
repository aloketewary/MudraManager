# Achievements & Gamification

> **Purpose:** "Build financial habits through rewards, streaks, and milestones."

---

## Key Files

| File | Role |
|---|---|
| `achievements_screen.dart` | Full achievement gallery |
| `gamification_service.dart` | Achievement tracking engine |
| `gamification_providers.dart` | State management for gamification |
| `achievement_registry.dart` | All available achievements defined |
| `achievement_unlock_listener.dart` | Event-driven unlock detection |
| `achievement.dart` | Achievement model |
| `user_rank.dart` | Level/rank model |
| `gamification_enum.dart` | Enums for achievement types |
| `achievement_card.dart` | Achievement display card |
| `achievement_unlock_dialog.dart` | Celebration dialog on unlock |
| `badge_showcase.dart` | Badge grid display |
| `level_badge.dart` | Level indicator widget |
| `recent_achievement_card.dart` | Dashboard card for latest unlock |
| `streak_indicator.dart` | Streak count display |
| `streak_saved_celebration_sheet.dart` | Streak milestone celebration |
| `debug_gamification_button.dart` | Dev testing tool |

---

## Design Decisions

### 1. Deferred Initialization

Gamification loads 3 seconds after app UI renders. It's never on the critical path. Users don't wait for badge computation.

### 2. Achievement Categories

- **Streaks** — Consecutive days logging expenses
- **Milestones** — Total transactions, budgets created, goals completed
- **Behavioral** — Staying under budget for a month, saving consistently
- **Exploration** — Using new features, trying plugins

### 3. Levels & Ranks

Users accumulate XP from achievements. Levels unlock cosmetic rewards (new skins, badge borders). No functionality is locked behind levels.

### 4. Celebration Moments

Unlocking an achievement triggers:
- Full-screen dialog with confetti
- Haptic feedback
- Tone-aware congratulation message
- Badge added to profile

### 5. Non-Punitive

There are no "failures" or "lost streaks" displayed prominently. A broken streak simply resets — no shame messaging. The system celebrates progress, never punishes lapses.

---

## Interactions

- Achievement unlocked → celebration dialog auto-shows
- Profile → badge showcase
- Dashboard → recent achievement card (if new)
- Streak indicator visible on dashboard

