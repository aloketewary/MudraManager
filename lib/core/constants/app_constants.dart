class AppConstants {
  // SMS Processing
  static const int smsHashRetentionDays = 90;
  static const int maxSmsHashCount = 1000;
  
  // Pagination
  static const int transactionPageSize = 50;
  static const int defaultPageSize = 20;
  
  // Categories
  static const int maxCategoriesLimit = 50;
  static const int defaultCategoryLimit = 10;
  
  // Security
  static const Duration autoLockTimeout = Duration(minutes: 5);
  static const int maxLoginAttempts = 5;
  
  // Notifications
  static const int budgetAlertThreshold80 = 80;
  static const int budgetAlertThreshold90 = 90;
  static const int budgetAlertThreshold100 = 100;
  
  // Backup
  static const int autoBackupIntervalDays = 7;
  static const int maxBackupRetentionDays = 30;
  
  // Performance
  static const Duration debounceDelay = Duration(milliseconds: 300);
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
  
  // Retry Logic
  static const int maxRetryAttempts = 3;
  static const Duration retryInitialDelay = Duration(seconds: 1);
  
  // Cache
  static const Duration cacheExpiration = Duration(hours: 1);
  static const int maxCacheSize = 100;
  
  // Date Ranges
  static const int defaultMonthsToShow = 6;
  static const int maxHistoryMonths = 24;
  
  // Amounts
  static const double minTransactionAmount = 0.01;
  static const double maxTransactionAmount = 99999999.99;
  
  // UI
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double defaultBorderRadius = 12.0;
  static const double cardElevation = 2.0;
}
