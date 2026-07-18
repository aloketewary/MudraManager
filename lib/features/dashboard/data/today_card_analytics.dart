import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';
import 'package:mudra_manager/features/dashboard/presentation/widgets/daily_briefing_card.dart';

/// Lightweight analytics for Today Card validation.
///
/// Tracks behavioral sequences — not button clicks.
/// Designed to answer:
/// 1. Did user visit destination after seeing alert?
/// 2. Did bill/budget get resolved after alert?
/// 3. How quickly do users act?
/// 4. Does engagement decay over time?
/// 5. Which alert types drive action?
///
/// Storage: SharedPrefs JSON. No Isar schema changes needed.
/// Retention: Rolling 30-day window.
class TodayCardAnalytics {
  static const _eventsKey = 'today_card_events';
  static const _maxEvents = 200;
  static const _retentionDays = 30;

  /// Record a session start (dashboard opened).
  /// Creates natural grouping for sequence analysis.
  static void recordSessionStart() {
    _addEvent({
      'type': 'sessionStart',
      'ts': DateTime.now().toIso8601String(),
    });
  }

  /// Record that Today Card was shown in healthy state.
  static void recordCardShownHealthy() {
    _addEvent({
      'type': 'cardShownHealthy',
      'ts': DateTime.now().toIso8601String(),
    });
  }

  /// Record that Today Card was shown with an alert.
  /// Includes rich metadata about the alert for later analysis.
  static void recordCardShownAlert({
    required BriefingSignalType signalType,
    Map<String, dynamic> metadata = const {},
  }) {
    _addEvent({
      'type': 'cardShownAlert',
      'ts': DateTime.now().toIso8601String(),
      'signal': signalType.name,
      ...metadata,
    });
  }

  /// Record that user tapped the CTA on a warning card.
  static void recordCtaTapped({
    required BriefingSignalType signalType,
    required String destination,
  }) {
    _addEvent({
      'type': 'ctaTapped',
      'ts': DateTime.now().toIso8601String(),
      'signal': signalType.name,
      'dest': destination,
    });
  }

  /// Record that user opened a destination screen (budget/bills/etc).
  /// Called from destination screens — not from Today Card.
  static void recordDestinationOpened({
    required String destination,
  }) {
    _addEvent({
      'type': 'destinationOpened',
      'ts': DateTime.now().toIso8601String(),
      'dest': destination,
    });
  }

  /// Record that user opened Accounts / Net Worth screen.
  /// Trust proxy: are users still verifying balance manually?
  static void recordAccountsOpened() {
    _addEvent({
      'type': 'accountsOpened',
      'ts': DateTime.now().toIso8601String(),
    });
  }

  /// Record bill resolution (paid/executed) after alert was shown.
  static void recordBillResolved({
    required String billName,
    int? daysAfterAlert,
  }) {
    _addEvent({
      'type': 'billResolved',
      'ts': DateTime.now().toIso8601String(),
      'bill': billName,
      if (daysAfterAlert != null) 'daysAfter': daysAfterAlert,
    });
  }

  /// Record budget resolution (edited/adjusted) after alert was shown.
  static void recordBudgetResolved({
    required String budgetName,
    int? daysAfterAlert,
  }) {
    _addEvent({
      'type': 'budgetResolved',
      'ts': DateTime.now().toIso8601String(),
      'budget': budgetName,
      if (daysAfterAlert != null) 'daysAfter': daysAfterAlert,
    });
  }

  /// Record that an alert disappeared without user interaction.
  /// Fired when: alert was shown in session N, but session N+1 shows
  /// healthy state with no CTA tap or destination visit in between.
  static void recordAlertDismissedNaturally({
    required BriefingSignalType signalType,
  }) {
    _addEvent({
      'type': 'alertDismissedNaturally',
      'ts': DateTime.now().toIso8601String(),
      'signal': signalType.name,
    });
  }

  // ─────────────────────────────────────────────────────────
  // QUERY METHODS (for dev menu / future analysis)
  // ─────────────────────────────────────────────────────────

  /// Get all events within retention window.
  static List<Map<String, dynamic>> getEvents() {
    final raw = SharedPrefsUtil.instance.getString(_eventsKey);
    if (raw == null) return [];
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return _pruneOld(list);
  }

  /// Count alerts shown in a date range.
  static int alertsShownInRange(DateTime start, DateTime end) {
    return getEvents().where((e) {
      final ts = DateTime.parse(e['ts'] as String);
      return e['type'] == 'cardShownAlert' &&
          ts.isAfter(start) &&
          ts.isBefore(end);
    }).length;
  }

  /// Count destination visits within 24h of any alert.
  static int destinationVisitsAfterAlert() {
    final events = getEvents();
    int count = 0;

    for (int i = 0; i < events.length; i++) {
      final e = events[i];
      if (e['type'] != 'cardShownAlert') continue;
      final alertTime = DateTime.parse(e['ts'] as String);
      final cutoff = alertTime.add(const Duration(hours: 24));

      for (int j = i + 1; j < events.length; j++) {
        final next = events[j];
        final nextTime = DateTime.parse(next['ts'] as String);
        if (nextTime.isAfter(cutoff)) break;
        if (next['type'] == 'destinationOpened') {
          count++;
          break;
        }
      }
    }
    return count;
  }

  /// Weekly engagement: card shown events per week over last 4 weeks.
  static List<int> weeklyEngagement() {
    final now = DateTime.now();
    final weeks = <int>[];
    for (int w = 0; w < 4; w++) {
      final start = now.subtract(Duration(days: (w + 1) * 7));
      final end = now.subtract(Duration(days: w * 7));
      final count = getEvents().where((e) {
        final ts = DateTime.parse(e['ts'] as String);
        final type = e['type'] as String;
        return (type == 'ctaTapped' || type == 'destinationOpened') &&
            ts.isAfter(start) &&
            ts.isBefore(end);
      }).length;
      weeks.add(count);
    }
    return weeks.reversed.toList();
  }

  /// Get the last alert signal type (for natural dismissal detection).
  static BriefingSignalType? getLastAlertSignal() {
    final events = getEvents();
    for (int i = events.length - 1; i >= 0; i--) {
      if (events[i]['type'] == 'cardShownAlert') {
        final name = events[i]['signal'] as String?;
        if (name == null) return null;
        return BriefingSignalType.values.firstWhere(
          (e) => e.name == name,
          orElse: () => BriefingSignalType.billDueToday,
        );
      }
    }
    return null;
  }

  /// Check if user interacted after last alert (for dismissal detection).
  static bool hasInteractionAfterLastAlert() {
    final events = getEvents();
    int lastAlertIdx = -1;
    for (int i = events.length - 1; i >= 0; i--) {
      if (events[i]['type'] == 'cardShownAlert') {
        lastAlertIdx = i;
        break;
      }
    }
    if (lastAlertIdx == -1) return false;

    for (int i = lastAlertIdx + 1; i < events.length; i++) {
      final type = events[i]['type'] as String;
      if (type == 'ctaTapped' ||
          type == 'destinationOpened' ||
          type == 'billResolved' ||
          type == 'budgetResolved') {
        return true;
      }
    }
    return false;
  }

  /// Clear all analytics data.
  static Future<void> reset() async {
    await SharedPrefsUtil.instance.setString(_eventsKey, '[]');
  }

  // ─────────────────────────────────────────────────────────
  // INTERNALS
  // ─────────────────────────────────────────────────────────

  static void _addEvent(Map<String, dynamic> event) {
    final raw = SharedPrefsUtil.instance.getString(_eventsKey);
    final list = raw != null
        ? (jsonDecode(raw) as List).cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];

    list.add(event);

    // Prune old + cap size
    final pruned = _pruneOld(list);
    final capped = pruned.length > _maxEvents
        ? pruned.sublist(pruned.length - _maxEvents)
        : pruned;

    SharedPrefsUtil.instance.setString(_eventsKey, jsonEncode(capped));
  }

  static List<Map<String, dynamic>> _pruneOld(
    List<Map<String, dynamic>> events,
  ) {
    final cutoff = DateTime.now().subtract(
      const Duration(days: _retentionDays),
    );
    return events.where((e) {
      final ts = DateTime.tryParse(e['ts'] as String? ?? '');
      return ts != null && ts.isAfter(cutoff);
    }).toList();
  }
}

/// Riverpod provider for accessing analytics in dev menu.
final todayCardAnalyticsProvider = Provider<List<Map<String, dynamic>>>((ref) {
  return TodayCardAnalytics.getEvents();
});
