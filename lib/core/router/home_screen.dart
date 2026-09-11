import 'package:animations/animations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:mudra_manager/core/db/models/notification_record.dart';
import 'package:mudra_manager/core/db/models/user_profile.dart';
import 'package:mudra_manager/core/entitlement/entitlement_provider.dart';
import 'package:mudra_manager/core/extension/localization_extenstion.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:mudra_manager/core/providers/app_mode_provider.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/providers/notification_record_service.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/services/notification_service.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/features/account/data/account_providers.dart';
import 'package:mudra_manager/features/dashboard/data/greeting_provider.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/dashboard_data_provider.dart';
import 'package:mudra_manager/features/dashboard/presentation/screens/dashboard_home.dart';
import 'package:mudra_manager/features/gamification/data/achievement_unlock_listener.dart';
import 'package:mudra_manager/features/gamification/presentation/widgets/streak_indicator.dart';
import 'package:mudra_manager/features/profile/data/user_profile_provider.dart';
import 'package:mudra_manager/features/profile/presentation/screens/profile_reference_screen.dart';
import 'package:mudra_manager/features/statistics/presentation/screens/statistics_screen.dart';
import 'package:mudra_manager/features/transactions/data/view_mode_provider.dart';
import 'package:mudra_manager/features/transactions/domain/transaction_view_mode.dart';
import 'package:mudra_manager/features/transactions/presentation/screens/transaction_list_screen.dart';
import 'package:mudra_manager/features/statistics/presentation/screens/utility_screen.dart';
import 'package:mudra_manager/features/transactions/presentation/widgets/quick_add_transaction_sheet.dart';
import 'package:mudra_manager/shared/widgets/adaptive_text.dart';
import 'package:mudra_manager/shared/widgets/finance_v2/finance_amount.dart';
import 'package:mudra_manager/shared/widgets/animated_greeting.dart';
import 'package:flutter_boring_avatars/flutter_boring_avatars.dart';
import 'package:mudra_manager/features/trip/data/trip_provider.dart';
import 'package:mudra_manager/shared/widgets/speed_dial_fab.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/core/db/field_encryption_service.dart';

class HomePage extends ConsumerStatefulWidget {
  final int initialIndex;
  const HomePage({super.key, this.initialIndex = 0});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends ConsumerState<HomePage> {
  late int _selectedIndex;
  final transactionListKey = GlobalKey<TransactionListScreenState>();
  final utilityKey = GlobalKey<UtilityScreenState>();
  late AppLog log;
  final _speedDialKey = GlobalKey<ExpandableFabState>();

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    // Critical — needed for widget click handling
    _setupMethodChannel();
    _setupWidgetClickListener();

    // Deferred — not needed for first frame
    Future.delayed(const Duration(seconds: 2), () {
      if (!context.mounted) return;
      initNotification();
      ref.read(achievementUnlockListenerProvider).initialize(context);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    log = AppLog(ref.read(loggerProvider), 'HomeScreen');
  }

  void _setupMethodChannel() {
    const platform = MethodChannel('com.mudramanager.app/widget');
    platform.setMethodCallHandler((call) async {
      if (call.method == 'widgetAction') {
        final action = call.arguments as String?;
        log.i('Widget action received: $action');
        if (action == 'add_transaction' || action == 'ADD_TRANSACTION') {
          await Future.delayed(const Duration(milliseconds: 300));
          if (context.mounted) {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => const QuickAddTransactionSheet(),
            );
          }
        }
      }
    });
  }

  void _setupWidgetClickListener() {
    HomeWidget.widgetClicked.listen((uri) {
      if (uri?.host == 'add_transaction' && mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => const QuickAddTransactionSheet(),
        );
      }
    });
  }

  @override
  void didUpdateWidget(HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIndex != oldWidget.initialIndex) {
      _selectedIndex = widget.initialIndex;
    }
  }

  int? _stackIndexForNavigationIndex(int index, bool isSimple) {
    if (isSimple) {
      return switch (index) {
        0 => 0,
        1 => 1,
        _ => null,
      };
    }

    return switch (index) {
      0 => 0,
      1 => 1,
      2 => 2,
      3 => 3,
      _ => null,
    };
  }

  int? _navigationIndexForStackIndex(int index, bool isSimple) {
    if (isSimple) {
      return switch (index) {
        0 => 0,
        1 => 1,
        _ => null,
      };
    }

    return switch (index) {
      0 => 0,
      1 => 1,
      2 => 2,
      3 => 3,
      _ => null,
    };
  }

  void _openProfile() {
    HapticFeedback.mediumImpact();
    context.push(AppRoutes.profile);
  }

  void _onTabSelected(int index) {
    final stackIndex = _stackIndexForNavigationIndex(
      index,
      ref.read(isSimpleModeProvider),
    );
    if (stackIndex == null) return;

    HapticFeedback.mediumImpact();
    log.d('Tab changed: $index');
    setState(() => _selectedIndex = stackIndex);
    _speedDialKey.currentState?.close();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeEntitlementGuardProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final ctxt = AppLocalizations.of(context)!;
    final isSimple = ref.watch(isSimpleModeProvider);
    final color = Theme.of(context).colorScheme;
    final shellBackground = color.surface;
    // Full mode: Home(0), Activity(1), Manage(2), Insights(3).
    // Simple mode: Home(0), Activity(1), with add action separated to the right.
    final effectiveStackIndex = _selectedIndex.clamp(0, 4).toInt();
    final selectedNavigationIndex =
        _navigationIndexForStackIndex(effectiveStackIndex, isSimple) ?? 0;
    final stackIndex = effectiveStackIndex;

    return PopScope(
      canPop: effectiveStackIndex == 0,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && effectiveStackIndex != 0) {
          _onTabSelected(0);
        }
      },
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: shellBackground,
            appBar: buildTopBar(profileAsync, stackIndex),
            // Reference-matched floating navigation dock.
            extendBody: true,
            bottomNavigationBar: _buildFloatingBottomNav(
              color: color,
              ctxt: ctxt,
              isSimple: isSimple,
              selectedNavigationIndex: selectedNavigationIndex,
            ),
            body: Stack(
              children: [
                PageTransitionSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder:
                      (child, primaryAnimation, secondaryAnimation) {
                    return FadeThroughTransition(
                      animation: primaryAnimation,
                      secondaryAnimation: secondaryAnimation,
                      child: child,
                    );
                  },
                  child: IndexedStack(
                    index: stackIndex,
                    children: [
                      const DashboardHome(),
                      TransactionListScreen(
                        key: transactionListKey,
                        isTabActive: stackIndex == 1,
                      ),
                      UtilityScreen(
                        key: utilityKey,
                        isTabActive: stackIndex == 2,
                      ),
                      const StatisticsScreen(),
                      const ProfileReferenceScreen(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ExpandableFab(
            key: _speedDialKey,
            collapsedAsCircle: true,
            showCollapsedButton: false,
            padding: const EdgeInsets.only(bottom: 84),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingBottomNav({
    required ColorScheme color,
    required AppLocalizations ctxt,
    required bool isSimple,
    required int selectedNavigationIndex,
  }) {
    final destinations = <_FloatingNavDestination>[
      _FloatingNavDestination(
        outlineAsset: 'assets/logo/nav/outline/home.svg',
        solidAsset: 'assets/logo/nav/solid/home.svg',
        label: ctxt.home_screen_title,
      ),
      _FloatingNavDestination(
        outlineAsset: 'assets/logo/nav/outline/activity.svg',
        solidAsset: 'assets/logo/nav/solid/activity.svg',
        label: ctxt.nav_activity,
        iconScale: 1.25,
      ),
      _FloatingNavDestination(
        outlineAsset: 'assets/logo/nav/outline/utility.svg',
        solidAsset: 'assets/logo/nav/solid/utility.svg',
        label: ctxt.nav_manage,
        usesTripIcon: true,
      ),
      _FloatingNavDestination(
        outlineAsset: 'assets/logo/nav/outline/statistics.svg',
        solidAsset: 'assets/logo/nav/solid/statistics.svg',
        label: ctxt.nav_insights,
      ),
    ];

    if (isSimple) destinations.removeRange(2, destinations.length);

    final isLight = color.brightness == Brightness.light;
    final dockRadius = BorderRadius.circular(22);
    final dockColor =
        isLight ? color.surfaceContainerLow : color.surfaceContainerHigh;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(40, 6, 40, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              height: 56,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: dockColor,
                borderRadius: dockRadius,
                border: Border.all(
                  color: color.outlineVariant.withValues(
                    alpha: isLight ? 0.72 : 0.42,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.shadow.withValues(alpha: isLight ? 0.18 : 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: dockRadius,
                clipBehavior: Clip.antiAlias,
                child: Row(
                  children: [
                    for (var index = 0; index < destinations.length; index++)
                      _buildFloatingNavItem(
                        destination: destinations[index],
                        selected: selectedNavigationIndex == index,
                        color: color,
                        onTap: () => _onTabSelected(index),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _buildCenterAddButton(color),
        ],
      ),
    );
  }

  Widget _buildFloatingNavItem({
    required _FloatingNavDestination destination,
    required bool selected,
    required ColorScheme color,
    required VoidCallback onTap,
  }) {
    final iconColor =
        selected ? color.onPrimaryContainer : color.onSurfaceVariant;
    var outlineAsset = destination.outlineAsset;
    var solidAsset = destination.solidAsset;

    if (destination.usesTripIcon) {
      final activeTrips = ref.watch(activeTripsProvider);
      final hasActiveTrip = activeTrips.maybeWhen(
        data: (trips) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          return trips.any((trip) {
            if (!trip.isTrip) return false;
            final start = DateTime(
              trip.startDate.year,
              trip.startDate.month,
              trip.startDate.day,
            );
            return trip.isActive && !today.isBefore(start);
          });
        },
        orElse: () => false,
      );
      if (hasActiveTrip) {
        outlineAsset = 'assets/logo/nav/outline/trip.svg';
        solidAsset = 'assets/logo/nav/solid/trip.svg';
      }
    }

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: destination.label,
        child: Tooltip(
          message: destination.label,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              customBorder: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color:
                        selected ? color.primaryContainer : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: selected
                        ? Border.all(
                            color: color.primary.withValues(alpha: 0.14),
                          )
                        : null,
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: color.primary.withValues(alpha: 0.16),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: _buildNormalizedNavIcon(
                    asset: selected ? solidAsset : outlineAsset,
                    color: iconColor,
                    scale: destination.iconScale,
                  ).animate(target: selected ? 1 : 0).scale(
                        begin: const Offset(0.9, 0.9),
                        end: const Offset(1, 1),
                        curve: Curves.easeOutCubic,
                        duration: 250.ms,
                      ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNormalizedNavIcon({
    required String asset,
    required Color color,
    required double scale,
  }) {
    return SizedBox.square(
      dimension: 24,
      child: Center(
        child: Transform.scale(
          scale: scale,
          child: SvgPicture.asset(
            asset,
            width: 22,
            height: 22,
            fit: BoxFit.contain,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterAddButton(ColorScheme color) {
    return SizedBox.square(
      dimension: 52,
      child: FloatingActionButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          _speedDialKey.currentState?.toggle();
        },
        tooltip: 'Add transaction',
        backgroundColor: color.primary,
        foregroundColor: color.onPrimary,
        elevation: 4,
        focusColor: color.primary.withValues(alpha: 0.12),
        hoverColor: color.primary.withValues(alpha: 0.12),
        shape: const CircleBorder(),
        child: const Icon(LucideIcons.plus, size: 24),
      ),
    );
  }

  PreferredSizeWidget _buildActivityHomeStyleHeader(
    TextTheme textTheme,
    ColorScheme color,
    AppLocalizations ctxt,
    AppSpacing spacing,
  ) {
    final viewMode = ref.watch(viewModeProvider);
    final calendarLabel = switch (viewMode) {
      DateRangeView(:final start, :final end) =>
        '${DateFormat.MMMd(ctxt.localeName).format(start)} - ${DateFormat.MMMd(ctxt.localeName).format(end)}',
      MonthView(:final year, :final month) =>
        MaterialLocalizations.of(context).formatMonthYear(
          DateTime(year, month),
        ),
      InfiniteView() => MaterialLocalizations.of(context).formatMonthYear(
          DateTime.now(),
        ),
    };

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: color.surfaceContainerHigh,
      foregroundColor: color.onSurface,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.surfaceContainerHigh,
              color.primaryContainer.withValues(alpha: 0.72),
            ],
          ),
        ),
      ),
      scrolledUnderElevation: 0,
      toolbarHeight: 80,
      titleSpacing: spacing.cardInner,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(spacing.radiusLarge + spacing.elementGap),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      title: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ctxt.transaction_screen_title,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: spacing.elementGapMin),
          Material(
            color: color.surface.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(spacing.radiusMedium),
            child: InkWell(
              onTap: () {
                HapticFeedback.mediumImpact();
                transactionListKey.currentState?.toggleCalendarSelection();
              },
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.elementGap,
                  vertical: spacing.elementGapMin,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.calendarDays,
                      size: spacing.iconXS,
                      color: color.primary,
                    ),
                    SizedBox(width: spacing.elementGapMin),
                    Text(
                      calendarLabel,
                      style: textTheme.labelMedium?.copyWith(
                        color: color.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(width: spacing.elementGapMin),
                    Icon(
                      LucideIcons.chevronDown,
                      size: spacing.iconXS,
                      color: color.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: spacing.elementGapMin),
          child: IconButton(
            tooltip: ctxt.common_search,
            onPressed: () {
              HapticFeedback.mediumImpact();
              transactionListKey.currentState?.toggleSearch();
            },
            icon: const Icon(LucideIcons.search),
            style: IconButton.styleFrom(
              foregroundColor: color.onSurface,
              backgroundColor: color.surfaceContainerHighest,
              minimumSize: Size.square(spacing.touchTargetSmall),
              maximumSize: Size.square(spacing.touchTargetSmall),
              padding: EdgeInsets.zero,
              shape: const CircleBorder(),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(right: spacing.cardInner),
          child: IconButton(
            tooltip: ctxt.common_filter,
            onPressed: () => transactionListKey.currentState
                ?.showFilterBottomSheet(context, spacing),
            icon: const Icon(LucideIcons.listFilter),
            style: IconButton.styleFrom(
              foregroundColor: color.onSurface,
              backgroundColor: color.surfaceContainerHighest,
              minimumSize: Size.square(spacing.touchTargetSmall),
              maximumSize: Size.square(spacing.touchTargetSmall),
              padding: EdgeInsets.zero,
              shape: const CircleBorder(),
            ),
          ),
        ),
      ],
    );
  }

  PreferredSizeWidget? buildTopBar(
    AsyncValue<UserProfile?> profileAsync,
    int selectedIndex,
  ) {
    final toneGreeting = ref.watch(greetingProvider);
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    final notificationService = ref.watch(notificationRecordServiceProvider);
    final ctxt = AppLocalizations.of(context)!;
    final spacing = ref.watch(spacingProvider);
    final isBalanceVisible = ref.watch(balanceVisibilityProvider);

    switch (selectedIndex) {
      case 0:
        final totalBalance = ref.watch(dashboardTotalBalanceProvider);
        return AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: color.surfaceContainerHigh,
          flexibleSpace: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.surfaceContainerHigh,
                  color.primaryContainer.withValues(alpha: 0.72),
                ],
              ),
            ),
          ),
          scrolledUnderElevation: 0,
          toolbarHeight: 80,
          titleSpacing: spacing.cardInner,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(spacing.radiusLarge + spacing.elementGap),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          title: GestureDetector(
            onTap: _openProfile,
            child: Row(
              children: [
                profileAsync.when(
                  data: (profile) => Container(
                    width: spacing.touchTargetSmall,
                    height: spacing.touchTargetSmall,
                    padding: EdgeInsets.all(spacing.elementGapMin / 2),
                    decoration: BoxDecoration(
                      color: color.surfaceContainerHighest,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.primary.withValues(alpha: 0.32),
                        width: spacing.strokeThin,
                      ),
                    ),
                    child: ClipOval(
                      child: BoringAvatar(
                        name: FieldEncryptionService.safeDisplay(
                          profile?.name,
                          'User',
                        ),
                        palette: BoringAvatarPalette([
                          color.primary,
                          color.tertiary,
                          color.primaryContainer,
                          color.tertiaryContainer,
                        ]),
                        type: BoringAvatarType.beam,
                      ),
                    ),
                  ),
                  loading: () => Container(
                    width: spacing.touchTargetSmall,
                    height: spacing.touchTargetSmall,
                    decoration: BoxDecoration(
                      color: color.surfaceContainerHighest,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.outlineVariant,
                        width: spacing.strokeThin,
                      ),
                    ),
                  ),
                  error: (_, __) => Container(
                    width: spacing.touchTargetSmall,
                    height: spacing.touchTargetSmall,
                    decoration: BoxDecoration(
                      color: color.surfaceContainerHighest,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.outlineVariant,
                        width: spacing.strokeThin,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: spacing.radiusMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      profileAsync.when(
                        data: (profile) => AnimatedGreeting(
                          greeting: '${ctxt.translate(toneGreeting)},',
                          name: FieldEncryptionService.safeDisplay(
                            profile?.name,
                            'Awesome User',
                          ),
                          greetingStyle: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w400,
                          ),
                          nameStyle: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        loading: () => AdaptiveText(
                          '${ctxt.translate(toneGreeting)},',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                        ),
                        error: (_, __) => AdaptiveText(
                          '${ctxt.translate(toneGreeting)},',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                        ),
                      ),
                      SizedBox(height: spacing.elementGapMin / 2),
                      Text(
                        'Turn dreams into balance',
                        style: textTheme.bodySmall?.copyWith(
                          color: color.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(
              spacing.cardInner * 3 + spacing.sectionGap,
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                spacing.cardInner,
                0,
                spacing.cardInner,
                spacing.cardInner,
              ),
              child: Container(
                padding: EdgeInsets.all(spacing.elementGap),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${ctxt.balanceHistory_currentBalance} (${BaseCurrency.code})',
                            style: textTheme.bodySmall?.copyWith(
                              color: color.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: spacing.elementGapMin),
                          FinanceAmount(
                            value: totalBalance,
                            compact: false,
                            fixedStringLength: 2,
                            glow: true,
                            glowColor: color.primary,
                            style: textTheme.headlineMedium?.copyWith(
                              color: color.onSurface,
                              fontWeight: FontWeight.w500,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: spacing.elementGapMin),
                    IconButton(
                      tooltip:
                          isBalanceVisible ? 'Hide balance' : 'Show balance',
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        ref
                            .read(balanceVisibilityProvider.notifier)
                            .update((visible) => !visible);
                      },
                      icon: Icon(
                        isBalanceVisible ? LucideIcons.eye : LucideIcons.eyeOff,
                      ),
                      style: IconButton.styleFrom(
                        foregroundColor: color.onSurfaceVariant,
                        backgroundColor: color.surfaceContainerHighest,
                        minimumSize: Size.square(spacing.touchTargetSmall),
                        shape: const CircleBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: spacing.cardHorizontal),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [StreakIndicator()],
              ),
            ),
            Consumer(
              builder: (context, ref, _) {
                final activeTrips = ref.watch(activeTripsProvider);
                return activeTrips.maybeWhen(
                  data: (trips) {
                    if (trips.isEmpty) return const SizedBox.shrink();
                    final now = DateTime.now();
                    final today = DateTime(now.year, now.month, now.day);

                    // Find active ongoing trip (started & isTrip)
                    final ongoingTrip = trips.where((t) {
                      if (!t.isTrip) return false;
                      final start = DateTime(
                        t.startDate.year,
                        t.startDate.month,
                        t.startDate.day,
                      );
                      return !today.isBefore(start);
                    }).firstOrNull;

                    // Find upcoming trip within 7 days
                    final upcomingTrip = ongoingTrip == null
                        ? trips.where((t) {
                            if (!t.isTrip) return false;
                            final start = DateTime(
                              t.startDate.year,
                              t.startDate.month,
                              t.startDate.day,
                            );
                            final daysUntil = start.difference(today).inDays;
                            return daysUntil > 0 && daysUntil <= 7;
                          }).firstOrNull
                        : null;

                    final trip = ongoingTrip ?? upcomingTrip;
                    if (trip == null) return const SizedBox.shrink();

                    final isUpcoming = ongoingTrip == null;
                    final daysUntil = isUpcoming
                        ? DateTime(
                            trip.startDate.year,
                            trip.startDate.month,
                            trip.startDate.day,
                          ).difference(today).inDays
                        : 0;

                    return InkWell(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        context.push(AppRoutes.tripDetail, extra: trip.id);
                      },
                      borderRadius: BorderRadius.circular(spacing.radiusMedium),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: spacing.cardHorizontal,
                          vertical: spacing.cardVertical,
                        ),
                        decoration: BoxDecoration(
                          color: isUpcoming
                              ? color.tertiaryContainer
                              : color.secondaryContainer,
                          borderRadius:
                              BorderRadius.circular(spacing.radiusMedium),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isUpcoming
                                  ? LucideIcons.calendar
                                  : LucideIcons.planeTakeoff,
                              size: 14,
                              color: isUpcoming
                                  ? color.onTertiaryContainer
                                  : color.onSecondaryContainer,
                            ),
                            SizedBox(width: spacing.elementGapMin),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 72),
                              child: Text(
                                isUpcoming
                                    ? '${daysUntil}d · ${trip.name}'
                                    : trip.name,
                                style: textTheme.labelSmall?.copyWith(
                                  color: isUpcoming
                                      ? color.onTertiaryContainer
                                      : color.onSecondaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 300.ms)
                        .slideX(begin: 0.2, end: 0);
                  },
                  orElse: () => const SizedBox.shrink(),
                );
              },
            ),
            StreamBuilder<List<NotificationRecord>>(
              stream: notificationService.watchNotifications(),
              builder: (_, snapshot) {
                final count = (snapshot.data ?? [])
                    .where((n) => !n.isRead && !n.isArchived)
                    .length;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      tooltip: ctxt.common_notifications,
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        context.push(AppRoutes.notifications);
                      },
                      icon: const Icon(LucideIcons.bell),
                      style: IconButton.styleFrom(
                        foregroundColor: color.onSurface,
                        backgroundColor: Colors.transparent,
                        side: BorderSide(
                          color: color.onSurface.withValues(alpha: 0.28),
                          width: spacing.strokeThin,
                        ),
                        minimumSize: Size.square(spacing.touchTargetSmall),
                        maximumSize: Size.square(spacing.touchTargetSmall),
                        padding: EdgeInsets.zero,
                        shape: const CircleBorder(),
                      ),
                    ),
                    if (count > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.elasticOut,
                          builder: (_, scale, child) =>
                              Transform.scale(scale: scale, child: child),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: color.error,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              count > 9 ? '9+' : '$count',
                              style: TextStyle(
                                color: color.onError,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            SizedBox(width: spacing.elementGap),
          ],
        );
      case 1:
        return _buildActivityHomeStyleHeader(
          textTheme,
          color,
          ctxt,
          spacing,
        );
      case 2:
        return AppBar(
          automaticallyImplyLeading: false,
          title: Text(ctxt.nav_manage, style: textTheme.titleLarge),
          actions: [
            IconButton(
              onPressed: () {
                utilityKey.currentState?.showCustomizeSheet();
              },
              icon: const Icon(LucideIcons.settings2),
              tooltip: ctxt.common_customize,
            ),
          ],
        );
      case 3:
        return null;
      case 4:
        return null;
    }
    return null;
  }

  void initNotification() async {
    final savedTime = await NotificationService.getSavedReminderTime();
    ref.read(reminderTimeProvider.notifier).set(savedTime);
  }
}

class _FloatingNavDestination {
  final String outlineAsset;
  final String solidAsset;
  final String label;
  final bool usesTripIcon;
  final double iconScale;

  const _FloatingNavDestination({
    required this.outlineAsset,
    required this.solidAsset,
    required this.label,
    this.usesTripIcon = false,
    this.iconScale = 1,
  });
}
