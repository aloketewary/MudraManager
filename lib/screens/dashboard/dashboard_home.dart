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
import 'package:mudra_manager/screens/transaction/add_edit_transaction_screen.dart';
import 'package:mudra_manager/screens/transaction/transfer_screen.dart';
import 'package:mudra_manager/theme/design_tokens.dart';

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

    return Scaffold(
      body: SingleChildScrollView(
        key: GlobalKey(debugLabel: "dashboard_home"),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
                            HapticFeedback.lightImpact();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => AddEditTransactionScreen(),
                              ),
                            );
                          },
                          child: Hero(
                            tag: 'addTransactionHero',
                            child: Container(
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                borderRadius: DesignTokens.borderRadiusLarge,
                                gradient: LinearGradient(
                                  colors: [
                                    color.primary,
                                    color.primary.withOpacity(0.85),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: AppElevation.coloredElevation(
                                  color.primary,
                                  intensity: 0.25,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: color.onPrimary
                                        .withOpacity(0.2),
                                    child: Icon(
                                      Icons.add_circle_outline,
                                      size: 30,
                                      color: color.onPrimary,
                                    ),
                                  ),
                                  SizedBox(width: DesignTokens.spacing8),
                                  Expanded(
                                    child: Text(
                                      ctxt.dashboard_add_transaction_text
                                          .toUpperCase(),
                                      textAlign: TextAlign.center,
                                      style: textTheme.labelLarge?.copyWith(
                                        color: color.onPrimary,
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
                            HapticFeedback.lightImpact();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TransferScreen(),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              borderRadius: DesignTokens.borderRadiusLarge,
                              border: Border.all(
                                color: color.primary,
                                width: 2,
                              ),
                              color: color.surface,
                              boxShadow: AppElevation.elevation1(color.primary),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: color.primaryContainer,
                                  child: Icon(
                                    Icons.arrow_circle_right_outlined,
                                    size: 30,
                                    color: color.primary,
                                  ),
                                ),
                                SizedBox(width: DesignTokens.spacing8),
                                Expanded(
                                  child: Text(
                                    ctxt.dashboard_add_transfer_text
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
                            HapticFeedback.lightImpact();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => AddEditTransactionScreen(),
                              ),
                            );
                          },
                          child: Hero(
                            tag: 'addTransactionHero',
                            child: Container(
                              width: 120,
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                borderRadius: DesignTokens.borderRadiusLarge,
                                gradient: LinearGradient(
                                  colors: [
                                    color.primary,
                                    color.primary.withOpacity(0.85),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: AppElevation.coloredElevation(
                                  color.primary,
                                  intensity: 0.25,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: color.onPrimary
                                        .withOpacity(0.2),
                                    child: Icon(
                                      Icons.add_circle_outline,
                                      size: 30,
                                      color: color.onPrimary,
                                    ),
                                  ),
                                  SizedBox(width: DesignTokens.spacing8),
                                  Expanded(
                                    child: Text(
                                      ctxt.dashboard_add_transaction_text
                                          .toUpperCase(),
                                      textAlign: TextAlign.center,
                                      style: textTheme.labelLarge?.copyWith(
                                        color: color.onPrimary,
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
                            HapticFeedback.lightImpact();
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
                              borderRadius: DesignTokens.borderRadiusLarge,
                              border: Border.all(
                                color: color.primary,
                                width: 2,
                              ),
                              color: color.surface,
                              boxShadow: AppElevation.elevation1(color.primary),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: color.primaryContainer,
                                  child: Icon(
                                    Icons.arrow_circle_right_outlined,
                                    size: 30,
                                    color: color.primary,
                                  ),
                                ),
                                SizedBox(width: DesignTokens.spacing8),
                                Expanded(
                                  child: Text(
                                    ctxt.dashboard_add_transfer_text
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
