import 'dart:typed_data';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/entitlement/entitlement_feature.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';
import 'package:mudra_manager/core/router/home_screen.dart';
import 'package:mudra_manager/core/utils/auth_gate.dart';
import 'package:mudra_manager/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:mudra_manager/features/analytics/presentation/financial_health_screen.dart';
import 'package:mudra_manager/features/analytics/presentation/spending_personality_screen.dart';
import 'package:mudra_manager/features/analytics/presentation/net_worth_screen.dart';
import 'package:mudra_manager/features/analytics/presentation/tax_estimation_screen.dart';
import 'package:mudra_manager/features/analytics/presentation/cash_flow_forecast_screen.dart';
import 'package:mudra_manager/features/analytics/presentation/spending_trends_screen.dart';
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
import 'package:mudra_manager/features/category/presentation/screens/add_edit_category_screen.dart';
import 'package:mudra_manager/features/profile/presentation/screens/app_settings_page.dart';
import 'package:mudra_manager/features/profile/presentation/screens/appearance_screen.dart';
import 'package:mudra_manager/features/profile/presentation/screens/backup_restore_screen.dart';
import 'package:mudra_manager/features/profile/presentation/screens/choose_language_screen.dart';
import 'package:mudra_manager/features/profile/presentation/screens/currency_settings_screen.dart';
import 'package:mudra_manager/features/profile/presentation/screens/exchange_rate_screen.dart';
import 'package:mudra_manager/features/profile/presentation/screens/archived_transactions_screen.dart';
import 'package:mudra_manager/features/profile/presentation/screens/edit_user_profile_screen.dart';
import 'package:mudra_manager/features/profile/presentation/screens/help_screen.dart';
import 'package:mudra_manager/features/account/presentation/screens/manage_account_screen.dart';
import 'package:mudra_manager/features/category/presentation/screens/manage_categories_screen.dart';
import 'package:mudra_manager/features/profile/presentation/screens/notification_settings_screen.dart';
import 'package:mudra_manager/features/profile/presentation/screens/setting_screen.dart';
import 'package:mudra_manager/features/profile/presentation/screens/sms_import_setting_screen.dart';
import 'package:mudra_manager/features/profile/presentation/screens/theme_picker_screen.dart';
import 'package:mudra_manager/features/skin/presentation/screens/skin_picker_screen.dart';
import 'package:mudra_manager/features/skin/presentation/screens/skin_editor_screen.dart';
import 'package:mudra_manager/features/account/presentation/screens/add_edit_account_screen.dart';
import 'package:mudra_manager/features/recap/presentation/screens/monthly_recap_screen.dart';
import 'package:mudra_manager/features/sms/presentation/screens/sms_activity_screen.dart';
import 'package:mudra_manager/core/db/models/sms_activity.dart';
import 'package:mudra_manager/features/statistics/presentation/screens/monthly_comparison_screen.dart';
import 'package:mudra_manager/features/transactions/presentation/screens/add_edit_transaction_screen.dart';
import 'package:mudra_manager/features/transactions/presentation/screens/add_recurring_transaction_screen.dart';
import 'package:mudra_manager/features/transactions/presentation/screens/bill_control_center_screen.dart';
import 'package:mudra_manager/features/transactions/presentation/screens/transfer_screen_new.dart';
import 'package:mudra_manager/features/trip/presentation/screens/add_trip_transaction_screen.dart';
import 'package:mudra_manager/features/trip/presentation/screens/edit_trip_screen.dart';
import 'package:mudra_manager/features/trip/presentation/screens/expense_detail_screen.dart';
import 'package:mudra_manager/features/trip/presentation/screens/group_detail_dispatcher.dart';
import 'package:mudra_manager/features/trip/presentation/screens/trips_screen.dart';
import 'package:mudra_manager/features/upgrade/presentation/screens/upgrade_screen.dart';
import 'package:mudra_manager/features/import_export/presentation/screens/import_export_screen.dart';
import 'package:mudra_manager/features/import_export/presentation/screens/import_preview_screen.dart';
import 'package:mudra_manager/features/dashboard/presentation/screens/widget_analytics_screen.dart';
import 'package:mudra_manager/features/account/presentation/screens/credit_card_bills_screen.dart';
import 'package:mudra_manager/plugins/credit_card_reminder_settings.dart';
import 'package:mudra_manager/shared/screens/notification_page_screen.dart';
import 'package:mudra_manager/features/gamification/screens/achievements_screen.dart';
import 'package:mudra_manager/features/marketplace/screens/plugin_groups_screen.dart';
import 'package:mudra_manager/shared/widgets/pro_gate.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  static GoRouter router(bool showOnboarding) => GoRouter(
        navigatorKey: rootNavigatorKey,
        initialLocation: showOnboarding ? AppRoutes.onboarding : AppRoutes.home,
        debugLogDiagnostics: true,
        errorBuilder: (context, state) {
          // Unhandled deep links (e.g. website URLs) redirect to home
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go(AppRoutes.home);
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
        redirect: (context, state) {
          final isOnboardingComplete =
              SharedPrefsUtil.instance.isOnboardingComplete();
          final isOnOnboardingPage =
              state.matchedLocation == AppRoutes.onboarding;
          final isOnAccountSetupPage =
              state.matchedLocation == AppRoutes.accountSetup;

          // Handle root path from deep links
          if (state.matchedLocation == '/') {
            return isOnboardingComplete ? AppRoutes.home : AppRoutes.onboarding;
          }

          // If onboarding is complete and user is on onboarding/setup page, redirect to home
          if (isOnboardingComplete &&
              (isOnOnboardingPage || isOnAccountSetupPage)) {
            return AppRoutes.home;
          }

          // If onboarding is not complete and user is not on onboarding/setup pages, redirect to onboarding
          if (!isOnboardingComplete &&
              !isOnOnboardingPage &&
              !isOnAccountSetupPage) {
            return AppRoutes.onboarding;
          }

          return null; // No redirect needed
        },
        routes: [
          GoRoute(
            path: AppRoutes.onboarding,
            builder: (context, state) => const OnboardingScreen(),
          ),
          GoRoute(
            path: AppRoutes.accountSetup,
            builder: (context, state) => const AccountSetupScreen(),
          ),
          ShellRoute(
            builder: (context, state, child) => AuthGate(child: child),
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomePage(initialIndex: 0),
              ),
              GoRoute(
                path: AppRoutes.transactions,
                builder: (context, state) => const HomePage(initialIndex: 1),
              ),
              GoRoute(
                path: AppRoutes.utilities,
                builder: (context, state) => const HomePage(initialIndex: 2),
              ),
              GoRoute(
                path: AppRoutes.statistics,
                builder: (context, state) => const HomePage(initialIndex: 3),
              ),
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const HomePage(initialIndex: 4),
              ),
              GoRoute(
                path: AppRoutes.addTransaction,
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
                path: AppRoutes.transfer,
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
                    smsActivity: extra?['smsActivity'] as SmsActivity?,
                  );
                },
              ),

              GoRoute(
                path: AppRoutes.smsActivity,
                pageBuilder: (context, state) => CustomTransitionPage(
                  key: state.pageKey,
                  child: const SmsActivityScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return SharedAxisTransition(
                      animation: animation,
                      secondaryAnimation: secondaryAnimation,
                      transitionType: SharedAxisTransitionType.horizontal,
                      child: child,
                    );
                  },
                ),
              ),
              GoRoute(
                path: AppRoutes.notifications,
                pageBuilder: (context, state) => CustomTransitionPage(
                  key: state.pageKey,
                  child: const NotificationPage(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return SharedAxisTransition(
                      animation: animation,
                      secondaryAnimation: secondaryAnimation,
                      transitionType: SharedAxisTransitionType.horizontal,
                      child: child,
                    );
                  },
                ),
              ),
              GoRoute(
                path: AppRoutes.editProfile,
                builder: (context, state) => const EditUserProfileScreen(),
              ),
              GoRoute(
                path: AppRoutes.appSettings,
                pageBuilder: (context, state) => CustomTransitionPage(
                  key: state.pageKey,
                  child: const AppSettingsPage(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return SharedAxisTransition(
                      animation: animation,
                      secondaryAnimation: secondaryAnimation,
                      transitionType: SharedAxisTransitionType.horizontal,
                      child: child,
                    );
                  },
                ),
              ),
              GoRoute(
                path: AppRoutes.dashboardCustomize,
                builder: (context, state) => const ProGate(
                  feature: ProFeature.dashboardCustomize,
                  child: DashboardCustomizeScreen(),
                ),
              ),
              GoRoute(
                path: AppRoutes.commandCenter,
                builder: (context, state) => const CommandCenterScreen(),
              ),
              GoRoute(
                path: AppRoutes.recurringExpenses,
                builder: (context, state) => const RecurringExpensesScreen(),
              ),
              GoRoute(
                path: AppRoutes.security,
                builder: (context, state) => const SecuritySettingsScreen(),
              ),
              GoRoute(
                path: AppRoutes.notificationSettings,
                builder: (context, state) => const NotificationSettingsScreen(),
              ),
              GoRoute(
                path: AppRoutes.smsImport,
                builder: (context, state) => const SmsImportSettingsScreen(),
              ),
              GoRoute(
                path: AppRoutes.chooseLanguage,
                builder: (context, state) => const ChooseLanguageScreen(),
              ),
              GoRoute(
                path: AppRoutes.themePicker,
                builder: (context, state) => const ThemePickerScreen(),
              ),
              GoRoute(
                path: AppRoutes.skinPicker,
                builder: (context, state) => const SkinPickerScreen(),
              ),
              GoRoute(
                path: AppRoutes.skinEditor,
                builder: (context, state) => const SkinEditorScreen(),
              ),
              GoRoute(
                path: AppRoutes.backupRestore,
                builder: (context, state) => const ProGate(
                  feature: ProFeature.cloudBackup,
                  child: BackupRestoreScreen(),
                ),
              ),

              GoRoute(
                path: AppRoutes.about,
                builder: (context, state) => const AboutScreen(),
              ),
              GoRoute(
                path: AppRoutes.help,
                builder: (context, state) => const HelpScreen(),
              ),
              GoRoute(
                path: AppRoutes.manageAccounts,
                pageBuilder: (context, state) => CustomTransitionPage(
                  key: state.pageKey,
                  child: const ManageAccountScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return SharedAxisTransition(
                      animation: animation,
                      secondaryAnimation: secondaryAnimation,
                      transitionType: SharedAxisTransitionType.horizontal,
                      child: child,
                    );
                  },
                ),
              ),
              GoRoute(
                path: AppRoutes.manageCategories,
                pageBuilder: (context, state) => CustomTransitionPage(
                  key: state.pageKey,
                  child: const ManageCategoriesScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return SharedAxisTransition(
                      animation: animation,
                      secondaryAnimation: secondaryAnimation,
                      transitionType: SharedAxisTransitionType.horizontal,
                      child: child,
                    );
                  },
                ),
              ),
              GoRoute(
                path: AppRoutes.addBudget,
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  return AddBudgetScreen(existing: extra?['budget']);
                },
              ),
              GoRoute(
                path: AppRoutes.addGoal,
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  return AddEditGoalScreen(goal: extra?['goal']);
                },
              ),
              GoRoute(
                path: AppRoutes.addCategory,
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  return AddEditCategoryScreen(
                    existing: extra?['category'],
                    initialParent: extra?['parent'] as Category?,
                    initialType: extra?['type'] as CategoryType?,
                  );
                },
              ),
              GoRoute(
                path: AppRoutes.budgetDashboard,
                pageBuilder: (context, state) => CustomTransitionPage(
                  key: state.pageKey,
                  child: const AdaptiveBudgetDashboard(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return SharedAxisTransition(
                      animation: animation,
                      secondaryAnimation: secondaryAnimation,
                      transitionType: SharedAxisTransitionType.horizontal,
                      child: child,
                    );
                  },
                ),
              ),
              GoRoute(
                path: AppRoutes.budgetDetails,
                pageBuilder: (context, state) {
                  final data = state.extra as BudgetWithProgress;
                  return CustomTransitionPage(
                    key: state.pageKey,
                    child: BudgetDetailsScreen(data: data),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return SharedAxisTransition(
                        animation: animation,
                        secondaryAnimation: secondaryAnimation,
                        transitionType: SharedAxisTransitionType.horizontal,
                        child: child,
                      );
                    },
                  );
                },
              ),
              GoRoute(
                path: AppRoutes.goalScreen,
                pageBuilder: (context, state) => CustomTransitionPage(
                  key: state.pageKey,
                  child: const GoalScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return SharedAxisTransition(
                      animation: animation,
                      secondaryAnimation: secondaryAnimation,
                      transitionType: SharedAxisTransitionType.horizontal,
                      child: child,
                    );
                  },
                ),
              ),
              GoRoute(
                path: AppRoutes.goalDetails,
                pageBuilder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  return CustomTransitionPage(
                    key: state.pageKey,
                    child: GoalDetailsScreen(goal: extra?['goal']),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return SharedAxisTransition(
                        animation: animation,
                        secondaryAnimation: secondaryAnimation,
                        transitionType: SharedAxisTransitionType.horizontal,
                        child: child,
                      );
                    },
                  );
                },
              ),
              GoRoute(
                path: AppRoutes.addAccount,
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
                path: AppRoutes.monthlyComparison,
                builder: (context, state) => const MonthlyComparisonScreen(),
              ),
              GoRoute(
                path: AppRoutes.recurringTransactions,
                builder: (context, state) => const BillControlCenterScreen(),
              ),
              GoRoute(
                path: AppRoutes.addRecurring,
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  return AddRecurringTransactionScreen(
                    recurring: extra?['recurring'],
                  );
                },
              ),
              GoRoute(
                path: AppRoutes.trips,
                pageBuilder: (context, state) => CustomTransitionPage(
                  key: state.pageKey,
                  child: const TripsScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return SharedAxisTransition(
                      animation: animation,
                      secondaryAnimation: secondaryAnimation,
                      transitionType: SharedAxisTransitionType.horizontal,
                      child: child,
                    );
                  },
                ),
              ),

              GoRoute(
                path: AppRoutes.tripDetail,
                pageBuilder: (context, state) {
                  final tripId = state.extra as int;
                  return CustomTransitionPage(
                    key: state.pageKey,
                    child: GroupDetailDispatcher(tripId: tripId),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      return SharedAxisTransition(
                        animation: animation,
                        secondaryAnimation: secondaryAnimation,
                        transitionType: SharedAxisTransitionType.horizontal,
                        child: child,
                      );
                    },
                  );
                },
              ),
              GoRoute(
                path: AppRoutes.addTripTransaction,
                builder: (context, state) {
                  final extra = state.extra;
                  final tripId = extra is int
                      ? extra
                      : (extra as Map<String, dynamic>)['tripId'] as int;
                  return AddTripTransactionScreen(tripId: tripId);
                },
              ),
              GoRoute(
                path: AppRoutes.createTrip,
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  return ManageTripScreen(isTrip: extra?['isTrip'] ?? true);
                },
              ),
              GoRoute(
                path: '${AppRoutes.editTrip}/:id',
                builder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  return ManageTripScreen(tripId: id);
                },
              ),
              GoRoute(
                path: AppRoutes.expenseDetail,
                builder: (context, state) {
                  final data = state.extra as Map<String, dynamic>;
                  return ExpenseDetailScreen(
                    expenseId: data['expenseId'] as int,
                    tripId: data['tripId'] as int,
                  );
                },
              ),
              GoRoute(
                path: AppRoutes.analytics,
                pageBuilder: (context, state) => CustomTransitionPage(
                  key: state.pageKey,
                  child: const ProGate(
                    feature: ProFeature.advancedAnalytics,
                    child: AnalyticsScreen(),
                  ),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return SharedAxisTransition(
                      animation: animation,
                      secondaryAnimation: secondaryAnimation,
                      transitionType: SharedAxisTransitionType.horizontal,
                      child: child,
                    );
                  },
                ),
              ),
              GoRoute(
                path: AppRoutes.financialHealth,
                builder: (context, state) => const ProGate(
                  feature: ProFeature.advancedAnalytics,
                  child: FinancialHealthScreen(),
                ),
              ),
              GoRoute(
                path: AppRoutes.spendingPersonality,
                builder: (context, state) => const ProGate(
                  feature: ProFeature.spendingPersonality,
                  child: SpendingPersonalityScreen(),
                ),
              ),
              GoRoute(
                path: AppRoutes.netWorth,
                builder: (context, state) => const ProGate(
                  feature: ProFeature.netWorth,
                  child: NetWorthScreen(),
                ),
              ),
              GoRoute(
                path: AppRoutes.taxEstimation,
                builder: (context, state) => const ProGate(
                  feature: ProFeature.advancedAnalytics,
                  child: TaxEstimationScreen(),
                ),
              ),
              GoRoute(
                path: AppRoutes.cashFlowForecast,
                builder: (context, state) => const ProGate(
                  feature: ProFeature.advancedAnalytics,
                  child: CashFlowForecastScreen(),
                ),
              ),
              GoRoute(
                path: AppRoutes.spendingTrends,
                builder: (context, state) => const ProGate(
                  feature: ProFeature.advancedAnalytics,
                  child: SpendingTrendsScreen(),
                ),
              ),
              GoRoute(
                path: AppRoutes.achievements,
                builder: (context, state) => const AchievementsScreen(),
              ),
              GoRoute(
                path: AppRoutes.monthlyRecap,
                builder: (context, state) {
                  final month = state.extra as DateTime?;
                  return ProGate(
                    feature: ProFeature.monthlyRecap,
                    child: MonthlyRecapScreen(month: month),
                  );
                },
              ),
              GoRoute(
                path: AppRoutes.marketplace,
                builder: (context, state) => const PluginGroupsScreen(),
              ),
              GoRoute(
                path: AppRoutes.creditCardReminders,
                builder: (context, state) => const CreditCardReminderSettings(),
              ),
              GoRoute(
                path: AppRoutes.creditCardBills,
                builder: (context, state) => const CreditCardBillsScreen(),
              ),
              // Add route (inside the ShellRoute routes list, near the other settings routes)
              GoRoute(
                path: AppRoutes.appearance,
                builder: (context, state) => const AppearanceScreen(),
              ),
              GoRoute(
                path: AppRoutes.upgrade,
                builder: (context, state) => const UpgradeScreen(),
              ),
              GoRoute(
                path: AppRoutes.currencySettings,
                builder: (context, state) => const CurrencySettingsScreen(),
              ),
              GoRoute(
                path: AppRoutes.exchangeRates,
                builder: (context, state) => const ExchangeRateScreen(),
              ),
              GoRoute(
                path: AppRoutes.archivedTransactions,
                builder: (context, state) => const ArchivedTransactionsScreen(),
              ),
              GoRoute(
                path: AppRoutes.importExport,
                builder: (context, state) => const ImportExportScreen(),
              ),
              GoRoute(
                path: AppRoutes.widgetAnalytics,
                builder: (context, state) => const WidgetAnalyticsScreen(),
              ),
              GoRoute(
                path: AppRoutes.importPreview,
                builder: (context, state) {
                  final bytes = state.extra;
                  if (bytes is! Uint8List) {
                    return const Scaffold(
                      body: Center(child: Text('Invalid file data')),
                    );
                  }
                  return ImportPreviewScreen(fileBytes: bytes);
                },
              ),
            ],
          ),
        ],
      );
}
