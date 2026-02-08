import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/db/models/user_profile.dart' show UserProfile;
import 'package:mudra_manager/l10n/app_localizations.dart'
    show AppLocalizations;
import 'package:mudra_manager/providers/greeting_provider.dart';
import 'package:mudra_manager/providers/isar_provider.dart'
    show reminderTimeProvider;
import 'package:mudra_manager/providers/notification_record_service.dart';
import 'package:mudra_manager/providers/user_profile_provider.dart';
import 'package:mudra_manager/screens/profile/profile_screen.dart';
import 'package:mudra_manager/screens/statistics/statistics_screen.dart';
import 'package:mudra_manager/screens/transaction/transaction_list_screen.dart';
import 'package:mudra_manager/service/notification_service.dart'
    show NotificationService;
import 'package:mudra_manager/util/localization_extension.dart';
import 'package:mudra_manager/components/adaptive_text.dart';
import 'dashboard/dashboard_home.dart';
import 'utility/utility_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _fabController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _pages = [
      DashboardHome(),
      TransactionListScreen(key: transactionListKey),
      UtilityScreen(key: utilityKey),
      StatisticsScreen(key: statisticsKey),
      ProfileScreen(),
    ];
    initNotification();
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    HapticFeedback.mediumImpact();
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    var ctxt = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: buildTopBar(profileAsync, _selectedIndex),
      extendBody: true,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton:
          _selectedIndex == 1
              ? FloatingActionButton.extended(
                heroTag: 'addTransactionHero',
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  context.push('/add-transaction');
                },
                icon: Icon(Icons.add),
                label: Text(ctxt.add_edit_transaction_screen_title),
              )
              : _selectedIndex == 2
              ? FloatingActionButton.extended(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  utilityKey.currentState?.showCustomizeSheet();
                },
                icon: Icon(Icons.tune),
                label: Text('Customise'),
              )
              : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onTabSelected,
        elevation: 0,
        animationDuration: Duration(milliseconds: 300),
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: ctxt.home_screen_title,
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: ctxt.transaction_screen_title,
          ),
          NavigationDestination(
            icon: Icon(Icons.widgets_outlined),
            selectedIcon: Icon(Icons.widgets),
            label: "Utilities",
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_graph_outlined),
            selectedIcon: Icon(Icons.auto_graph),
            label: ctxt.statistics_screen_title,
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: ctxt.profile_screen_title,
          ),
        ],
      ),
      body:
          _selectedIndex == 4
              ? _pages[_selectedIndex]
              : _selectedIndex == 2
              ? SafeArea(
                bottom: false,
                child: _pages[_selectedIndex],
              )
              : SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 80),
                  child: _pages[_selectedIndex],
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
                data:
                    (greeting) => AdaptiveText(
                      '${ctxt.translate(greeting)},',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                    ),
                loading:
                    () => AdaptiveText(
                      '${ctxt.greeting_hello_text}, ',
                      style: textTheme.titleMedium,
                      maxLines: 1,
                    ),
                error: (e, _) => Text("Error: $e"),
              ),
              profileAsync.when(
                data:
                    (profile) => AdaptiveText(
                      profile?.name ?? 'Awesome User',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                    ),
                loading:
                    () => SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                error: (e, _) => Text("Error: $e"),
              ),
            ],
          ),
          actions: [
            FutureBuilder(
              future: notificationService.countUnreadNotification(),
              builder: (_, snapshot) {
                var count = snapshot.data ?? 0;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.notifications_outlined, size: 28),
                      onPressed: () => context.push('/notifications'),
                    ),
                    if (count > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: color.error,
                            shape: BoxShape.circle,
                          ),
                          constraints: BoxConstraints(
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
            SizedBox(width: 8),
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
              onPressed:
                  () => transactionListKey.currentState?.showFilterBottomSheet(
                    context,
                  ),
              icon: Icon(Icons.filter_list),
            ),
          ],
        );
      case 2:
        return AppBar(title: Text("Utilities", style: textTheme.titleLarge));
      case 3:
        return AppBar(
          title: Text(
            ctxt.statistics_screen_title,
            style: textTheme.titleLarge,
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.save_alt_outlined),
              onPressed:
                  () => statisticsKey.currentState?.showExportOptions(context),
            ),
          ],
        );
      case 4:
        return null;
    }
  }

  void initNotification() async {
    final savedTime = await NotificationService.getSavedReminderTime();
    ref.read(reminderTimeProvider.notifier).state = savedTime;
  }
}
