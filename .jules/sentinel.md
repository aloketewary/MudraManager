## 2025-04-24 - [Encryption Data Corruption Prevention]
**Vulnerability:** Potential data corruption (double-encryption) when modifying and re-saving already encrypted records.
**Learning:** When fetching records from the database that are already encrypted, they must be decrypted before any modifications are made. If they are re-saved with a call to `encryptFields()` without prior decryption, the data becomes double-encrypted and unreadable upon subsequent single-decryption fetches.
**Prevention:** Use the `.withDecryption()` extension on all database fetches for models that use field-level encryption, especially when those records will be modified and saved back to the database.

## 2025-05-15 - [Portable Backup Encryption Pattern]
**Vulnerability:** Encrypted data (PII, transactions) becomes unreadable when restored on a different device because it was exported using the source device's unique hardware-bound encryption key.
**Learning:** Field-level encryption in Isar uses device-specific keys (stored in Keystore/Keychain). Portable backups must contain plaintext data (the backup file itself is separately encrypted with a user-provided password) to ensure it can be re-encrypted on the destination device.
**Prevention:** Always use `.withDecryption()` during the export phase of a backup and call `.encryptFields()` before calling `.put()` during the restore phase.

## 2025-05-20 - [Comprehensive Field Encryption Integration]
**Vulnerability:** Sensitive user-provided descriptions in Recurring Transactions and Goals were stored as plaintext, bypassing the encryption architecture used for regular Transactions.
**Learning:** Encryption must be applied consistently across all models containing PII or financial notes. Relying on primary service classes for encryption is insufficient if secondary services or UI screens perform direct database writes (e.g., SMS approval flow, recurring processing).
**Prevention:** Centralize encryption/decryption logic in model extensions and mandate their use in both retrieval (via `withDecryption()`) and persistence (via `encryptFields()`) layers across all feature modules.

## 2025-05-22 - [Encryption-Induced Query Regression]
**Vulnerability:** Core matching and filtering logic (e.g., `CategoryRule` matching, `BillService` duplicate check) failed or became extremely slow after applying field-level encryption.
**Learning:** Isar cannot filter or search within AES-256 ciphertext at the database level. Attempting to use `.filter().bodyContains()` or `.merchantNameEqualTo()` on encrypted fields returns zero results. Furthermore, fetching and decrypting the entire collection inside a loop (as done initially in `SmsActivityService`) causes $O(N^2)$ performance degradation.
**Prevention:** 1. Use deterministic non-sensitive indexed fields (like `smsHash`) for lookups where possible. 2. If content-based matching is required, fetch the decrypted collection once outside the loop and perform in-memory filtering.

## 2025-05-28 - [Encrypted Query Failure & Double Encryption Risk]
**Vulnerability:** Application logic failure (duplicate records) and potential data corruption when querying or saving encrypted fields.
**Learning:** Standard database filters like `bodyContains()` fail on encrypted fields because the ciphertext does not contain the plaintext substrings. Additionally, calling `encryptFields()` multiple times on the same object (e.g., in nested service calls) leads to double-encryption, making data unrecoverable.
**Prevention:** Use deterministic, non-encrypted indexed fields (like `smsHash`) for record lookups. Ensure that `encryptFields()` is called exactly once immediately before the final database write in a transaction, and decrypt the object if it needs to be reused.
