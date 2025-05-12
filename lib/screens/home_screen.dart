import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/db/models/user_profile.dart' show UserProfile;
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
import 'package:shared_preferences/shared_preferences.dart';

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

  @override
  void initState() {
    super.initState();
    _pages = [
      DashboardHome(),
      TransactionListScreen(),
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
                  label: const Text("Add Transaction"),
                ),
              )
              : null,
      // So FAB doesn't push BottomAppBar up
      bottomNavigationBar: BottomNavigationBar(
        enableFeedback: true,
        type: BottomNavigationBarType.fixed,
        // unselectedItemColor: color.primary,
        backgroundColor: color.surface,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Activity',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_graph),
            label: 'Statistics',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
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
                      '$greeting,',
                      style: textTheme.titleMedium?.copyWith(
                        color: color.onPrimary,
                      ),
                    ),
                loading:
                    () => Text(
                      'Hello, ',
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
            "Activity",
            style: textTheme.titleLarge?.copyWith(color: color.onPrimary),
          ),
        );
      case 2:
        return AppBar(
          title: Text(
            "Statistics",
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
            "Profile",
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
