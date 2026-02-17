import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/l10n/app_localizations.dart';
import 'package:mudra_manager/screens/budget/budget_mini_card.dart';
import 'package:mudra_manager/screens/dashboard/cash_flow_screen.dart'
    show CashFlowScreen;
import 'package:mudra_manager/screens/dashboard/net_worth_mini_card.dart';
import 'package:mudra_manager/screens/goal/goal_mini_card.dart';
import 'package:mudra_manager/screens/dashboard/swipeable_account_card.dart';
import 'package:mudra_manager/screens/dashboard/financial_health_card.dart';
import 'package:mudra_manager/screens/dashboard/net_worth_card.dart';
import 'package:mudra_manager/screens/dashboard/spending_prediction_card.dart';
import 'package:mudra_manager/screens/dashboard/budget_card.dart';
import 'package:mudra_manager/screens/dashboard/goal_card.dart';
import 'package:mudra_manager/screens/dashboard/cash_flow_screen.dart';
import 'package:mudra_manager/screens/reusable/responseive_layout_builder.dart';
import 'package:mudra_manager/screens/reusable/budget_alert_banner.dart';
import 'package:mudra_manager/screens/reusable/period_calendar_selector.dart';
import 'package:mudra_manager/providers/budget_alert_provider.dart';

import 'package:mudra_manager/screens/trip/active_trip_mini_card.dart';

class _AnimatedCard extends StatefulWidget {
  final Widget child;
  final int delay;

  const _AnimatedCard({required this.child, this.delay = 0});

  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

class DashboardHome extends ConsumerStatefulWidget {
  const DashboardHome({super.key});

  @override
  ConsumerState<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends ConsumerState<DashboardHome> {
  double globalPadding = 8.0;
  double allBoxWidthFactor = 0.4;
  PeriodType _selectedPeriod = PeriodType.month;
  DateTime? _customStart;
  DateTime? _customEnd;

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
            CashFlowScreen(
              globalPadding: globalPadding,
              selectedPeriod: _selectedPeriod,
              customStart: _customStart,
              customEnd: _customEnd,
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: globalPadding),
              child: PeriodCalendarSelector(
                selectedPeriod: _selectedPeriod,
                customStart: _customStart,
                customEnd: _customEnd,
                onChanged: (period, start, end) {
                  setState(() {
                    _selectedPeriod = period;
                    _customStart = start;
                    _customEnd = end;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            _AnimatedCard(delay: 0, child: FinancialHealthCard(globalPadding: globalPadding)),
            const SizedBox(height: 16),
            _AnimatedCard(delay: 100, child: NetWorthCard(globalPadding: globalPadding)),
            const SizedBox(height: 16),
            _AnimatedCard(delay: 200, child: SpendingPredictionCard(globalPadding: globalPadding)),
            const SizedBox(height: 16),
            _AnimatedCard(delay: 300, child: ActiveTripMiniCard(globalPadding: globalPadding)),
            const SizedBox(height: 16),
            _AnimatedCard(delay: 400, child: BudgetCard(globalPadding: globalPadding)),
            const SizedBox(height: 16),
            _AnimatedCard(delay: 500, child: GoalCard(globalPadding: globalPadding)),
            const SizedBox(height: 100), // Extra space for bottom nav
          ],
        ),
      ),
    );
  }
}
