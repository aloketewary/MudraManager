import 'package:mudra_manager/core/tone/tone_pack.dart';
import 'package:mudra_manager/core/tone/tone_variation.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 🤝 BUDDY — warm, casual, encouraging (default)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class FriendlyTonePack extends TonePack {
  @override
  String get id => 'friendly';
  @override
  String get name => 'Friendly';
  @override
  String get description => 'Warm, casual & encouraging';
  @override
  String get emoji => '🤝';

  @override
  String get txnAdded => pickRandom([
    'Done! Transaction saved ✨',
    'Got it! All logged 👍',
    'Saved! You\'re on top of it ✨',
    'Noted! One more tracked 📝',
  ]);
  @override
  String get txnUpdated => pickRandom([
    'Updated! Looking good 👍',
    'Changes saved! ✓',
    'All updated! 👌',
  ]);
  @override
  String get txnDeleted => pickRandom([
    'Gone! Transaction removed 🗑️',
    'Deleted! One less to track',
    'Removed! Clean slate 🗑️',
  ]);
  @override
  String get txnFailed => 'Hmm, couldn\'t save that. Try again?';
  @override
  String get txnNotFound => 'Can\'t find that transaction';

  @override
  String get enterAmount => 'How much was it? Enter an amount';
  @override
  String get pickAccount => 'Which account? Pick one to continue';
  @override
  String get pickCategory => 'What was it for? Choose a category';
  @override
  String get fillAllFields => 'Almost there — fill in all the fields';
  @override
  String get invalidAmount => 'That doesn\'t look right — enter a valid amount';
  @override
  String get futureDate => 'Pick today or earlier';
  @override
  String get selectAccountAndCategory => 'Pick an account & category first';

  @override
  String tripCreated(bool isTrip) => isTrip
      ? 'Trip created — let\'s go! ✈️'
      : 'Group ready — let\'s split! 🤝';
  @override
  String tripUpdated(bool isTrip) =>
      isTrip ? 'Trip updated! 👌' : 'Group updated! 👌';
  @override
  String tripDeleted(bool isTrip) => isTrip ? 'Trip deleted' : 'Group deleted';
  @override
  String tripFinalized(bool isTrip) =>
      isTrip ? 'Trip wrapped up! 🎉' : 'Group closed! 🎉';
  @override
  String tripNameRequired(bool isTrip) =>
      isTrip ? 'Give your trip a name!' : 'Give your group a name!';
  @override
  String get addParticipant => 'Add at least one person to split with';
  @override
  String tripLimitReached(bool isTrip) =>
      'Free plan allows 1 active ${isTrip ? 'trip' : 'group'}. Go Pro for unlimited! 🚀';
  @override
  String expenseAddedToTrip(bool isTrip) =>
      isTrip ? 'Expense added to trip! 💰' : 'Expense added to group! 💰';

  @override
  String get budgetCreated => pickRandom([
    'Budget set! Let\'s stay on track 💪',
    'Budget locked in! You\'re planning ahead 💪',
    'Nice! Budget is ready to roll 📊',
  ]);
  @override
  String get budgetUpdated => 'Budget updated!';
  @override
  String get budgetDeleted => 'Budget removed';

  @override
  String get goalCreated => pickRandom([
    'Goal set! You got this 🎯',
    'New goal! Let\'s make it happen 🎯',
    'Goal locked in! Eyes on the prize 🎯',
  ]);
  @override
  String get goalUpdated => 'Goal updated!';
  @override
  String get goalDeleted => 'Goal removed';

  @override
  String get accountCreated => 'Account added! 🏦';
  @override
  String get accountUpdated => 'Account updated!';
  @override
  String get accountDeleted => 'Account removed';
  @override
  String get accountLocked =>
      'This account is locked — upgrade to Pro to use it 🔒';

  @override
  String get categoryCreated => 'Category added!';
  @override
  String get categoryDeleted => 'Category removed';
  @override
  String get categoryNameRequired => 'Give it a name!';

  @override
  String get billAdded => 'Bill tracked! I\'ll remind you 🔔';
  @override
  String get billPaid => pickRandom([
    'Nice, bill marked as paid! ✅',
    'Bill done! One less to worry about ✅',
    'Paid! That\'s a relief ✅',
  ]);
  @override
  String get billDeleted => 'Bill removed';

  @override
  String get backupSuccess => 'Backup done! Your data is safe 🛡️';
  @override
  String get backupFailed => 'Backup didn\'t work — try again?';
  @override
  String get restoreSuccess => 'Restored! Welcome back 🎉';
  @override
  String get restoreFailed => 'Restore failed — is the file okay?';
  @override
  String get invalidBackupFile => 'That doesn\'t look like a valid backup file';
  @override
  String get corruptBackup => 'This backup looks corrupted 😕';

  @override
  String get settingsSaved => 'Saved! ✓';
  @override
  String get reminderUpdated => 'Reminder updated ⏰';
  @override
  String toggledOn(String feature) => '$feature is on ✓';
  @override
  String toggledOff(String feature) => '$feature is off';

  @override
  String get biometricFailed => 'Authentication failed — try again';
  @override
  String get incorrectPin => 'Wrong PIN — give it another shot';

  @override
  String get notificationAccessDenied =>
      'Need notification access to auto-import transactions';
  @override
  String get smsImportEnabled =>
      'Auto import is on! I\'ll track your transactions 📩';

  @override
  String get noTransactions =>
      pickRandom([
        'Nothing here yet\nAdd your first transaction to get started',
        'Empty for now\nStart tracking — it only takes a sec',
        'No transactions yet\nYour financial journey starts with one entry',
      ]);
  @override
  String get noBudgets => 'No budgets yet\nSet one up to track your spending';
  @override
  String get noGoals => 'No goals yet\nDream big — set your first goal!';
  @override
  String get noBills =>
      'No bills tracked\nAdd recurring bills so you never miss a payment';
  @override
  String get noAccounts => 'No accounts yet\nAdd one to start tracking';
  @override
  String get noCategories => 'No categories yet';
  @override
  String get noNotifications => 'All quiet here\nNo notifications yet';
  @override
  String noFilterResults(String filter) => 'No $filter notifications';
  @override
  String get noData => 'Not enough data yet\nKeep tracking to unlock insights';
  @override
  String get noRecurring =>
      'No recurring transactions\nAdd bills to auto-track them';

  @override
  String get exportSuccess => 'Report exported! 📄';
  @override
  String exportFailed(String error) => 'Export didn\'t work: $error';

  @override
  String get purchaseFailed => 'Purchase didn\'t go through — try again?';
  @override
  String get playNotAvailable => 'Google Play isn\'t available on this device';

  @override
  String errorWith(String detail) => 'Something went wrong: $detail';
  @override
  String get genericError => 'Something went wrong. Try again?';

  @override
  String get deleteTitle => 'Are you sure?';
  @override
  String deleteMessage(String? param) =>
      'This ${param != null ? 'remove $param and' : ''}can\'t be undone — want to go ahead?';
  @override
  String get deleteConfirm => 'Delete';
  @override
  String get deleteCancel => 'Keep it';
  @override
  String get logoutTitle => 'Leaving already?';
  @override
  String get logoutMessage => 'All your data will be cleared from this device.';
  @override
  String get logoutConfirm => 'Logout';

  @override
  String get insightBillsDueSoon => 'Heads up — bills incoming';
  @override
  String insightBillsDueMessage(int count) =>
      '$count bill${count > 1 ? "s" : ""} due soon, don\'t forget!';
  @override
  String get insightOverBudget => 'Over budget';
  @override
  String insightOverBudgetMessage(int count) =>
      '$count budget${count > 1 ? "s" : ""} went over this month — worth a look';
  @override
  String get insightNearBudget => 'Getting close...';
  @override
  String insightNearBudgetMessage(int count) =>
      '$count budget${count > 1 ? "s" : ""} past 80% — still time to rein it in';
  @override
  String get insightOverspending => 'Spending outpacing income';
  @override
  String insightOverspendingMessage(String amount) =>
      'You\'re ₹$amount over your income this month — might want to slow down';
  @override
  String get insightSpendingSpike => 'Spending spike today';
  @override
  String insightSpendingSpikeMessage(String avg, String today) =>
      'You usually spend ₹$avg/day. Today\'s already ₹$today.';
  @override
  String get insightWeekendAlert => 'Weekend spending alert';
  @override
  String insightWeekendAlertMessage(String avg, String current) =>
      'You usually spend ₹$avg on weekends. This one\'s already ₹$current.';
  @override
  String insightMoneyLeak(String category, int count, String total) =>
      '$category: $count times this month, ₹$total total — small hits add up';
  @override
  String insightBestDay(
    String worst,
    String wAvg,
    String best,
    String bAvg,
    String saving,
  ) =>
      '₹$wAvg avg on ${worst}s vs ₹$bAvg on ${best}s — that\'s ₹$saving you could keep';
  @override
  String get insightGetStarted => 'Let\'s get started! 🚀';
  @override
  String get insightGetStartedMessage =>
      'Add your first transaction — it only takes a sec';

  @override
  String singleApproved(String amountStr) =>
      'Your transaction$amountStr has been tracked. I\'m on it! 💪';
  @override
  String allApproved(int count, String amountStr) =>
      '$count transaction${count > 1 ? 's' : ''}$amountStr tracked while you were away. No worries, I handled it! 😎';
  @override
  String mixedResults(int approved, int reviewCount) =>
      'Tracked $approved transaction${approved > 1 ? 's' : ''}, but $reviewCount need${reviewCount == 1 ? 's' : ''} a quick look. Let\'s review together! 👀';
  @override
  String allNeedReview(int reviewCount) =>
      '$reviewCount transaction${reviewCount > 1 ? 's' : ''} need${reviewCount == 1 ? 's' : ''} your review. Let\'s sort ${reviewCount == 1 ? 'it' : 'them'} out! 🤝';

  @override
  String greetingMorning(String name) => 'Good morning, $name! ☀️';
  @override
  String greetingAfternoon(String name) => 'Hey $name, how\'s the day going?';
  @override
  String greetingEvening(String name) => 'Evening, $name! Time to wind down 🌙';
  @override
  String get dashboardWelcomeBack => 'Welcome back! Let\'s see where you stand';
  @override
  String get dashboardAllCaughtUp => pickRandom([
    'You\'re all caught up! 🎉',
    'Nothing needs your attention — nice! ✨',
    'All good here! Enjoy your day 🎉',
  ]);
  @override
  String streakMessage(int days) => '$days day streak! Keep it going! 🔥';

  // ── Contextual Notifications ──
  @override
  String budgetExceededNotif(String name, String spent, String limit) =>
      '$name is over budget — ₹$spent of ₹$limit spent. Might want to ease up';
  @override
  String budgetWarningNotif(String name, String remaining, String pct) =>
      '$name is at $pct% — only ₹$remaining left to play with';
  @override
  String billDueNotif(String name, String amount, String when) =>
      '$name (₹$amount) is due $when — just a heads up!';
  @override
  String balanceDropNotif(String days) =>
      'At this pace, things could get tight in about $days days';
  @override
  String savingsOpportunityNotif(String category, String amount) =>
      '$category is trending ₹$amount higher than last month — small cuts add up!';
  @override
  String unusualSpendingNotif(String today, String multiplier) =>
      '₹$today spent today — that\'s ${multiplier}x your usual. Big day?';
  @override
  String pendingSmsNotif(int count) =>
      'Picked up $count from your messages — quick review?';
  @override
  String moneyLeakNotif(String category, int count, String total) =>
      '$category: $count transactions, ₹$total this month — worth a look';
  @override
  String reEngageMissYou(int lostStreak) => lostStreak > 3
      ? 'Your $lostStreak-day streak is gone — but a new one starts with one tap'
      : 'It\'s been a while — just open the app to get back on track';
  @override
  String reEngageUntracked(int days, String estimatedSpend) =>
      'You probably spent around ₹$estimatedSpend since you last checked — quick catch-up?';
  @override
  String get reEngageQuickNudge =>
      'Track today\'s spending before it slips — just one tap';
  @override
  String dailySummaryNotif(String spent, String earned, String topCategory) =>
      'Spent ₹$spent · Earned ₹$earned\nMost went to $topCategory';
  @override
  String get dailySummaryEmpty => pickRandom([
    'Nothing recorded yesterday — either a zero-spend win or time to catch up!',
    'Quiet day yesterday — your wallet thanks you!',
    'No transactions yesterday — fresh start today!',
  ]);
  @override
  String weeklySummaryNotif(String total, String topCategory, String trend) =>
      'You spent ₹$total\nMost on $topCategory\n$trend';
  @override
  String streakAtRisk(int streak) =>
      '$streak-day streak on the line — just open the app to keep it alive!';
  @override
  String streakLost(int streak) =>
      'Your $streak-day streak ended — it happens! One tap starts a new one';
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 📋 PROFESSIONAL — clean, formal, no emojis
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class ProfessionalTonePack extends TonePack {
  @override
  String get id => 'professional';
  @override
  String get name => 'Professional';
  @override
  String get description => 'Clean, formal & precise';
  @override
  String get emoji => '📋';

  @override
  String get txnAdded => pickRandom([
    'Transaction recorded.',
    'Entry saved successfully.',
    'Transaction logged.',
  ]);
  @override
  String get txnUpdated => pickRandom([
    'Transaction updated.',
    'Changes applied.',
    'Record updated successfully.',
  ]);
  @override
  String get txnDeleted => pickRandom([
    'Transaction deleted.',
    'Record removed.',
    'Entry deleted successfully.',
  ]);
  @override
  String get txnFailed => 'Failed to save transaction. Please retry.';
  @override
  String get txnNotFound => 'Transaction not found.';

  @override
  String get enterAmount => 'Please enter a valid amount.';
  @override
  String get pickAccount => 'Please select an account.';
  @override
  String get pickCategory => 'Please select a category.';
  @override
  String get fillAllFields => 'All required fields must be completed.';
  @override
  String get invalidAmount => 'Invalid amount entered.';
  @override
  String get futureDate => 'Future dates are not permitted.';
  @override
  String get selectAccountAndCategory => 'Account and category are required.';

  @override
  String tripCreated(bool isTrip) =>
      isTrip ? 'Trip created successfully.' : 'Split group created.';
  @override
  String tripUpdated(bool isTrip) =>
      isTrip ? 'Trip updated.' : 'Group updated.';
  @override
  String tripDeleted(bool isTrip) =>
      isTrip ? 'Trip deleted.' : 'Group deleted.';
  @override
  String tripFinalized(bool isTrip) =>
      isTrip ? 'Trip finalized.' : 'Group closed.';
  @override
  String tripNameRequired(bool isTrip) =>
      isTrip ? 'Trip name is required.' : 'Group name is required.';
  @override
  String get addParticipant => 'At least one participant is required.';
  @override
  String tripLimitReached(bool isTrip) =>
      'Free plan limit: 1 active ${isTrip ? 'trip' : 'group'}. Upgrade for more.';
  @override
  String expenseAddedToTrip(bool isTrip) =>
      isTrip ? 'Expense linked to trip.' : 'Expense linked to group.';

  @override
  String get budgetCreated => pickRandom([
    'Budget created.',
    'Budget configured successfully.',
    'New budget is active.',
  ]);
  @override
  String get budgetUpdated => 'Budget updated.';
  @override
  String get budgetDeleted => 'Budget deleted.';

  @override
  String get goalCreated => pickRandom([
    'Goal created.',
    'Savings goal configured.',
    'New goal is active.',
  ]);
  @override
  String get goalUpdated => 'Goal updated.';
  @override
  String get goalDeleted => 'Goal deleted.';

  @override
  String get accountCreated => 'Account added.';
  @override
  String get accountUpdated => 'Account updated.';
  @override
  String get accountDeleted => 'Account removed.';
  @override
  String get accountLocked => 'Account locked. Pro subscription required.';

  @override
  String get categoryCreated => 'Category added.';
  @override
  String get categoryDeleted => 'Category removed.';
  @override
  String get categoryNameRequired => 'Category name is required.';

  @override
  String get billAdded => 'Bill added. Reminders will be sent.';
  @override
  String get billPaid => pickRandom([
    'Bill marked as paid.',
    'Payment recorded.',
    'Bill settled.',
  ]);
  @override
  String get billDeleted => 'Bill removed.';

  @override
  String get backupSuccess => 'Backup completed successfully.';
  @override
  String get backupFailed => 'Backup failed. Please try again.';
  @override
  String get restoreSuccess => 'Data restored successfully.';
  @override
  String get restoreFailed => 'Restore failed. Verify the backup file.';
  @override
  String get invalidBackupFile => 'Invalid backup file format.';
  @override
  String get corruptBackup => 'Backup file is corrupted.';

  @override
  String get settingsSaved => 'Settings saved.';
  @override
  String get reminderUpdated => 'Reminder time updated.';
  @override
  String toggledOn(String feature) => '$feature enabled.';
  @override
  String toggledOff(String feature) => '$feature disabled.';

  @override
  String get biometricFailed => 'Authentication failed.';
  @override
  String get incorrectPin => 'Incorrect PIN.';

  @override
  String get notificationAccessDenied =>
      'Notification access is required for auto-import.';
  @override
  String get smsImportEnabled => 'Auto-import enabled.';

  @override
  String get noTransactions =>
      pickRandom([
        'No transactions recorded.\nAdd your first entry.',
        'No records found.\nBegin by adding a transaction.',
        'Transaction history is empty.\nStart recording.',
      ]);
  @override
  String get noBudgets => 'No budgets configured.';
  @override
  String get noGoals => 'No goals set.';
  @override
  String get noBills => 'No recurring bills.';
  @override
  String get noAccounts => 'No accounts configured.';
  @override
  String get noCategories => 'No categories defined.';
  @override
  String get noNotifications => 'No notifications.';
  @override
  String noFilterResults(String filter) => 'No $filter notifications found.';
  @override
  String get noData => 'Insufficient data.\nContinue recording transactions.';
  @override
  String get noRecurring => 'No recurring transactions configured.';

  @override
  String get exportSuccess => 'Report exported.';
  @override
  String exportFailed(String error) => 'Export failed: $error';

  @override
  String get purchaseFailed => 'Purchase failed. Please retry.';
  @override
  String get playNotAvailable => 'Google Play Services unavailable.';

  @override
  String errorWith(String detail) => 'Error: $detail';
  @override
  String get genericError => 'An error occurred.';

  @override
  String get deleteTitle => 'Confirm Deletion';
  @override
  String deleteMessage(String? param) =>
      'This ${param != null ? 'remove $param ' : ''}action is irreversible. Proceed?';
  @override
  String get deleteConfirm => 'Delete';
  @override
  String get deleteCancel => 'Cancel';
  @override
  String get logoutTitle => 'Confirm Logout';
  @override
  String get logoutMessage => 'All local data will be erased.';
  @override
  String get logoutConfirm => 'Logout';

  @override
  String get insightBillsDueSoon => 'Upcoming bills';
  @override
  String insightBillsDueMessage(int count) =>
      '$count bill${count > 1 ? "s" : ""} due within the next few days.';
  @override
  String get insightOverBudget => 'Budget exceeded';
  @override
  String insightOverBudgetMessage(int count) =>
      '$count budget${count > 1 ? "s" : ""} exceeded this month.';
  @override
  String get insightNearBudget => 'Approaching budget limit';
  @override
  String insightNearBudgetMessage(int count) =>
      '$count budget${count > 1 ? "s" : ""} above 80% utilization.';
  @override
  String get insightOverspending => 'Expenses exceed income';
  @override
  String insightOverspendingMessage(String amount) =>
      'Expenditure exceeds income by $amount this month.';
  @override
  String get insightSpendingSpike => 'Elevated spending today';
  @override
  String insightSpendingSpikeMessage(String avg, String today) =>
      'Daily average: $avg. Today: $today.';
  @override
  String get insightWeekendAlert => 'Weekend spending elevated';
  @override
  String insightWeekendAlertMessage(String avg, String current) =>
      'Weekend average: $avg. Current: $current.';
  @override
  String insightMoneyLeak(String category, int count, String total) =>
      '$category: $count transactions, $total total this month.';
  @override
  String insightBestDay(
    String worst,
    String wAvg,
    String best,
    String bAvg,
    String saving,
  ) =>
      '$wAvg avg on ${worst}s vs $bAvg on ${best}s. Potential saving: $saving.';
  @override
  String get insightGetStarted => 'Get started';
  @override
  String get insightGetStartedMessage =>
      'Record your first transaction to begin tracking.';

  @override
  String singleApproved(String amountStr) =>
      'Transaction$amountStr recorded automatically.';
  @override
  String allApproved(int count, String amountStr) =>
      '$count transaction${count > 1 ? 's' : ''}$amountStr processed automatically.';
  @override
  String mixedResults(int approved, int reviewCount) =>
      '$approved processed, $reviewCount require${reviewCount == 1 ? 's' : ''} review.';
  @override
  String allNeedReview(int reviewCount) =>
      '$reviewCount transaction${reviewCount > 1 ? 's' : ''} pending review.';

  @override
  String greetingMorning(String name) => 'Good morning, $name.';
  @override
  String greetingAfternoon(String name) => 'Good afternoon, $name.';
  @override
  String greetingEvening(String name) => 'Good evening, $name.';
  @override
  String get dashboardWelcomeBack => 'Welcome back. Here is your summary.';
  @override
  String get dashboardAllCaughtUp => pickRandom([
    'All items are up to date.',
    'No pending actions.',
    'Everything is current.',
  ]);
  @override
  String streakMessage(int days) => '$days consecutive days of tracking.';

  @override
  String budgetExceededNotif(String name, String spent, String limit) =>
      '$name exceeded: ₹$spent of ₹$limit allocated.';
  @override
  String budgetWarningNotif(String name, String remaining, String pct) =>
      '$name at $pct% utilization. ₹$remaining remaining.';
  @override
  String billDueNotif(String name, String amount, String when) =>
      '$name (₹$amount) due $when.';
  @override
  String balanceDropNotif(String days) =>
      'At current rate, funds may be insufficient in $days days.';
  @override
  String savingsOpportunityNotif(String category, String amount) =>
      '$category trending ₹$amount above last month.';
  @override
  String unusualSpendingNotif(String today, String multiplier) =>
      '₹$today recorded today — ${multiplier}x daily average.';
  @override
  String pendingSmsNotif(int count) =>
      '$count SMS transactions detected. Review required.';
  @override
  String moneyLeakNotif(String category, int count, String total) =>
      '$category: $count transactions totaling ₹$total this month.';
  @override
  String reEngageMissYou(int lostStreak) => lostStreak > 3
      ? '$lostStreak-day streak ended. Resume tracking to start a new one.'
      : 'Tracking has been inactive. Resume to maintain records.';
  @override
  String reEngageUntracked(int days, String estimatedSpend) =>
      '$days days untracked. Estimated unrecorded spending: ₹$estimatedSpend.';
  @override
  String get reEngageQuickNudge =>
      'Record today\'s transactions to maintain accurate records.';
  @override
  String dailySummaryNotif(String spent, String earned, String topCategory) =>
      'Expenditure: ₹$spent · Income: ₹$earned\nPrimary category: $topCategory';
  @override
  String get dailySummaryEmpty => pickRandom([
    'No transactions recorded yesterday.',
    'Yesterday had no recorded activity.',
    'No entries for the previous day.',
  ]);
  @override
  String weeklySummaryNotif(String total, String topCategory, String trend) =>
      'Weekly expenditure: ₹$total\nTop category: $topCategory\n$trend';
  @override
  String streakAtRisk(int streak) =>
      '$streak-day tracking streak at risk. Open the app to maintain it.';
  @override
  String streakLost(int streak) =>
      '$streak-day streak ended. Resume tracking to begin a new one.';
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 🎮 PLAYFUL — fun, gamified, lots of emojis
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class MotivationalTonePack extends TonePack {
  @override
  String get id => 'motivational';
  @override
  String get name => 'Motivational';
  @override
  String get description => 'Encouraging & uplifting';
  // emoji
  @override
  String get emoji => '💪'; // was '🎮'

// Transaction
  @override
  String get txnAdded => pickRandom([
    'Great move! Transaction saved! 💪',
    'Logged! You\'re on a roll 💪',
    'Another one tracked! Keep the momentum! ✨',
    'Saved! Every entry is a step forward! 🚀',
  ]);
  @override
  String get txnUpdated => pickRandom([
    'Nice update! Staying sharp! ✨',
    'Updated! Precision matters! ✨',
    'Changes saved! You\'re on it! 👍',
  ]);
  @override
  String get txnDeleted => pickRandom([
    'Cleared out! One less to worry about',
    'Removed! Keeping things clean! 💪',
    'Gone! Focus on what matters',
  ]);
  @override
  String get txnFailed => 'Didn\'t go through — give it another shot!';
  @override
  String get txnNotFound => 'Can\'t find that one — it may have been removed';

// Validation
  @override
  String get enterAmount => 'Every rupee counts — enter the amount!';
  @override
  String get pickAccount => 'Pick an account to keep things organized!';
  @override
  String get pickCategory => 'Categorize it — you\'ll thank yourself later!';
  @override
  String get fillAllFields => 'Almost there! Fill in everything to continue';
  @override
  String get invalidAmount => 'That amount doesn\'t look right — try again!';
  @override
  String get futureDate => 'Let\'s stay in the present — pick today or earlier';
  @override
  String get selectAccountAndCategory =>
      'Account & category first — you\'re almost done!';

// Trip & Split
  @override
  String tripCreated(bool isTrip) => isTrip
      ? 'Trip created! Great planning! ✈️'
      : 'Group ready! Smart move splitting costs! 🤝';
  @override
  String tripUpdated(bool isTrip) =>
      isTrip ? 'Trip updated! 👌' : 'Group updated! 👌';
  @override
  String tripDeleted(bool isTrip) => isTrip ? 'Trip removed' : 'Group removed';
  @override
  String tripFinalized(bool isTrip) => isTrip
      ? 'Trip wrapped up! Well done! 🎉'
      : 'All settled! Great teamwork! 🎉';
  @override
  String tripNameRequired(bool isTrip) =>
      isTrip ? 'Give your trip a name!' : 'Name your group!';
  @override
  String get addParticipant => 'Add at least one person to split with!';
  @override
  String tripLimitReached(bool isTrip) =>
      'Free plan allows 1 active ${isTrip ? 'trip' : 'group'}. Go Pro for unlimited! 🚀';
  @override
  String expenseAddedToTrip(bool isTrip) =>
      isTrip ? 'Expense added to trip! 💰' : 'Expense added to group! 💰';

// Budget
  @override
  String get budgetCreated => pickRandom([
    'Smart move! Budget is set! 💪',
    'Budget locked in! You\'re taking control! 💪',
    'That\'s discipline! Budget ready! 📊',
  ]);
  @override
  String get budgetUpdated => 'Budget adjusted — staying flexible!';
  @override
  String get budgetDeleted => 'Budget removed';

// Goal
  @override
  String get goalCreated => pickRandom([
    'Love the ambition! Goal set! 🎯',
    'Big dreams start here! Goal locked in! 🎯',
    'That\'s the spirit! New goal ready! 🚀',
  ]);
  @override
  String get goalUpdated => 'Goal refined — keep pushing!';
  @override
  String get goalDeleted => 'Goal removed — new priorities, new plans';

// Account
  @override
  String get accountCreated => 'Account added! You\'re getting organized! 🏦';
  @override
  String get accountUpdated => 'Account updated!';
  @override
  String get accountDeleted => 'Account removed';
  @override
  String get accountLocked => 'This account is locked — Go Pro to unlock! 🔒';

// Category
  @override
  String get categoryCreated => 'New category added!';
  @override
  String get categoryDeleted => 'Category removed';
  @override
  String get categoryNameRequired => 'Give it a name!';

// Bill
  @override
  String get billAdded => 'Bill tracked! You\'re staying ahead! 🔔';
  @override
  String get billPaid => pickRandom([
    'Bill paid! One less thing to worry about! ✅',
    'Crushed it! Bill is done! ✅',
    'Paid and done! You\'re ahead of the game! 💪',
  ]);
  @override
  String get billDeleted => 'Bill removed';

// Backup
  @override
  String get backupSuccess => 'Backed up! Your progress is safe! 🛡️';
  @override
  String get backupFailed => 'Backup didn\'t work — try again!';
  @override
  String get restoreSuccess => 'Restored! Right back on track! 🎉';
  @override
  String get restoreFailed => 'Restore failed — check the file and retry';
  @override
  String get invalidBackupFile => 'That doesn\'t look like a valid backup';
  @override
  String get corruptBackup => 'This backup seems damaged';

// Settings
  @override
  String get settingsSaved => 'Saved! ✓';
  @override
  String get reminderUpdated => 'Reminder set! ⏰';
  @override
  String toggledOn(String feature) => '$feature is on! ✓';
  @override
  String toggledOff(String feature) => '$feature turned off';

// Auth
  @override
  String get biometricFailed => 'Authentication failed — try again!';
  @override
  String get incorrectPin => 'Wrong PIN — you\'ve got this, try again!';

// SMS
  @override
  String get notificationAccessDenied =>
      'Need notification access to auto-track transactions';
  @override
  String get smsImportEnabled =>
      'Auto-import on! Your finances track themselves now! 📩';

// Empty States
  @override
  String get noTransactions =>
      pickRandom([
        'Fresh start! 🌟\nAdd your first transaction — every journey begins with one step',
        'Empty slate! 🌟\nYour first entry is waiting — let\'s go!',
        'Nothing yet! 💪\nOne transaction and you\'re on your way!',
      ]);
  @override
  String get noBudgets =>
      'No budgets yet\nSet one up — your future self will thank you! 💪';
  @override
  String get noGoals => 'No goals yet\nDream big — set your first goal! 🎯';
  @override
  String get noBills =>
      'No bills tracked\nStay ahead by adding your recurring bills';
  @override
  String get noAccounts =>
      'No accounts yet\nAdd one to start your financial journey!';
  @override
  String get noCategories => 'No categories yet';
  @override
  String get noNotifications =>
      'All clear!\nNo notifications — you\'re on top of things';
  @override
  String noFilterResults(String filter) => 'No $filter notifications';
  @override
  String get noData => 'Keep going! 📈\nMore data means better insights';
  @override
  String get noRecurring =>
      'No recurring transactions\nAutomate your bills to stay ahead!';

// Export
  @override
  String get exportSuccess => 'Report exported! 📄';
  @override
  String exportFailed(String error) => 'Export failed: $error';

// Pro
  @override
  String get purchaseFailed => 'Purchase didn\'t go through — try again!';
  @override
  String get playNotAvailable => 'Google Play isn\'t available on this device';

// Generic
  @override
  String errorWith(String detail) => 'Something went wrong: $detail';
  @override
  String get genericError => 'Something went wrong — try again!';

// Confirmations
  @override
  String get deleteTitle => 'Are you sure?';
  @override
  String deleteMessage(String? param) =>
      '${param != null ? '$param will be removed. ' : ''}This can\'t be undone.';
  @override
  String get deleteConfirm => 'Delete';
  @override
  String get deleteCancel => 'Keep it';
  @override
  String get logoutTitle => 'Heading out?';
  @override
  String get logoutMessage => 'All data on this device will be cleared.';
  @override
  String get logoutConfirm => 'Logout';

// Insights
  @override
  String get insightBillsDueSoon => 'Bills coming up! 📋';
  @override
  String insightBillsDueMessage(int count) =>
      '$count bill${count > 1 ? "s" : ""} due soon — stay ahead!';
  @override
  String get insightOverBudget => 'Over budget — time to regroup';
  @override
  String insightOverBudgetMessage(int count) =>
      '$count budget${count > 1 ? "s" : ""} exceeded — you can course-correct!';
  @override
  String get insightNearBudget => 'Almost at the limit';
  @override
  String insightNearBudgetMessage(int count) =>
      '$count budget${count > 1 ? "s" : ""} past 80% — you\'ve got this, stay mindful!';
  @override
  String get insightOverspending => 'Spending exceeding income';
  @override
  String insightOverspendingMessage(String amount) =>
      '₹$amount over income — small adjustments make a big difference!';
  @override
  String get insightSpendingSpike => 'Spending spike today';
  @override
  String insightSpendingSpikeMessage(String avg, String today) =>
      'Usually ₹$avg/day. Today\'s ₹$today — be intentional!';
  @override
  String get insightWeekendAlert => 'Weekend spending alert';
  @override
  String insightWeekendAlertMessage(String avg, String current) =>
      'Weekend avg: ₹$avg. This one\'s ₹$current — stay aware!';
  @override
  String insightMoneyLeak(String category, int count, String total) =>
      '$category: $count times, ₹$total — small wins add up if you cut back!';
  @override
  String insightBestDay(
          String worst, String wAvg, String best, String bAvg, String saving,) =>
      '₹$wAvg on ${worst}s vs ₹$bAvg on ${best}s — ₹$saving potential savings!';
  @override
  String get insightGetStarted => 'Let\'s build something great! 🚀';
  @override
  String get insightGetStartedMessage =>
      'Add your first transaction — you\'re one step away!';

// Smart Notifications
  @override
  String singleApproved(String amountStr) =>
      'Transaction$amountStr tracked! You\'re on it! 💪';
  @override
  String allApproved(int count, String amountStr) =>
      '$count transaction${count > 1 ? 's' : ''}$amountStr auto-tracked! Effortless! 😎';
  @override
  String mixedResults(int approved, int reviewCount) =>
      'Tracked $approved, but $reviewCount need${reviewCount == 1 ? 's' : ''} a quick look. Almost there! 👀';
  @override
  String allNeedReview(int reviewCount) =>
      '$reviewCount transaction${reviewCount > 1 ? 's' : ''} need${reviewCount == 1 ? 's' : ''} your review — let\'s sort ${reviewCount == 1 ? 'it' : 'them'} out!';

  @override
  String greetingMorning(String name) =>
      'Rise and shine, $name! Today\'s your day! ☀️';
  @override
  String greetingAfternoon(String name) =>
      'Crushing it, $name! Keep the momentum! 💪';
  @override
  String greetingEvening(String name) =>
      'Great day, $name! Let\'s see your wins! 🌟';
  @override
  String get dashboardWelcomeBack =>
      'You\'re back! Let\'s keep the progress going! 🚀';
  @override
  String get dashboardAllCaughtUp => pickRandom([
    'All caught up — you\'re ahead of the game! 🏆',
    'Nothing pending — you\'re on top of it 💪',
    'All clear! Keep this energy going 🏆',
  ]);
  @override
  String streakMessage(int days) => '$days day streak! Unstoppable! 🔥';

  @override
  String budgetExceededNotif(String name, String spent, String limit) =>
      '$name went over — ₹$spent of ₹$limit. You can course-correct! 💪';
  @override
  String budgetWarningNotif(String name, String remaining, String pct) =>
      '$name is at $pct% — ₹$remaining left. You\'ve got this!';
  @override
  String billDueNotif(String name, String amount, String when) =>
      '$name (₹$amount) due $when — stay ahead of it! 🔔';
  @override
  String balanceDropNotif(String days) =>
      'Funds could run tight in $days days — small adjustments now pay off big!';
  @override
  String savingsOpportunityNotif(String category, String amount) =>
      '$category is up ₹$amount — a little discipline here goes a long way! 💡';
  @override
  String unusualSpendingNotif(String today, String multiplier) =>
      '₹$today today — ${multiplier}x your average! Be intentional! 🎯';
  @override
  String pendingSmsNotif(int count) =>
      '$count transactions auto-detected — review them to stay on top! 📩';
  @override
  String moneyLeakNotif(String category, int count, String total) =>
      '$category: $count times, ₹$total — small wins add up if you cut back!';
  @override
  String reEngageMissYou(int lostStreak) => lostStreak > 3
      ? 'Your $lostStreak-day streak ended — but comebacks are the best stories! 🔥'
      : 'You\'ve been away — today\'s a great day to restart!';
  @override
  String reEngageUntracked(int days, String estimatedSpend) =>
      '$days days untracked, ~₹$estimatedSpend missed — let\'s catch up! 💪';
  @override
  String get reEngageQuickNudge =>
      'One quick entry keeps the momentum going — you\'ve got this!';
  @override
  String dailySummaryNotif(String spent, String earned, String topCategory) =>
      'Spent ₹$spent · Earned ₹$earned\n$topCategory led the way — keep tracking!';
  @override
  String get dailySummaryEmpty => pickRandom([
    'Zero spend yesterday — your wallet thanks you! ✨',
    'Nothing spent yesterday — that\'s willpower! 💪',
    'A no-spend day! That\'s a win! 🏆',
  ]);
  @override
  String weeklySummaryNotif(String total, String topCategory, String trend) =>
      '₹$total this week on $topCategory\n$trend — keep pushing!';
  @override
  String streakAtRisk(int streak) =>
      '$streak-day streak is on the line — don\'t let it slip! 🔥';
  @override
  String streakLost(int streak) =>
      'Your $streak-day streak ended — but comebacks are the best stories! 💪';
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 🧘 ZEN — calm, mindful, minimal
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class CalmTonePack extends TonePack {
  @override
  String get id => 'calm';
  @override
  String get name => 'Calm';
  @override
  String get description => 'Calm, mindful & minimal';
  @override
  String get emoji => '🧘';

  @override
  String get txnAdded => pickRandom([
    'Noted.',
    'Recorded.',
    'Saved quietly.',
  ]);
  @override
  String get txnUpdated => pickRandom([
    'Updated.',
    'Adjusted.',
    'Changes saved.',
  ]);
  @override
  String get txnDeleted => pickRandom([
    'Released.',
    'Removed.',
    'Let go.',
  ]);
  @override
  String get txnFailed => 'That didn\'t land. Try once more.';
  @override
  String get txnNotFound => 'Not found. It may have moved on.';

  @override
  String get enterAmount => 'An amount is needed.';
  @override
  String get pickAccount => 'Choose where this belongs.';
  @override
  String get pickCategory => 'Give it a purpose.';
  @override
  String get fillAllFields => 'A few things are still empty.';
  @override
  String get invalidAmount => 'The amount needs adjusting.';
  @override
  String get futureDate => 'Stay in the present.';
  @override
  String get selectAccountAndCategory => 'Account and category, please.';

  @override
  String tripCreated(bool isTrip) =>
      isTrip ? 'Journey begins.' : 'Group formed.';
  @override
  String tripUpdated(bool isTrip) => 'Adjusted.';
  @override
  String tripDeleted(bool isTrip) => 'Let go.';
  @override
  String tripFinalized(bool isTrip) =>
      isTrip ? 'Journey complete.' : 'Settled.';
  @override
  String tripNameRequired(bool isTrip) => 'It needs a name.';
  @override
  String get addParticipant => 'Add someone to share with.';
  @override
  String tripLimitReached(bool isTrip) =>
      'One at a time on the free path. Pro opens more.';
  @override
  String expenseAddedToTrip(bool isTrip) => 'Added.';

  @override
  String get budgetCreated => pickRandom([
    'Boundary set.',
    'Budget in place.',
    'Limits defined.',
  ]);
  @override
  String get budgetUpdated => 'Adjusted.';
  @override
  String get budgetDeleted => 'Released.';

  @override
  String get goalCreated => pickRandom([
    'Intention set.',
    'A new direction.',
    'Goal planted.',
  ]);
  @override
  String get goalUpdated => 'Refined.';
  @override
  String get goalDeleted => 'Released.';

  @override
  String get accountCreated => 'Account opened.';
  @override
  String get accountUpdated => 'Adjusted.';
  @override
  String get accountDeleted => 'Closed.';
  @override
  String get accountLocked => 'This one is resting. Pro unlocks it.';

  @override
  String get categoryCreated => 'Added.';
  @override
  String get categoryDeleted => 'Removed.';
  @override
  String get categoryNameRequired => 'A name, please.';

  @override
  String get billAdded => 'Noted. You\'ll be reminded.';
  @override
  String get billPaid => pickRandom([
    'Settled.',
    'Paid. One less.',
    'Done. Peace of mind.',
  ]);
  @override
  String get billDeleted => 'Released.';

  @override
  String get backupSuccess => 'Safely stored.';
  @override
  String get backupFailed => 'Couldn\'t save. Try again gently.';
  @override
  String get restoreSuccess => 'Restored. Welcome back.';
  @override
  String get restoreFailed => 'Couldn\'t restore. Check the file.';
  @override
  String get invalidBackupFile => 'This file doesn\'t feel right.';
  @override
  String get corruptBackup => 'The file seems damaged.';

  @override
  String get settingsSaved => 'Saved.';
  @override
  String get reminderUpdated => 'Reminder adjusted.';
  @override
  String toggledOn(String feature) => '$feature — on.';
  @override
  String toggledOff(String feature) => '$feature — off.';

  @override
  String get biometricFailed => 'Not recognized. Try again.';
  @override
  String get incorrectPin => 'Not quite. Try again.';

  @override
  String get notificationAccessDenied =>
      'Permission needed for quiet tracking.';
  @override
  String get smsImportEnabled => 'Quietly watching your transactions.';

  @override
  String get noTransactions => pickRandom([
    'A clean slate.\nBegin when you\'re ready.',
    'Nothing here yet.\nStart gently.',
    'Empty.\nA fresh beginning awaits.',
  ]);
  @override
  String get noBudgets => 'No boundaries yet.\nSet one when it feels right.';
  @override
  String get noGoals => 'No intentions yet.\nSet one when you\'re ready.';
  @override
  String get noBills => 'Nothing recurring.\nPeaceful.';
  @override
  String get noAccounts => 'No accounts yet.\nStart simply.';
  @override
  String get noCategories => 'No categories yet.';
  @override
  String get noNotifications => 'Silence.\nNothing needs attention.';
  @override
  String noFilterResults(String filter) => 'Nothing in $filter.';
  @override
  String get noData => 'Not enough yet.\nIt will come with time.';
  @override
  String get noRecurring => 'Nothing recurring.\nAdd when ready.';

  @override
  String get exportSuccess => 'Exported.';
  @override
  String exportFailed(String error) => 'Export issue: $error';

  @override
  String get purchaseFailed => 'Purchase didn\'t complete. Try again.';
  @override
  String get playNotAvailable => 'Play Store not available here.';

  @override
  String errorWith(String detail) => 'A hiccup: $detail';
  @override
  String get genericError => 'Something shifted. Try again.';

  @override
  String get deleteTitle => 'Let go?';
  @override
  String deleteMessage(String? param) =>
      'Once ${param != null ? '$param ' : ''}released, it cannot return.';
  @override
  String get deleteConfirm => 'Release';
  @override
  String get deleteCancel => 'Hold on';
  @override
  String get logoutTitle => 'Moving on?';
  @override
  String get logoutMessage => 'Your data here will be cleared.';
  @override
  String get logoutConfirm => 'Leave';

  @override
  String get insightBillsDueSoon => 'Bills approaching';
  @override
  String insightBillsDueMessage(int count) =>
      '$count bill${count > 1 ? "s" : ""} arriving soon.';
  @override
  String get insightOverBudget => 'Over the line';
  @override
  String insightOverBudgetMessage(int count) =>
      '$count budget${count > 1 ? "s" : ""} exceeded. Reflect and adjust.';
  @override
  String get insightNearBudget => 'Nearing the edge';
  @override
  String insightNearBudgetMessage(int count) =>
      '$count budget${count > 1 ? "s" : ""} past 80%. Mindful spending helps.';
  @override
  String get insightOverspending => 'Outflow exceeds inflow';
  @override
  String insightOverspendingMessage(String amount) =>
      '$amount more spent than earned. A moment to pause.';
  @override
  String get insightSpendingSpike => 'A heavier day';
  @override
  String insightSpendingSpikeMessage(String avg, String today) =>
      'Usually $avg/day. Today, $today.';
  @override
  String get insightWeekendAlert => 'Weekend spending';
  @override
  String insightWeekendAlertMessage(String avg, String current) =>
      'Usually $avg. This weekend, $current.';
  @override
  String insightMoneyLeak(String category, int count, String total) =>
      '$category: $count times, $total. Small streams form rivers.';
  @override
  String insightBestDay(
    String worst,
    String wAvg,
    String best,
    String bAvg,
    String saving,
  ) =>
      '${worst}s: $wAvg. ${best}s: $bAvg. $saving to keep.';
  @override
  String get insightGetStarted => 'A fresh start';
  @override
  String get insightGetStartedMessage => 'Begin with your first transaction.';

  @override
  String singleApproved(String amountStr) =>
      'Transaction$amountStr — quietly tracked.';
  @override
  String allApproved(int count, String amountStr) =>
      '$count transaction${count > 1 ? 's' : ''}$amountStr — all handled in the background.';
  @override
  String mixedResults(int approved, int reviewCount) =>
      '$approved tracked. $reviewCount await${reviewCount == 1 ? 's' : ''} your attention.';
  @override
  String allNeedReview(int reviewCount) =>
      '$reviewCount await${reviewCount == 1 ? 's' : ''} your review.';

  @override
  String greetingMorning(String name) => 'Good morning, $name.';
  @override
  String greetingAfternoon(String name) => 'Afternoon, $name.';
  @override
  String greetingEvening(String name) => 'Evening, $name. Rest well.';
  @override
  String get dashboardWelcomeBack => 'Welcome back.';
  @override
  String get dashboardAllCaughtUp => pickRandom([
    'Everything is in order.',
    'Nothing needs attention.',
    'All is well.',
  ]);
  @override
  String streakMessage(int days) => '$days days of mindful tracking.';

  @override
  String budgetExceededNotif(String name, String spent, String limit) =>
      '$name has passed its limit. ₹$spent of ₹$limit.';
  @override
  String budgetWarningNotif(String name, String remaining, String pct) =>
      '$name is at $pct%. ₹$remaining remains.';
  @override
  String billDueNotif(String name, String amount, String when) =>
      '$name — ₹$amount, due $when.';
  @override
  String balanceDropNotif(String days) =>
      'At this pace, about $days days of runway remain.';
  @override
  String savingsOpportunityNotif(String category, String amount) =>
      '$category is ₹$amount above last month. A moment to reflect.';
  @override
  String unusualSpendingNotif(String today, String multiplier) =>
      '₹$today today. ${multiplier}x the usual rhythm.';
  @override
  String pendingSmsNotif(int count) => '$count transactions await your review.';
  @override
  String moneyLeakNotif(String category, int count, String total) =>
      '$category: $count times, ₹$total. Small streams form rivers.';
  @override
  String reEngageMissYou(int lostStreak) => lostStreak > 3
      ? 'A $lostStreak-day rhythm ended. Begin again when ready.'
      : 'It\'s been quiet. Return when you\'re ready.';
  @override
  String reEngageUntracked(int days, String estimatedSpend) =>
      '$days days untracked. Perhaps ~₹$estimatedSpend. No rush.';
  @override
  String get reEngageQuickNudge => 'A small note today keeps things clear.';
  @override
  String dailySummaryNotif(String spent, String earned, String topCategory) =>
      '₹$spent spent · ₹$earned earned\nMostly $topCategory.';
  @override
  String get dailySummaryEmpty => pickRandom([
    'A quiet day. Nothing recorded.',
    'Yesterday was still. No entries.',
    'Nothing spent. A restful day.',
  ]);
  @override
  String weeklySummaryNotif(String total, String topCategory, String trend) =>
      '₹$total this week. $topCategory led. $trend.';
  @override
  String streakAtRisk(int streak) =>
      'A $streak-day rhythm may end today. A moment to return.';
  @override
  String streakLost(int streak) =>
      'A $streak-day rhythm ended. Begin again when ready.';
}
