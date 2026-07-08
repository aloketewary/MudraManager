# Dashboard Theme Fix — Tasks

## Phase 1: Theme System

- [x] Update `lib/core/skin/model/skin.dart` → `SkinStyle` defaults (SaaS-grade)
  - `cardRadius: 12.0` (was 16)
  - `buttonRadius: 12.0` (was 12 - keep)
  - `inputRadius: 12.0` (was 12 - keep)
  - `cardElevation: 0.0` (was 0 - keep)

- [x] Update `assets/skins/finance.json` (SaaS-grade palette)
  - Primary: `#3B82F6` (SaaS Blue)
  - Surface: `#FAFAFA` (light), `#1F1F1F` (dark)
  - OnSurface: `#1F2937` (light), `#E5E5E5` (dark)
  - Outline: `#E5E7EB` (light), `#374151` (dark)
  - `cardRadius: 12` in style

- [x] Update `lib/core/providers/spacing_provider.dart` → 4px grid system
  - `cardInner = 20.0` (was 16.0)
  - `sectionGap = 24.0` (was 16.0)
  - Keep `radiusLarge = 12.0`, `radiusMedium = 12.0`, `radiusSmall = 8.0`

- [x] Update all widgets to use `spacingProvider`
  - Replaced `Tone.current.borderRadius` with `spacing.radiusSmall`
  - All dashboard widgets updated
  - Other feature files also updated for consistency

## Phase 2: Widget Updates

- [x] `daily_briefing_card.dart` — already uses spacing, verified no Tone.current.borderRadius
- [x] `health_strip.dart` — already uses spacing
- [x] `net_worth_card.dart` — replaced hardcoded values with spacing provider
- [x] `budget_card.dart` — verified no hardcoded spacing
- [x] `goal_card.dart` — replaced hardcoded values with spacing provider
- [x] `dashboard_animated_card.dart` — replaced hardcoded values with spacing provider
- [x] `first_transaction_nudge.dart` — replaced hardcoded values with spacing provider
- [x] `net_worth_mini_card.dart` — replaced hardcoded values with spacing provider
- [x] `command_center_screen.dart` — replaced Tone.current with spacing
- [x] `dashboard_home.dart` — replaced Tone.current with spacing
- [x] `dashboard_action_button.dart` — replaced hardcoded values with spacing provider
- [x] `dashboard_banners.dart` — replaced hardcoded values with spacing provider
- [x] `financial_health_card.dart` — replaced hardcoded values with spacing provider
- [x] `spending_personality_card.dart` — replaced hardcoded values with spacing provider

## Phase 3: Responsive

- [x] Verify widgets use spacing provider (all hardcoded values replaced)
- [x] Test mobile (320px-428px)
- [x] Test tablet (768px-1024px)
- [ ] Fix overflow if found
- [ ] 44x44dp minimum touch targets (spacing.touchTarget = 48.0)

## Phase 4: Polish

- [ ] Verify 60fps animations (flutter_animate already used)
- [ ] WCAG AA contrast check (new palette verified)
- [ ] Consistent loading states across all cards
- [ ] Visual audit for alignment and spacing consistency