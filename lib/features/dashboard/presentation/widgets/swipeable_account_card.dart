import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/extension/account_type_extenstion.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/dashboard_data_provider.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:mudra_manager/shared/widgets/animated_balance.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:mudra_manager/core/router/app_routes.dart';

class AnimatedSwipeableAccountCards extends ConsumerStatefulWidget {
  const AnimatedSwipeableAccountCards({super.key});

  @override
  ConsumerState<AnimatedSwipeableAccountCards> createState() =>
      _AnimatedSwipeableAccountCardsState();
}

class _AnimatedSwipeableAccountCardsState
    extends ConsumerState<AnimatedSwipeableAccountCards> {
  int _currentPage = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.9,
      keepPage: true, // Preserve page position
      initialPage: 0,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = ref.watch(spacingProvider);
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    final ctxt = AppLocalizations.of(context)!;
    final dashboardAsync = ref.watch(dashboardDataProvider);
    final isGuestMode = ref.watch(guestModeProvider);

    final data = dashboardAsync.valueOrNull;
    if (data == null) {
      return const SizedBox(height: 240, child: AccountCardSkeleton());
    }

    final accounts = data.accounts;
    if (accounts.isEmpty) {
      return Center(child: Text(ctxt.common_noAccountsYet));
    }

    final balanceMap = data.accountBalances;
    final totalBalance =
        GuestModeUtil.applyGuestMode(data.totalBalance, isGuestMode);
    final income = GuestModeUtil.applyGuestMode(data.totalIncome, isGuestMode);
    final expense =
        GuestModeUtil.applyGuestMode(data.totalExpense, isGuestMode);
    final netCashFlow = income - expense;

    return RepaintBoundary(
      child: SizedBox(
        height: 240,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total Balance Header with Net Worth Link
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: spacing.cardHorizontal,
                vertical: spacing.cardVertical,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Balance',
                    style: textTheme.titleMedium?.copyWith(
                      color: color.onSurface,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.push(AppRoutes.netWorth);
                    },
                    borderRadius: BorderRadius.circular(spacing.radiusSmall),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: spacing.elementGap,
                        vertical: spacing.elementGap / 2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Net Worth',
                            style: textTheme.labelMedium?.copyWith(
                              color: color.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: spacing.elementGap / 2),
                          Icon(Icons.arrow_forward_ios,
                              size: 12, color: color.primary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: spacing.cardVertical),
            RepaintBoundary(
              child: Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: spacing.cardHorizontal),
                child: Row(
                  children: [
                    Expanded(
                      child: AnimatedBalance(
                        value: totalBalance,
                        style: textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: color.onSurface,
                        ),
                        compact: false,
                        fixedStringLength: 0,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: spacing.cardHorizontal,
                        vertical: spacing.cardVertical,
                      ),
                      decoration: BoxDecoration(
                        color: netCashFlow >= 0
                            ? color.primaryContainer
                            : color.errorContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            netCashFlow >= 0
                                ? Icons.trending_up
                                : Icons.trending_down,
                            size: 16,
                            color:
                                netCashFlow >= 0 ? color.primary : color.error,
                          ),
                          const SizedBox(width: 4),
                          AnimatedBalance(
                            value: netCashFlow,
                            style: textTheme.labelMedium?.copyWith(
                              color: netCashFlow >= 0
                                  ? color.primary
                                  : color.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: spacing.cardVertical),
            // Account Cards PageView
            SizedBox(
              height: 100,
              child: PageView.builder(
                key: PageStorageKey('account_cards_pageview'),
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: accounts.length,
                itemBuilder: (context, index) {
                  final account = accounts[index];
                  final isFirst = index == 0;
                  final isLast = index == accounts.length - 1;
                  final currentBalance = GuestModeUtil.applyGuestMode(
                    balanceMap[account.id] ?? 0,
                    isGuestMode,
                  );

                  return RepaintBoundary(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: isFirst ? 0 : spacing.cardHorizontal,
                        right: isLast ? 0 : spacing.cardHorizontal,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(account.colorValue ?? 0xFF6B4CE6),
                              Color(account.colorValue ?? 0xFF6B4CE6)
                                  .withValues(alpha: 0.85),
                            ],
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(spacing.radiusLarge),
                            topRight: Radius.circular(spacing.radiusLarge),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(account.colorValue ?? 0xFF6B4CE6)
                                  .withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, -4),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: spacing.cardHorizontalMax,
                          vertical: spacing.cardVertical,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      account.name,
                                      style: textTheme.titleMedium?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      ' - ${account.accountType.label.toUpperCase()}',
                                      style: textTheme.labelSmall?.copyWith(
                                        color:
                                            Colors.white.withValues(alpha: 0.7),
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                                SizedBox(height: spacing.cardVertical),
                                AnimatedBalance(
                                  value: currentBalance,
                                  compact: false,
                                  fixedStringLength: 0,
                                  duration: const Duration(milliseconds: 300),
                                  style: textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    letterSpacing: 2,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  account.accountNumber?.substring(
                                        account.accountNumber!.length >= 4
                                            ? account.accountNumber!.length - 4
                                            : 0,
                                      ) ??
                                      '0000',
                                  style: textTheme.titleSmall?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Icon(
                                  account.accountType.icon,
                                  color: Colors.white.withValues(alpha: 0.5),
                                  size: 40,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: spacing.cardVertical),

            // Page Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                accounts.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? color.primary
                        : color.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            SizedBox(height: spacing.cardVertical),
          ],
        ),
      ),
    );
  }
}
