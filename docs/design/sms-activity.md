# SMS Activity

> **Purpose:** "Which SMS messages did the app parse, and did it get them right?"

---

## Key Files

| File | Role |
|---|---|
| `sms_activity_screen.dart` | List of parsed SMS with status |
| `sms_info_card.dart` | SMS parsing result card |
| `settings_action_card.dart` | SMS settings action buttons |
| `settings_toggle_card.dart` | SMS toggle preferences |
| `sms_import_setting_screen.dart` | SMS import configuration |

---

## Design Decisions

### 1. Transparency Over Magic

Users see exactly which SMS messages were parsed, what transaction was created, and the confidence level. No black box.

### 2. Correction Flow

If the parser misidentified a transaction (wrong amount, wrong category), users can correct it inline. The correction feeds back into the parser's category rules.

### 3. 50+ Bank Support

The SMS parser supports major Indian banks, UPI apps, and wallets:
- SBI, HDFC, ICICI, Axis, Kotak, PNB, BOB, etc.
- Google Pay, PhonePe, Paytm, Amazon Pay
- Credit card alerts, EMI deductions

### 4. Duplicate Prevention

SMS matching checks against existing transactions (amount + date + merchant similarity) before creating new entries. Recurring bill SMS is matched to existing bills.

### 5. Permission-Gated

SMS access requires explicit permission. The app works fully without it — SMS is an enhancement, not a requirement.

---

## Interactions

- Tap SMS entry → shows parsed transaction, option to edit
- Toggle → enable/disable auto-import
- "Re-parse" → re-processes SMS with updated rules

