import 'package:mudra_manager/core/currency/currency_service.dart';
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
  String budgetExceededBy(String amount) =>
      'You\'ve exceeded your budget by $amount 😬';
  @override
  String budgetSlowDown(String amount, int days) =>
      'Slow down — only $amount left for $days days';
  @override
  String budgetSafePerDay(String amount) =>
      'You can spend $amount/day safely 👍';
  @override
  String get budgetExceededAdjust =>
      'You\'ve exceeded this budget. Maybe ease up a bit?';
  @override
  String budgetOnTrack(String amount) =>
      'On track! $amount/day keeps you within budget';
  @override
  String get budgetGreatDiscipline =>
      'Great discipline! You\'re well within your budget ✨';
  @override
  String budgetAlreadySpent(String amount) =>
      'You\'ve already spent $amount — this won\'t fit';
  @override
  String budgetMayExceedIn(int days) =>
      'At current pace, you may exceed in $days days';
  @override
  String budgetGettingTight(String amount, int days) =>
      'Getting tight — $amount left for $days days';
  @override
  String budgetInControl(String amount) =>
      'You\'re in control — about $amount/day works 👌';

  // ── Monthly Comparison ──
  @override
  String comparisonSpentLess(String amount) =>
      'Nice! You spent $amount less than last month 🎉';
  @override
  String comparisonSpentMore(String amount) =>
      'You spent $amount more than last month — worth a look';
  @override
  String get comparisonSpentSame =>
      'Spending is about the same as last month — steady!';
  @override
  String comparisonTopIncrease(String category, String amount) =>
      '$category went up the most (+$amount)';
  @override
  String comparisonTopDecrease(String category, String amount) =>
      'You cut back on $category the most (-$amount) 👍';
  @override
  String comparisonPrediction(String amount) =>
      'At this pace, you\'ll spend about $amount this month';
  @override
  String comparisonTxnCount(int current, int last) =>
      '${current > last ? '${current - last} more' : '${last - current} fewer'} transactions than last month';
  @override
  String comparisonDailyAvg(String current, String last) =>
      'Daily average: $current vs $last last month';
  @override
  String comparisonByThisDay(String amount) =>
      'By this day last month, you\'d spent $amount';

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
  String goalMilestone25(String goalName) => 'Good start on $goalName! 🌱';
  @override
  String goalMilestone50(String goalName) => 'Halfway there on $goalName! 🚀';
  @override
  String goalMilestone75(String goalName) => 'Almost done with $goalName! 🔥';
  @override
  String goalMilestone100(String goalName) => '🎉 $goalName is complete! You did it!';
  @override
  String goalOnTrack(String goalName) => 'You\'re on track — keep going! 👍';
  @override
  String goalBehind(String goalName) => 'A little behind — you can catch up!';
  @override
  String goalAhead(String goalName, String days) => 'You\'re ahead by $days days 🎉';
  @override
  String goalDailyNeeded(String amount) => 'Save $amount/day to reach on time';
  @override
  String goalPredictedDate(String date) => 'At this pace, you\'ll reach by $date';
  @override
  String goalContributionThisMonth(String amount) => '+$amount added this month';
  @override
  String goalNoDeadline(String goalName) => 'No rush — save at your own pace ✨';

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

  // ── Currency ──
  @override
  String get currencyChanged => 'Base currency updated! 💱';
  @override
  String currencyArchivedCount(int count, String newCurrency) =>
      'Switched to $newCurrency. $count transactions archived.';
  @override
  String get currencyChangeTitle => 'Change base currency?';
  @override
  String get currencyChangeWarning =>
      'All existing transactions will be archived. You start fresh with the new currency.';
  @override
  String get currencyChangeConfirm => 'Archive & Change';
  @override
  String get currencyChangeCancel => 'Keep it';
  @override
  String get currencyPickerTitle => 'Choose Your Currency';
  @override
  String get currencyPickerSubtitle =>
      'All your totals and budgets will be shown in this currency.';
  @override
  String get currencyChangeIrreversible => 'This action cannot be undone.';
  @override
  String get archivedTransactionsTitle => 'Archived Transactions';
  @override
  String get noArchivedTransactions => 'No archived transactions yet\nThey\'ll show up here if you change your base currency';
  @override
  String noTripExpenses(bool isTrip) => isTrip
      ? 'No expenses yet\nAdd your first trip expense to get started'
      : 'No expenses yet\nAdd a split expense to start tracking';

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
      'You\'re ${BaseCurrency.symbol}$amount over your income this month — might want to slow down';
  @override
  String get insightSpendingSpike => 'Spending spike today';
  @override
  String insightSpendingSpikeMessage(String avg, String today) =>
      'You usually spend ${BaseCurrency.symbol}$avg/day. Today\'s already ${BaseCurrency.symbol}$today.';
  @override
  String get insightWeekendAlert => 'Weekend spending alert';
  @override
  String insightWeekendAlertMessage(String avg, String current) =>
      'You usually spend ${BaseCurrency.symbol}$avg on weekends. This one\'s already ${BaseCurrency.symbol}$current.';
  @override
  String insightMoneyLeak(String category, int count, String total) =>
      '$category: $count times this month, ${BaseCurrency.symbol}$total total — small hits add up';
  @override
  String insightBestDay(
    String worst,
    String wAvg,
    String best,
    String bAvg,
    String saving,
  ) =>
      '${BaseCurrency.symbol}$wAvg avg on ${worst}s vs ${BaseCurrency.symbol}$bAvg on ${best}s — that\'s ${BaseCurrency.symbol}$saving you could keep';
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
      '$name is over budget — ${BaseCurrency.symbol}$spent of ${BaseCurrency.symbol}$limit spent. Might want to ease up';
  @override
  String budgetWarningNotif(String name, String remaining, String pct) =>
      '$name is at $pct% — only ${BaseCurrency.symbol}$remaining left to play with';
  @override
  String billDueNotif(String name, String amount, String when) =>
      '$name (${BaseCurrency.symbol}$amount) is due $when — just a heads up!';
  @override
  String billPaidNotif(String name, String amount) =>
      '${BaseCurrency.symbol}$amount for $name — sorted! ✅';
  @override
  String balanceDropNotif(String days) =>
      'At this pace, things could get tight in about $days days';
  @override
  String savingsOpportunityNotif(String category, String amount) =>
      '$category is trending ${BaseCurrency.symbol}$amount higher than last month — small cuts add up!';
  @override
  String unusualSpendingNotif(String today, String multiplier) =>
      '${BaseCurrency.symbol}$today spent today — that\'s ${multiplier}x your usual. Big day?';
  @override
  String pendingSmsNotif(int count) =>
      'Picked up $count from your messages — quick review?';
  @override
  String moneyLeakNotif(String category, int count, String total) =>
      '$category: $count transactions, ${BaseCurrency.symbol}$total this month — worth a look';
  @override
  String reEngageMissYou(int lostStreak) => lostStreak > 3
      ? 'Your $lostStreak-day streak is gone — but a new one starts with one tap'
      : 'It\'s been a while — just open the app to get back on track';
  @override
  String reEngageUntracked(int days, String estimatedSpend) =>
      'You probably spent around ${BaseCurrency.symbol}$estimatedSpend since you last checked — quick catch-up?';
  @override
  String get reEngageQuickNudge =>
      'Track today\'s spending before it slips — just one tap';
  @override
  String dailySummaryNotif(String spent, String earned, String topCategory) =>
      'Spent ${BaseCurrency.symbol}$spent · Earned ${BaseCurrency.symbol}$earned\nMost went to $topCategory';
  @override
  String get dailySummaryEmpty => pickRandom([
    'Nothing recorded yesterday — either a zero-spend win or time to catch up!',
    'Quiet day yesterday — your wallet thanks you!',
    'No transactions yesterday — fresh start today!',
  ]);
  @override
  String weeklySummaryNotif(String total, String topCategory, String trend) =>
      'You spent ${BaseCurrency.symbol}$total\nMost on $topCategory\n$trend';
  @override
  String streakAtRisk(int streak) =>
      '$streak-day streak on the line — just open the app to keep it alive!';
  @override
  String streakLost(int streak) =>
      'Your $streak-day streak ended — it happens! One tap starts a new one';

  // ── Growth: Morning Insight ──
  @override
  String morningInsightSpent(String amount, String avg) =>
      'You spent ${BaseCurrency.symbol}$amount yesterday — your daily avg is ${BaseCurrency.symbol}$avg';
  @override
  String morningInsightUnderAvg(String amount, String saved) =>
      'Only ${BaseCurrency.symbol}$amount yesterday — ${BaseCurrency.symbol}$saved under your average! 🎉';
  @override
  String get morningInsightZeroSpend =>
      'Zero spend yesterday — your wallet thanks you! 💪';
  @override
  String morningInsightTopCategory(String category, String amount) =>
      'Most went to $category (${BaseCurrency.symbol}$amount)';

  // ── Growth: Under-Budget Streak ──
  @override
  String underBudgetStreakNotif(int days) =>
      '🔥 $days days under budget — you\'re crushing it!';
  @override
  String underBudgetStreakBroken(String budget) =>
      '$budget went over today — tomorrow\'s a fresh start!';

  // ── Growth: Weekly Recap Nudge ──
  @override
  String weeklyRecapNudge(String hookStat) =>
      '$hookStat — tap to see your full weekly recap 📊';

  // ── Growth: Content-Rich Re-engagement ──
  @override
  String reEngageDay2Sms(int count) =>
      '📩 $count SMS transactions waiting — takes 5 seconds to review';
  @override
  String reEngageDay3Budgets(int count) =>
      '💰 You have $count active budget${count > 1 ? 's' : ''} — check how they\'re doing';
  @override
  String reEngageDay7Spend(String amount) =>
      'You spent $amount this week. See the full breakdown.';
  @override
  String weeklyRecapHookStat(String pct, String category) =>
      '$pct% of your spending went to $category';

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
  String budgetExceededBy(String amount) =>
      'Budget exceeded by $amount.';
  @override
  String budgetSlowDown(String amount, int days) =>
      '$amount remaining for $days days. Consider reducing expenditure.';
  @override
  String budgetSafePerDay(String amount) =>
      'Safe daily spend: $amount.';
  @override
  String get budgetExceededAdjust =>
      'Budget exceeded. Review spending or adjust the limit.';
  @override
  String budgetOnTrack(String amount) =>
      'On track. $amount/day within budget.';
  @override
  String get budgetGreatDiscipline =>
      'Well within budget. Good financial discipline.';
  @override
  String budgetAlreadySpent(String amount) =>
      'Current spending ($amount) exceeds this budget amount.';
  @override
  String budgetMayExceedIn(int days) =>
      'At current rate, budget may be exceeded in $days days.';
  @override
  String budgetGettingTight(String amount, int days) =>
      '$amount remaining for $days days. Budget is tight.';
  @override
  String budgetInControl(String amount) =>
      'Sustainable pace at $amount/day.';

  // ── Monthly Comparison ──
  @override
  String comparisonSpentLess(String amount) =>
      'Spending decreased by $amount compared to last month.';
  @override
  String comparisonSpentMore(String amount) =>
      'Spending increased by $amount compared to last month.';
  @override
  String get comparisonSpentSame =>
      'Spending is consistent with last month.';
  @override
  String comparisonTopIncrease(String category, String amount) =>
      '$category: highest increase (+$amount).';
  @override
  String comparisonTopDecrease(String category, String amount) =>
      '$category: largest reduction (-$amount).';
  @override
  String comparisonPrediction(String amount) =>
      'Projected month-end expenditure: $amount.';
  @override
  String comparisonTxnCount(int current, int last) =>
      '${current > last ? '${current - last} additional' : '${last - current} fewer'} transactions versus last month.';
  @override
  String comparisonDailyAvg(String current, String last) =>
      'Daily average: $current (previous: $last).';
  @override
  String comparisonByThisDay(String amount) =>
      'Expenditure by this date last month: $amount.';

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
  String goalMilestone25(String goalName) => '$goalName: 25% milestone reached.';
  @override
  String goalMilestone50(String goalName) => '$goalName: 50% complete.';
  @override
  String goalMilestone75(String goalName) => '$goalName: 75% complete.';
  @override
  String goalMilestone100(String goalName) => '$goalName: Goal achieved.';
  @override
  String goalOnTrack(String goalName) => 'On track to meet your goal.';
  @override
  String goalBehind(String goalName) => 'Slightly behind schedule. Consider increasing contributions.';
  @override
  String goalAhead(String goalName, String days) => 'Ahead of schedule by $days days.';
  @override
  String goalDailyNeeded(String amount) => 'Required daily savings: $amount.';
  @override
  String goalPredictedDate(String date) => 'Projected completion: $date.';
  @override
  String goalContributionThisMonth(String amount) => '+$amount contributed this month.';
  @override
  String goalNoDeadline(String goalName) => 'No target date set. Save at your discretion.';

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

  // ── Currency ──
  @override
  String get currencyChanged => 'Base currency updated.';
  @override
  String currencyArchivedCount(int count, String newCurrency) =>
      'Switched to $newCurrency. $count transactions archived.';
  @override
  String get currencyChangeTitle => 'Change Base Currency';
  @override
  String get currencyChangeWarning =>
      'All existing transactions will be archived. Transaction history will be reset.';
  @override
  String get currencyChangeConfirm => 'Archive & Change';
  @override
  String get currencyChangeCancel => 'Cancel';
  @override
  String get currencyPickerTitle => 'Select Currency';
  @override
  String get currencyPickerSubtitle =>
      'All totals, budgets, and analytics will use this currency.';
  @override
  String get currencyChangeIrreversible => 'This action is irreversible.';
  @override
  String get archivedTransactionsTitle => 'Archived Transactions';
  @override
  String get noArchivedTransactions => 'No archived transactions.\nTransactions are archived upon base currency change.';
  @override
  String noTripExpenses(bool isTrip) => isTrip
      ? 'No expenses recorded.\nAdd trip expenses to begin tracking.'
      : 'No expenses recorded.\nAdd split expenses to begin.';

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
      '$name exceeded: ${BaseCurrency.symbol}$spent of ${BaseCurrency.symbol}$limit allocated.';
  @override
  String budgetWarningNotif(String name, String remaining, String pct) =>
      '$name at $pct% utilization. ${BaseCurrency.symbol}$remaining remaining.';
  @override
  String billDueNotif(String name, String amount, String when) =>
      '$name (${BaseCurrency.symbol}$amount) due $when.';
  @override
  String billPaidNotif(String name, String amount) =>
      '${BaseCurrency.symbol}$amount for $name recorded.';
  @override
  String balanceDropNotif(String days) =>
      'At current rate, funds may be insufficient in $days days.';
  @override
  String savingsOpportunityNotif(String category, String amount) =>
      '$category trending ${BaseCurrency.symbol}$amount above last month.';
  @override
  String unusualSpendingNotif(String today, String multiplier) =>
      '${BaseCurrency.symbol}$today recorded today — ${multiplier}x daily average.';
  @override
  String pendingSmsNotif(int count) =>
      '$count SMS transactions detected. Review required.';
  @override
  String moneyLeakNotif(String category, int count, String total) =>
      '$category: $count transactions totaling ${BaseCurrency.symbol}$total this month.';
  @override
  String reEngageMissYou(int lostStreak) => lostStreak > 3
      ? '$lostStreak-day streak ended. Resume tracking to start a new one.'
      : 'Tracking has been inactive. Resume to maintain records.';
  @override
  String reEngageUntracked(int days, String estimatedSpend) =>
      '$days days untracked. Estimated unrecorded spending: ${BaseCurrency.symbol}$estimatedSpend.';
  @override
  String get reEngageQuickNudge =>
      'Record today\'s transactions to maintain accurate records.';
  @override
  String dailySummaryNotif(String spent, String earned, String topCategory) =>
      'Expenditure: ${BaseCurrency.symbol}$spent · Income: ${BaseCurrency.symbol}$earned\nPrimary category: $topCategory';
  @override
  String get dailySummaryEmpty => pickRandom([
    'No transactions recorded yesterday.',
    'Yesterday had no recorded activity.',
    'No entries for the previous day.',
  ]);
  @override
  String weeklySummaryNotif(String total, String topCategory, String trend) =>
      'Weekly expenditure: ${BaseCurrency.symbol}$total\nTop category: $topCategory\n$trend';
  @override
  String streakAtRisk(int streak) =>
      '$streak-day tracking streak at risk. Open the app to maintain it.';
  @override
  String streakLost(int streak) =>
      '$streak-day streak ended. Resume tracking to begin a new one.';

  // ── Growth: Morning Insight ──
  @override
  String morningInsightSpent(String amount, String avg) =>
      'Yesterday: ${BaseCurrency.symbol}$amount spent. Daily average: ${BaseCurrency.symbol}$avg.';
  @override
  String morningInsightUnderAvg(String amount, String saved) =>
      '${BaseCurrency.symbol}$amount spent yesterday — ${BaseCurrency.symbol}$saved below average.';
  @override
  String get morningInsightZeroSpend =>
      'No expenditure recorded yesterday.';
  @override
  String morningInsightTopCategory(String category, String amount) =>
      'Primary category: $category (${BaseCurrency.symbol}$amount).';

  // ── Growth: Under-Budget Streak ──
  @override
  String underBudgetStreakNotif(int days) =>
      '$days consecutive days within budget.';
  @override
  String underBudgetStreakBroken(String budget) =>
      '$budget exceeded today. Review spending.';

  // ── Growth: Weekly Recap Nudge ──
  @override
  String weeklyRecapNudge(String hookStat) =>
      '$hookStat — view your weekly summary.';

  // ── Growth: Content-Rich Re-engagement ──
  @override
  String reEngageDay2Sms(int count) =>
      '$count SMS transactions detected. Review required.';
  @override
  String reEngageDay3Budgets(int count) =>
      '$count active budget${count > 1 ? 's' : ''} require attention.';
  @override
  String reEngageDay7Spend(String amount) =>
      'Weekly expenditure: $amount. View full summary.';
  @override
  String weeklyRecapHookStat(String pct, String category) =>
      '$pct% of expenditure allocated to $category.';
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

  @override
  String budgetExceededBy(String amount) =>
      'Over by $amount — you can course-correct! 💪';
  @override
  String budgetSlowDown(String amount, int days) =>
      'Only $amount left for $days days — stay focused!';
  @override
  String budgetSafePerDay(String amount) =>
      '$amount/day keeps you on track — you\'ve got this! 💪';
  @override
  String get budgetExceededAdjust =>
      'Over budget — but every day is a chance to reset! 💪';
  @override
  String budgetOnTrack(String amount) =>
      'Crushing it! $amount/day keeps you in the zone!';
  @override
  String get budgetGreatDiscipline =>
      'Amazing discipline! You\'re way ahead! 🏆';
  @override
  String budgetAlreadySpent(String amount) =>
      'Already spent $amount — this budget won\'t cover it';
  @override
  String budgetMayExceedIn(int days) =>
      'At this pace, you\'ll exceed in $days days — time to adjust!';
  @override
  String budgetGettingTight(String amount, int days) =>
      'Tight! $amount for $days days — stay sharp!';
  @override
  String budgetInControl(String amount) =>
      'In control! $amount/day is sustainable — keep it up! 🚀';

  // ── Monthly Comparison ──
  @override
  String comparisonSpentLess(String amount) =>
      'You saved $amount compared to last month — amazing discipline! 🎉';
  @override
  String comparisonSpentMore(String amount) =>
      '$amount more than last month — you can course-correct! 💪';
  @override
  String get comparisonSpentSame =>
      'Holding steady! Consistent spending shows control 💪';
  @override
  String comparisonTopIncrease(String category, String amount) =>
      '$category jumped the most (+$amount) — worth watching!';
  @override
  String comparisonTopDecrease(String category, String amount) =>
      'Great cut on $category (-$amount) — that\'s discipline! 💪';
  @override
  String comparisonPrediction(String amount) =>
      'On track to spend $amount this month — stay focused!';
  @override
  String comparisonTxnCount(int current, int last) =>
      '${current > last ? '${current - last} more' : '${last - current} fewer'} transactions — ${current > last ? 'stay mindful!' : 'nice restraint!'}';
  @override
  String comparisonDailyAvg(String current, String last) =>
      '$current/day vs $last/day last month';
  @override
  String comparisonByThisDay(String amount) =>
      'By this day last month you\'d spent $amount — how do you compare?';

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

  @override
  String goalMilestone25(String goalName) => 'Great start on $goalName! The journey begins! 🌟';
  @override
  String goalMilestone50(String goalName) => 'Halfway there on $goalName! Unstoppable! 💪';
  @override
  String goalMilestone75(String goalName) => 'Almost there! $goalName is within reach! 🔥';
  @override
  String goalMilestone100(String goalName) => '🏆 $goalName COMPLETE! You\'re a champion!';
  @override
  String goalOnTrack(String goalName) => 'Crushing it! Right on track! 💪';
  @override
  String goalBehind(String goalName) => 'A little behind — but comebacks are your thing! 💪';
  @override
  String goalAhead(String goalName, String days) => 'Ahead by $days days! Unstoppable! 🚀';
  @override
  String goalDailyNeeded(String amount) => 'Save $amount/day — you\'ve got this! 💪';
  @override
  String goalPredictedDate(String date) => 'At this pace, you\'ll crush it by $date! 🎯';
  @override
  String goalContributionThisMonth(String amount) => '+$amount this month! Keep the momentum! 🔥';
  @override
  String goalNoDeadline(String goalName) => 'No deadline — every step counts! 🚀';

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
  // ── Currency ──
  @override
  String get currencyChanged => 'Currency switched! New chapter! 💱';
  @override
  String currencyArchivedCount(int count, String newCurrency) =>
      'Switched to $newCurrency! $count transactions archived — fresh start! 🚀';
  @override
  String get currencyChangeTitle => 'Ready to switch?';
  @override
  String get currencyChangeWarning =>
      'All existing transactions get archived. You start fresh — a clean slate!';
  @override
  String get currencyChangeConfirm => 'Let\'s do it!';
  @override
  String get currencyChangeCancel => 'Not yet';
  @override
  String get currencyPickerTitle => 'Pick Your Currency! 🌍';
  @override
  String get currencyPickerSubtitle =>
      'Everything — totals, budgets, goals — will show in this currency.';
  @override
  String get currencyChangeIrreversible => 'This can\'t be undone — but your archived data is safe!';
  @override
  String get archivedTransactionsTitle => 'Archived Transactions';
  @override
  String get noArchivedTransactions => 'Nothing archived yet! 📦\nIf you ever switch currencies, your old transactions land here safely';
  @override
  String noTripExpenses(bool isTrip) => isTrip
      ? 'No expenses yet! ✈️\nStart adding trip expenses — every rupee counts!'
      : 'No expenses yet! 🤝\nAdd your first split expense — let\'s go!';

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
      '${BaseCurrency.symbol}$amount over income — small adjustments make a big difference!';
  @override
  String get insightSpendingSpike => 'Spending spike today';
  @override
  String insightSpendingSpikeMessage(String avg, String today) =>
      'Usually ${BaseCurrency.symbol}$avg/day. Today\'s ${BaseCurrency.symbol}$today — be intentional!';
  @override
  String get insightWeekendAlert => 'Weekend spending alert';
  @override
  String insightWeekendAlertMessage(String avg, String current) =>
      'Weekend avg: ${BaseCurrency.symbol}$avg. This one\'s ${BaseCurrency.symbol}$current — stay aware!';
  @override
  String insightMoneyLeak(String category, int count, String total) =>
      '$category: $count times, ${BaseCurrency.symbol}$total — small wins add up if you cut back!';
  @override
  String insightBestDay(
          String worst, String wAvg, String best, String bAvg, String saving,) =>
      '${BaseCurrency.symbol}$wAvg on ${worst}s vs ${BaseCurrency.symbol}$bAvg on ${best}s — ${BaseCurrency.symbol}$saving potential savings!';
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
      '$name went over — ${BaseCurrency.symbol}$spent of ${BaseCurrency.symbol}$limit. You can course-correct! 💪';
  @override
  String budgetWarningNotif(String name, String remaining, String pct) =>
      '$name is at $pct% — ${BaseCurrency.symbol}$remaining left. You\'ve got this!';
  @override
  String billDueNotif(String name, String amount, String when) =>
      '$name (${BaseCurrency.symbol}$amount) due $when — stay ahead of it! 🔔';
  @override
  String billPaidNotif(String name, String amount) =>
      '${BaseCurrency.symbol}$amount for $name — done and dusted! 💪';
  @override
  String balanceDropNotif(String days) =>
      'Funds could run tight in $days days — small adjustments now pay off big!';
  @override
  String savingsOpportunityNotif(String category, String amount) =>
      '$category is up ${BaseCurrency.symbol}$amount — a little discipline here goes a long way! 💡';
  @override
  String unusualSpendingNotif(String today, String multiplier) =>
      '${BaseCurrency.symbol}$today today — ${multiplier}x your average! Be intentional! 🎯';
  @override
  String pendingSmsNotif(int count) =>
      '$count transactions auto-detected — review them to stay on top! 📩';
  @override
  String moneyLeakNotif(String category, int count, String total) =>
      '$category: $count times, ${BaseCurrency.symbol}$total — small wins add up if you cut back!';
  @override
  String reEngageMissYou(int lostStreak) => lostStreak > 3
      ? 'Your $lostStreak-day streak ended — but comebacks are the best stories! 🔥'
      : 'You\'ve been away — today\'s a great day to restart!';
  @override
  String reEngageUntracked(int days, String estimatedSpend) =>
      '$days days untracked, ~${BaseCurrency.symbol}$estimatedSpend missed — let\'s catch up! 💪';
  @override
  String get reEngageQuickNudge =>
      'One quick entry keeps the momentum going — you\'ve got this!';
  @override
  String dailySummaryNotif(String spent, String earned, String topCategory) =>
      'Spent ${BaseCurrency.symbol}$spent · Earned ${BaseCurrency.symbol}$earned\n$topCategory led the way — keep tracking!';
  @override
  String get dailySummaryEmpty => pickRandom([
    'Zero spend yesterday — your wallet thanks you! ✨',
    'Nothing spent yesterday — that\'s willpower! 💪',
    'A no-spend day! That\'s a win! 🏆',
  ]);
  @override
  String weeklySummaryNotif(String total, String topCategory, String trend) =>
      '${BaseCurrency.symbol}$total this week on $topCategory\n$trend — keep pushing!';
  @override
  String streakAtRisk(int streak) =>
      '$streak-day streak is on the line — don\'t let it slip! 🔥';
  @override
  String streakLost(int streak) =>
      'Your $streak-day streak ended — but comebacks are the best stories! 💪';

  // ── Growth: Morning Insight ──
  @override
  String morningInsightSpent(String amount, String avg) =>
      'You spent ${BaseCurrency.symbol}$amount yesterday — avg is ${BaseCurrency.symbol}$avg. Stay focused! 💪';
  @override
  String morningInsightUnderAvg(String amount, String saved) =>
      '${BaseCurrency.symbol}$amount yesterday — ${BaseCurrency.symbol}$saved saved vs your average! Amazing! 🎉';
  @override
  String get morningInsightZeroSpend =>
      'Zero spend yesterday — that\'s willpower! Champion move! 🏆';
  @override
  String morningInsightTopCategory(String category, String amount) =>
      '$category led at ${BaseCurrency.symbol}$amount — stay aware!';

  // ── Growth: Under-Budget Streak ──
  @override
  String underBudgetStreakNotif(int days) =>
      '🔥 $days days under budget — unstoppable! Keep pushing!';
  @override
  String underBudgetStreakBroken(String budget) =>
      '$budget went over — but every day is a chance to reset! 💪';

  // ── Growth: Weekly Recap Nudge ──
  @override
  String weeklyRecapNudge(String hookStat) =>
      '$hookStat — your weekly recap is ready! Let\'s review! 📊';

  // ── Growth: Content-Rich Re-engagement ──
  @override
  String reEngageDay2Sms(int count) =>
      '📩 $count SMS transactions waiting — takes 5 seconds! 💪';
  @override
  String reEngageDay3Budgets(int count) =>
      '💰 $count active budget${count > 1 ? 's' : ''} — see how you\'re doing! 💪';
  @override
  String reEngageDay7Spend(String amount) =>
      '$amount spent this week — let\'s see the breakdown! 📊';
  @override
  String weeklyRecapHookStat(String pct, String category) =>
      '$pct% of your spending went to $category — interesting!';
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
  String budgetExceededBy(String amount) =>
      'Over by $amount. A moment to reflect.';
  @override
  String budgetSlowDown(String amount, int days) =>
      '$amount left across $days days. Gently.';
  @override
  String budgetSafePerDay(String amount) =>
      '$amount/day feels right.';
  @override
  String get budgetExceededAdjust =>
      'Past the boundary. Pause and reconsider.';
  @override
  String budgetOnTrack(String amount) =>
      'Flowing well. $amount/day.';
  @override
  String get budgetGreatDiscipline =>
      'Well within bounds. Peaceful.';
  @override
  String budgetAlreadySpent(String amount) =>
      '$amount already spent. This won\'t hold.';
  @override
  String budgetMayExceedIn(int days) =>
      'At this rhythm, the boundary arrives in $days days.';
  @override
  String budgetGettingTight(String amount, int days) =>
      '$amount for $days days. Tread lightly.';
  @override
  String budgetInControl(String amount) =>
      'Balanced. $amount/day.';

  // ── Monthly Comparison ──
  @override
  String comparisonSpentLess(String amount) =>
      '$amount less than last month. A lighter path.';
  @override
  String comparisonSpentMore(String amount) =>
      '$amount more than last month. A moment to notice.';
  @override
  String get comparisonSpentSame =>
      'Spending flows at the same pace.';
  @override
  String comparisonTopIncrease(String category, String amount) =>
      '$category rose the most (+$amount).';
  @override
  String comparisonTopDecrease(String category, String amount) =>
      '$category eased the most (-$amount).';
  @override
  String comparisonPrediction(String amount) =>
      'This month may settle around $amount.';
  @override
  String comparisonTxnCount(int current, int last) =>
      '${current > last ? '${current - last} more' : '${last - current} fewer'} transactions than before.';
  @override
  String comparisonDailyAvg(String current, String last) =>
      '$current/day now. $last/day before.';
  @override
  String comparisonByThisDay(String amount) =>
      'By this day last month: $amount.';

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
  String goalMilestone25(String goalName) => 'A seed planted for $goalName.';
  @override
  String goalMilestone50(String goalName) => 'Halfway. Steady progress on $goalName.';
  @override
  String goalMilestone75(String goalName) => 'Nearly there. $goalName approaches.';
  @override
  String goalMilestone100(String goalName) => '$goalName. Complete. Breathe.';
  @override
  String goalOnTrack(String goalName) => 'Flowing at the right pace.';
  @override
  String goalBehind(String goalName) => 'Slightly behind. No rush.';
  @override
  String goalAhead(String goalName, String days) => '$days days ahead. Steady.';
  @override
  String goalDailyNeeded(String amount) => '$amount/day brings balance.';
  @override
  String goalPredictedDate(String date) => 'The path leads to $date.';
  @override
  String goalContributionThisMonth(String amount) => '+$amount this month. Quietly growing.';
  @override
  String goalNoDeadline(String goalName) => 'No timeline. Let it unfold.';

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

  // ── Currency ──
  @override
  String get currencyChanged => 'Currency shifted.';
  @override
  String currencyArchivedCount(int count, String newCurrency) =>
      'Now $newCurrency. $count transactions archived. A new beginning.';
  @override
  String get currencyChangeTitle => 'A new currency?';
  @override
  String get currencyChangeWarning =>
      'Existing transactions will be archived. A fresh page begins.';
  @override
  String get currencyChangeConfirm => 'Let go & change';
  @override
  String get currencyChangeCancel => 'Stay';
  @override
  String get currencyPickerTitle => 'Choose your currency';
  @override
  String get currencyPickerSubtitle =>
      'Your totals and budgets will reflect this choice.';
  @override
  String get currencyChangeIrreversible => 'Once changed, it cannot return.';
  @override
  String get archivedTransactionsTitle => 'Archived';
  @override
  String get noArchivedTransactions => 'Nothing here yet.\nPast transactions rest here after a currency change.';
  @override
  String noTripExpenses(bool isTrip) => isTrip
      ? 'Empty for now.\nAdd expenses when ready.'
      : 'Nothing yet.\nBegin when the moment comes.';

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
      '$name has passed its limit. ${BaseCurrency.symbol}$spent of ${BaseCurrency.symbol}$limit.';
  @override
  String budgetWarningNotif(String name, String remaining, String pct) =>
      '$name is at $pct%. ${BaseCurrency.symbol}$remaining remains.';
  @override
  String billDueNotif(String name, String amount, String when) =>
      '$name — ${BaseCurrency.symbol}$amount, due $when.';
  @override
  String billPaidNotif(String name, String amount) =>
      '$name — ${BaseCurrency.symbol}$amount, recorded.';
  @override
  String balanceDropNotif(String days) =>
      'At this pace, about $days days of runway remain.';
  @override
  String savingsOpportunityNotif(String category, String amount) =>
      '$category is ${BaseCurrency.symbol}$amount above last month. A moment to reflect.';
  @override
  String unusualSpendingNotif(String today, String multiplier) =>
      '${BaseCurrency.symbol}$today today. ${multiplier}x the usual rhythm.';
  @override
  String pendingSmsNotif(int count) => '$count transactions await your review.';
  @override
  String moneyLeakNotif(String category, int count, String total) =>
      '$category: $count times, ${BaseCurrency.symbol}$total. Small streams form rivers.';
  @override
  String reEngageMissYou(int lostStreak) => lostStreak > 3
      ? 'A $lostStreak-day rhythm ended. Begin again when ready.'
      : 'It\'s been quiet. Return when you\'re ready.';
  @override
  String reEngageUntracked(int days, String estimatedSpend) =>
      '$days days untracked. Perhaps ~${BaseCurrency.symbol}$estimatedSpend. No rush.';
  @override
  String get reEngageQuickNudge => 'A small note today keeps things clear.';
  @override
  String dailySummaryNotif(String spent, String earned, String topCategory) =>
      '${BaseCurrency.symbol}$spent spent · ${BaseCurrency.symbol}$earned earned\nMostly $topCategory.';
  @override
  String get dailySummaryEmpty => pickRandom([
    'A quiet day. Nothing recorded.',
    'Yesterday was still. No entries.',
    'Nothing spent. A restful day.',
  ]);
  @override
  String weeklySummaryNotif(String total, String topCategory, String trend) =>
      '${BaseCurrency.symbol}$total this week. $topCategory led. $trend.';
  @override
  String streakAtRisk(int streak) =>
      'A $streak-day rhythm may end today. A moment to return.';
  @override
  String streakLost(int streak) =>
      'A $streak-day rhythm ended. Begin again when ready.';

  // ── Growth: Morning Insight ──
  @override
  String morningInsightSpent(String amount, String avg) =>
      '${BaseCurrency.symbol}$amount yesterday. Your rhythm: ${BaseCurrency.symbol}$avg/day.';
  @override
  String morningInsightUnderAvg(String amount, String saved) =>
      '${BaseCurrency.symbol}$amount yesterday. ${BaseCurrency.symbol}$saved lighter than usual.';
  @override
  String get morningInsightZeroSpend =>
      'A still day. Nothing spent.';
  @override
  String morningInsightTopCategory(String category, String amount) =>
      'Mostly $category (${BaseCurrency.symbol}$amount).';

  // ── Growth: Under-Budget Streak ──
  @override
  String underBudgetStreakNotif(int days) =>
      '$days days within your boundaries. Steady.';
  @override
  String underBudgetStreakBroken(String budget) =>
      '$budget crossed its boundary. Breathe and begin again.';

  // ── Growth: Weekly Recap Nudge ──
  @override
  String weeklyRecapNudge(String hookStat) =>
      '$hookStat — your week awaits review.';

  // ── Growth: Content-Rich Re-engagement ──
  @override
  String reEngageDay2Sms(int count) =>
      '$count transactions await your attention.';
  @override
  String reEngageDay3Budgets(int count) =>
      '$count budget${count > 1 ? 's' : ''} in motion. A moment to check.';
  @override
  String reEngageDay7Spend(String amount) =>
      '$amount this week. Your recap awaits.';
  @override
  String weeklyRecapHookStat(String pct, String category) =>
      '$pct% flowed to $category.';

}
