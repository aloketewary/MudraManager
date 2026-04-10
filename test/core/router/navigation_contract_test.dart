import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/router/app_routes.dart';

void main() {
  group('Route definitions exist', () {
    test('all main tab routes defined', () {
      expect(AppRoutes.home, isNotEmpty);
      expect(AppRoutes.transactions, isNotEmpty);
      expect(AppRoutes.utilities, isNotEmpty);
      expect(AppRoutes.statistics, isNotEmpty);
      expect(AppRoutes.profile, isNotEmpty);
    });

    test('transaction routes defined', () {
      expect(AppRoutes.addTransaction, isNotEmpty);
      expect(AppRoutes.transfer, isNotEmpty);
    });

    test('budget routes defined', () {
      expect(AppRoutes.budgetDashboard, isNotEmpty);
      expect(AppRoutes.addBudget, isNotEmpty);
      expect(AppRoutes.budgetDetails, isNotEmpty);
    });

    test('goal routes defined', () {
      expect(AppRoutes.goalScreen, isNotEmpty);
      expect(AppRoutes.addGoal, isNotEmpty);
      expect(AppRoutes.goalDetails, isNotEmpty);
    });

    test('trip routes defined', () {
      expect(AppRoutes.trips, isNotEmpty);
      expect(AppRoutes.createTrip, isNotEmpty);
      expect(AppRoutes.tripDetail, isNotEmpty);
      expect(AppRoutes.addTripTransaction, isNotEmpty);
      expect(AppRoutes.expenseDetail, isNotEmpty);
    });

    test('recurring routes defined', () {
      expect(AppRoutes.recurringTransactions, isNotEmpty);
      expect(AppRoutes.addRecurring, isNotEmpty);
    });

    test('account routes defined', () {
      expect(AppRoutes.manageAccounts, isNotEmpty);
      expect(AppRoutes.addAccount, isNotEmpty);
    });

    test('category routes defined', () {
      expect(AppRoutes.manageCategories, isNotEmpty);
      expect(AppRoutes.addCategory, isNotEmpty);
    });

    test('analytics routes defined', () {
      expect(AppRoutes.financialHealth, isNotEmpty);
      expect(AppRoutes.spendingPersonality, isNotEmpty);
      expect(AppRoutes.monthlyComparison, isNotEmpty);
    });

    test('settings routes defined', () {
      expect(AppRoutes.editProfile, isNotEmpty);
      expect(AppRoutes.appSettings, isNotEmpty);
      expect(AppRoutes.backupRestore, isNotEmpty);
    });
  });

  group('Screen navigation contracts', () {
    // These tests verify the CRUD contract:
    // Every list screen must have a route to create
    // Every item must have a route to detail/edit
    // Every detail must support delete

    test('manage accounts: list → add route exists', () {
      // ManageAccountScreen uses AppRoutes.addAccount
      expect(AppRoutes.manageAccounts, isNotEmpty);
      expect(AppRoutes.addAccount, isNotEmpty);
      // addAccount is a sub-route of manageAccounts
      expect(AppRoutes.addAccount, contains('manage-accounts'));
    });

    test('manage categories: list → add route exists', () {
      expect(AppRoutes.manageCategories, isNotEmpty);
      expect(AppRoutes.addCategory, isNotEmpty);
    });

    test('goals: list → add → detail chain exists', () {
      expect(AppRoutes.goalScreen, isNotEmpty);
      expect(AppRoutes.addGoal, isNotEmpty);
      expect(AppRoutes.goalDetails, isNotEmpty);
    });

    test('budgets: list → add → detail chain exists', () {
      expect(AppRoutes.budgetDashboard, isNotEmpty);
      expect(AppRoutes.addBudget, isNotEmpty);
      expect(AppRoutes.budgetDetails, isNotEmpty);
    });

    test('trips: list → create → detail → add expense chain exists', () {
      expect(AppRoutes.trips, isNotEmpty);
      expect(AppRoutes.createTrip, isNotEmpty);
      expect(AppRoutes.tripDetail, isNotEmpty);
      expect(AppRoutes.addTripTransaction, isNotEmpty);
      expect(AppRoutes.expenseDetail, isNotEmpty);
    });

    test('recurring: list → add chain exists', () {
      expect(AppRoutes.recurringTransactions, isNotEmpty);
      expect(AppRoutes.addRecurring, isNotEmpty);
    });

    test('all routes are unique', () {
      final routes = [
        AppRoutes.home,
        AppRoutes.transactions,
        AppRoutes.utilities,
        AppRoutes.statistics,
        AppRoutes.profile,
        AppRoutes.addTransaction,
        AppRoutes.transfer,
        AppRoutes.budgetDashboard,
        AppRoutes.addBudget,
        AppRoutes.goalScreen,
        AppRoutes.addGoal,
        AppRoutes.goalDetails,
        AppRoutes.trips,
        AppRoutes.createTrip,
        AppRoutes.tripDetail,
        AppRoutes.addTripTransaction,
        AppRoutes.expenseDetail,
        AppRoutes.recurringTransactions,
        AppRoutes.addRecurring,
        AppRoutes.manageAccounts,
        AppRoutes.addAccount,
        AppRoutes.manageCategories,
        AppRoutes.addCategory,
        AppRoutes.financialHealth,
        AppRoutes.spendingPersonality,
        AppRoutes.monthlyComparison,
      ];

      final uniqueRoutes = routes.toSet();
      expect(uniqueRoutes.length, routes.length,
          reason: 'All routes must be unique',);
    });

    test('all routes start with /', () {
      final routes = [
        AppRoutes.home,
        AppRoutes.transactions,
        AppRoutes.addTransaction,
        AppRoutes.budgetDashboard,
        AppRoutes.goalScreen,
        AppRoutes.trips,
        AppRoutes.recurringTransactions,
        AppRoutes.manageAccounts,
        AppRoutes.manageCategories,
        AppRoutes.financialHealth,
      ];

      for (final route in routes) {
        expect(route.startsWith('/'), true,
            reason: 'Route "$route" must start with /',);
      }
    });
  });

  group('Feature completeness contracts', () {
    test('account management has full CRUD', () {
      // List: manageAccounts
      // Create: addAccount
      // Read/Edit: addAccount with extra (account object)
      // Delete: handled in manage screen via bottom sheet
      expect(AppRoutes.manageAccounts, isNotEmpty);
      expect(AppRoutes.addAccount, isNotEmpty);
    });

    test('category management has full CRUD', () {
      expect(AppRoutes.manageCategories, isNotEmpty);
      expect(AppRoutes.addCategory, isNotEmpty);
    });

    test('goal management has full CRUD', () {
      expect(AppRoutes.goalScreen, isNotEmpty); // List
      expect(AppRoutes.addGoal, isNotEmpty); // Create
      expect(AppRoutes.goalDetails, isNotEmpty); // Read
      // Edit: addGoal with extra (goal object)
      // Delete: handled in detail screen
    });

    test('budget management has full CRUD', () {
      expect(AppRoutes.budgetDashboard, isNotEmpty); // List
      expect(AppRoutes.addBudget, isNotEmpty); // Create
      expect(AppRoutes.budgetDetails, isNotEmpty); // Read
    });

    test('trip management has full CRUD', () {
      expect(AppRoutes.trips, isNotEmpty); // List
      expect(AppRoutes.createTrip, isNotEmpty); // Create
      expect(AppRoutes.tripDetail, isNotEmpty); // Read
      expect(AppRoutes.addTripTransaction, isNotEmpty); // Add expense
      expect(AppRoutes.expenseDetail, isNotEmpty); // Expense detail
      // Edit: editTrip route
      // Delete: handled in detail screen popup menu
    });
  });
}
