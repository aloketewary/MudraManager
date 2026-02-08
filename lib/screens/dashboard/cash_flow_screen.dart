import 'package:go_router/go_router.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/db/filter_type.dart' show FilterType;
import 'package:mudra_manager/l10n/app_localizations.dart'
    show AppLocalizations;
import 'package:mudra_manager/providers/filter_provider.dart';
import 'package:mudra_manager/screens/reusable/animated_balance.dart';
import 'package:mudra_manager/screens/reusable/responseive_layout_builder.dart';

import 'package:mudra_manager/util/localization_extension.dart';

class CashFlowScreen extends ConsumerStatefulWidget {
  final double globalPadding;

  const CashFlowScreen({super.key, this.globalPadding = 16.0});

  @override
  ConsumerState<CashFlowScreen> createState() => _CashFlowScreenState();
}

class _CashFlowScreenState extends ConsumerState<CashFlowScreen> {
  double leftBoxWidthFactor = 0.5;
  double rightBoxWidthFactor = 0.5;
  double tiltAngleDegrees = 20.0;
  double tiltExpenseAngleDegrees = 20.0;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final filter = ref.watch(filterProvider);
    final now = DateTime.now();
    final ctxt = AppLocalizations.of(context)!;

    DateTime startDate;
    DateTime endDate;

    switch (filter) {
      case FilterType.day:
        startDate = DateTime(now.year, now.month, now.day);
        endDate = startDate;
        break;
      case FilterType.week:
        startDate = now.subtract(Duration(days: now.weekday - 1));
        endDate = startDate.add(const Duration(days: 6));
        break;
      case FilterType.month:
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(
          now.year,
          now.month + 1,
          1,
        ).subtract(const Duration(days: 1));
        break;
      case FilterType.year:
        startDate = DateTime(now.year, 1, 1);
        endDate = DateTime(
          now.year + 1,
          1,
          1,
        ).subtract(const Duration(days: 1));
        break;
      case FilterType.all:
        // Fallback values, or fetch min/max from transactions if needed
        startDate = DateTime.fromMillisecondsSinceEpoch(0);
        endDate = now;
        break;
    }

    final summary = ref.watch(filteredDashboardTransactionsProvider);
    return summary.when(
      skipLoadingOnReload: true,
      data: (data) {
        final income = data['income'] ?? 0.0;
        final expense = data['expense'] ?? 0.0;
        final total = income - expense;
        return Padding(
          padding: EdgeInsets.all(widget.globalPadding),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      ctxt.dashboard_cash_flow_text,
                      style: textTheme.titleLarge?.copyWith(
                        color: color.primary,
                      ),
                    ),
                    Hero(
                      tag: 'cashFlowPage',
                      child: TextButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          context.push('/transactions');
                        },
                        child: const Text('View All'),
                      ),
                    ),
                  ],
                ),
              ),
              ResponsiveLayoutBuilder(
                sizedBoxHeight: 350,
                columnWidget: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    buildCashFlowCard(
                      false,
                      income,
                      startDate,
                      endDate,
                      filter,
                    ),
                    SizedBox(height: 12),
                    buildCashFlowCard(
                      true,
                      expense,
                      startDate,
                      endDate,
                      filter,
                    ),
                  ],
                ),
                rowWidget: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    buildCashFlowCard(
                      false,
                      income,
                      startDate,
                      endDate,
                      filter,
                    ),
                    buildCashFlowCard(
                      true,
                      expense,
                      startDate,
                      endDate,
                      filter,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading:
          () => Container(
            width: 120,
            height: 170,
            margin: const EdgeInsets.only(right: 8.0),
            child: Center(child: CircularProgressIndicator(value: 25)),
          ),
      error: (e, _) => Center(child: Text("Error: $e")),
    );
  }

  Widget buildCashFlowCard(
    bool isExpense,
    double value,
    DateTime startDate,
    DateTime endDate,
    FilterType filter,
  ) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;
    final tiltAngleRadians = math.pi * tiltAngleDegrees / 180;
    final tiltExpenseAngleRadians = math.pi * tiltExpenseAngleDegrees / 180;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: SizedBox(
        height: 170,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
          },
          child: Card(
            elevation: 0,
            color: isExpense ? color.errorContainer : color.primaryContainer,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                HapticFeedback.mediumImpact();
              },
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    !isExpense
                        ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: color.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Transform.rotate(
                                angle: tiltAngleRadians,
                                child: Icon(
                                  Icons.arrow_downward,
                                  size: 16,
                                  color: color.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6.0),
                            Flexible(
                              child: Text(
                                ctxt.transaction_type_income.toUpperCase(),
                                textAlign: TextAlign.center,
                                style: textTheme.labelMedium?.copyWith(
                                  color: color.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        )
                        : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Flexible(
                              child: Text(
                                ctxt.transaction_type_expense.toUpperCase(),
                                textAlign: TextAlign.center,
                                style: textTheme.labelMedium?.copyWith(
                                  color: color.error,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6.0),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: color.error.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Transform.rotate(
                                angle: tiltExpenseAngleRadians,
                                child:  Icon(
                                  Icons.arrow_upward,
                                  size: 16,
                                  color: color.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                    Flexible(
                      child: Container(
                        height: 80,
                        alignment: Alignment.centerLeft,
                        child: Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            Text(
                              ctxt.formatCurrencyWithSign(0, value),
                              style: textTheme.titleLarge?.copyWith(
                                color: (isExpense
                                        ? color.error
                                        : color.primary)
                                    .withValues(alpha: 0.1),
                                fontSize: 60,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.fade,
                            ),
                            AnimatedBalance(
                              value: value,
                              style: textTheme.titleMedium?.copyWith(
                                color:
                                    isExpense
                                        ? color.error
                                        : color.primary,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                              fixedStringLength: 0,
                              overflow: TextOverflow.fade,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Text(
                      FilterType.day == filter
                          ? DateFormat(
                            "dd MMM yy",
                            ctxt.localeName,
                          ).format(startDate)
                          : "${DateFormat("dd MMM yy", ctxt.localeName).format(startDate)} - ${DateFormat("dd MMM yy", ctxt.localeName).format(endDate)}",
                      style: textTheme.labelSmall?.copyWith(
                        color: color.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
