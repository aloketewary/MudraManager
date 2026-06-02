# Monthly Recap

> **Purpose:** "A story of my month — what happened, how I did, what stands out."

---

## Key Files

| File | Role |
|---|---|
| `monthly_recap_screen.dart` | Full-screen story-style recap |

---

## Design Decisions

### 1. Story Format, Not Report

The recap is presented as a vertical story (Instagram Stories-inspired) with pages:
- Total spending with visual
- Top categories
- Biggest expense
- Savings highlight
- Comparison vs last month
- Personality/archetype for the month

### 2. Available After Month Ends

The recap generates on the 1st of each month for the previous month. Not available mid-month — it's a retrospective, not a dashboard.

### 3. Tone-Aware Copy

All recap text respects the user's tone preference (friendly vs professional). Friendly: "You crushed it this month! 🎉" vs Professional: "Spending was 12% below budget."

### 4. Shareable (Future)

Designed to be screenshot-friendly with cards that look good when shared — though sharing is not yet implemented.

---

## Interactions

- Notification on 1st of month → opens recap
- Also accessible from analytics hub
- Tap any section → deep-dives to relevant screen

