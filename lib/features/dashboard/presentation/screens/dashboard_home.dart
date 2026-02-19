import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';
import 'package:mudra_manager/features/budget/data/budget_alert_provider.dart';
import 'package:mudra_manager/features/dashboard/presentation/screens/cash_flow_screen.dart';
import 'package:mudra_manager/features/dashboard/presentation/widgets/budget_card.dart';
import 'package:mudra_manager/features/dashboard/presentation/widgets/financial_health_card.dart';
import 'package:mudra_manager/features/dashboard/presentation/widgets/goal_card.dart';
import 'package:mudra_manager/features/dashboard/presentation/widgets/net_worth_card.dart';
import 'package:mudra_manager/features/dashboard/presentation/widgets/spending_prediction_card.dart';
import 'package:mudra_manager/features/dashboard/presentation/widgets/dashboard_action_button.dart';
import 'package:mudra_manager/features/dashboard/presentation/widgets/swipeable_account_card.dart';
import 'package:mudra_manager/features/profile/data/help_guide_provider.dart';
import 'package:mudra_manager/features/statistics/presentation/widgets/period_selector.dart';
import 'package:mudra_manager/features/trip/presentation/widgets/active_trip_mini_card.dart';
import 'package:mudra_manager/shared/widgets/budget_alert_banner.dart';
import 'package:mudra_manager/shared/widgets/period_calendar_selector.dart';
import 'package:mudra_manager/shared/widgets/responseive_layout_builder.dart';

class _AnimatedCard extends StatefulWidget {
  final Widget child;
  final int delay;

  const _AnimatedCard({required this.child, this.delay = 0});

  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard>
    with SingleTickerProviderStateMixin {
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

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

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
      child: SlideTransition(position: _slideAnimation, child: widget.child),
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
    final ctxt = AppLocalizations.of(context)!;
    final alerts = ref.watch(budgetAlertsProvider);
    final hasSeenHelp = ref.watch(hasSeenHelpGuideProvider);

    return Scaffold(
      body: SingleChildScrollView(
        key: GlobalKey(debugLabel: 'dashboard_home'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!hasSeenHelp)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Card(
                  elevation: 0,
                  color: color.primaryContainer,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      context.push('/help');
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: color.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.help_outline,
                              color: color.onPrimary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'New to Mudra Manager?',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: color.onPrimaryContainer,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Check out our help guide to get started',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: color.onPrimaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: color.onPrimaryContainer,
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              size: 20,
                              color: color.onPrimaryContainer,
                            ),
                            onPressed: () async {
                              await SharedPrefsUtil.instance
                                  .setHasSeenHelpGuide(true);
                              ref
                                  .read(hasSeenHelpGuideProvider.notifier)
                                  .state = true;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
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
                      child: DashboardActionButton(
                        label: ctxt.dashboard_add_transaction_text,
                        icon: Icons.add_circle_outline,
                        onTap: () => context.push('/add-transaction'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: DashboardActionButton(
                        label: ctxt.dashboard_add_transfer_text,
                        icon: Icons.swap_horiz,
                        onTap: () => context.push('/transfer'),
                        backgroundColor: color.surfaceContainerHigh,
                        iconColor: color.tertiary,
                        textColor: color.tertiary,
                      ),
                    ),
                  ],
                ),
                rowWidget: Row(
                  children: [
                    Expanded(
                      child: DashboardActionButton(
                        label: ctxt.dashboard_add_transaction_text,
                        icon: Icons.add_circle_outline,
                        onTap: () => context.push('/add-transaction'),
                        heroTag: 'addTransactionHero',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DashboardActionButton(
                        label: ctxt.dashboard_add_transfer_text,
                        icon: Icons.swap_horiz,
                        onTap: () => context.push('/transfer'),
                        backgroundColor: color.surfaceContainerHigh,
                        iconColor: color.tertiary,
                        textColor: color.tertiary,
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
            _AnimatedCard(
              delay: 0,
              child: FinancialHealthCard(globalPadding: globalPadding),
            ),
            const SizedBox(height: 16),
            _AnimatedCard(
              delay: 100,
              child: NetWorthCard(globalPadding: globalPadding),
            ),
            const SizedBox(height: 16),
            _AnimatedCard(
              delay: 200,
              child: SpendingPredictionCard(globalPadding: globalPadding),
            ),
            const SizedBox(height: 16),
            _AnimatedCard(
              delay: 300,
              child: ActiveTripMiniCard(globalPadding: globalPadding),
            ),
            const SizedBox(height: 16),
            _AnimatedCard(
              delay: 400,
              child: BudgetCard(globalPadding: globalPadding),
            ),
            const SizedBox(height: 16),
            _AnimatedCard(
              delay: 500,
              child: GoalCard(globalPadding: globalPadding),
            ),
            const SizedBox(height: 100), // Extra space for bottom nav
          ],
        ),
      ),
    );
  }
}
