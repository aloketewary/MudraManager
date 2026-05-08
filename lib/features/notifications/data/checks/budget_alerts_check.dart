import 'dart:convert';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/budget.dart';
import 'package:mudra_manager/core/db/models/budget_type.dart';
import 'package:mudra_manager/core/db/models/notification_record.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/tone/tone_provider.dart';
import 'package:mudra_manager/features/notifications/data/smart_check.dart';

class BudgetAlertsCheck extends SmartCheck {
  BudgetAlertsCheck(super.isarService);

  @override
  String get type => 'budget_alerts';

  @override
  Future<void> run() async {
    final isar = await isarService.getInstance();
    final now = DateTime.now();
    final budgets =
        await isar.budgets.filter().isArchivedEqualTo(false).findAll();

    final exceeded = <String>[];
    final warnings = <String>[];

    for (final budget in budgets) {
      if (budget.recurrence == BudgetRecurrence.none &&
          budget.endDate.isBefore(now)) {
        continue;
      }

      final (start, end) = budget.getCurrentPeriodRange(now);

      double spent;
      if (budget.budgetType == BudgetType.tagWise) {
        await budget.budgetTags.load();
        final tagIds = budget.budgetTags.map((t) => t.id).toSet();
        if (tagIds.isEmpty) continue;
        final txns = await isar.transactions
            .filter()
            .isExpenseEqualTo(true)
            .dateBetween(start, end)
            .findAll();
        for (final t in txns) {
          await t.tags.load();
        }
        spent = 0;
        for (final t in txns) {
          if (t.tags.any((tag) => tagIds.contains(tag.id))) {
            spent += t.baseAmount;
          }
        }
      } else if (budget.budgetType == BudgetType.dayWise ||
          budget.budgetType == BudgetType.festival ||
          budget.budgetType == BudgetType.travel) {
        await budget.categories.load();
        final categoryIds = budget.categories.map((c) => c.id).toList();
        final txns = await isar.transactions
            .filter()
            .isExpenseEqualTo(true)
            .dateBetween(start, end)
            .findAll();
        if (categoryIds.isEmpty) {
          spent = txns.fold<double>(0.0, (s, t) => s + t.baseAmount);
        } else {
          for (final t in txns) {
            t.category.loadSync();
          }
          spent = txns
              .where((t) =>
                  t.category.value != null &&
                  categoryIds.contains(t.category.value!.id,),)
              .fold<double>(0.0, (s, t) => s + t.baseAmount);
        }
      } else {
        await budget.categories.load();
        final categoryIds = budget.categories.map((c) => c.id).toList();
        if (categoryIds.isEmpty) continue;
        final txns = await isar.transactions
            .filter()
            .isExpenseEqualTo(true)
            .dateBetween(start, end)
            .findAll();
        for (final t in txns) {
          t.category.loadSync();
        }
        spent = txns
            .where((t) =>
                t.category.value != null &&
                categoryIds.contains(t.category.value!.id,),)
            .fold<double>(0.0, (s, t) => s + t.baseAmount);
      }

      final pct = budget.amount > 0 ? (spent / budget.amount * 100) : 0.0;

      if (pct < 80 &&
          (budget.notifiedAt80 || budget.notifiedAt90 || budget.notifiedAt100)) {
        budget.notifiedAt80 = false;
        budget.notifiedAt90 = false;
        budget.notifiedAt100 = false;
        await isar.writeTxn(() => isar.budgets.put(budget));
      }

      if (pct >= 100 && !budget.notifiedAt100) {
        exceeded.add(budget.name);
        budget.notifiedAt100 = true;
        await isar.writeTxn(() => isar.budgets.put(budget));
      } else if (pct >= 80 && !budget.notifiedAt80 && !budget.notifiedAt100) {
        warnings.add(budget.name);
        budget.notifiedAt80 = true;
        await isar.writeTxn(() => isar.budgets.put(budget));
      }
    }

    if (exceeded.isNotEmpty) {
      final n = exceeded.length;
      await SmartNotificationEmitter.emit(
        isar,
        type: 'budget_exceeded',
        title: Tone.appL10n?.notif_budgetsOverLimitTitle(n) ??
            '🚨 $n budget${n > 1 ? 's' : ''} over limit',
        body: n == 1
            ? Tone.appL10n?.notif_budgetExceededBody(exceeded.first) ??
                '${exceeded.first} is over budget — time to review'
            : Tone.appL10n
                    ?.notif_budgetExceededBodyMulti(exceeded.join(', ')) ??
                '${exceeded.join(', ')} are over budget',
        channel: 'budget_alerts',
        channelName: 'Budget Alerts',
        priority: NotificationPriority.urgent,
        primaryAction: 'Review Budgets',
        actionData: jsonEncode({'type': 'view_budget'}),
      );
    } else if (warnings.isNotEmpty) {
      final n = warnings.length;
      await SmartNotificationEmitter.emit(
        isar,
        type: 'budget_warning',
        title: Tone.appL10n?.notif_budgetsGettingTightTitle(n) ??
            '⚠️ $n budget${n > 1 ? 's' : ''} getting tight',
        body: n == 1
            ? Tone.appL10n?.notif_budgetWarningBody(warnings.first) ??
                '${warnings.first} is nearing the limit'
            : Tone.appL10n
                    ?.notif_budgetWarningBodyMulti(warnings.join(', ')) ??
                '${warnings.join(', ')} are nearing their limits',
        channel: 'budget_alerts',
        channelName: 'Budget Alerts',
        priority: NotificationPriority.high,
        primaryAction: 'View Details',
        actionData: jsonEncode({'type': 'view_budget'}),
      );
    }
  }
}
