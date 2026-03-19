abstract class AppRoutes {
  // Auth & Onboarding
  static const onboarding = '/onboarding';
  static const accountSetup = '/account-setup';

  // Main tabs
  static const home = '/home';
  static const transactions = '/transactions';
  static const utilities = '/utilities';
  static const statistics = '/statistics';
  static const profile = '/profile';

  // Transactions
  static const addTransaction = '/add-transaction';
  static const transfer = '/transfer';

  // Budget
  static const budgetDashboard = '/budget-dashboard';
  static const addBudget = '/add-budget';
  static const budgetDetails = '/budget-details';

  // Goals
  static const goalScreen = '/goal-screen';
  static const addGoal = '/add-goal';
  static const goalDetails = '/goal-details';

  // Recurring
  static const recurringTransactions = '/recurring-transactions';
  static const recurringExpenses = '/recurring-expenses';
  static const addRecurring = '/add-recurring';

  // Trips
  static const trips = '/trips';
  static const createTrip = '/create-trip';
  static const tripDetail = '/trip-detail';
  static const addTripTransaction = '/add-trip-transaction';
  static const editTrip = '/edit-trip';
  static const expenseDetail = '/expense-detail';

  // Analytics & Statistics
  static const analytics = '/analytics';
  static const financialHealth = '/financial-health';
  static const spendingPersonality = '/spending-personality';
  static const netWorth = '/net-worth';
  static const monthlyComparison = '/monthly-comparison';
  static const monthlyRecap = '/monthly-recap';

  // Profile & Settings
  static const editProfile = '/edit-profile';
  static const appSettings = '/app-settings';
  static const security = '/security';
  static const notificationSettings = '/notification-settings';
  static const smsImport = '/sms-import';
  static const chooseLanguage = '/choose-language';
  static const themePicker = '/theme-picker';
  static const backupRestore = '/backup-restore';
  static const about = '/about';
  static const help = '/help';
  static const appearance = '/appearance';

  // Accounts & Categories
  static const manageAccounts = '/manage-accounts';
  static const addAccount = '/manage-accounts/add';
  static const manageCategories = '/manage-categories';
  static const addCategory = '/add-category';

  // Dashboard
  static const dashboardCustomize = '/dashboard-customize';
  static const commandCenter = '/command-center';

  // Other
  static const smsActivity = '/sms-activity';
  static const notifications = '/notifications';
  static const achievements = '/achievements';
  static const marketplace = '/marketplace';
  static const creditCardReminders = '/credit-card-reminders';
}
