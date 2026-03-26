import 'dart:async';

class RefreshHelper {
  static const _minDuration = Duration(milliseconds: 1500);

  /// Runs [action] and ensures the returned Future takes at least [_minDuration].
  static Future<void> withMinDuration(Future<void> Function() action) async {
    await Future.wait([
      action(),
      Future.delayed(_minDuration),
    ]);
  }
}
