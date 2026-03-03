import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/budget/data/budget_alert_provider.dart';
import 'package:mudra_manager/features/dashboard/presentation/screens/cash_flow_screen.dart';
import 'package:mudra_manager/features/dashboard/presentation/widgets/budget_card.dart';
import 'package:mudra_manager/features/dashboard/presentation/widgets/financial_health_card.dart';
import 'package:mudra_manager/features/dashboard/presentation/widgets/goal_card.dart';
import 'package:mudra_manager/features/dashboard/presentation/widgets/net_worth_card.dart';
import 'package:mudra_manager/features/dashboard/presentation/widgets/spending_prediction_card.dart';
import 'package:mudra_manager/features/dashboard/presentation/widgets/recurring_expenses_card.dart';
import 'package:mudra_manager/features/dashboard/presentation/widgets/spending_personality_card.dart';
import 'package:mudra_manager/features/dashboard/presentation/widgets/dashboard_action_button.dart';
import 'package:mudra_manager/features/dashboard/presentation/widgets/swipeable_account_card.dart';
import 'package:mudra_manager/features/profile/data/help_guide_provider.dart';
import 'package:mudra_manager/features/trip/presentation/widgets/active_trip_mini_card.dart';
import 'package:mudra_manager/features/marketplace/services/marketplace_service.dart';
import 'package:mudra_manager/shared/widgets/budget_alert_banner.dart';
import 'package:mudra_manager/shared/widgets/period_calendar_selector.dart';
import 'package:mudra_manager/shared/widgets/responseive_layout_builder.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

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
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: widget.child,
        ),
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
  final AppLog log = AppLog(getLogger(), 'DashBoardHome');
  List<String> _visibleCards = [];
  List<String> _cardOrder = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCardPreferences();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = SharedPrefsUtil.instance;
      final lastCheckIn = prefs.getLastDailyCheckIn();
      final now = DateTime.now();

      // Only check in if not already done today
      if (lastCheckIn == null ||
          !(lastCheckIn.year == now.year &&
              lastCheckIn.month == now.month &&
              lastCheckIn.day == now.day)) {
        final service = await ref.read(gamificationServiceInitProvider.future);
        final result = await service.updateDailyCheckIn();
        if (result != null && mounted) {
          await prefs.setLastDailyCheckIn(now);
          SnackbarService.success('🔥 $result');
          log.i('✅ Daily check-in completed');
        }
      }
    });
  }

  Future<void> _loadCardPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final visible = prefs.getStringList('visible_dashboard_cards');
    final order = prefs.getStringList('dashboard_cards_order');
    
    // Check if travel plugin is enabled
    final marketplace = MarketplaceService();
    final isTravelEnabled = await marketplace.isPluginEnabled('com.mudra.travel_expenses');
    
    setState(() {
      _visibleCards = visible ??
          [
            'accounts',
            'action_buttons',
            'spending_personality',
            'cash_flow',
            'financial_health',
            'net_worth',
            'spending_prediction',
            'recurring_expenses',
            if (isTravelEnabled) 'active_trip',
            'budget',
            'goal'
          ];
      _cardOrder = order ??
          [
            'accounts',
            'action_buttons',
            'spending_personality',
            'cash_flow',
            'financial_health',
            'net_worth',
            'spending_prediction',
            'recurring_expenses',
            if (isTravelEnabled) 'active_trip',
            'budget',
            'goal'
          ];
      _isLoading = false;
    });
  }

  bool _isCardVisible(String cardId) => _visibleCards.contains(cardId);

  Widget? _buildCard(String cardId, int index) {
    if (!_isCardVisible(cardId)) return null;

    switch (cardId) {
      case 'accounts':
        return const AnimatedSwipeableAccountCards();
      case 'action_buttons':
        return Container(
          margin: EdgeInsets.symmetric(horizontal: globalPadding),
          child: ResponsiveLayoutBuilder(
            columnWidget: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: DashboardActionButton(
                    label: AppLocalizations.of(context)!
                        .dashboard_add_transaction_text,
                    icon: Icons.add_circle_outline,
                    onTap: () => context.push('/add-transaction'),
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: DashboardActionButton(
                    label: AppLocalizations.of(context)!
                        .dashboard_add_transfer_text,
                    icon: Icons.swap_horiz,
                    onTap: () => context.push('/transfer'),
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHigh,
                    iconColor: Theme.of(context).colorScheme.tertiary,
                    textColor: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
              ],
            ),
            rowWidget: Row(
              children: [
                Expanded(
                  child: DashboardActionButton(
                    label: AppLocalizations.of(context)!
                        .dashboard_add_transaction_text,
                    icon: Icons.add_circle_outline,
                    onTap: () => context.push('/add-transaction'),
                    heroTag: 'addTransactionHeroDashboard',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DashboardActionButton(
                    label: AppLocalizations.of(context)!
                        .dashboard_add_transfer_text,
                    icon: Icons.swap_horiz,
                    onTap: () => context.push('/transfer'),
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHigh,
                    iconColor: Theme.of(context).colorScheme.tertiary,
                    textColor: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
              ],
            ),
          ),
        );
      case 'spending_personality':
        return SpendingPersonalityCard(globalPadding: globalPadding);
      case 'cash_flow':
        return Column(
          children: [
            CashFlowScreen(
              globalPadding: globalPadding,
              selectedPeriod: _selectedPeriod,
              customStart: _customStart,
              customEnd: _customEnd,
            ),
            const SizedBox(height: 8),
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
          ],
        );
      case 'financial_health':
        return _AnimatedCard(
            delay: index * 100,
            child: FinancialHealthCard(globalPadding: globalPadding));
      case 'net_worth':
        return _AnimatedCard(
            delay: index * 100,
            child: NetWorthCard(globalPadding: globalPadding));
      case 'spending_prediction':
        return _AnimatedCard(
            delay: index * 100,
            child: SpendingPredictionCard(globalPadding: globalPadding));
      case 'recurring_expenses':
        return RecurringExpensesCard(globalPadding: globalPadding);
      case 'active_trip':
        return _AnimatedCard(
            delay: index * 100,
            child: ActiveTripMiniCard(globalPadding: globalPadding));
      case 'budget':
        return _AnimatedCard(
            delay: index * 100,
            child: BudgetCard(globalPadding: globalPadding));
      case 'goal':
        return _AnimatedCard(
            delay: index * 100, child: GoalCard(globalPadding: globalPadding));
      default:
        return null;
    }
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
    final hasAnyVisibleCards = _visibleCards.isNotEmpty;

    if (_isLoading) {
      return Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: globalPadding,
                  vertical: 8,
                ),
                child: SkeletonLoader(
                  width: double.infinity,
                  height: 180,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: globalPadding,
                  vertical: 8,
                ),
                child: SkeletonLoader(
                  width: double.infinity,
                  height: 100,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: globalPadding,
                  vertical: 8,
                ),
                child: SkeletonLoader(
                  width: double.infinity,
                  height: 120,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: globalPadding,
                  vertical: 8,
                ),
                child: SkeletonLoader(
                  width: double.infinity,
                  height: 140,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: globalPadding,
                  vertical: 8,
                ),
                child: SkeletonLoader(
                  width: double.infinity,
                  height: 160,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      );
    }

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
            ...() {
              final widgets = <Widget>[];
              for (int i = 0; i < _cardOrder.length; i++) {
                final widget = _buildCard(_cardOrder[i], i);
                if (widget != null && widget is! SizedBox) {
                  widgets.add(widget);
                }
              }
              return widgets;
            }(),
            if (!hasAnyVisibleCards)
              Container(
                margin: const EdgeInsets.all(16),
                child: Card(
                  elevation: 0,
                  color: color.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.dashboard_customize,
                          size: 64,
                          color: color.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No cards enabled',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Enable dashboard cards to see your financial overview',
                          style: textTheme.bodyMedium?.copyWith(
                            color: color.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () => context.push('/dashboard-customize'),
                          icon: const Icon(Icons.add),
                          label: const Text('Enable Cards'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 100), // Extra space for bottom nav
          ],
        ),
      ),
    );
  }
}
