import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Emits the current date and re-emits at midnight or when re-evaluated
/// after app resume. Time-sensitive providers (budgets, alerts) watch
/// this to refresh when a period boundary crosses without any DB write.
final dateChangeProvider = StreamProvider<DateTime>((ref) async* {
  DateTime today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  var current = today();
  yield current;

  await for (final _ in Stream.periodic(const Duration(seconds: 60))) {
    final now = today();
    if (now != current) {
      current = now;
      yield now;
    }
  }
});
