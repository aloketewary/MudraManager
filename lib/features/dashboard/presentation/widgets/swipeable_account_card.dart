import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:mudra_manager/shared/widgets/no_data_found.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/extension/account_type_extenstion.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/account_display_style_provider.dart';
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
    extends ConsumerState<AnimatedSwipeableAccountCards>
    with SingleTickerProviderStateMixin {
  int _currentPage = 0;
  int balanceViewIndex = -1;
  bool _accountsExpanded = false;
  late PageController _pageController;

  // Stack state
  bool _stackExpanded = false;
  late AnimationController _stackController;
  late Animation<double> _stackAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.9,
      keepPage: true,
      initialPage: 0,
    );
    _stackController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _stackAnimation = CurvedAnimation(
      parent: _stackController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _stackController.dispose();
    super.dispose();
  }

  void _toggleStack() {
    HapticFeedback.mediumImpact();
    setState(() => _stackExpanded = !_stackExpanded);
    if (_stackExpanded) {
      _stackController.forward();
    } else {
      _stackController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = ref.watch(spacingProvider);
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    final dashboardAsync = ref.watch(dashboardDataProvider);
    final isGuestMode = ref.watch(guestModeProvider);
    final displayStyle = ref.watch(accountDisplayStyleProvider);

    final data = dashboardAsync.valueOrNull;
    if (data == null) {
      return const Column(children: [AccountCardSkeleton()]);
    }

    final accounts = data.accounts;
    if (accounts.isEmpty) {
      return Center(child: NoDataFound(
        message: BuddyMessages.noAccounts,
        iconData: LucideIcons.wallet,
      ),);
    }

    final balanceMap = data.accountBalances;
    final totalBalance =
        GuestModeUtil.applyGuestMode(data.totalBalance, isGuestMode);
    final income = GuestModeUtil.applyGuestMode(data.totalIncome, isGuestMode);
    final expense =
        GuestModeUtil.applyGuestMode(data.totalExpense, isGuestMode);
    final netCashFlow = income - expense;

    final header = _buildHeader(
      spacing,
      textTheme,
      color,
      totalBalance,
      netCashFlow,
      accounts, // new
      balanceMap, // new
      isGuestMode, // new
    );

    return RepaintBoundary(
      child: switch (displayStyle) {
        AccountDisplayStyle.carousel => _buildCarouselSection(
            header,
            accounts,
            balanceMap,
            isGuestMode,
            spacing,
            textTheme,
            color,
          ),
        AccountDisplayStyle.stack => _buildStackSection(
            header,
            accounts,
            balanceMap,
            isGuestMode,
            spacing,
            textTheme,
            color,
          ),
        AccountDisplayStyle.bento => _buildBentoSection(
            header,
            accounts,
            balanceMap,
            isGuestMode,
            spacing,
            textTheme,
            color,
          ),
      },
    );
  }

  // ── SHARED HEADER ──
  List<Widget> _buildHeader(
    AppSpacing spacing,
    TextTheme textTheme,
    ColorScheme color,
    double totalBalance,
    double netCashFlow,
    List<Account> accounts,
    Map<int, double> balanceMap,
    bool isGuestMode,
  ) {
    final ctxt = AppLocalizations.of(context)!;
    final isTotal = balanceViewIndex == -1;
    final displayLabel =
        isTotal ? ctxt.dashboard_totalBalance : accounts[balanceViewIndex].name;
    final displayBalance = isTotal
        ? totalBalance
        : GuestModeUtil.applyGuestMode(
            balanceMap[accounts[balanceViewIndex].id] ?? 0,
            isGuestMode,
          );

    return [
      Padding(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.cardHorizontal,
          vertical: spacing.cardVertical,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              displayLabel,
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
                      ctxt.dashboard_netWorthLink,
                      style: textTheme.labelMedium?.copyWith(
                        color: color.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: spacing.elementGap / 2),
                    Icon(
                      LucideIcons.chevronRight,
                      size: 12,
                      color: color.primary,
                    ),
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
          padding: EdgeInsets.symmetric(horizontal: spacing.cardHorizontal),
          child: Row(
            children: [
              Expanded(
                child: AnimatedBalance(
                  value: displayBalance,
                  currencyCode: isTotal ? null : accounts[balanceViewIndex].currencyCode,
                  style: textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: color.onSurface,
                  ),
                  compact: false,
                  fixedStringLength: 0,
                ),
              ),
              if (accounts.length > 1) ...[
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      balanceViewIndex++;
                      if (balanceViewIndex >= accounts.length) {
                        balanceViewIndex = -1;
                      }
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.all(spacing.elementGap),
                    decoration: BoxDecoration(
                      color: color.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.chevronRight,
                      size: 18,
                      color: color.onSurfaceVariant,
                    ),
                  ),
                ),
                SizedBox(width: spacing.elementGap),
              ],
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.cardHorizontal,
                  vertical: spacing.cardVertical,
                ),
                decoration: BoxDecoration(
                  color: netCashFlow >= 0
                      ? color.primaryContainer
                      : color.errorContainer,
                  borderRadius: BorderRadius.circular(spacing.radiusLarge),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      netCashFlow >= 0
                          ? LucideIcons.trendingUp
                          : LucideIcons.trendingDown,
                      size: 16,
                      color: netCashFlow >= 0 ? color.primary : color.error,
                    ),
                    SizedBox(width: spacing.elementGap / 2),
                    AnimatedBalance(
                      value: netCashFlow,
                      style: textTheme.labelMedium?.copyWith(
                        color: netCashFlow >= 0 ? color.primary : color.error,
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
      GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _accountsExpanded = !_accountsExpanded);
        },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: spacing.cardHorizontal),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.cardHorizontal,
                  vertical: spacing.elementGap / 2,
                ),
                decoration: BoxDecoration(
                  color: color.surfaceContainerHighest.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(spacing.radiusSmall),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _accountsExpanded ? ctxt.dashboard_hideAccounts : ctxt.dashboard_showAccounts,
                      style: textTheme.labelSmall?.copyWith(
                        color: color.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: spacing.elementGap / 2),
                    AnimatedRotation(
                      turns: _accountsExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 250),
                      child: Icon(
                        LucideIcons.chevronDown,
                        size: 16,
                        color: color.onSurfaceVariant,
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
    ];
  }

  // ── CAROUSEL SECTION (existing) ──
  Widget _buildCarouselSection(
    List<Widget> header,
    List<Account> accounts,
    Map<int, double> balanceMap,
    bool isGuestMode,
    AppSpacing spacing,
    TextTheme textTheme,
    ColorScheme color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...header,
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _accountsExpanded
              ? Column(
                  children: [
                    SizedBox(
                      height: spacing == const AppSpacing() ? 100.0 : 140.0,
                      child: _buildCarousel(
                        accounts,
                        balanceMap,
                        isGuestMode,
                        spacing,
                        textTheme,
                      ),
                    ),
                    SizedBox(height: spacing.cardVertical),
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
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  // ── STACK SECTION ──
  Widget _buildStackSection(
    List<Widget> header,
    List<Account> accounts,
    Map<int, double> balanceMap,
    bool isGuestMode,
    AppSpacing spacing,
    TextTheme textTheme,
    ColorScheme color,
  ) {
    const collapsedCardHeight = 72.0;
    const stackPeek = 5.0;
    final maxPeekCards = math.min(accounts.length, 5);
    final collapsedHeight =
        collapsedCardHeight + (maxPeekCards - 1) * stackPeek;
    final expandedHeight = accounts.length * (collapsedCardHeight + 8.0) - 8.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...header,
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _accountsExpanded
              ? AnimatedBuilder(
                  animation: _stackAnimation,
                  builder: (context, _) {
                    final t = _stackAnimation.value;
                    final currentHeight = collapsedHeight +
                        (expandedHeight - collapsedHeight) * t;

                    return Column(
                      children: [
                        GestureDetector(
                          onTap: _toggleStack,
                          child: SizedBox(
                            height: currentHeight,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: spacing.cardHorizontal,
                              ),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children:
                                    List.generate(accounts.length, (index) {
                                  final account = accounts[index];
                                  final accentColor =
                                      Color(account.colorValue ?? 0xFF6B4CE6);
                                  final balance = GuestModeUtil.applyGuestMode(
                                    balanceMap[account.id] ?? 0,
                                    isGuestMode,
                                  );
                                  final collapsedTop = index < maxPeekCards
                                      ? index * stackPeek
                                      : (maxPeekCards - 1) * stackPeek;
                                  final expandedTop =
                                      index * (collapsedCardHeight + 8.0);
                                  final top = collapsedTop +
                                      (expandedTop - collapsedTop) * t;
                                  final collapsedScale = 1.0 -
                                      (math.min(index, maxPeekCards - 1) *
                                          0.02);
                                  final scale = collapsedScale +
                                      (1.0 - collapsedScale) * t;
                                  final opacity = index == 0
                                      ? 1.0
                                      : (0.4 + 0.6 * t).clamp(0.0, 1.0);

                                  return Positioned(
                                    top: top,
                                    left: 0,
                                    right: 0,
                                    child: Transform.scale(
                                      scale: scale,
                                      alignment: Alignment.topCenter,
                                      child: Opacity(
                                        opacity: opacity,
                                        child: Container(
                                          height: collapsedCardHeight,
                                          decoration: BoxDecoration(
                                            color: accentColor,
                                            borderRadius: BorderRadius.circular(
                                              spacing.radiusMedium,
                                            ),
                                          ),
                                          padding: EdgeInsets.symmetric(
                                            horizontal:
                                                spacing.cardHorizontalMax,
                                            vertical: spacing.cardVertical,
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      account.name,
                                                      style: textTheme
                                                          .titleSmall
                                                          ?.copyWith(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    SizedBox(height: spacing.elementGap / 4),
                                                    Text(
                                                      account.accountType.label,
                                                      style: textTheme
                                                          .labelSmall
                                                          ?.copyWith(
                                                        color: Colors.white
                                                            .withValues(
                                                                alpha: 0.7,),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              AnimatedBalance(
                                                currencyCode: account.currencyCode,
                                                value: balance,
                                                compact: false,
                                                fixedStringLength: 0,
                                                style: textTheme.titleMedium
                                                    ?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                  fontFamily: 'monospace',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).reversed.toList(),
                              ),
                            ),
                          ),
                        ),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: _stackExpanded ? 0.0 : 1.0,
                          child: Padding(
                            padding: EdgeInsets.only(top: spacing.cardVertical),
                            child: Center(
                              child: Text(
                                AppLocalizations.of(context)!.dashboard_accountsTapExpand(accounts.length),
                                style: textTheme.labelSmall?.copyWith(
                                  color: color.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                )
              : const SizedBox.shrink(),
        ),
        SizedBox(height: spacing.cardVertical),
      ],
    );
  }

// ── BENTO GRID SECTION ──
  Widget _buildBentoSection(
    List<Widget> header,
    List<Account> accounts,
    Map<int, double> balanceMap,
    bool isGuestMode,
    AppSpacing spacing,
    TextTheme textTheme,
    ColorScheme color,
  ) {
    // Sort by balance descending for visual weight
    final sorted = List<Account>.from(accounts)
      ..sort(
        (a, b) => (balanceMap[b.id] ?? 0)
            .abs()
            .compareTo((balanceMap[a.id] ?? 0).abs()),
      );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...header,
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _accountsExpanded
              ? Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: spacing.cardHorizontal),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final gridWidth = constraints.maxWidth;
                      final gap = spacing.elementGap;
                      final halfWidth = (gridWidth - gap) / 2;
                      const smallTileHeight = 88.0;
                      const largeTileHeight =
                          88.0 * 2 + 8.0; // two small tiles + gap

                      final tiles = <Widget>[];

                      if (sorted.length == 1) {
                        tiles.add(
                          _buildBentoTile(
                            sorted[0],
                            balanceMap,
                            isGuestMode,
                            spacing,
                            textTheme,
                            width: gridWidth,
                            height: smallTileHeight,
                            isLarge: false,
                          ),
                        );
                      } else if (sorted.length == 2) {
                        tiles.add(
                          Row(
                            children: [
                              _buildBentoTile(
                                sorted[0],
                                balanceMap,
                                isGuestMode,
                                spacing,
                                textTheme,
                                width: halfWidth,
                                height: smallTileHeight + 40,
                                isLarge: false,
                              ),
                              SizedBox(width: gap),
                              _buildBentoTile(
                                sorted[1],
                                balanceMap,
                                isGuestMode,
                                spacing,
                                textTheme,
                                width: halfWidth,
                                height: smallTileHeight + 40,
                                isLarge: false,
                              ),
                            ],
                          ),
                        );
                      } else if (sorted.length == 3) {
                        // Hero left (tall) + two stacked right
                        tiles.add(
                          SizedBox(
                            height: largeTileHeight,
                            child: Row(
                              children: [
                                _buildBentoTile(
                                  sorted[0],
                                  balanceMap,
                                  isGuestMode,
                                  spacing,
                                  textTheme,
                                  width: halfWidth,
                                  height: largeTileHeight,
                                  isLarge: true,
                                ),
                                SizedBox(width: gap),
                                SizedBox(
                                  width: halfWidth,
                                  child: Column(
                                    children: [
                                      _buildBentoTile(
                                        sorted[1],
                                        balanceMap,
                                        isGuestMode,
                                        spacing,
                                        textTheme,
                                        width: halfWidth,
                                        height: smallTileHeight,
                                        isLarge: false,
                                      ),
                                      SizedBox(height: gap),
                                      _buildBentoTile(
                                        sorted[2],
                                        balanceMap,
                                        isGuestMode,
                                        spacing,
                                        textTheme,
                                        width: halfWidth,
                                        height: smallTileHeight,
                                        isLarge: false,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      } else {
                        // 4+ accounts: hero tile on top, rest in 2-col grid
                        // Hero = full width
                        tiles.add(
                          _buildBentoTile(
                            sorted[0],
                            balanceMap,
                            isGuestMode,
                            spacing,
                            textTheme,
                            width: gridWidth,
                            height: smallTileHeight + 20,
                            isLarge: true,
                          ),
                        );
                        tiles.add(SizedBox(height: gap));

                        // Remaining in pairs
                        final rest = sorted.sublist(1);
                        for (int i = 0; i < rest.length; i += 2) {
                          if (i + 1 < rest.length) {
                            tiles.add(
                              Row(
                                children: [
                                  _buildBentoTile(
                                    rest[i],
                                    balanceMap,
                                    isGuestMode,
                                    spacing,
                                    textTheme,
                                    width: halfWidth,
                                    height: smallTileHeight,
                                    isLarge: false,
                                  ),
                                  SizedBox(width: gap),
                                  _buildBentoTile(
                                    rest[i + 1],
                                    balanceMap,
                                    isGuestMode,
                                    spacing,
                                    textTheme,
                                    width: halfWidth,
                                    height: smallTileHeight,
                                    isLarge: false,
                                  ),
                                ],
                              ),
                            );
                          } else {
                            // Odd one out — full width
                            tiles.add(
                              _buildBentoTile(
                                rest[i],
                                balanceMap,
                                isGuestMode,
                                spacing,
                                textTheme,
                                width: gridWidth,
                                height: smallTileHeight,
                                isLarge: false,
                              ),
                            );
                          }
                          if (i + 2 < rest.length) {
                            tiles.add(SizedBox(height: gap));
                          }
                        }
                      }

                      return Column(children: tiles);
                    },
                  ),
                )
              : const SizedBox.shrink(),
        ),
        SizedBox(height: spacing.cardVertical),
      ],
    );
  }

  Widget _buildBentoTile(
    Account account,
    Map<int, double> balanceMap,
    bool isGuestMode,
    AppSpacing spacing,
    TextTheme textTheme, {
    required double width,
    required double height,
    required bool isLarge,
  }) {
    final accentColor = Color(account.colorValue ?? 0xFF6B4CE6);
    final balance = GuestModeUtil.applyGuestMode(
      balanceMap[account.id] ?? 0,
      isGuestMode,
    );

    return SizedBox(
      width: width,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          color: accentColor,
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
        ),
        padding: EdgeInsets.all(spacing.cardInner),
        child: isLarge
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        account.accountType.icon,
                        color: Colors.white.withValues(alpha: 0.8),
                        size: 22,
                      ),
                      SizedBox(width: spacing.elementGap),
                      Expanded(
                        child: Text(
                          account.name,
                          style: textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    account.accountType.label,
                    style: textTheme.labelSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                  AnimatedBalance(
                    currencyCode: account.currencyCode,
                    value: balance,
                    compact: false,
                    fixedStringLength: 0,
                    style: textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        account.accountType.icon,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 18,
                      ),
                      SizedBox(width: spacing.elementGap),
                      Expanded(
                        child: Text(
                          account.name,
                          style: textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  AnimatedBalance(
                    currencyCode: account.currencyCode,
                    value: balance,
                    compact: true,
                    fixedStringLength: 0,
                    style: textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ── CAROUSEL (existing PageView) ──
  Widget _buildCarousel(
    List<Account> accounts,
    Map<int, double> balanceMap,
    bool isGuestMode,
    AppSpacing spacing,
    TextTheme textTheme,
  ) {
    return PageView.builder(
      key: const PageStorageKey('account_cards_pageview'),
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
                color: Color(account.colorValue ?? 0xFF6B4CE6),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(spacing.radiusLarge),
                  topRight: Radius.circular(spacing.radiusLarge),
                ),
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
                              color: Colors.white.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      SizedBox(height: spacing.cardVertical),
                      AnimatedBalance(
                        currencyCode: account.currencyCode,
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
    );
  }
}
