import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/user_profile.dart';
import 'package:mudra_manager/core/extension/localization_extenstion.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/providers/notification_record_service.dart';
import 'package:mudra_manager/core/services/notification_service.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/features/dashboard/data/greeting_provider.dart';
import 'package:mudra_manager/features/dashboard/presentation/screens/dashboard_home.dart';
import 'package:mudra_manager/features/gamification/providers/achievement_unlock_listener.dart';
import 'package:mudra_manager/features/gamification/widgets/streak_indicator.dart';
import 'package:mudra_manager/features/profile/data/user_profile_provider.dart';
import 'package:mudra_manager/features/profile/presentation/screens/profile_screen.dart';
import 'package:mudra_manager/features/statistics/presentation/screens/statistics_screen.dart';
import 'package:mudra_manager/features/statistics/presentation/screens/utility_screen.dart';
import 'package:mudra_manager/features/transactions/presentation/widgets/quick_add_transaction_sheet.dart';
import 'package:mudra_manager/features/transactions/presentation/screens/transaction_list_screen.dart';
import 'package:mudra_manager/shared/widgets/adaptive_text.dart';

class HomePage extends ConsumerStatefulWidget {
  final int initialIndex;
  const HomePage({super.key, this.initialIndex = 0});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends ConsumerState<HomePage>
    with TickerProviderStateMixin {
  late int _selectedIndex;
  List<Widget> _pages = [];
  final statisticsKey = GlobalKey<StatisticsScreenState>();
  final transactionListKey = GlobalKey<TransactionListScreenState>();
  final utilityKey = GlobalKey<UtilityScreenState>();
  late AnimationController _fabController;
  late AppLog log;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _pages = [
      const DashboardHome(),
      TransactionListScreen(key: transactionListKey),
      UtilityScreen(key: utilityKey),
      StatisticsScreen(key: statisticsKey),
      const ProfileScreen(),
    ];
    initNotification();
    _setupWidgetClickListener();
    _setupMethodChannel();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(achievementUnlockListenerProvider).initialize(context);
      }
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
      if (call.method == 'widgetAction' &&
          call.arguments == 'add_transaction') {
        log.i('Widget button clicked - opening quick add sheet');
        if (mounted) {
          await Future.delayed(const Duration(milliseconds: 300));
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => const QuickAddTransactionSheet(),
          );
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

    // Update route to match tab
    final routes = [
      '/home',
      '/transactions',
      '/utilities',
      '/statistics',
      '/profile',
    ];
    context.go(routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final ctxt = AppLocalizations.of(context)!;

    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _selectedIndex != 0) {
          _onTabSelected(0);
        }
      },
      child: Scaffold(
        appBar: buildTopBar(profileAsync, _selectedIndex),
        extendBody: true,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: _selectedIndex == 1
            ? FloatingActionButton.extended(
                heroTag: 'addTransactionHeroTab1',
                onPressed: () => context.push('/add-transaction'),
                icon: const Icon(Icons.add),
                label: Text(ctxt.dashboard_add_transaction_text),
              )
            : _selectedIndex == 2
                ? FloatingActionButton.extended(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      utilityKey.currentState?.showCustomizeSheet();
                    },
                    icon: const Icon(Icons.tune),
                    label: const Text('Customise'),
                  )
                : null,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onTabSelected,
          elevation: 0,
          animationDuration: const Duration(milliseconds: 300),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: ctxt.home_screen_title,
            ),
            NavigationDestination(
              icon: const Icon(Icons.receipt_long_outlined),
              selectedIcon: const Icon(Icons.receipt_long),
              label: ctxt.transaction_screen_title,
            ),
            const NavigationDestination(
              icon: Icon(Icons.widgets_outlined),
              selectedIcon: Icon(Icons.widgets),
              label: 'Utilities',
            ),
            NavigationDestination(
              icon: const Icon(Icons.auto_graph_outlined),
              selectedIcon: const Icon(Icons.auto_graph),
              label: ctxt.statistics_screen_title,
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person),
              label: ctxt.profile_screen_title,
            ),
          ],
        ),
        body: _selectedIndex == 4
            ? _pages[_selectedIndex]
            : _selectedIndex == 2
            ? SafeArea(bottom: false, child: _pages[_selectedIndex])
            : SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 80),
                  child: _pages[_selectedIndex],
                ),
              ),
      ),
    );
  }

  PreferredSizeWidget? buildTopBar(
    AsyncValue<UserProfile?> profileAsync,
    int selectedIndex,
  ) {
    final greetingAsync = ref.watch(greetingProvider);
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    final notificationService = ref.watch(notificationRecordServiceProvider);
    final ctxt = AppLocalizations.of(context)!;

    switch (selectedIndex) {
      case 0:
        return AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              greetingAsync.when(
                data: (greeting) => AdaptiveText(
                  '${ctxt.translate(greeting)},',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                ),
                loading: () => AdaptiveText(
                  '${ctxt.greeting_hello_text}, ',
                  style: textTheme.titleMedium,
                  maxLines: 1,
                ),
                error: (e, _) => Text('Error: $e'),
              ),
              profileAsync.when(
                data: (profile) => AdaptiveText(
                  profile?.name ?? 'Awesome User',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                ),
                loading: () => const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (e, _) => Text('Error: $e'),
              ),
            ],
          ),
          actions: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [StreakIndicator()],
              ),
            ),
            FutureBuilder(
              future: notificationService.countUnreadNotification(),
              builder: (_, snapshot) {
                final count = snapshot.data ?? 0;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined, size: 28),
                      onPressed: () => context.push('/notifications'),
                    ),
                    if (count > 0)
                      Positioned(
                        right: 8,
                        top: 8,
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
                            '$count',
                            style: TextStyle(
                              color: color.onError,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        );
      case 1:
        return AppBar(
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
              icon: const Icon(Icons.search_rounded),
            ),
            IconButton(
              onPressed: () => transactionListKey.currentState
                  ?.showFilterBottomSheet(context),
              icon: const Icon(Icons.filter_list_rounded),
            ),
          ],
        );
      case 2:
        return AppBar(title: Text('Utilities', style: textTheme.titleLarge));
      case 3:
        return AppBar(
          title: Text(
            ctxt.statistics_screen_title,
            style: textTheme.titleLarge,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.save_alt_outlined),
              onPressed: () =>
                  statisticsKey.currentState?.showExportOptions(context),
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
}
