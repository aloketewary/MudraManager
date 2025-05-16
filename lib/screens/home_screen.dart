import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/db/models/user_profile.dart' show UserProfile;
import 'package:mudra_manager/l10n/app_localizations.dart' show AppLocalizations;
import 'package:mudra_manager/providers/greeting_provider.dart';
import 'package:mudra_manager/providers/isar_provider.dart'
    show reminderTimeProvider;
import 'package:mudra_manager/providers/notification_record_service.dart';
import 'package:mudra_manager/providers/user_profile_provider.dart';
import 'package:mudra_manager/screens/notifications/notification_page_screen.dart';
import 'package:mudra_manager/screens/profile/profile_screen.dart';
import 'package:mudra_manager/screens/statistics/statistics_screen.dart';
import 'package:mudra_manager/screens/transaction/add_edit_transaction_screen.dart';
import 'package:mudra_manager/screens/transaction/transaction_list_screen.dart';
import 'package:mudra_manager/service/notification_service.dart'
    show NotificationService;
import 'package:mudra_manager/util/localization_extension.dart';

import 'dashboard/dashboard_home.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends ConsumerState<HomePage> {
  int _selectedIndex = 0;
  List<Widget> _pages = [];
  final statisticsKey = GlobalKey<StatisticsScreenState>();
  final transactionListKey = GlobalKey<TransactionListScreenState>();

  @override
  void initState() {
    super.initState();
    _pages = [
      DashboardHome(),
      TransactionListScreen(key: transactionListKey,),
      StatisticsScreen(key: statisticsKey),
      ProfileScreen(),
    ];
    initNotification();
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    var color = Theme.of(context).colorScheme;
    var ctxt = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: buildTopBar(profileAsync, _selectedIndex),
      resizeToAvoidBottomInset: false,
      extendBody: true,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton:
          _selectedIndex == 1
              ? AnimatedSwitcher(
                duration: const Duration(
                  milliseconds: 500,
                ), // slower and smoother
                switchInCurve: Curves.easeInOutBack,
                switchOutCurve: Curves.easeIn,
                child: FloatingActionButton.extended(
                  key: const ValueKey('extended'),
                  onPressed: _onFabPressed,
                  icon: const Icon(Icons.add),
                  label: Text(ctxt.add_edit_transaction_screen_title),
                ),
              )
              : null,
      // So FAB doesn't push BottomAppBar up
      bottomNavigationBar: BottomNavigationBar(
        enableFeedback: true,
        type: BottomNavigationBarType.fixed,
        // unselectedItemColor: color.primary,
        backgroundColor: color.surface,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ctxt.home_screen_title),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: ctxt.transaction_screen_title,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_graph),
            label: ctxt.statistics_screen_title,
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ctxt.profile_screen_title),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: color.primary,
        onTap: _onTabSelected,
      ),
      body: SafeArea(child: _pages[_selectedIndex]),
    );
  }

  void _onFabPressed() {
    // Navigate to Add Transaction screen or open bottom sheet
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddEditTransactionScreen()),
    );
  }

  PreferredSizeWidget buildTopBar(
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              greetingAsync.when(
                data:
                    (greeting) => Text(
                      '${ctxt.translate(greeting)},',
                      style: textTheme.titleMedium?.copyWith(
                        color: color.onPrimary,
                      ),
                    ),
                loading:
                    () => Text(
                      '${ctxt.greeting_hello_text}, ',
                      style: textTheme.titleMedium?.copyWith(
                        color: color.onPrimary,
                      ),
                    ),
                error: (e, _) => Center(child: Text("Error: $e")),
              ),
              profileAsync.when(
                data: (profile) {
                  return Text(
                    profile?.name ?? 'Awesome User',
                    style: textTheme.titleLarge?.copyWith(
                      color: color.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text("Error: $e")),
              ),
            ],
          ),
          actions: [
            FutureBuilder(
              future: notificationService.countUnreadNotification(),
              builder: (_, snapshot) {
                var notificationCount = snapshot.data;
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationPage(),
                        ),);
                    },
                    child: Stack(
                      children: [
                        const Icon(Icons.notifications_none, size: 28),
                        if ((notificationCount ?? 0) > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                '$notificationCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      case 1:
        return AppBar(
          title: Text(
            ctxt.transaction_screen_title,
            style: textTheme.titleLarge?.copyWith(color: color.onPrimary),
          ),
          actions: [
            IconButton(onPressed: () {
              transactionListKey.currentState?.showFilterBottomSheet(context);
            }, icon: Icon(Icons.filter_list))
          ],
        );
      case 2:
        return AppBar(
          title: Text(
            ctxt.statistics_screen_title,
            style: textTheme.titleLarge?.copyWith(color: color.onPrimary),
          ),
          actions: [
            IconButton(
              enableFeedback: true,
              icon: Icon(Icons.save_alt_outlined),
              onPressed: () {
                statisticsKey.currentState?.showExportOptions(context);
              },
            ),
          ],
        );
      default:
        return AppBar(
          title: Text(
            ctxt.profile_screen_title,
            style: textTheme.titleLarge?.copyWith(color: color.onPrimary),
          ),
        );
    }
  }

  void initNotification() async {
    final savedTime = await NotificationService.getSavedReminderTime();
    ref.read(reminderTimeProvider.notifier).state = savedTime;
  }
}
