import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/notification_record.dart';
import 'package:mudra_manager/core/db/models/user_profile.dart';
import 'package:mudra_manager/core/entitlement/entitlement_provider.dart';
import 'package:mudra_manager/core/extension/localization_extenstion.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/providers/notification_record_service.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/services/notification_service.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/features/dashboard/data/greeting_provider.dart';
import 'package:mudra_manager/features/dashboard/presentation/screens/dashboard_home.dart';
import 'package:mudra_manager/features/gamification/providers/achievement_unlock_listener.dart';
import 'package:mudra_manager/features/gamification/widgets/streak_indicator.dart';
import 'package:mudra_manager/features/profile/data/user_profile_provider.dart';
import 'package:mudra_manager/features/profile/presentation/screens/profile_screen.dart';
import 'package:mudra_manager/features/statistics/presentation/screens/statistics_screen.dart';
import 'package:mudra_manager/features/statistics/presentation/screens/export_options_screen.dart';
import 'package:mudra_manager/features/dashboard/data/status_data_provider.dart';
import 'package:mudra_manager/plugins/export_plugin.dart';
import 'package:mudra_manager/features/statistics/presentation/screens/utility_screen.dart';
import 'package:mudra_manager/features/transactions/presentation/widgets/quick_add_transaction_sheet.dart';
import 'package:mudra_manager/features/transactions/presentation/screens/transaction_list_screen.dart';
import 'package:mudra_manager/shared/widgets/adaptive_text.dart';
import 'package:mudra_manager/shared/widgets/animated_greeting.dart';
import 'package:flutter_boring_avatars/flutter_boring_avatars.dart';
import 'package:mudra_manager/features/trip/data/trip_provider.dart';
import 'package:mudra_manager/shared/widgets/speed_dial_fab.dart';
import 'package:mudra_manager/core/router/app_routes.dart';

class HomePage extends ConsumerStatefulWidget {
  final int initialIndex;
  const HomePage({super.key, this.initialIndex = 0});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends ConsumerState<HomePage>
    with TickerProviderStateMixin {
  late int _selectedIndex;
  final transactionListKey = GlobalKey<TransactionListScreenState>();
  final utilityKey = GlobalKey<UtilityScreenState>();
  late AnimationController _fabController;
  late AppLog log;
  final _speedDialKey = GlobalKey<ExpandableFabState>();

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0,
    );

    // Critical — needed for widget click handling
    _setupMethodChannel();
    _setupWidgetClickListener();

    // Deferred — not needed for first frame
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
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
          if (mounted) {
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

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    HapticFeedback.mediumImpact();
    log.d('Tab changed: $index');
    setState(() => _selectedIndex = index);
    // Close speed dial when leaving transactions tab
    _speedDialKey.currentState?.close();
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeEntitlementGuardProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final ctxt = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && _selectedIndex != 0) {
          _onTabSelected(0);
        }
      },
      child: Scaffold(
        appBar: buildTopBar(profileAsync, _selectedIndex),
        extendBody: true,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onTabSelected,
          elevation: 0,
          animationDuration: const Duration(milliseconds: 300),
          destinations: [
            NavigationDestination(
              icon: SvgPicture.asset(
                'assets/logo/nav/outline/home.svg',
                colorFilter: ColorFilter.mode(
                  isDark ? Colors.white : Colors.black,
                  BlendMode.srcIn,
                ),
              ),
              selectedIcon: SvgPicture.asset(
                'assets/logo/nav/solid/home.svg',
                colorFilter: ColorFilter.mode(
                  isDark ? Colors.white : Colors.black,
                  BlendMode.srcIn,
                ),
              ).animate(target: _selectedIndex == 0 ? 1 : 0).scale(
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1, 1),
                    curve: Curves.easeOutCubic,
                    duration: 250.ms,
                  ),
              label: ctxt.home_screen_title,
            ),
            NavigationDestination(
              icon: SvgPicture.asset(
                'assets/logo/nav/outline/activity.svg',
                colorFilter: ColorFilter.mode(
                  isDark ? Colors.white : Colors.black,
                  BlendMode.srcIn,
                ),
              ),
              selectedIcon: SvgPicture.asset(
                'assets/logo/nav/solid/activity.svg',
                colorFilter: ColorFilter.mode(
                  isDark ? Colors.white : Colors.black,
                  BlendMode.srcIn,
                ),
              ).animate(target: _selectedIndex == 1 ? 1 : 0).scale(
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1, 1),
                    curve: Curves.easeOutCubic,
                    duration: 250.ms,
                  ),
              label: ctxt.nav_activity,
            ),
            NavigationDestination(
              icon: Consumer(
                builder: (context, ref, _) {
                  final activeTrips = ref.watch(activeTripsProvider);
                  final hasActiveTrip = activeTrips.maybeWhen(
                    data: (trips) {
                      final now = DateTime.now();
                      final today = DateTime(now.year, now.month, now.day);
                      return trips.any((t) {
                        if (!t.isTrip) return false;
                        final start = DateTime(t.startDate.year, t.startDate.month, t.startDate.day);
                        return t.isActive && !today.isBefore(start);
                      });
                    },
                    orElse: () => false,
                  );
                  return SvgPicture.asset(
                    hasActiveTrip
                        ? 'assets/logo/nav/outline/trip.svg'
                        : 'assets/logo/nav/outline/utility.svg',
                    colorFilter: ColorFilter.mode(
                      hasActiveTrip
                          ? Theme.of(context).colorScheme.primary
                          : (isDark ? Colors.white : Colors.black),
                      BlendMode.srcIn,
                    ),
                  );
                },
              ),
              selectedIcon: Consumer(
                builder: (context, ref, _) {
                  final activeTrips = ref.watch(activeTripsProvider);
                  final hasActiveTrip = activeTrips.maybeWhen(
                    data: (trips) {
                      final now = DateTime.now();
                      final today = DateTime(now.year, now.month, now.day);
                      return trips.any((t) {
                        if (!t.isTrip) return false;
                        final start = DateTime(t.startDate.year, t.startDate.month, t.startDate.day);
                        return t.isActive && !today.isBefore(start);
                      });
                    },
                    orElse: () => false,
                  );
                  return SvgPicture.asset(
                    hasActiveTrip
                        ? 'assets/logo/nav/solid/trip.svg'
                        : 'assets/logo/nav/solid/utility.svg',
                    colorFilter: ColorFilter.mode(
                      hasActiveTrip
                          ? Theme.of(context).colorScheme.primary
                          : (isDark ? Colors.white : Colors.black),
                      BlendMode.srcIn,
                    ),
                  ).animate(target: _selectedIndex == 2 ? 1 : 0).scale(
                        begin: const Offset(0.9, 0.9),
                        end: const Offset(1, 1),
                        curve: Curves.easeOutCubic,
                        duration: 250.ms,
                      );
                },
              ),
              label: ctxt.nav_manage,
            ),
            NavigationDestination(
              icon: SvgPicture.asset(
                'assets/logo/nav/outline/statistics.svg',
                colorFilter: ColorFilter.mode(
                  isDark ? Colors.white : Colors.black,
                  BlendMode.srcIn,
                ),
              ),
              selectedIcon: SvgPicture.asset(
                'assets/logo/nav/solid/statistics.svg',
                colorFilter: ColorFilter.mode(
                  isDark ? Colors.white : Colors.black,
                  BlendMode.srcIn,
                ),
              ).animate(target: _selectedIndex == 3 ? 1 : 0).scale(
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1, 1),
                    curve: Curves.easeOutCubic,
                    duration: 250.ms,
                  ),
              label: ctxt.nav_insights,
            ),
            NavigationDestination(
              icon: Consumer(
                builder: (context, ref, _) {
                  final isPro = ref.watch(isProProvider).valueOrNull ?? false;
                  return SvgPicture.asset(
                    isPro
                        ? 'assets/logo/nav/outline/pro_profile.svg'
                        : 'assets/logo/nav/outline/profile.svg',
                    colorFilter: ColorFilter.mode(
                      isPro
                          ? const Color(0xFFD4AF37)
                          : (isDark ? Colors.white : Colors.black),
                      BlendMode.srcIn,
                    ),
                  );
                },
              ),
              selectedIcon: Consumer(
                builder: (context, ref, _) {
                  final isPro = ref.watch(isProProvider).valueOrNull ?? false;
                  return SvgPicture.asset(
                    isPro
                        ? 'assets/logo/nav/solid/pro_profile.svg'
                        : 'assets/logo/nav/solid/profile.svg',
                    colorFilter: ColorFilter.mode(
                      isPro
                          ? const Color(0xFFD4AF37)
                          : (isDark ? Colors.white : Colors.black),
                      BlendMode.srcIn,
                    ),
                  ).animate(target: _selectedIndex == 4 ? 1 : 0).scale(
                        begin: const Offset(0.9, 0.9),
                        end: const Offset(1, 1),
                        curve: Curves.easeOutCubic,
                        duration: 250.ms,
                      );
                },
              ),
              label: ctxt.profile_screen_title,
            ),
          ],
        ),
        body: Stack(
          children: [
            IndexedStack(
              index: _selectedIndex,
              children: [
                const DashboardHome(),
                TransactionListScreen(
                  key: transactionListKey,
                  isTabActive: _selectedIndex == 1,
                  onScrollChanged: (isScrollingDown) {
                    if (isScrollingDown) {
                      _fabController.reverse();
                    } else {
                      _fabController.forward();
                    }
                  },
                ),
                UtilityScreen(key: utilityKey, isTabActive: _selectedIndex == 2),
                const StatisticsScreen(),
                const ProfileScreen(),
              ],
            ),
            if (_selectedIndex == 1)
              ExpandableFab(
                key: _speedDialKey,
                visibilityController: _fabController,
                padding: const EdgeInsets.only(bottom: 16),
              ),
          ],
        ),
      ),
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

    switch (selectedIndex) {
      case 0:
        return AppBar(
          automaticallyImplyLeading: false,
          title: GestureDetector(
            onTap: () => _onTabSelected(4),
            child: Row(
              children: [
                profileAsync.when(
                  data: (profile) => SizedBox(
                    width: 32,
                    height: 32,
                    child: ClipOval(
                      child: BoringAvatar(
                        name: profile?.name ?? 'User',
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
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                  ),
                  error: (_, __) => Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      profileAsync.when(
                        data: (profile) => AnimatedGreeting(
                          greeting: '${ctxt.translate(toneGreeting)},',
                          name: profile?.name ?? 'Awesome User',
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
                    ],
                  ),
                ),
              ],
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
                      final start = DateTime(t.startDate.year, t.startDate.month, t.startDate.day);
                      return !today.isBefore(start);
                    }).firstOrNull;

                    // Find upcoming trip within 7 days
                    final upcomingTrip = ongoingTrip == null
                        ? trips.where((t) {
                            if (!t.isTrip) return false;
                            final start = DateTime(t.startDate.year, t.startDate.month, t.startDate.day);
                            final daysUntil = start.difference(today).inDays;
                            return daysUntil > 0 && daysUntil <= 7;
                          }).firstOrNull
                        : null;

                    final trip = ongoingTrip ?? upcomingTrip;
                    if (trip == null) return const SizedBox.shrink();

                    final isUpcoming = ongoingTrip == null;
                    final daysUntil = isUpcoming
                        ? DateTime(trip.startDate.year, trip.startDate.month, trip.startDate.day)
                            .difference(today)
                            .inDays
                        : 0;

                    return InkWell(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        context.push(AppRoutes.tripDetail, extra: trip.id);
                      },
                      borderRadius: BorderRadius.circular(spacing.radiusMedium),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: spacing.cardHorizontal, vertical: spacing.cardVertical),
                        decoration: BoxDecoration(
                          color: isUpcoming
                              ? color.tertiaryContainer
                              : color.secondaryContainer,
                          borderRadius: BorderRadius.circular(spacing.radiusMedium),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isUpcoming ? LucideIcons.calendar : LucideIcons.planeTakeoff,
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
                    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.2, end: 0);
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
                      icon: const Icon(LucideIcons.bell, size: 28),
                      onPressed: () => context.push(AppRoutes.notifications),
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
        return AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            ctxt.transaction_screen_title,
            style: textTheme.titleLarge,
          ),
          actions: [
            IconButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                transactionListKey.currentState?.toggleSearch();
              },
              icon: const Icon(LucideIcons.search),
            ),
            IconButton(
              onPressed: () => transactionListKey.currentState
                  ?.showFilterBottomSheet(context, spacing),
              icon: const Icon(LucideIcons.listFilter),
            ),
          ],
        );
      case 2:
        return AppBar(
          automaticallyImplyLeading: false,
          title: Text('Manage', style: textTheme.titleLarge),
          actions: [
            IconButton(
              onPressed: () {
                utilityKey.currentState?.showCustomizeSheet();
              },
              icon: const Icon(LucideIcons.settings2),
              tooltip: 'Customize',
            ),
          ],
        );
      case 3:
        return AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            'Insights',
            style: textTheme.titleLarge,
          ),
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.download),
              onPressed: () => _showExportDialog(context),
            ),
          ],
        );
      case 4:
        return null;
    }
    return null;
  }

  void initNotification() async {
    final savedTime = await NotificationService.getSavedReminderTime();
    ref.read(reminderTimeProvider.notifier).state = savedTime;
  }

  void _showExportDialog(BuildContext context) {
    final stats = ref.read(statsProvider('Month'));
    final profile = ref.read(userProfileProvider).value;

    stats.maybeWhen(
      data: (data) {
        showDialog(
          context: context,
          builder: (_) => Dialog.fullscreen(
            child: ExportOptionsScreen(
              exportData: ExportData(
                income: data.income,
                expense: data.expense,
                savingsRate: data.savingsRate,
                avgDailySpend: data.avgDailySpend,
                transactions: data.recent,
                categoryData: data.categoryData,
                categoryDataMap: data.categoryDataMap,
                startDate: DateTime.now().subtract(const Duration(days: 30)),
                endDate: DateTime.now(),
                userName: profile?.name,
              ),
            ),
          ),
        );
      },
      orElse: () {},
    );
  }
}
