import 'package:flutter/material.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';

class AppException implements Exception {
  final String code;
  final String message;
  final String? userMessage;
  final dynamic originalError;

  AppException({
    required this.code,
    required this.message,
    this.userMessage,
    this.originalError,
  });

  @override
  String toString() => 'AppException($code): $message';
}

class DatabaseException extends AppException {
  DatabaseException(String message, {dynamic error})
      : super(
          code: 'DB_ERROR',
          message: message,
          userMessage: 'Failed to save data. Please try again.',
          originalError: error,
        );
}

class SmsProcessingException extends AppException {
  SmsProcessingException(String message, {dynamic error})
      : super(
          code: 'SMS_ERROR',
          message: message,
          userMessage: 'Failed to process SMS transaction.',
          originalError: error,
        );
}

class BackupException extends AppException {
  BackupException(String message, {dynamic error})
      : super(
          code: 'BACKUP_ERROR',
          message: message,
          userMessage: 'Backup operation failed.',
          originalError: error,
        );
}

/// Retry a future operation with exponential backoff
Future<T> withRetry<T>(
  Future<T> Function() operation, {
  int maxAttempts = 3,
  Duration initialDelay = const Duration(seconds: 1),
}) async {
  final log = AppLog(getLogger(), 'Retry');
  for (int i = 0; i < maxAttempts; i++) {
    try {
      return await operation();
    } catch (e) {
      if (i == maxAttempts - 1) rethrow;
      await Future.delayed(initialDelay * (i + 1));
      log.w('Retry attempt ${i + 1} after error: $e');
    }
  }
  throw Exception('Max retry attempts reached');
}

/// Safe execution with error handling
Future<T?> safeExecute<T>(
  Future<T> Function() operation, {
  T? fallback,
  void Function(dynamic error)? onError,
}) async {
  final log = AppLog(getLogger(), 'SafeExec');
  try {
    return await operation();
  } catch (e) {
    onError?.call(e);
    log.e('Safe execute caught error', e);
    return fallback;
  }
}
