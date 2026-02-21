import 'package:logger/logger.dart';
import 'package:intl/intl.dart';

class Slf4jPrinter extends LogPrinter {
  static final _timeFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
  static const _levelWidth = 5;

  String _pad(String text, int width) {
    return text.padRight(width).substring(0, width);
  }

  String _levelLabel(Level level) {
    switch (level) {
      case Level.trace:
        return 'TRACE';
      case Level.debug:
        return 'DEBUG';
      case Level.info:
        return 'INFO ';
      case Level.warning:
        return 'WARN ';
      case Level.error:
        return 'ERROR';
      case Level.fatal:
        return 'FATAL';
      default:
        return 'INFO ';
    }
  }

  @override
  List<String> log(LogEvent event) {
    final now = _timeFormat.format(DateTime.now());
    final level = _pad(_levelLabel(event.level), _levelWidth);

    String tag = 'App';
    String message = event.message.toString();

    if (message.contains('|')) {
      final parts = message.split('|');
      tag = parts.first;
      message = parts.sublist(1).join('|');
    }

    final paddedTag = _pad(tag, 14);
    final line = '[$level] $now | $paddedTag | $message';
    
    final lines = [_colorize(event.level, line)];
    
    // Add error details if present
    if (event.error != null) {
      lines.add(_colorize(event.level, '  Error: ${event.error}'));
    }
    
    // Add stack trace if present
    if (event.stackTrace != null) {
      lines.add(_colorize(event.level, '  Stack trace:'));
      lines.addAll(event.stackTrace.toString().split('\n').map((line) => _colorize(event.level, '    $line')));
    }

    return lines;
  }

  String _colorize(Level level, String text) {
    switch (level) {
      case Level.info:
        return const AnsiColor.fg(12)(text);
      case Level.warning:
        return const AnsiColor.fg(214)(text);
      case Level.error:
      case Level.fatal:
        return const AnsiColor.fg(196)(text);
      case Level.debug:
        return const AnsiColor.fg(244)(text);
      default:
        return text;
    }
  }
}
