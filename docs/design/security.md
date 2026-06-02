# Security

> **Purpose:** "Keep my financial data private — even from someone borrowing my phone."

---

## Key Files

| File | Role |
|---|---|
| `auth_gate.dart` | Biometric/PIN gate on app launch |
| `auth_service.dart` | Authentication state management |
| `guest_mode_toggle.dart` | Hides all amounts |
| `pin_entry_dialog.dart` | PIN input UI |
| `pin_migration.dart` | PIN storage migration |
| `field_encryption_service.dart` | Field-level encryption |
| `encryption_migration.dart` | Encryption schema migration |
| `account_encryption_migration.dart` | Account data encryption |

---

## Design Decisions

### 1. Biometric Lock

App requires biometric (fingerprint/face) or PIN on every launch. Configurable timeout for re-lock.

### 2. Guest Mode

"Guest mode" hides all monetary amounts (shows •••• instead). Users can hand their phone to someone without revealing finances. Toggle-able with biometric confirmation.

### 3. Field-Level Encryption

Sensitive fields (account numbers, balances) are encrypted at rest in Isar. Even if the database file is extracted, data is unreadable without device credentials.

### 4. No Cloud = No Breach Surface

The strongest security decision: data never leaves the device. No server means no data breach, no account compromise, no credential management.

### 5. PIN as Fallback

For devices without biometric hardware, a 4-6 digit PIN provides the lock mechanism. Stored hashed, never in plaintext.

---

## Interactions

- App launch → biometric prompt
- Failed biometric → PIN fallback
- Guest mode toggle → biometric confirmation required
- Settings → configure lock timeout, change PIN

