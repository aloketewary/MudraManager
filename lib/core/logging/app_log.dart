import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:uuid/uuid.dart';

class AppLog {
  final Logger _logger;
  final String _tag;

  AppLog(this._logger, this._tag);

  void i(Object msg) => _logger.i('$_tag|$msg');

  void w(Object msg, [Object? error, StackTrace? st]) => 
      _logger.w('$_tag|$msg', error: error, stackTrace: st);

  void d(Object msg) => _logger.d('$_tag|$msg');

  void e(Object msg, [Object? error, StackTrace? st]) {
    _logger.e('$_tag|$msg', error: error, stackTrace: st);
  }
}

extension LoggerX on Ref {
  AppLog getLogger(String tag) {
    return AppLog(read(loggerProvider), tag);
  }
}

class LogContext {
  final String correlationId;

  LogContext(this.correlationId);

  static LogContext create() {
    return LogContext(const Uuid().v8());
  }
}