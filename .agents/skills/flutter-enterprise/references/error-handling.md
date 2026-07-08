# Comprehensive Error Handling for Flutter Enterprise Apps

## Overview

Effective error handling is crucial for enterprise applications to ensure reliability, maintainability, and good user experience. This guide covers comprehensive error handling strategies for Flutter apps using clean architecture.

## Error Handling Architecture

### Error Types

```dart
// lib/core/errors/exceptions.dart
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const AppException(this.message, [this.code, this.details]);

  @override
  String toString() => 'AppException: $message';
}

class ServerException extends AppException {
  const ServerException(String message, [String? code, dynamic details])
      : super(message, code, details);
}

class NetworkException extends AppException {
  const NetworkException(String message, [String? code, dynamic details])
      : super(message, code, details);
}

class ValidationException extends AppException {
  const ValidationException(String message, [String? code, dynamic details])
      : super(message, code, details);
}

class CacheException extends AppException {
  const CacheException(String message, [String? code, dynamic details])
      : super(message, code, details);
}

class AuthenticationException extends AppException {
  const AuthenticationException(String message, [String? code, dynamic details])
      : super(message, code, details);
}

class AuthorizationException extends AppException {
  const AuthorizationException(String message, [String? code, dynamic details])
      : super(message, code, details);
}

class TimeoutException extends AppException {
  const TimeoutException(String message, [String? code, dynamic details])
      : super(message, code, details);
}

class UnknownException extends AppException {
  const UnknownException(String message, [String? code, dynamic details])
      : super(message, code, details);
}
```

### Failure Classes

```dart
// lib/core/errors/failures.dart
abstract class Failure {
  final String message;
  final String? code;
  final dynamic details;
  final DateTime timestamp;

  const Failure(this.message, [this.code, this.details])
      : timestamp = DateTime.now();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Failure &&
        other.message == message &&
        other.code == code &&
        other.details == details;
  }

  @override
  int get hashCode {
    return message.hashCode ^
        code.hashCode ^
        details.hashCode;
  }
}

class ServerFailure extends Failure {
  const ServerFailure(String message, [String? code, dynamic details])
      : super(message, code, details);
}

class NetworkFailure extends Failure {
  const NetworkFailure(String message, [String? code, dynamic details])
      : super(message, code, details);
}

class ValidationFailure extends Failure {
  const ValidationFailure(String message, [String? code, dynamic details])
      : super(message, code, details);
}

class CacheFailure extends Failure {
  const CacheFailure(String message, [String? code, dynamic details])
      : super(message, code, details);
}

class AuthenticationFailure extends Failure {
  const AuthenticationFailure(String message, [String? code, dynamic details])
      : super(message, code, details);
}

class AuthorizationFailure extends Failure {
  const AuthorizationFailure(String message, [String? code, dynamic details])
      : super(message, code, details);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure(String message, [String? code, dynamic details])
      : super(message, code, details);
}

class UnknownFailure extends Failure {
  const UnknownFailure(String message, [String? code, dynamic details])
      : super(message, code, details);
}
```

## Centralized Error Handler

```dart
// lib/core/errors/error_handler.dart
import 'package:dio/dio.dart';
import '../network/network_info.dart';
import 'exceptions.dart';
import 'failures.dart';

class ErrorHandler {
  final NetworkInfo networkInfo;

  const ErrorHandler(this.networkInfo);

  Failure handleException(Exception exception) {
    if (exception is DioException) {
      return _handleDioException(exception);
    } else if (exception is AppException) {
      return _handleAppException(exception);
    } else {
      return UnknownFailure(exception.toString());
    }
  }

  Failure _handleDioException(DioException exception) {
    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutFailure('Request timeout', 'TIMEOUT');

      case DioExceptionType.connectionError:
        return NetworkFailure('No internet connection', 'NO_INTERNET');

      case DioExceptionType.badResponse:
        return _handleHttpError(exception);

      case DioExceptionType.cancel:
        return NetworkFailure('Request cancelled', 'CANCELLED');

      default:
        return UnknownFailure('Network error: ${exception.message}');
    }
  }

  Failure _handleHttpError(DioException exception) {
    final statusCode = exception.response?.statusCode;
    final message = exception.response?.data?['message'] ?? 'Unknown error';

    switch (statusCode) {
      case 400:
        return ValidationFailure(message, 'BAD_REQUEST');
      case 401:
        return AuthenticationFailure(message, 'UNAUTHORIZED');
      case 403:
        return AuthorizationFailure(message, 'FORBIDDEN');
      case 404:
        return ServerFailure('Resource not found', 'NOT_FOUND');
      case 422:
        return ValidationFailure(message, 'VALIDATION_ERROR');
      case 429:
        return ServerFailure('Too many requests', 'RATE_LIMIT');
      case 500:
      case 502:
      case 503:
        return ServerFailure(message, 'SERVER_ERROR');
      default:
        return ServerFailure(message, statusCode.toString());
    }
  }

  Failure _handleAppException(AppException exception) {
    if (exception is ServerException) {
      return ServerFailure(exception.message, exception.code, exception.details);
    } else if (exception is NetworkException) {
      return NetworkFailure(exception.message, exception.code, exception.details);
    } else if (exception is ValidationException) {
      return ValidationFailure(exception.message, exception.code, exception.details);
    } else if (exception is CacheException) {
      return CacheFailure(exception.message, exception.code, exception.details);
    } else if (exception is AuthenticationException) {
      return AuthenticationFailure(exception.message, exception.code, exception.details);
    } else if (exception is AuthorizationException) {
      return AuthorizationFailure(exception.message, exception.code, exception.details);
    } else {
      return UnknownFailure(exception.message, exception.code, exception.details);
    }
  }
}
```

## Error Reporting Service

```dart
// lib/core/errors/error_reporting_service.dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:logger/logger.dart';
import 'failures.dart';

class ErrorReportingService {
  final Logger _logger;
  final FirebaseCrashlytics _crashlytics;

  ErrorReportingService(this._logger, this._crashlytics);

  Future<void> reportError(Failure failure, {String? context}) async {
    // Log to console
    _logger.e(
      'Error reported',
      error: failure.message,
      stackTrace: StackTrace.current,
    );

    // Send to crash reporting service
    await _crashlytics.recordError(
      failure,
      fatal: _isFatalError(failure),
      information: [
        DiagnosticsProperty('code', failure.code),
        DiagnosticsProperty('timestamp', failure.timestamp),
        if (context != null) DiagnosticsProperty('context', context),
        if (failure.details != null) DiagnosticsProperty('details', failure.details),
      ],
    );
  }

  Future<void> reportMessage(String message, {LogLevel level = LogLevel.info}) async {
    _logger.log(level, message);

    if (level == LogLevel.error || level == LogLevel.fatal) {
      await _crashlytics.log(message);
    }
  }

  void setUserIdentifier(String userId) {
    _crashlytics.setUserIdentifier(userId);
  }

  void setCustomKey(String key, dynamic value) {
    _crashlytics.setCustomKey(key, value);
  }

  bool _isFatalError(Failure failure) {
    return failure is AuthenticationFailure ||
           failure is AuthorizationFailure ||
           failure is ServerFailure;
  }
}
```

## Error Handling in Repository Layer

```dart
// lib/features/user/data/repositories/user_repository_impl.dart
class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource remoteDataSource;
  final UserLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final ErrorHandler errorHandler;
  final ErrorReportingService errorReporting;

  UserRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
    required this.errorHandler,
    required this.errorReporting,
  });

  @override
  Future<List<User>> getUsers({int page = 1, int limit = 20}) async {
    try {
      if (await networkInfo.isConnected) {
        final remoteUsers = await remoteDataSource.getUsers(page: page, limit: limit);
        await localDataSource.cacheUsers(remoteUsers);
        return remoteUsers.map((model) => model.toEntity()).toList();
      } else {
        return await _getCachedUsers();
      }
    } on Exception catch (e) {
      final failure = errorHandler.handleException(e);
      await errorReporting.reportError(failure, context: 'UserRepository.getUsers');
      throw failure;
    }
  }

  @override
  Future<User> getUserById(String id) async {
    try {
      if (await networkInfo.isConnected) {
        final remoteUser = await remoteDataSource.getUserById(id);
        if (remoteUser != null) {
          await localDataSource.cacheUser(remoteUser);
          return remoteUser.toEntity();
        }
        throw ServerException('User not found', 'NOT_FOUND');
      } else {
        return await _getCachedUserById(id);
      }
    } on Exception catch (e) {
      final failure = errorHandler.handleException(e);
      await errorReporting.reportError(failure, context: 'UserRepository.getUserById');
      throw failure;
    }
  }
}
```

## Error Handling in Use Cases

```dart
// lib/features/user/domain/usecases/get_users_usecase.dart
class GetUsersUseCase {
  final UserRepository repository;
  final ErrorHandler errorHandler;
  final ErrorReportingService errorReporting;

  GetUsersUseCase(this.repository, this.errorHandler, this.errorReporting);

  Future<Either<Failure, List<User>>> call({int page = 1, int limit = 20}) async {
    if (page < 1) {
      final failure = ValidationFailure('Page must be greater than 0', 'INVALID_PAGE');
      await errorReporting.reportError(failure, context: 'GetUsersUseCase.validation');
      return Left(failure);
    }

    if (limit < 1 || limit > 100) {
      final failure = ValidationFailure('Limit must be between 1 and 100', 'INVALID_LIMIT');
      await errorReporting.reportError(failure, context: 'GetUsersUseCase.validation');
      return Left(failure);
    }

    try {
      final users = await repository.getUsers(page: page, limit: limit);
      return Right(users);
    } on Failure catch (failure) {
      await errorReporting.reportError(failure, context: 'GetUsersUseCase.execution');
      return Left(failure);
    } catch (e) {
      final failure = errorHandler.handleException(e);
      await errorReporting.reportError(failure, context: 'GetUsersUseCase.execution');
      return Left(failure);
    }
  }
}
```

## Error Handling in Presentation Layer

### Provider Error Handling

```dart
// lib/features/user/presentation/providers/user_provider.dart
class UserProvider extends ChangeNotifier {
  final GetUsersUseCase getUsers;
  final ErrorHandler errorHandler;
  final ErrorReportingService errorReporting;

  UserState _state = const UserState();
  UserState get state => _state;

  UserProvider({
    required this.getUsers,
    required this.errorHandler,
    required this.errorReporting,
  });

  Future<void> loadUsers({bool refresh = false}) async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();

    try {
      final result = await getUsers();

      result.fold(
        (failure) {
          _state = _state.copyWith(isLoading: false, error: failure);
          _showUserFriendlyError(failure);
        },
        (users) {
          _state = _state.copyWith(isLoading: false, users: users);
        },
      );
    } catch (e) {
      final failure = errorHandler.handleException(e);
      await errorReporting.reportError(failure, context: 'UserProvider.loadUsers');
      _state = _state.copyWith(isLoading: false, error: failure);
      _showUserFriendlyError(failure);
    }

    notifyListeners();
  }

  void _showUserFriendlyError(Failure failure) {
    // Convert technical errors to user-friendly messages
    String userMessage;

    if (failure is NetworkFailure) {
      userMessage = 'Please check your internet connection and try again.';
    } else if (failure is ServerFailure) {
      userMessage = 'Server is temporarily unavailable. Please try again later.';
    } else if (failure is ValidationFailure) {
      userMessage = 'Please check your input and try again.';
    } else if (failure is AuthenticationFailure) {
      userMessage = 'Please log in to continue.';
    } else {
      userMessage = 'An unexpected error occurred. Please try again.';
    }

    // Show snackbar or dialog
    _showErrorDialog(userMessage);
  }

  void _showErrorDialog(String message) {
    // Implementation for showing error dialog
  }
}
```

### Bloc Error Handling

```dart
// lib/features/user/presentation/bloc/user_bloc.dart
class UserBloc extends Bloc<UserEvent, UserState> {
  final GetUsersUseCase getUsers;
  final ErrorHandler errorHandler;
  final ErrorReportingService errorReporting;

  UserBloc({
    required this.getUsers,
    required this.errorHandler,
    required this.errorReporting,
  }) : super(UserInitial()) {
    on<LoadUsers>(_onLoadUsers);
  }

  Future<void> _onLoadUsers(LoadUsers event, Emitter<UserState> emit) async {
    emit(UserLoading());

    try {
      final result = await getUsers();

      result.fold(
        (failure) async {
          await errorReporting.reportError(failure, context: 'UserBloc.loadUsers');
          emit(UserError(_getUserFriendlyMessage(failure)));
        },
        (users) {
          emit(UserLoaded(users));
        },
      );
    } catch (e) {
      final failure = errorHandler.handleException(e);
      await errorReporting.reportError(failure, context: 'UserBloc.loadUsers');
      emit(UserError(_getUserFriendlyMessage(failure)));
    }
  }

  String _getUserFriendlyMessage(Failure failure) {
    if (failure is NetworkFailure) {
      return 'Please check your internet connection and try again.';
    } else if (failure is ServerFailure) {
      return 'Server is temporarily unavailable. Please try again later.';
    } else if (failure is ValidationFailure) {
      return 'Please check your input and try again.';
    } else if (failure is AuthenticationFailure) {
      return 'Please log in to continue.';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }
}
```

### Riverpod Error Handling

```dart
// lib/features/user/presentation/providers/user_provider.dart
class UserNotifier extends StateNotifier<AsyncValue<List<User>>> {
  final GetUsersUseCase getUsers;
  final ErrorHandler errorHandler;
  final ErrorReportingService errorReporting;

  UserNotifier({
    required this.getUsers,
    required this.errorHandler,
    required this.errorReporting,
  }) : super(const AsyncValue.loading());

  Future<void> loadUsers() async {
    state = const AsyncValue.loading();

    try {
      final result = await getUsers();

      result.fold(
        (failure) async {
          await errorReporting.reportError(failure, context: 'UserNotifier.loadUsers');
          state = AsyncValue.error(_getUserFriendlyMessage(failure));
        },
        (users) {
          state = AsyncValue.data(users);
        },
      );
    } catch (e) {
      final failure = errorHandler.handleException(e);
      await errorReporting.reportError(failure, context: 'UserNotifier.loadUsers');
      state = AsyncValue.error(_getUserFriendlyMessage(failure));
    }
  }

  String _getUserFriendlyMessage(Failure failure) {
    if (failure is NetworkFailure) {
      return 'Please check your internet connection and try again.';
    } else if (failure is ServerFailure) {
      return 'Server is temporarily unavailable. Please try again later.';
    } else if (failure is ValidationFailure) {
      return 'Please check your input and try again.';
    } else if (failure is AuthenticationFailure) {
      return 'Please log in to continue.';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }
}
```

## Error UI Components

### Error Widget

```dart
// lib/core/widgets/error_widget.dart
class ErrorWidget extends StatelessWidget {
  final Failure failure;
  final VoidCallback? onRetry;

  const ErrorWidget({
    Key? key,
    required this.failure,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getErrorIcon(),
              size: 64,
              color: Theme.of(context).errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              _getErrorMessage(),
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getErrorIcon() {
    if (failure is NetworkFailure) {
      return Icons.wifi_off;
    } else if (failure is ServerFailure) {
      return Icons.cloud_off;
    } else if (failure is ValidationFailure) {
      return Icons.error_outline;
    } else {
      return Icons.error;
    }
  }

  String _getErrorMessage() {
    if (failure is NetworkFailure) {
      return 'Please check your internet connection and try again.';
    } else if (failure is ServerFailure) {
      return 'Server is temporarily unavailable. Please try again later.';
    } else if (failure is ValidationFailure) {
      return 'Please check your input and try again.';
    } else if (failure is AuthenticationFailure) {
      return 'Please log in to continue.';
    } else {
      return failure.message;
    }
  }
}
```

### Error Dialog

```dart
// lib/core/widgets/error_dialog.dart
class ErrorDialog extends StatelessWidget {
  final Failure failure;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const ErrorDialog({
    Key? key,
    required this.failure,
    this.onRetry,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            _getErrorIcon(),
            color: Theme.of(context).errorColor,
          ),
          const SizedBox(width: 8),
          Text(_getErrorTitle()),
        ],
      ),
      content: Text(_getErrorMessage()),
      actions: [
        if (onRetry != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry?.call();
            },
            child: const Text('Retry'),
          ),
        TextButton(
          onPressed: onDismiss ?? () => Navigator.of(context).pop(),
          child: const Text('Dismiss'),
        ),
      ],
    );
  }

  IconData _getErrorIcon() {
    if (failure is NetworkFailure) {
      return Icons.wifi_off;
    } else if (failure is ServerFailure) {
      return Icons.cloud_off;
    } else if (failure is ValidationFailure) {
      return Icons.error_outline;
    } else {
      return Icons.error;
    }
  }

  String _getErrorTitle() {
    if (failure is NetworkFailure) {
      return 'Network Error';
    } else if (failure is ServerFailure) {
      return 'Server Error';
    } else if (failure is ValidationFailure) {
      return 'Validation Error';
    } else if (failure is AuthenticationFailure) {
      return 'Authentication Error';
    } else {
      return 'Error';
    }
  }

  String _getErrorMessage() {
    if (failure is NetworkFailure) {
      return 'Please check your internet connection and try again.';
    } else if (failure is ServerFailure) {
      return 'Server is temporarily unavailable. Please try again later.';
    } else if (failure is ValidationFailure) {
      return 'Please check your input and try again.';
    } else if (failure is AuthenticationFailure) {
      return 'Please log in to continue.';
    } else {
      return failure.message;
    }
  }
}
```

## Error Handling Best Practices

1. **Centralized Error Handling**: Use a centralized error handler to convert exceptions to failures
2. **User-Friendly Messages**: Convert technical errors to user-friendly messages
3. **Error Reporting**: Report errors to analytics for monitoring and debugging
4. **Consistent Error Types**: Use consistent error types across the application
5. **Proper Error Display**: Show appropriate error UI based on error type
6. **Retry Mechanisms**: Provide retry options for recoverable errors
7. **Error Logging**: Log errors for debugging and monitoring
8. **Graceful Degradation**: Handle errors gracefully without crashing the app

## Error Handling Configuration

```dart
// lib/core/errors/error_config.dart
class ErrorConfig {
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 1);
  static const bool enableErrorReporting = true;
  static const bool enableErrorLogging = true;

  static Map<String, String> get errorMessages => {
    'NETWORK_ERROR': 'Please check your internet connection and try again.',
    'SERVER_ERROR': 'Server is temporarily unavailable. Please try again later.',
    'VALIDATION_ERROR': 'Please check your input and try again.',
    'AUTHENTICATION_ERROR': 'Please log in to continue.',
    'UNKNOWN_ERROR': 'An unexpected error occurred. Please try again.',
  };
}
```

This comprehensive error handling guide ensures robust error management in enterprise Flutter applications, providing better user experience and easier debugging.