import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mudra_manager/core/db/models/goal.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';
import 'package:mudra_manager/core/router/home_screen.dart';
import 'package:mudra_manager/core/utils/auth_gate.dart';
import 'package:mudra_manager/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:mudra_manager/features/budget/data/budget_service_provider.dart';
import 'package:mudra_manager/features/budget/presentation/screens/add_budget_screen.dart';
import 'package:mudra_manager/features/budget/presentation/screens/budget_dashboard.dart';
import 'package:mudra_manager/features/budget/presentation/screens/budget_details_screen.dart';
import 'package:mudra_manager/features/goal/presentation/screens/add_edit_goal_screen.dart';
import 'package:mudra_manager/features/goal/presentation/screens/goal_details_screen.dart';
import 'package:mudra_manager/features/goal/presentation/screens/goal_screen.dart';
import 'package:mudra_manager/features/onboarding/presentation/screens/account_setup_screen.dart';
import 'package:mudra_manager/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:mudra_manager/features/profile/presentation/screens/about_app.dart';
import 'package:mudra_manager/features/profile/presentation/screens/add_edit_category_screen.dart';
import 'package:mudra_manager/features/profile/presentation/screens/app_settings_page.dart';
import 'package:mudra_manager/features/profile/presentation/screens/backup_restore_screen.dart';
import 'package:mudra_manager/features/profile/presentation/screens/choose_language_screen.dart';
import 'package:mudra_manager/features/profile/presentation/screens/edit_user_profile_screen.dart';
import 'package:mudra_manager/features/profile/presentation/screens/help_screen.dart';
import 'package:mudra_manager/features/profile/presentation/screens/manage_account_screen.dart';
import 'package:mudra_manager/features/profile/presentation/screens/manage_categories_screen.dart';
import 'package:mudra_manager/features/profile/presentation/screens/notification_settings_screen.dart';
import 'package:mudra_manager/features/profile/presentation/screens/setting_screen.dart';
import 'package:mudra_manager/features/profile/presentation/screens/sms_import_setting_screen.dart';
import 'package:mudra_manager/features/profile/presentation/screens/theme_picker_screen.dart';
import 'package:mudra_manager/features/profile/presentation/widgets/account_form.dart';
import 'package:mudra_manager/features/sms/presentation/screens/review_pending_transactions_screen_refactored.dart';
import 'package:mudra_manager/features/statistics/presentation/screens/monthly_comparison_screen.dart';
import 'package:mudra_manager/features/transactions/presentation/screens/add_edit_transaction_screen.dart';
import 'package:mudra_manager/features/transactions/presentation/screens/add_recurring_transaction_screen.dart';
import 'package:mudra_manager/features/transactions/presentation/screens/recurring_transactions_screen.dart';
import 'package:mudra_manager/features/transactions/presentation/screens/transfer_screen.dart';
import 'package:mudra_manager/features/trip/presentation/screens/add_trip_transaction_screen.dart';
import 'package:mudra_manager/features/trip/presentation/screens/create_trip_screen.dart';
import 'package:mudra_manager/features/trip/presentation/screens/edit_trip_screen.dart';
import 'package:mudra_manager/features/trip/presentation/screens/trip_detail_screen.dart';
import 'package:mudra_manager/features/trip/presentation/screens/trips_screen.dart';
import 'package:mudra_manager/shared/screens/notification_page_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  static GoRouter router(bool showOnboarding) => GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: showOnboarding ? '/onboarding' : '/home',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isOnboardingComplete = SharedPrefsUtil.instance
          .isOnboardingComplete();
      final isOnOnboardingPage = state.matchedLocation == '/onboarding';
      final isOnAccountSetupPage = state.matchedLocation == '/account-setup';

      // If onboarding is complete and user is on onboarding/setup page, redirect to home
      if (isOnboardingComplete &&
          (isOnOnboardingPage || isOnAccountSetupPage)) {
        return '/home';
      }

      // If onboarding is not complete and user is not on onboarding/setup pages, redirect to onboarding
      if (!isOnboardingComplete &&
          !isOnOnboardingPage &&
          !isOnAccountSetupPage) {
        return '/onboarding';
      }

      return null; // No redirect needed
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/account-setup',
        builder: (context, state) => const AccountSetupScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AuthGate(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomePage(initialIndex: 0),
          ),
          GoRoute(
            path: '/transactions',
            builder: (context, state) => const HomePage(initialIndex: 1),
          ),
          GoRoute(
            path: '/utilities',
            builder: (context, state) => const HomePage(initialIndex: 2),
          ),
          GoRoute(
            path: '/statistics',
            builder: (context, state) => const HomePage(initialIndex: 3),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const HomePage(initialIndex: 4),
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
            builder: (context, state) =>
                const ReviewPendingTransactionsScreen(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationPage(),
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
            builder: (context, state) => const SecuritySettingsScreen(),
          ),
          GoRoute(
            path: '/notification-settings',
            builder: (context, state) => const NotificationSettingsScreen(),
          ),
          GoRoute(
            path: '/sms-import',
            builder: (context, state) => const SmsImportSettingsScreen(),
          ),
          GoRoute(
            path: '/language',
            builder: (context, state) => const ChooseLanguageScreen(),
          ),
          GoRoute(
            path: '/theme',
            builder: (context, state) => const ThemePickerScreen(),
          ),
          GoRoute(
            path: '/backup-restore',
            builder: (context, state) => const BackupRestoreScreen(),
          ),
          GoRoute(
            path: '/about',
            builder: (context, state) => const AboutScreen(),
          ),
          GoRoute(
            path: '/help',
            builder: (context, state) => const HelpScreen(),
          ),
          GoRoute(
            path: '/manage-accounts',
            builder: (context, state) => const ManageAccountScreen(),
          ),
          GoRoute(
            path: '/manage-categories',
            builder: (context, state) => const ManageCategoriesScreen(),
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
            builder: (context, state) => const BudgetDashboard(),
          ),
          GoRoute(
            path: '/budget-details',
            builder: (context, state) {
              final data = state.extra as BudgetWithProgress;
              return BudgetDetailsScreen(data: data);
            },
          ),
          GoRoute(
            path: '/goal-screen',
            builder: (context, state) => const GoalScreen(),
          ),
          GoRoute(
            path: '/goal-details',
            builder: (context, state) {
              final goal = state.extra as Goal;
              return GoalDetailsScreen(goal: goal);
            },
          ),
          GoRoute(
            path: '/manage-accounts/add',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return AccountForm(
                account: extra?['account'],
                accountNumber: extra?['accountNumber'],
                bankName: extra?['bankName'],
              );
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
          GoRoute(
            path: '/analytics',
            builder: (context, state) => const AnalyticsScreen(),
          ),
        ],
      ),
    ],
  );
}
