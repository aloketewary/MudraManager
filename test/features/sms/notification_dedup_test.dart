import 'package:flutter_test/flutter_test.dart';

/// Tests the in-memory dedup logic used by NotificationListenerBridge.
/// Since _isDuplicate is private, we replicate the exact algorithm here
/// to verify correctness of the sliding-window hash dedup.
void main() {
  group('In-memory notification dedup', () {
    late Set<String> hashSet;
    late List<String> hashQueue;
    const maxSize = 200;

    bool isDuplicate(String hash) {
      if (hash.isEmpty) return true;
      if (hashSet.contains(hash)) return true;

      hashSet.add(hash);
      hashQueue.add(hash);

      if (hashQueue.length > maxSize) {
        final oldest = hashQueue.removeAt(0);
        hashSet.remove(oldest);
      }

      return false;
    }

    setUp(() {
      hashSet = {};
      hashQueue = [];
    });

    test('empty hash is treated as duplicate', () {
      expect(isDuplicate(''), isTrue);
    });

    test('first occurrence is not a duplicate', () {
      expect(isDuplicate('hash_1'), isFalse);
    });

    test('second occurrence of same hash is a duplicate', () {
      isDuplicate('hash_1');
      expect(isDuplicate('hash_1'), isTrue);
    });

    test('different hashes are not duplicates', () {
      expect(isDuplicate('hash_1'), isFalse);
      expect(isDuplicate('hash_2'), isFalse);
    });

    test('sliding window evicts oldest hash after max size', () {
      // Fill the window
      for (int i = 0; i < maxSize; i++) {
        isDuplicate('hash_$i');
      }
      expect(hashSet.length, maxSize);
      expect(hashQueue.length, maxSize);

      // hash_0 is still in the set
      expect(isDuplicate('hash_0'), isTrue);

      // Add one more — should evict hash_0
      isDuplicate('hash_new');
      expect(hashSet.length, maxSize);
      expect(hashQueue.length, maxSize);

      // hash_0 was evicted, so it's no longer a duplicate
      expect(hashSet.contains('hash_0'), isFalse);
      // Re-adding hash_0 should succeed (not duplicate)
      expect(isDuplicate('hash_0'), isFalse);
    });

    test('recent hashes within window are still detected', () {
      for (int i = 0; i < 50; i++) {
        isDuplicate('hash_$i');
      }
      // All 50 should still be detected as duplicates
      for (int i = 0; i < 50; i++) {
        expect(isDuplicate('hash_$i'), isTrue);
      }
    });
  });
}
