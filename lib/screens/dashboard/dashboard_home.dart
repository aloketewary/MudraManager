import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/db/models/user_profile.dart';
import 'package:mudra_manager/providers/greeting_provider.dart';
import 'package:mudra_manager/providers/user_profile_provider.dart';
import 'package:mudra_manager/screens/budget/budget_mini_card.dart';
import 'package:mudra_manager/screens/dashboard/cash_flow_screen.dart'
    show CashFlowScreen;
import 'package:mudra_manager/screens/dashboard/filter_chip_screen.dart'
    show FilterChips;
import 'package:mudra_manager/screens/dashboard/swipeable_account_card.dart';
import 'package:mudra_manager/screens/transaction/add_edit_transaction_screen.dart';
import 'package:mudra_manager/screens/transaction/transfer_screen.dart';
import 'package:shared_preferences/src/shared_preferences_legacy.dart';

class DashboardHome extends ConsumerStatefulWidget {
  const DashboardHome({super.key});

  @override
  ConsumerState<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends ConsumerState<DashboardHome> {
  double globalPadding = 8.0;
  double allBoxWidthFactor = 0.4;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      body: SingleChildScrollView(
        key: GlobalKey(debugLabel: "dashboard_home"),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 20),
            AnimatedSwipeableAccountCards(),
            SizedBox(height: 20),
            Container(
              margin: EdgeInsets.only(
                left: globalPadding,
                right: globalPadding,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    flex: (allBoxWidthFactor * 100).toInt(),
                    child: SizedBox(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddEditTransactionScreen(),
                            ),
                          );
                        },
                        child: Container(
                          width: 120,
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25.0),
                            color: color.primary,
                            // Light background color
                            border: Border.all(
                              color: color.primary,
                            ), // Subtle border
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              CircleAvatar(
                                radius: 20,
                                child: Icon(Icons.add_circle_outline, size: 30),
                              ),
                              const SizedBox(width: 8.0),
                              Expanded(
                                child: Text(
                                  "ADD TRANSACTION",
                                  textAlign: TextAlign.center,
                                  style: textTheme.labelLarge?.copyWith(
                                    color: color.onPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    flex: (allBoxWidthFactor * 100).toInt(),
                    child: SizedBox(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TransferScreen(),
                            ),
                          );
                        },
                        child: Container(
                          width: 120,
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25.0),
                            border: Border.all(color: color.primary),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              CircleAvatar(
                                radius: 20,
                                child: Icon(
                                  Icons.arrow_circle_right_outlined,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 8.0),
                              Expanded(
                                child: Text(
                                  "TRANSFER",
                                  textAlign: TextAlign.center,
                                  style: textTheme.labelLarge?.copyWith(
                                    color: color.primary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
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
            ),
            CashFlowScreen(globalPadding: globalPadding),
            Container(
              margin: EdgeInsets.only(
                left: globalPadding,
                right: globalPadding,
              ),
              child: FilterChips(),
            ),
            SizedBox(height: 16),
            BudgetMiniCard(globalPadding: globalPadding),
          ],
        ),
      ),
    );
  }
}
