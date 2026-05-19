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

## 2026-05-19 - Optimized Spending Personality Aggregation
**Learning:** Consolidating separate Isar queries for income and expenses into a single pass, combined with replacing asynchronous link loading (`await load()`) with synchronous loading (`loadSync()`), significantly reduces I/O latency and event loop overhead in analytics features.
**Action:** Use single-pass query aggregation and `loadSync()` for link traversal inside performance-critical loops.
