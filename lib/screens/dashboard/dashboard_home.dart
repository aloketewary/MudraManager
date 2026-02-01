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
import 'package:mudra_manager/theme/app_colors.dart';
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
            SizedBox(height: 16),
            AnimatedSwipeableAccountCards(),
            SizedBox(height: 16),
            Container(
              margin: EdgeInsets.only(
                left: globalPadding,
                right: globalPadding,
              ),
              child: ResponsiveLayoutBuilder(
                sizedBoxHeight: 110,
                columnWidget: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: (allBoxWidthFactor * 100).toInt(),
                      child: SizedBox(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            context.push('/add-transaction');
                          },
                          child: Hero(
                            tag: 'addTransactionHero',
                            child: Container(
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                borderRadius: DesignTokens.borderRadiusLarge,
                                gradient: LinearGradient(
                                  colors: AppColors.glassGradient(color.primary, isDark),
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                border: Border.all(
                                  color: color.primary.withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                                boxShadow: AppColors.glassShadow(color.primary, isDark),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: color.primary.withValues(alpha: 0.15),
                                    child: Icon(
                                      Icons.add_circle_outline,
                                      size: 24,
                                      color: color.primary,
                                    ),
                                  ),
                                  SizedBox(width: DesignTokens.spacing8),
                                  Expanded(
                                    child: Text(
                                      ctxt.dashboard_add_transaction_text
                                          .toUpperCase(),
                                      textAlign: TextAlign.center,
                                      style: textTheme.labelLarge?.copyWith(
                                        color: color.primary,
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
                    SizedBox(height: DesignTokens.spacing8),
                    Expanded(
                      flex: (allBoxWidthFactor * 100).toInt(),
                      child: SizedBox(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            context.push('/transfer');
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              borderRadius: DesignTokens.borderRadiusLarge,
                              gradient: LinearGradient(
                                colors: AppColors.glassGradient(AppColors.transfer, isDark),
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(
                                color: AppColors.transfer.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                              boxShadow: AppColors.glassShadow(AppColors.transfer, isDark),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: AppColors.transfer.withValues(alpha: 0.15),
                                  child: const Icon(
                                    Icons.swap_horiz,
                                    size: 24,
                                    color: AppColors.transfer,
                                  ),
                                ),
                                SizedBox(width: DesignTokens.spacing8),
                                Expanded(
                                  child: Text(
                                    ctxt.dashboard_add_transfer_text
                                        .toUpperCase(),
                                    textAlign: TextAlign.center,
                                    style: textTheme.labelLarge?.copyWith(
                                      color: AppColors.transfer,
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
                  ],
                ),
                rowWidget: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: (allBoxWidthFactor * 100).toInt(),
                      child: SizedBox(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            context.push('/add-transaction');
                          },
                          child: Hero(
                            tag: 'addTransactionHero',
                            child: Container(
                              width: 120,
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                borderRadius: DesignTokens.borderRadiusLarge,
                                gradient: LinearGradient(
                                  colors: AppColors.glassGradient(color.primary, isDark),
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                border: Border.all(
                                  color: color.primary.withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                                boxShadow: AppColors.glassShadow(color.primary, isDark),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: color.primary.withValues(alpha: 0.15),
                                    child: Icon(
                                      Icons.add_circle_outline,
                                      size: 24,
                                      color: color.primary,
                                    ),
                                  ),
                                  SizedBox(width: DesignTokens.spacing8),
                                  Expanded(
                                    child: Text(
                                      ctxt.dashboard_add_transaction_text
                                          .toUpperCase(),
                                      textAlign: TextAlign.center,
                                      style: textTheme.labelLarge?.copyWith(
                                        color: color.primary,
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
                    SizedBox(width: DesignTokens.spacing8),
                    Expanded(
                      flex: (allBoxWidthFactor * 100).toInt(),
                      child: SizedBox(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            context.push('/transfer');
                          },
                          child: Container(
                            width: 120,
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              borderRadius: DesignTokens.borderRadiusLarge,
                              gradient: LinearGradient(
                                colors: AppColors.glassGradient(AppColors.transfer, isDark),
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(
                                color: AppColors.transfer.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                              boxShadow: AppColors.glassShadow(AppColors.transfer, isDark),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: AppColors.transfer.withValues(alpha: 0.15),
                                  child: const Icon(
                                    Icons.swap_horiz,
                                    size: 24,
                                    color: AppColors.transfer,
                                  ),
                                ),
                                SizedBox(width: DesignTokens.spacing8),
                                Expanded(
                                  child: Text(
                                    ctxt.dashboard_add_transfer_text
                                        .toUpperCase(),
                                    textAlign: TextAlign.center,
                                    style: textTheme.labelLarge?.copyWith(
                                      color: AppColors.transfer,
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
                  ],
                ),
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
            NetWorthMiniCard(globalPadding: globalPadding),
            SizedBox(height: 16),
            ActiveTripMiniCard(globalPadding: globalPadding),
            SizedBox(height: 16),
            BudgetMiniCard(globalPadding: globalPadding),
            SizedBox(height: 16),
            GoalMiniCard(globalPadding: globalPadding),
            SizedBox(height: 80), // Extra space for bottom nav
          ],
        ),
      ),
    );
  }
}
