# Skin System

> **Purpose:** "Change the app's entire visual personality — not just colors."

---

## Key Files

| File | Role |
|---|---|
| `skin_picker_screen.dart` | Browse and select skins |
| `skin_editor_screen.dart` | Customize skin parameters |
| `skin_preview_card.dart` | Visual preview of a skin |
| `skin.dart` | Skin model (colors, radii, typography, tone) |
| `skin_provider.dart` | Active skin state |
| `skin_repository.dart` | Skin loading and storage |
| `skin_to_theme.dart` | Converts skin → Flutter ThemeData |
| `skin_aware_tone.dart` | Links skin to tone system |

---

## Design Decisions

### 1. Skin > Theme

A theme changes colors. A skin changes the app's personality:
- Color palette
- Border radius (sharp vs rounded)
- Typography weight and pairing
- Card elevation style
- Linked tone pack (how the app "talks")

### 2. Bundled + Unlockable

Some skins are bundled free. Others are unlocked through:
- Achievement milestones
- Pro subscription
- Gamification levels

### 3. Editor for Pro Users

Pro users can create custom skins by adjusting parameters in `skin_editor_screen.dart`. Presets serve as starting points.

### 4. Instant Preview

Skin selection shows a live preview card before applying. No blind commitment.

---

## Interactions

- Browse skins → preview card → tap to apply
- Locked skins show unlock requirement
- Pro badge on custom editor
- Skin change = instant, no restart

