import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/extensions/field_encryption_ext.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/notification_record.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:mudra_manager/core/services/notification_service.dart';
import 'package:mudra_manager/core/tone/tone_provider.dart';
import 'dart:convert';

import 'package:mudra_manager/features/notifications/data/smart_check.dart';
import 'package:mudra_manager/features/notifications/data/all_checks.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SmartNotificationService {
  static final SmartNotificationService instance =
      SmartNotificationService._(IsarService());
  static final AppLog _log = AppLog(getLogger(), 'SmartNotificationService');
  final IsarService _isarService;

  SmartNotificationService._(this._isarService);

  /// All OS notifications route through NotificationService gateway.
  /// This method only handles in-app record persistence + dedup.
  Future<void> _emit(
    Isar isar, {
    required String type,
    required String title,
    required String body,
    required String channel,
    required String channelName,
    NotificationPriority priority = NotificationPriority.normal,
    NotificationCategory category = NotificationCategory.financial,
    String? primaryAction,
    String? secondaryAction,
    String? actionData,
    int? budgetId,
  }) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final existing = await isar.notificationRecords
        .filter()
        .typeEqualTo(type)
        .timestampGreaterThan(startOfDay)
        .findFirst();
    if (existing != null) return;

    final record = NotificationRecord()
      ..title = title
      ..body = body
      ..timestamp = DateTime.now()
      ..isRead = false
      ..type = type
      ..priority = priority
      ..category = category
      ..source = NotificationSource.smart
      ..primaryAction = primaryAction
      ..secondaryAction = secondaryAction
      ..actionData = actionData
      ..budgetId = budgetId;

    record.encryptFields(); // Sentinel: Encrypt smart alert content (contains budget/spending info)
    await isar.writeTxn(() => isar.notificationRecords.put(record));

    String? payload;
    if (actionData != null) {
      try {
        final data = jsonDecode(actionData) as Map<String, dynamic>;
        payload = data['type'] as String?;
      } catch (_) {}
    }

    await NotificationService.showLocalNotification(
      id: type.hashCode.abs() % 2147483647,
      title: title,
      body: body,
      payload: payload,
      dedupKey: type,
    );

    _log.i('Smart alert emitted: $type');
  }

  // ─── Extracted checks (independently testable) ───
  late final List<SmartCheck> _checks = [
    MorningInsightCheck(_isarService),
    UnusualSpendingCheck(_isarService),
    PendingSmsCheck(_isarService),
    MoneyLeakCheck(_isarService),
    WeeklyRecapNudgeCheck(_isarService),
    BudgetAlertsCheck(_isarService),
    UpcomingBillsCheck(_isarService),
    BalanceDropCheck(_isarService),
    SavingsOpportunityCheck(_isarService),
  ];

  // ─── MASTER RUN ───
  Future<void> runSmartChecks() async {
    final prefs = await SharedPreferences.getInstance();
    final smartEnabled = prefs.getBool('smart_alerts_enabled') ?? true;

    // Re-engagement always runs (has its own toggle)
    final reEngagement = ReEngagementCheck(_isarService);
    try {
      await reEngagement.run();
    } catch (e) {
      _log.e('Smart check "re_engagement" failed', e);
    }

    if (!smartEnabled) return;

    for (final check in _checks) {
      try {
        await check.run();
      } catch (e) {
        _log.e('Smart check "${check.type}" failed', e);
      }
    }
    _log.i('All smart checks completed');
  }

  // ─── EVENT-DRIVEN METHODS (called from other services) ───

  /// Notify when a recurring bill is actually paid (auto-created or SMS-matched).
  Future<void> notifyBillPaid({
    required String description,
    required double amount,
    required int billId,
    required bool wasSmsMatched,
  }) async {
    final isar = await _isarService.getInstance();
    await _emit(
      isar,
      type: 'bill_paid_$billId',
      title: wasSmsMatched
          ? Tone.appL10n?.notif_billPaidAutoTitle(description) ??
              '✅ $description — auto-matched'
          : Tone.appL10n?.notif_billPaidRecordedTitle(description) ??
              '✅ $description — recorded',
      body: Tone.current.billPaidNotif(
        description,
        amount.toStringAsFixed(0),
      ),
      channel: 'bill_reminders',
      channelName: 'Bill Reminders',
      priority: NotificationPriority.normal,
      primaryAction: 'View Bills',
      actionData: jsonEncode({'type': 'view_bills'}),
    );
  }

  /// Notify when budget is exceeded (called from BudgetAlertService).
  Future<void> notifyBudgetExceeded({
    required List<String> names,
    required double spent,
    required double limit,
  }) async {
    final isar = await _isarService.getInstance();
    final n = names.length;
    await _emit(
      isar,
      type: 'budget_exceeded_realtime',
      title: Tone.appL10n?.notif_budgetsOverLimitTitle(n) ??
          '🚨 $n budget${n > 1 ? 's' : ''} exceeded!',
      body: n == 1
          ? Tone.appL10n?.notif_budgetExceededBody(names.first) ??
              '${names.first} is over budget — time to review'
          : Tone.appL10n
                  ?.notif_budgetExceededBodyMulti(names.join(', ')) ??
              '${names.join(', ')} are over budget',
      channel: 'budget_alerts',
      channelName: 'Budget Alerts',
      priority: NotificationPriority.urgent,
      primaryAction: 'Review Budgets',
      actionData: jsonEncode({'type': 'view_budget'}),
    );
  }

  /// Notify when budget is near limit (called from BudgetAlertService).
  Future<void> notifyBudgetWarning({
    required List<String> names,
    required double percentage,
  }) async {
    final isar = await _isarService.getInstance();
    final n = names.length;
    await _emit(
      isar,
      type: 'budget_warning_realtime',
      title: Tone.appL10n?.notif_budgetsGettingTightTitle(n) ??
          '⚠️ $n budget${n > 1 ? 's' : ''} near limit',
      body: n == 1
          ? Tone.appL10n?.notif_budgetWarningPctBody(
                  names.first, percentage.toStringAsFixed(0),) ??
              '${names.first}: ${percentage.toStringAsFixed(0)}% used'
          : Tone.appL10n
                  ?.notif_budgetWarningBodyMulti(names.join(', ')) ??
              '${names.join(', ')} are nearing their limits',
      channel: 'budget_alerts',
      channelName: 'Budget Alerts',
      priority: NotificationPriority.high,
      primaryAction: 'View Details',
      actionData: jsonEncode({'type': 'view_budget'}),
    );
  }
}
