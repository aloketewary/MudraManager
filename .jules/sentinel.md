## 2025-04-24 - [Encryption Data Corruption Prevention]
**Vulnerability:** Potential data corruption (double-encryption) when modifying and re-saving already encrypted records.
**Learning:** When fetching records from the database that are already encrypted, they must be decrypted before any modifications are made. If they are re-saved with a call to `encryptFields()` without prior decryption, the data becomes double-encrypted and unreadable upon subsequent single-decryption fetches.
**Prevention:** Use the `.withDecryption()` extension on all database fetches for models that use field-level encryption, especially when those records will be modified and saved back to the database.
