import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/db/filter_type.dart' show FilterType;
import 'package:mudra_manager/providers/filter_provider.dart';
import 'package:mudra_manager/screens/reusable/animated_balance.dart';
import 'package:mudra_manager/screens/transaction/transaction_list_screen.dart';

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
    final tiltAngleRadians = math.pi * tiltAngleDegrees / 180;
    final tiltExpenseAngleRadians = math.pi * tiltExpenseAngleDegrees / 180;
    final filter = ref.watch(filterProvider);
    final now = DateTime.now();

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
                      'Cash Flow',
                      style: textTheme.titleLarge?.copyWith(
                        color: color.primary,
                      ),
                    ),
                    IconButton.filled(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    TransactionListScreen(showAppBar: true),
                          ),
                        );
                      },
                      icon: Icon(Icons.open_in_new),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: (leftBoxWidthFactor * 100).toInt(),
                    child: SizedBox(
                      height: 170,
                      child: GestureDetector(
                        onTap: () => {},
                        child: Container(
                          width: 120,
                          padding: const EdgeInsets.all(8.0),
                          margin: const EdgeInsets.only(right: 8.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12.0),
                            color: color.primary,
                            // Light background color
                            border: Border.all(
                              color: color.primary,
                            ), // Subtle border
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  CircleAvatar(
                                    radius: 16,
                                    child: Transform.rotate(
                                      angle: tiltAngleRadians,
                                      child: Icon(
                                        Icons.arrow_downward,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8.0),
                                  Expanded(
                                    child: Text(
                                      "INCOME",
                                      textAlign: TextAlign.center,
                                      style: textTheme.labelLarge?.copyWith(
                                        color: color.onPrimary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
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
                                      "₹$income}",
                                      style: textTheme.titleLarge?.copyWith(
                                        color: color.onPrimary.withAlpha(10),
                                        fontSize: 80,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.fade,
                                    ),
                                    AnimatedBalance(
                                      value: income,
                                      style: textTheme.titleLarge?.copyWith(
                                        color: color.onPrimary,
                                        fontSize: 40,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      fixedStringLength: 0,
                                      overflow: TextOverflow.fade,
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                "${DateFormat("dd MMM yy").format(startDate)} - ${DateFormat("dd MMM yy").format(endDate)}",
                                style: textTheme.labelMedium?.copyWith(
                                  color: color.onPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: (rightBoxWidthFactor * 100).toInt(),
                    child: SizedBox(
                      height: 170,
                      child: GestureDetector(
                        onTap: () => {},
                        child: Container(
                          width: 120,
                          padding: const EdgeInsets.all(8.0),
                          margin: const EdgeInsets.only(right: 8.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12.0),
                            color: Colors.transparent,
                            // Light background color
                            border: Border.all(
                              color: color.primary,
                            ), // Subtle border
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      "EXPENSE",
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
                                      "₹$expense",
                                      style: textTheme.titleLarge?.copyWith(
                                        color: color.primary.withAlpha(10),
                                        fontSize: 80,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.fade,
                                    ),
                                    AnimatedBalance(
                                      value: expense,
                                      style: textTheme.titleLarge?.copyWith(
                                        color: color.primary,
                                        fontSize: 40,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      fixedStringLength: 0,
                                      overflow: TextOverflow.fade,
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                "${DateFormat("dd MMM yy").format(startDate)} - ${DateFormat("dd MMM yy").format(endDate)}",
                                style: textTheme.labelMedium?.copyWith(
                                  color: color.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
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
}
