import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/l10n/app_localizations.dart';
import 'package:mudra_manager/screens/budget/budget_mini_card.dart';
import 'package:mudra_manager/screens/dashboard/cash_flow_screen.dart'
    show CashFlowScreen;
import 'package:mudra_manager/screens/dashboard/filter_chip_screen.dart'
    show FilterChips;
import 'package:mudra_manager/screens/dashboard/net_worth_mini_card.dart';
import 'package:mudra_manager/screens/goal/goal_mini_card.dart';
import 'package:mudra_manager/screens/dashboard/swipeable_account_card.dart';
import 'package:mudra_manager/screens/reusable/responseive_layout_builder.dart';
import 'package:mudra_manager/screens/reusable/budget_alert_banner.dart';
import 'package:mudra_manager/providers/budget_alert_provider.dart';

import 'package:mudra_manager/theme/design_tokens.dart';
import 'package:mudra_manager/screens/trip/active_trip_mini_card.dart';

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
    var ctxt = AppLocalizations.of(context)!;
    final alerts = ref.watch(budgetAlertsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SingleChildScrollView(
        key: GlobalKey(debugLabel: "dashboard_home"),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (alerts.isNotEmpty)
              BudgetAlertBanner(
                alerts: alerts,
                onDismiss: () {
                  ref
                      .read(budgetAlertsProvider.notifier)
                      .dismissAlert(alerts.first);
                },
              ),
            const SizedBox(height: 16),
            const AnimatedSwipeableAccountCards(),
            const SizedBox(height: 16),
            Container(
              margin: EdgeInsets.symmetric(horizontal: globalPadding),
              child: ResponsiveLayoutBuilder(
                sizedBoxHeight: 110,
                columnWidget: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          context.push('/add-transaction');
                        },
                        child: Hero(
                          tag: 'addTransactionHero',
                          child: Card(
                            elevation: 0,
                            color: color.primaryContainer,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                context.push('/add-transaction');
                              },
                              child: Container(
                                height: 50,
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: color.primary.withValues(
                                        alpha: 0.15,
                                      ),
                                      child: Icon(
                                        Icons.add_circle_outline,
                                        size: 20,
                                        color: color.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        ctxt.dashboard_add_transaction_text
                                            .toUpperCase(),
                                        textAlign: TextAlign.center,
                                        style: textTheme.labelMedium?.copyWith(
                                          color: color.onPrimaryContainer,
                                          fontWeight: FontWeight.w600,
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
                      ),
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          context.push('/transfer');
                        },
                        child: Card(
                          elevation: 0,
                          color: color.surfaceContainerHigh,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              context.push('/transfer');
                            },
                            child: Container(
                              height: 50,
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: color.tertiary.withValues(
                                      alpha: 0.15,
                                    ),
                                    child: Icon(
                                      Icons.swap_horiz,
                                      size: 20,
                                      color: color.tertiary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      ctxt.dashboard_add_transfer_text
                                          .toUpperCase(),
                                      textAlign: TextAlign.center,
                                      style: textTheme.labelMedium?.copyWith(
                                        color: color.tertiary,
                                        fontWeight: FontWeight.w600,
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
                    ),
                  ],
                ),
                rowWidget: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          context.push('/add-transaction');
                        },
                        child: Hero(
                          tag: 'addTransactionHero',
                          child: Card(
                            elevation: 0,
                            color: color.primaryContainer,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                context.push('/add-transaction');
                              },
                              child: Container(
                                height: 50,
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: color.primary.withValues(
                                        alpha: 0.15,
                                      ),
                                      child: Icon(
                                        Icons.add_circle_outline,
                                        size: 20,
                                        color: color.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        ctxt.dashboard_add_transaction_text
                                            .toUpperCase(),
                                        textAlign: TextAlign.center,
                                        style: textTheme.labelMedium?.copyWith(
                                          color: color.onPrimaryContainer,
                                          fontWeight: FontWeight.w600,
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
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          context.push('/transfer');
                        },
                        child: Card(
                          elevation: 0,
                          color: color.surfaceContainerHigh,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              context.push('/transfer');
                            },
                            child: Container(
                              height: 50,
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: color.tertiary.withValues(
                                      alpha: 0.15,
                                    ),
                                    child: Icon(
                                      Icons.swap_horiz,
                                      size: 20,
                                      color: color.tertiary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      ctxt.dashboard_add_transfer_text
                                          .toUpperCase(),
                                      textAlign: TextAlign.center,
                                      style: textTheme.labelMedium?.copyWith(
                                        color: color.tertiary,
                                        fontWeight: FontWeight.w600,
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
                    ),
                  ],
                ),
              ),
            ),
            CashFlowScreen(globalPadding: globalPadding),
            Container(
              margin: EdgeInsets.symmetric(horizontal: globalPadding),
              child: const FilterChips(),
            ),
            const SizedBox(height: 16),
            NetWorthMiniCard(globalPadding: globalPadding),
            const SizedBox(height: 16),
            ActiveTripMiniCard(globalPadding: globalPadding),
            const SizedBox(height: 16),
            BudgetMiniCard(globalPadding: globalPadding),
            const SizedBox(height: 16),
            GoalMiniCard(globalPadding: globalPadding),
            const SizedBox(height: 100), // Extra space for bottom nav
          ],
        ),
      ),
    );
  }
}
