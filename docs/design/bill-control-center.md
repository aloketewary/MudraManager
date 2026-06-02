# Bill Control Center

> **Purpose:** "What recurring payments do I have, and what's due soon?"

---

## Key Files

| File | Role |
|---|---|
| `bill_control_center_screen.dart` | Master list of all recurring transactions & bills |
| `add_recurring_transaction_screen.dart` | Create/edit recurring transaction |
| `frequency_selector.dart` | Frequency picker (daily/weekly/monthly/yearly) |
| `subscription_list_card.dart` | Subscription-style bill card |
| `sms_activity_card.dart` | SMS-matched payment indicators |

---

## Design Decisions

### 1. Lazy Processing

Recurring transactions are processed **lazily** — only when the user opens this screen or via background Workmanager (every 6h). Never blocks app startup.

### 2. SMS Matching

When an SMS is detected that matches a recurring bill (amount + merchant + timing), the system auto-marks it as paid instead of creating a duplicate.

### 3. Visual Due Date Urgency

Bills are color-coded by urgency:
- Overdue → error color
- Due within 3 days → warning color
- Upcoming → neutral

### 4. One-Tap Mark as Paid

The most common action on this screen is confirming a bill was paid. One tap creates the transaction and moves the bill to next cycle.

---

## Interactions

- Tap bill → edit recurring transaction
- "Mark paid" → creates transaction, advances due date
- SMS auto-match → shows "matched" indicator, no duplicate

