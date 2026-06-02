# Onboarding

> **Purpose:** "Get the user set up in under 60 seconds — without overwhelm."

---

## Key Files

| File | Role |
|---|---|
| `onboarding_screen.dart` | Welcome flow (value props + permissions) |
| `account_setup_screen.dart` | First account creation |

---

## Design Decisions

### 1. Three Screens Max

Onboarding is at most 3 screens:
1. **Welcome** — What is Mudra Manager? (value props)
2. **Permissions** — SMS access (optional), notifications
3. **First Account** — Create your first bank/wallet account

Then you're in the app. No 7-screen tutorial.

### 2. SMS Permission is Optional

The app explains the benefit of SMS parsing but never gates functionality on it. Users who decline still get a fully functional app.

### 3. Account Setup is Mandatory

At least one account is required (even "Cash" works). This ensures the transaction flow has somewhere to record money.

### 4. No Sign-Up

Zero account creation. No email, no phone number, no password. Open app → use app. This is the strongest onboarding conversion rate possible.

### 5. Language Auto-Detected

Device language is auto-detected and applied. Users can change later in settings but shouldn't need to during onboarding.

---

## Interactions

- Swipe/tap through welcome screens
- SMS permission prompt → system dialog
- Account creation → minimal form (name + type + initial balance)
- "Get Started" → dashboard

