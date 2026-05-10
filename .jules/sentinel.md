## 2025-04-24 - [Encryption Data Corruption Prevention]
**Vulnerability:** Potential data corruption (double-encryption) when modifying and re-saving already encrypted records.
**Learning:** When fetching records from the database that are already encrypted, they must be decrypted before any modifications are made. If they are re-saved with a call to `encryptFields()` without prior decryption, the data becomes double-encrypted and unreadable upon subsequent single-decryption fetches.
**Prevention:** Use the `.withDecryption()` extension on all database fetches for models that use field-level encryption, especially when those records will be modified and saved back to the database.

## 2025-05-15 - [Portable Backup Encryption Pattern]
**Vulnerability:** Encrypted data (PII, transactions) becomes unreadable when restored on a different device because it was exported using the source device's unique hardware-bound encryption key.
**Learning:** Field-level encryption in Isar uses device-specific keys (stored in Keystore/Keychain). Portable backups must contain plaintext data (the backup file itself is separately encrypted with a user-provided password) to ensure it can be re-encrypted on the destination device.
**Prevention:** Always use `.withDecryption()` during the export phase of a backup and call `.encryptFields()` before calling `.put()` during the restore phase.
