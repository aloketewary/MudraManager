import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mudra_manager/screens/bills/bills_screen.dart';
import 'package:mudra_manager/screens/budget/add_budget_screen.dart';
import 'package:mudra_manager/screens/budget/budget_dashboard.dart';
import 'package:mudra_manager/screens/dashboard/dashboard_home.dart';
import 'package:mudra_manager/screens/goal/add_edit_goal_screen.dart';
import 'package:mudra_manager/screens/goal/goal_screen.dart';
import 'package:mudra_manager/screens/home_screen.dart';
import 'package:mudra_manager/screens/notifications/notification_page_screen.dart';
import 'package:mudra_manager/screens/onboarding/onboarding_screen.dart';
import 'package:mudra_manager/screens/profile/about_app.dart';
import 'package:mudra_manager/screens/profile/account_form.dart';
import 'package:mudra_manager/screens/profile/add_edit_category_screen.dart';
import 'package:mudra_manager/screens/profile/app_settings_page.dart';
import 'package:mudra_manager/screens/profile/backup_restore_screen.dart';
import 'package:mudra_manager/screens/profile/choose_language_screen.dart';
import 'package:mudra_manager/screens/profile/edit_user_profile_screen.dart';
import 'package:mudra_manager/screens/profile/manage_account_screen.dart';
import 'package:mudra_manager/screens/profile/manage_categories_screen.dart';
import 'package:mudra_manager/screens/profile/notification_settings_screen.dart';
import 'package:mudra_manager/screens/profile/profile_screen.dart';
import 'package:mudra_manager/screens/profile/setting_screen.dart';
import 'package:mudra_manager/screens/profile/sms_import_setting_screen.dart';
import 'package:mudra_manager/screens/profile/theme_picker_screen.dart';
import 'package:mudra_manager/screens/sms/review_pending_transactions_Screen.dart';
import 'package:mudra_manager/screens/statistics/statistics_screen.dart';
import 'package:mudra_manager/screens/transaction/add_edit_transaction_screen.dart';
import 'package:mudra_manager/screens/transaction/transaction_list_screen.dart';
import 'package:mudra_manager/screens/transaction/transfer_screen.dart';
import 'package:mudra_manager/screens/trip/edit_trip_screen.dart';
import 'package:mudra_manager/screens/utility/utility_screen.dart';
import 'package:mudra_manager/screens/utility/monthly_comparison_screen.dart';
import 'package:mudra_manager/screens/recurring/recurring_transactions_screen.dart';
import 'package:mudra_manager/screens/recurring/add_recurring_transaction_screen.dart';
import 'package:mudra_manager/screens/trip/trips_screen.dart';
import 'package:mudra_manager/screens/trip/create_trip_screen.dart';
import 'package:mudra_manager/screens/trip/trip_detail_screen.dart';
import 'package:mudra_manager/screens/trip/add_trip_transaction_screen.dart';
import 'package:mudra_manager/util/auth_gate.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  static GoRouter router(bool showOnboarding) => GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: showOnboarding ? '/onboarding' : '/home',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AuthGate(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => HomePage(initialIndex: 0),
          ),
          GoRoute(
            path: '/transactions',
            builder: (context, state) => HomePage(initialIndex: 1),
          ),
          GoRoute(
            path: '/utilities',
            builder: (context, state) => HomePage(initialIndex: 2),
          ),
          GoRoute(
            path: '/statistics',
            builder: (context, state) => HomePage(initialIndex: 3),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => HomePage(initialIndex: 4),
          ),
          GoRoute(
            path: '/add-transaction',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return AddEditTransactionScreen(
                transaction: extra?['transaction'],
              );
            },
          ),
          GoRoute(
            path: '/transfer',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return TransferScreen(
                amount: extra?['amount'],
                note: extra?['note'],
                date: extra?['date'],
                fromAccount: extra?['fromAccount'],
                toAccount: extra?['toAccount'],
                fromId: extra?['fromId'],
                toId: extra?['toId'],
              );
            },
          ),
          GoRoute(
            path: '/pending-transactions',
            builder: (context, state) => ReviewPendingTransactionsScreen(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => NotificationPage(),
          ),
          GoRoute(
            path: '/edit-profile',
            builder: (context, state) => const EditUserProfileScreen(),
          ),
          GoRoute(
            path: '/app-settings',
            builder: (context, state) => const AppSettingsPage(),
          ),
          GoRoute(
            path: '/security',
            builder: (context, state) => SecuritySettingsScreen(),
          ),
          GoRoute(
            path: '/bills',
            builder: (context, state) => const BillsScreen(),
          ),
          GoRoute(
            path: '/notification-settings',
            builder: (context, state) => const NotificationSettingsScreen(),
          ),
          GoRoute(
            path: '/sms-import',
            builder: (context, state) => SmsImportSettingsScreen(),
          ),
          GoRoute(
            path: '/language',
            builder: (context, state) => const ChooseLanguageScreen(),
          ),
          GoRoute(
            path: '/theme',
            builder: (context, state) => ThemePickerScreen(),
          ),
          GoRoute(
            path: '/backup-restore',
            builder: (context, state) => BackupRestoreScreen(),
          ),
          GoRoute(
            path: '/about',
            builder: (context, state) => const AboutScreen(),
          ),
          GoRoute(
            path: '/manage-accounts',
            builder: (context, state) => ManageAccountScreen(),
          ),
          GoRoute(
            path: '/manage-categories',
            builder: (context, state) => ManageCategoriesScreen(),
          ),
          GoRoute(
            path: '/add-budget',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return AddBudgetScreen(existing: extra?['budget']);
            },
          ),
          GoRoute(
            path: '/add-goal',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return AddEditGoalScreen(goal: extra?['goal']);
            },
          ),
          GoRoute(
            path: '/add-category',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return AddEditCategoryScreen(existing: extra?['category']);
            },
          ),
          GoRoute(
            path: '/budget-dashboard',
            builder: (context, state) => BudgetDashboard(),
          ),
          GoRoute(
            path: '/goal-screen',
            builder: (context, state) => GoalScreen(),
          ),
          GoRoute(
            path: '/manage-accounts/add',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return AccountForm(account: extra?['account']);
            },
          ),
          GoRoute(
            path: '/monthly-comparison',
            builder: (context, state) => const MonthlyComparisonScreen(),
          ),
          GoRoute(
            path: '/recurring-transactions',
            builder: (context, state) => const RecurringTransactionsScreen(),
          ),
          GoRoute(
            path: '/add-recurring',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return AddRecurringTransactionScreen(
                recurring: extra?['recurring'],
              );
            },
          ),
          GoRoute(
            path: '/trips',
            builder: (context, state) => const TripsScreen(),
          ),
          GoRoute(
            path: '/create-trip',
            builder: (context, state) => const CreateTripScreen(),
          ),
          GoRoute(
            path: '/trip-detail',
            builder: (context, state) {
              final tripId = state.extra as int;
              return TripDetailScreen(tripId: tripId);
            },
          ),
          GoRoute(
            path: '/add-trip-transaction',
            builder: (context, state) {
              final tripId = state.extra as int;
              return AddTripTransactionScreen(tripId: tripId);
            },
          ),
          GoRoute(
            path: '/edit-trip',
            builder: (context, state) {
              // Retrieve the tripId passed via 'extra'
              final tripId = state.extra as int;
              return EditTripScreen(tripId: tripId);
            },
          ),
        ],
      ),
    ],
  );
}
