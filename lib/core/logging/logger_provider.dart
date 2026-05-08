import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:mudra_manager/core/logging/slf4j_printer.dart';

final loggerProvider = Provider<Logger>((ref) => _cachedLogger);

final Logger _cachedLogger = Logger(
  printer: Slf4jPrinter(),
  level: kReleaseMode ? Level.warning : Level.debug,
);

Logger getLogger() => _cachedLogger;
