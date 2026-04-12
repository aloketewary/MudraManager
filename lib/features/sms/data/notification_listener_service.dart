import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:mudra_manager/core/db/models/pending_notifications.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';
import 'package:mudra_manager/core/services/notification_service.dart';
import 'package:mudra_manager/core/tone/tone_provider.dart';
import 'package:mudra_manager/features/sms/data/sms_processor_service.dart';
import 'package:uuid/uuid.dart';

class NotificationListenerBridge with WidgetsBindingObserver {
  static final NotificationListenerBridge instance =
      NotificationListenerBridge._();
  static final _log = AppLog(getLogger(), 'NotifListener');
  static const _channel = MethodChannel('com.mudramanager.app/notifications');
  bool _initialized = false;
  bool _isDraining = false;

  // Per-transaction notification rate limit: max 3 per minute
  static const _maxPerMinute = 3;
  final List<DateTime> _recentNotifTimestamps = [];
  int _suppressedCount = 0;
  final Queue<String> _recentHashQueue = Queue();
  final Set<String> _recentHashSet = {};
  NotificationListenerBridge._();
  final Queue<PendingNotifications> _retryQueue = Queue();
  final List<PendingNotifications> _deadLetterQueue = [];
  late final Isar _isar;
  Timer? _retryTimer;

  void initialize({
    required Isar isar,
  }) {
    if (_initialized) return;
    _isar = isar;
    _initialized = true;
    _channel.setMethodCallHandler(_handleMethodCall);
    WidgetsBinding.instance.addObserver(this);
    _log.i('Notification listener bridge initialized');
    _loadRetryQueueFromDb();
    _drainQueue();
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _processRetryQueue();
    });
  }

  void dispose() {
    _retryTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _channel.setMethodCallHandler(null);
    _log.i('Notification listener bridge disposed');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _log.i('App resumed, draining notification queue');
      _drainQueue();
    }
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onDrainQueue') {
      await _drainQueue();
    }
  }

  void _processRetryQueue() async {
    final now = DateTime.now();

    final toRetry =
        _retryQueue.where((e) => e.nextRetryAt.isBefore(now)).toList();

    for (final item in toRetry) {
      _retryQueue.remove(item);
      await _safeProcess(item, isRetry: true);
    }
  }

  bool _isDuplicate(String hash) {
    if (hash.isEmpty) {
      _log.w('Missing hash, skipping unsafe processing');
      return true;
    }
    if (_recentHashSet.contains(hash)) return true;

    _recentHashSet.add(hash);
    _recentHashQueue.addLast(hash);

    if (_recentHashQueue.length > 200) {
      final oldest = _recentHashQueue.removeFirst();
      _recentHashSet.remove(oldest);
    }

    return false;
  }

  String _detectSender(String title, String body) {
    if (title.isNotEmpty && title.length < 30) return title;

    final bankPattern = RegExp(r'([A-Z]{2,}(?:\sBANK)?)');
    final match = bankPattern.firstMatch(body);
    if (match != null) return match.group(1)!;

    return 'UNKNOWN';
  }

  Future<void> _drainQueue() async {
    if (_isDraining) {
      _log.w('Drain already in progress, skipping');
      return;
    }
    final correlationId = const Uuid().v7();
    _processRetryQueue();
    if (!SharedPrefsUtil.instance.getSmsImportEnabled()) return;
    _isDraining = true;
    try {
      final result = await _channel.invokeMethod<List>('drainQueue');
      if (result == null || result.isEmpty) return;

      _log.i('Processing ${result.length} queued notifications');

      int approved = 0, pending = 0, needsReview = 0;
      double totalAmount = 0;
      _suppressedCount = 0;

      for (final item in result) {
        final data = Map<String, dynamic>.from(item as Map);
        final text = data['text'] as String? ?? '';
        final title = data['title'] as String? ?? '';
        final timestamp = data['timestamp'] as int? ?? 0;
        final hash = data['hash'] as String? ?? '';

        if (timestamp == 0) continue;

        final rawBody = text.isNotEmpty ? text : title;
        if (rawBody.trim().isEmpty) continue;

        final sender = _detectSender(title, rawBody);

        final parseResult = await _safeProcess(
          PendingNotifications.create(
            body: rawBody,
            sender: sender,
            timestamp: timestamp,
            hash: hash,
          ),
        );

        switch (parseResult) {
          case ParseResult.approved:
            approved++;
            final matches = RegExp(
              r'(?:(?:[\p{Sc}]|[A-Z]{3})\s*)?(\d{1,3}(?:[,\s.]\d{3})*(?:[.,]\d{1,2})?)',
              unicode: true,
            ).allMatches(rawBody);

            double txnAmount = 0;

            for (final m in matches) {
              final value = parseAmount(m.group(1) ?? '');

              // heuristic: ignore large "balance-like" values
              if (value > 0 && value < 10000000) {
                // tweak if needed
                txnAmount = value;
                break;
              }
            }

            totalAmount += txnAmount;
            _showPerTxnNotification(
              isApproved: true,
              amount: txnAmount,
              sender: sender,
              index: approved,
            );
            break;
          case ParseResult.pending:
          case ParseResult.needsReview:
            pending++;
            _showPerTxnNotification(
              isApproved: false,
              amount: 0,
              sender: sender,
              index: pending,
            );
            break;
          case ParseResult.duplicate:
            _log.i('Duplicate transaction skipped');
            break;
          default:
            break;
        }
      }

      _log.i(
        'Queue drained: $approved approved, $pending pending, $needsReview needs review',
      );
      if (_suppressedCount > 0) {
        _showSmartNotification(approved, pending, needsReview, totalAmount);
      }
    } catch (e) {
      _log.e('Failed to drain notification queue', e);
    } finally {
      _isDraining = false;
    }
  }

  static const _notifId = 9900;

  /// Rate-limited per-transaction notification.
  /// Max [_maxPerMinute] in any rolling 60s window.
  void _showPerTxnNotification({
    required bool isApproved,
    required double amount,
    required String sender,
    required int index,
  }) {
    final now = DateTime.now();
    _recentNotifTimestamps.removeWhere(
      (t) => now.difference(t).inSeconds > 60,
    );
    if (_recentNotifTimestamps.length >= _maxPerMinute) {
      _suppressedCount++;
      return;
    }
    _recentNotifTimestamps.add(now);

    final String title;
    final String body;

    if (isApproved && amount > 0) {
      title = '✅ Transaction logged';
      body =
          '${formatCurrency(amount, code: BaseCurrency.code, decimals: 0)} from $sender — auto-saved';
    } else if (isApproved) {
      title = '✅ Transaction logged';
      body = 'From $sender — auto-saved';
    } else {
      title = '👀 Needs your review';
      body = 'Transaction from $sender — tap to review';
    }

    NotificationService.showLocalNotification(
      id: DateTime.now().microsecondsSinceEpoch % 100000000,
      title: title,
      body: body,
      payload: 'sms_activity',
      bypassThrottle: true,
    );
  }

  void _showSmartNotification(
    int approved,
    int pending,
    int needsReview,
    double totalAmount,
  ) {
    final total = approved + pending + needsReview;
    if (total == 0) return;

    final tone = Tone.current;
    String title;
    String body;

    if (total == 1 && approved == 1) {
      final amountStr = totalAmount > 0
          ? ' of ${formatCurrency(totalAmount, code: BaseCurrency.code, decimals: 0)}'
          : '';
      title = '✅ Got it!';
      body = tone.singleApproved(amountStr);
    } else if (approved > 0 && pending == 0 && needsReview == 0) {
      final amountStr = totalAmount > 0
          ? ' totalling ${formatCurrency(totalAmount, code: BaseCurrency.code, decimals: 0)}'
          : '';
      title = '✅ All caught up!';
      body = tone.allApproved(approved, amountStr);
    } else if (needsReview > 0 || pending > 0) {
      final reviewCount = pending + needsReview;
      if (approved > 0) {
        title = '📋 Almost there!';
        body = tone.mixedResults(approved, reviewCount);
      } else {
        title = '👋 Hey, need your help!';
        body = tone.allNeedReview(reviewCount);
      }
    } else {
      return;
    }

    NotificationService.showLocalNotification(
      id: _notifId,
      title: title,
      body: body,
      payload: 'sms_activity',
    );
  }

  static Future<bool> isPermissionGranted() async {
    try {
      final result = await _channel.invokeMethod<bool>('isListenerEnabled');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> openSettings() async {
    try {
      await _channel.invokeMethod('openListenerSettings');
    } catch (_) {}
  }

  double parseAmount(String raw) {
    if (raw.trim().isEmpty) return 0;

    // 1. Remove currency symbols & unwanted chars (keep digits, separators)
    String cleaned = raw.replaceAll(RegExp(r'[^\d.,]'), '');

    if (cleaned.isEmpty) return 0;

    // 2. If both '.' and ',' exist → detect format
    if (cleaned.contains('.') && cleaned.contains(',')) {
      final lastDot = cleaned.lastIndexOf('.');
      final lastComma = cleaned.lastIndexOf(',');

      if (lastDot > lastComma) {
        // US/India style: 1,234.56
        cleaned = cleaned.replaceAll(',', '');
      } else {
        // European style: 1.234,56
        cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
      }
    }

    // 3. Only comma exists
    else if (cleaned.contains(',')) {
      final parts = cleaned.split(',');

      if (parts.length > 1 && parts.last.length == 2) {
        // Likely decimal: 1234,56 → 1234.56
        cleaned = cleaned.replaceAll(',', '.');
      } else {
        // Thousand separator: 1,234 → 1234
        cleaned = cleaned.replaceAll(',', '');
      }
    }

    // 4. Only dot exists → assume standard decimal (safe default)
    // If only dot and looks like thousand format
    if (cleaned.contains('.') && !cleaned.contains(',')) {
      final parts = cleaned.split('.');
      if (parts.length > 1 && parts.last.length == 3) {
        cleaned = cleaned.replaceAll('.', '');
      }
    }

    // 5. Edge case: multiple dots (bad format like 1.234.567)
    final dotCount = '.'.allMatches(cleaned).length;
    if (dotCount > 1) {
      // Assume all but last are thousand separators
      final lastDot = cleaned.lastIndexOf('.');
      cleaned = cleaned.substring(0, lastDot).replaceAll('.', '') +
          cleaned.substring(lastDot);
    }

    return double.tryParse(cleaned) ?? 0;
  }

  Future<ParseResult> _safeProcess(
    PendingNotifications item, {
    bool isRetry = false,
  }) async {
    try {
      final result = await SmsProcessorService.instance.parseAndSaveTransaction(
        body: item.body,
        address: item.sender,
        sender: item.sender,
        timestamp: item.timestamp,
      );

      // ✅ SUCCESS → remove from DB
      if (result == ParseResult.approved ||
          result == ParseResult.pending ||
          result == ParseResult.needsReview) {
        await _isar.writeTxn(() async {
          await _isar.pendingNotifications.delete(item.id); // ensure id exists
        });
      }

      return result;
    } catch (e) {
      _log.e('Processing failed for ${item.hash}', e);

      item.retryCount++;

      if (item.retryCount <= 3) {
        // exponential backoff
        final base = 2 * item.retryCount;
        final jitter = Random().nextInt(3); // 0–2 sec
        item.nextRetryAt = DateTime.now().add(
          Duration(seconds: base + jitter),
        );

        await _saveRetryToDb(item);
        if (!_retryQueue.any((e) => e.hash == item.hash)) {
          _retryQueue.add(item);
        }
      } else {
        _deadLetterQueue.add(item);
        _log.w('Moved to dead letter queue: ${item.hash}');
      }

      return ParseResult.error;
    }
  }

  Future<void> _saveRetryToDb(PendingNotifications item) async {
    await _isar.writeTxn(() async {
      await _isar.pendingNotifications.putByHash(item);
    });
  }

  Future<void> _loadRetryQueueFromDb() async {
    final pendingItems = await _isar.pendingNotifications.where().findAll();
    _retryQueue.addAll(pendingItems);
    _log.i('Loaded ${pendingItems.length} pending notifications from DB');
  }
}
