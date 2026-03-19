import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';
import 'package:mudra_manager/core/router/home_screen.dart';
import 'package:mudra_manager/core/utils/auth_gate.dart';
import 'package:mudra_manager/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:mudra_manager/features/analytics/presentation/financial_health_screen.dart';
import 'package:mudra_manager/features/analytics/presentation/spending_personality_screen.dart';
import 'package:mudra_manager/features/analytics/presentation/net_worth_screen.dart';
import 'package:mudra_manager/features/budget/data/budget_service_provider.dart';
import 'package:mudra_manager/features/budget/presentation/screens/add_budget_screen.dart';
import 'package:mudra_manager/features/budget/presentation/screens/adaptive_budget_dashboard.dart';
import 'package:mudra_manager/features/budget/presentation/screens/budget_details_screen.dart';
import 'package:mudra_manager/features/dashboard/presentation/screens/dashboard_customize_screen.dart';
import 'package:mudra_manager/features/dashboard/presentation/screens/command_center_screen.dart';
import 'package:mudra_manager/features/dashboard/presentation/screens/recurring_expenses_screen.dart';
import 'package:mudra_manager/features/goal/presentation/screens/add_edit_goal_screen.dart';
import 'package:mudra_manager/features/goal/presentation/screens/goal_details_screen.dart';
import 'package:mudra_manager/features/goal/presentation/screens/goal_screen.dart';
import 'package:mudra_manager/features/onboarding/presentation/screens/account_setup_screen.dart';
import 'package:mudra_manager/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:mudra_manager/features/profile/presentation/screens/about_app.dart';
import 'package:mudra_manager/features/profile/presentation/screens/add_edit_category_screen.dart';
import 'package:mudra_manager/features/profile/presentation/screens/app_settings_page.dart';
import 'package:mudra_manager/features/profile/presentation/screens/appearance_screen.dart';
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
import 'package:mudra_manager/features/recap/presentation/screens/monthly_recap_screen.dart';
import 'package:mudra_manager/features/sms/presentation/screens/sms_activity_screen.dart';
import 'package:mudra_manager/features/statistics/presentation/screens/monthly_comparison_screen.dart';
import 'package:mudra_manager/features/transactions/presentation/screens/add_edit_transaction_screen.dart';
import 'package:mudra_manager/features/transactions/presentation/screens/add_recurring_transaction_screen.dart';
import 'package:mudra_manager/features/transactions/presentation/screens/bill_control_center_screen.dart';
import 'package:mudra_manager/features/transactions/presentation/screens/transfer_screen_new.dart';
import 'package:mudra_manager/features/trip/presentation/screens/add_trip_transaction_screen.dart';
import 'package:mudra_manager/features/trip/presentation/screens/edit_trip_screen.dart';
import 'package:mudra_manager/features/trip/presentation/screens/expense_detail_screen.dart';
import 'package:mudra_manager/features/trip/presentation/screens/trip_detail_screen.dart';
import 'package:mudra_manager/features/trip/presentation/screens/trips_screen.dart';
import 'package:mudra_manager/plugins/credit_card_reminder_settings.dart';
import 'package:mudra_manager/shared/screens/notification_page_screen.dart';
import 'package:mudra_manager/features/gamification/screens/achievements_screen.dart';
import 'package:mudra_manager/features/marketplace/screens/plugin_groups_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  static GoRouter router(bool showOnboarding) => GoRouter(
        navigatorKey: _rootNavigatorKey,
        initialLocation: showOnboarding ? '/onboarding' : '/home',
        debugLogDiagnostics: true,
        redirect: (context, state) {
          final isOnboardingComplete =
              SharedPrefsUtil.instance.isOnboardingComplete();
          final isOnOnboardingPage = state.matchedLocation == '/onboarding';
          final isOnAccountSetupPage =
              state.matchedLocation == '/account-setup';

          // Handle root path from deep links
          if (state.matchedLocation == '/') {
            return isOnboardingComplete ? '/home' : '/onboarding';
          }

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
                    smsActivity: extra?['smsActivity'],
                    initialIsIncome: extra?['isIncome'] as bool? ?? false,
                  );
                },
              ),
              GoRoute(
                path: '/transfer',
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  return TransferScreenNew(
                    initialAmount: extra?['amount'] as String?,
                    initialNote: extra?['note'] as String?,
                    initialDate: extra?['date'] as DateTime?,
                    initialFromAccount: extra?['fromAccount'] as Account?,
                    initialToAccount: extra?['toAccount'] as Account?,
                    editFromId: extra?['fromId'] as int?,
                    editToId: extra?['toId'] as int?,
                  );
                },
              ),

              GoRoute(
                path: '/sms-activity',
                builder: (context, state) => const SmsActivityScreen(),
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
                path: '/dashboard-customize',
                builder: (context, state) => const DashboardCustomizeScreen(),
              ),
              GoRoute(
                path: '/command-center',
                builder: (context, state) => const CommandCenterScreen(),
              ),
              GoRoute(
                path: '/recurring-expenses',
                builder: (context, state) => const RecurringExpensesScreen(),
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
                path: '/choose-language',
                builder: (context, state) => const ChooseLanguageScreen(),
              ),
              GoRoute(
                path: '/theme-picker',
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
                builder: (context, state) => const AdaptiveBudgetDashboard(),
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
                  final extra = state.extra as Map<String, dynamic>?;
                  return GoalDetailsScreen(goal: extra?['goal']);
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
                builder: (context, state) => const BillControlCenterScreen(),
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
                builder: (context, state) => const ManageTripScreen(),
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
                  final extra = state.extra;
                  final tripId = extra is int
                      ? extra
                      : (extra as Map<String, dynamic>)['tripId'] as int;
                  return AddTripTransactionScreen(tripId: tripId);
                },
              ),
              GoRoute(
                path: '/edit-trip/:id',
                builder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  return ManageTripScreen(tripId: id);
                },
              ),
              GoRoute(
                path: '/expense-detail',
                builder: (context, state) {
                  final data = state.extra as Map<String, dynamic>;
                  return ExpenseDetailScreen(
                    expenseId: data['expenseId'] as int,
                    tripId: data['tripId'] as int,
                  );
                },
              ),
              GoRoute(
                path: '/analytics',
                builder: (context, state) => const AnalyticsScreen(),
              ),
              GoRoute(
                path: '/financial-health',
                builder: (context, state) => const FinancialHealthScreen(),
              ),
              GoRoute(
                path: '/spending-personality',
                builder: (context, state) => const SpendingPersonalityScreen(),
              ),
              GoRoute(
                path: '/net-worth',
                builder: (context, state) => const NetWorthScreen(),
              ),
              GoRoute(
                path: '/achievements',
                builder: (context, state) => const AchievementsScreen(),
              ),
              GoRoute(
                path: '/monthly-recap',
                builder: (context, state) {
                  final month = state.extra as DateTime?;
                  return MonthlyRecapScreen(month: month);
                },
              ),
              GoRoute(
                path: '/marketplace',
                builder: (context, state) => const PluginGroupsScreen(),
              ),
              GoRoute(
                path: '/credit-card-reminders',
                builder: (context, state) => const CreditCardReminderSettings(),
              ),
              // Add route (inside the ShellRoute routes list, near the other settings routes)
              GoRoute(
                path: '/appearance',
                builder: (context, state) => const AppearanceScreen(),
              ),
            ],
          ),
        ],
      );
}
