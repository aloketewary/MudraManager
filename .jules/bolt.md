# Bolt's Journal - Mudra Performance Optimizations

## 2025-05-14 - Initial Performance Scan
**Learning:** Initializing the journal.
**Action:** Starting the hunt for performance bottlenecks in the Mudra codebase.

## 2025-05-14 - Optimized Tag Spending Aggregation
**Learning:** Nesting loops for aggregation in analytics providers (e.g., $O(\text{Tags} \times \text{Transactions})$) causes redundant database link loads (`loadSync()`) and significant performance degradation as data grows.
**Action:** Always use single-pass aggregation with hash maps ($O(N+M)$) for provider-level data processing.

## 2025-05-14 - Map Keys and Parallelization
**Learning:** When aggregating data into Maps using Isar model objects, use the model's `id` as the key instead of the object itself to avoid risks related to object equality. Also, when bulk database APIs are missing, use `Future.wait` to parallelize multiple independent queries (like `getBalanceOnDate`) to reduce sequential IPC overhead.
**Action:** Use IDs as Map keys and parallelize concurrent async calls with `Future.wait`.

## 2025-05-14 - Optimized Analytics Data Sharing
**Learning:** Multiple analytics providers fetching the same transaction list (e.g. last 365 days) causes redundant database I/O and IPC overhead.
**Action:** Use a shared `FutureProvider` (e.g., `analyticsTransactionsProvider`) to fetch data once and pass it as a parameter to service methods.

## 2025-05-14 - Advanced Analytics Efficiency
**Learning:** Methods performing multiple passes over transactions (using `.where()` or nested loops) scale poorly ($O(M \times N)$).
**Action:** Implement single-pass aggregation ($O(N)$) using hash maps or date-index math (`(now.year - tx.date.year) * 12 + (now.month - tx.date.month)`) to group transactions efficiently.
