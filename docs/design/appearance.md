# Appearance & Themes

> **Purpose:** "Make the app look and feel like mine."

---

## Key Files

| File | Role |
|---|---|
| `appearance_screen.dart` | Theme, font, color selection |
| `theme_picker_screen.dart` | Color theme grid picker |
| `choose_language_screen.dart` | Language selection |
| `app_color_theme_enum.dart` | Available color themes |
| `app_theme.dart` | Theme construction logic |
| `theme_provider.dart` | Active theme state |
| `skin_picker_screen.dart` | Visual skin selection |
| `skin_editor_screen.dart` | Custom skin editing |
| `skin_preview_card.dart` | Skin preview widget |

---

## Design Decisions

### 1. Material You + Manual Override

The app supports dynamic Material You theming (Android 12+) but also offers 10+ manual color themes for older devices or user preference.

### 2. AMOLED Dark Mode

A true black dark mode that saves battery on OLED screens. Not just "dark gray" — actually black backgrounds.

### 3. Skin System

Beyond color themes, "skins" change the overall visual personality:
- Typography pairing
- Card radius and elevation
- Animation style
- Tone of copy (linked to tone system)

### 4. Language Selection

37+ languages supported with real translations. Language change is instant — no app restart needed.

### 5. Font Selection

Users choose from curated Google Fonts pairings that work well for both Latin and Devanagari/Bengali scripts.

---

## Interactions

- Color theme tap → immediate preview + apply
- Dark/light/system toggle → instant switch
- Language selection → immediate locale change
- Skin selection → full visual personality change

