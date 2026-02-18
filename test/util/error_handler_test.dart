import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/utils/error_handler.dart';

void main() {
  group('Error Handling', () {
    test('withRetry succeeds on first attempt', () async {
      var attempts = 0;
      final result = await withRetry(() async {
        attempts++;
        return 'success';
      });

      expect(result, 'success');
      expect(attempts, 1);
    });

    test('withRetry retries on failure', () async {
      var attempts = 0;
      final result = await withRetry(() async {
        attempts++;
        if (attempts < 3) throw Exception('Fail');
        return 'success';
      });

      expect(result, 'success');
      expect(attempts, 3);
    });

    test('withRetry throws after max attempts', () async {
      expect(
        () => withRetry(
          () async => throw Exception('Always fail'),
          maxAttempts: 3,
        ),
        throwsException,
      );
    });

    test('safeExecute returns result on success', () async {
      final result = await safeExecute(() async => 'success');
      expect(result, 'success');
    });

    test('safeExecute returns fallback on error', () async {
      final result = await safeExecute(
        () async => throw Exception('Error'),
        fallback: 'fallback',
      );
      expect(result, 'fallback');
    });

    test('safeExecute calls onError callback', () async {
      var errorCalled = false;
      await safeExecute(
        () async => throw Exception('Error'),
        onError: (e) => errorCalled = true,
      );
      expect(errorCalled, true);
    });
  });

  group('Custom Exceptions', () {
    test('DatabaseException has correct properties', () {
      final exception = DatabaseException('Test error');

      expect(exception.code, 'DB_ERROR');
      expect(exception.message, 'Test error');
      expect(exception.userMessage, isNotNull);
    });

    test('SmsProcessingException has correct properties', () {
      final exception = SmsProcessingException('SMS error');

      expect(exception.code, 'SMS_ERROR');
      expect(exception.message, 'SMS error');
    });

    test('BackupException has correct properties', () {
      final exception = BackupException('Backup failed');

      expect(exception.code, 'BACKUP_ERROR');
      expect(exception.message, 'Backup failed');
    });
  });
}
