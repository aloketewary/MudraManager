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
import 'package:mudra_manager/screens/transaction/transaction_list_screen.dart';
import 'package:mudra_manager/theme/design_tokens.dart';
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
                      child: IconButton.filled(
                        onPressed: () {
              HapticFeedback.mediumImpact();
              context.push('/transactions');
            },
                        icon: Icon(Icons.open_in_new),
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

    return Expanded(
      flex: (rightBoxWidthFactor * 100).toInt(),
      child: SizedBox(
        height: 170,
        child: GestureDetector(
          onTap: () {
              HapticFeedback.mediumImpact();
              {};
            },
          child: Container(
            padding: const EdgeInsets.all(8.0),
            margin: const EdgeInsets.only(right: 8.0),
            decoration: BoxDecoration(
              borderRadius: DesignTokens.borderRadiusMedium,
              gradient:
                  isExpense
                      ? null
                      : LinearGradient(
                        colors: [
                          color.primary,
                          color.primary.withOpacity(0.85),
                          color.primaryContainer,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
              color: isExpense ? color.surface : null,
              border: Border.all(color: color.primary, width: 2),
              boxShadow:
                  isExpense
                      ? AppElevation.elevation1(color.primary)
                      : AppElevation.coloredElevation(
                        color.primary,
                        intensity: 0.25,
                      ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                !isExpense
                    ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        CircleAvatar(
                          radius: 16,
                          child: Transform.rotate(
                            angle: tiltAngleRadians,
                            child: Icon(Icons.arrow_downward, size: 16),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Text(
                            ctxt.transaction_type_income.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: textTheme.labelLarge?.copyWith(
                              color: color.onPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                    : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            ctxt.transaction_type_expense.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: textTheme.labelLarge?.copyWith(
                              color: color.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        CircleAvatar(
                          radius: 16,
                          child: Transform.rotate(
                            angle: tiltExpenseAngleRadians,
                            child: Icon(Icons.arrow_upward, size: 16),
                          ),
                        ),
                      ],
                    ),
                SizedBox(
                  height: 100,
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    // or whatever aligns best for you
                    children: [
                      Text(
                        ctxt.formatCurrencyWithSign(0, value),
                        style: textTheme.titleLarge?.copyWith(
                          color:
                              isExpense
                                  ? color.primary.withAlpha(10)
                                  : color.onPrimary.withAlpha(10),
                          fontSize: 80,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.fade,
                      ),
                      AnimatedBalance(
                        value: value,
                        style: textTheme.titleLarge?.copyWith(
                          color: isExpense ? color.primary : color.onPrimary,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                        fixedStringLength: 0,
                        overflow: TextOverflow.fade,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Text(
                    FilterType.day == filter
                        ? DateFormat(
                          "dd MMM yy",
                          ctxt.localeName,
                        ).format(startDate)
                        : "${DateFormat("dd MMM yy", ctxt.localeName).format(startDate)} - ${DateFormat("dd MMM yy", ctxt.localeName).format(endDate)}",
                    style: textTheme.labelMedium?.copyWith(
                      color: isExpense ? color.primary : color.onPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
