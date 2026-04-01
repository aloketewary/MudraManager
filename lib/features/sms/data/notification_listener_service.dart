import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';
import 'package:mudra_manager/core/services/notification_service.dart';
import 'package:mudra_manager/core/tone/tone_provider.dart';
import 'package:mudra_manager/features/sms/data/sms_processor_service.dart';

class NotificationListenerBridge with WidgetsBindingObserver {
  static final NotificationListenerBridge instance =
      NotificationListenerBridge._();
  static final _log = AppLog(getLogger(), 'NotifListener');
  static const _channel = MethodChannel('com.mudramanager.app/notifications');
  bool _initialized = false;
  bool _isDraining = false;

  NotificationListenerBridge._();

  void initialize() {
    if (_initialized) return;
    _initialized = true;
    _channel.setMethodCallHandler(_handleMethodCall);
    WidgetsBinding.instance.addObserver(this);
    _log.i('Notification listener bridge initialized');
    _drainQueue();
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

  Future<void> _drainQueue() async {
    if (_isDraining) return;
    if (!SharedPrefsUtil.instance.getSmsImportEnabled()) return;
    _isDraining = true;
    try {

      final result = await _channel.invokeMethod<List>('drainQueue');
      if (result == null || result.isEmpty) return;

      _log.i('Processing ${result.length} queued notifications');

      int approved = 0;
      int pending = 0;
      int needsReview = 0;
      double totalAmount = 0;

      for (final item in result) {
        final data = Map<String, dynamic>.from(item as Map);
        final text = data['text'] as String? ?? '';
        final title = data['title'] as String? ?? '';
        final timestamp = data['timestamp'] as int? ?? 0;

        if (timestamp == 0) continue;

        final body = text.isNotEmpty ? text : title;
        if (body.isEmpty) continue;

        final sender = title.isNotEmpty ? title : 'UNKNOWN';

        final parseResult = await SmsProcessorService.instance.parseAndSaveTransaction(
          body: body,
          address: sender,
          sender: sender,
          timestamp: timestamp,
        );

        switch (parseResult) {
          case ParseResult.approved:
            approved++;
            // Try to extract amount for the notification summary
            final amountMatch = RegExp(r'(?:Rs\.?\s*|INR\s*|₹\s*)([\d,]+(?:\.\d{1,2})?)')
                .firstMatch(body);
            if (amountMatch != null) {
              totalAmount += double.tryParse(
                    amountMatch.group(1)?.replaceAll(',', '') ?? '',
                  ) ?? 0;
            }
          case ParseResult.pending:
            pending++;
          case ParseResult.needsReview:
            needsReview++;
          default:
            break;
        }
      }

      _log.i('Queue drained: $approved approved, $pending pending, $needsReview needs review');
      _showSmartNotification(approved, pending, needsReview, totalAmount);
    } catch (e) {
      _log.e('Failed to drain notification queue', e);
    } finally {
      _isDraining = false;
    }
  }

  static const _notifId = 9900;

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
      final amountStr = totalAmount > 0 ? ' of ₹${totalAmount.toStringAsFixed(0)}' : '';
      title = '✅ Got it!';
      body = tone.singleApproved(amountStr);
    } else if (approved > 0 && pending == 0 && needsReview == 0) {
      final amountStr = totalAmount > 0 ? ' totalling ₹${totalAmount.toStringAsFixed(0)}' : '';
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
}
