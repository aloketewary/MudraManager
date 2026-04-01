import 'package:mudra_manager/core/tone/tone_pack.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 🤝 BUDDY — warm, casual, encouraging (default)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class BuddyTonePack extends TonePack {
  @override String get id => 'buddy';
  @override String get name => 'Buddy';
  @override String get description => 'Warm, casual & encouraging';
  @override String get emoji => '🤝';

  @override String get txnAdded => 'Done! Transaction saved ✨';
  @override String get txnUpdated => 'Updated! Looking good 👍';
  @override String get txnDeleted => 'Gone! Transaction removed 🗑️';
  @override String get txnFailed => 'Hmm, couldn\'t save that. Try again?';
  @override String get txnNotFound => 'Can\'t find that transaction 🤔';

  @override String get enterAmount => 'How much was it? Enter an amount';
  @override String get pickAccount => 'Which account? Pick one to continue';
  @override String get pickCategory => 'What was it for? Choose a category';
  @override String get fillAllFields => 'Almost there — fill in all the fields';
  @override String get invalidAmount => 'That doesn\'t look right — enter a valid amount';
  @override String get futureDate => 'Time travel? 😄 Pick today or earlier';
  @override String get selectAccountAndCategory => 'Pick an account & category first';

  @override String tripCreated(bool isTrip) => isTrip ? 'Trip created — let\'s go! ✈️' : 'Group ready — let\'s split! 🤝';
  @override String tripUpdated(bool isTrip) => isTrip ? 'Trip updated! 👌' : 'Group updated! 👌';
  @override String tripDeleted(bool isTrip) => isTrip ? 'Trip deleted' : 'Group deleted';
  @override String tripFinalized(bool isTrip) => isTrip ? 'Trip wrapped up! 🎉' : 'Group closed! 🎉';
  @override String tripNameRequired(bool isTrip) => isTrip ? 'Give your trip a name!' : 'Give your group a name!';
  @override String get addParticipant => 'Add at least one person to split with';
  @override String tripLimitReached(bool isTrip) => 'Free plan allows 1 active ${isTrip ? 'trip' : 'group'}. Go Pro for unlimited! 🚀';
  @override String expenseAddedToTrip(bool isTrip) => isTrip ? 'Expense added to trip! 💰' : 'Expense added to group! 💰';

  @override String get budgetCreated => 'Budget set! Let\'s stay on track 💪';
  @override String get budgetUpdated => 'Budget updated!';
  @override String get budgetDeleted => 'Budget removed';

  @override String get goalCreated => 'Goal set! You got this 🎯';
  @override String get goalUpdated => 'Goal updated!';
  @override String get goalDeleted => 'Goal removed';

  @override String get accountCreated => 'Account added! 🏦';
  @override String get accountUpdated => 'Account updated!';
  @override String get accountDeleted => 'Account removed';
  @override String get accountLocked => 'This account is locked — upgrade to Pro to use it 🔒';

  @override String get categoryCreated => 'Category added!';
  @override String get categoryDeleted => 'Category removed';
  @override String get categoryNameRequired => 'Give it a name!';

  @override String get billAdded => 'Bill tracked! I\'ll remind you 🔔';
  @override String get billPaid => 'Nice, bill marked as paid! ✅';
  @override String get billDeleted => 'Bill removed';

  @override String get backupSuccess => 'Backup done! Your data is safe 🛡️';
  @override String get backupFailed => 'Backup didn\'t work — try again?';
  @override String get restoreSuccess => 'Restored! Welcome back 🎉';
  @override String get restoreFailed => 'Restore failed — is the file okay?';
  @override String get invalidBackupFile => 'That doesn\'t look like a valid backup file';
  @override String get corruptBackup => 'This backup looks corrupted 😕';

  @override String get settingsSaved => 'Saved! ✓';
  @override String get reminderUpdated => 'Reminder updated ⏰';
  @override String toggledOn(String feature) => '$feature is on ✓';
  @override String toggledOff(String feature) => '$feature is off';

  @override String get biometricFailed => 'Authentication failed — try again';
  @override String get incorrectPin => 'Wrong PIN — give it another shot';

  @override String get notificationAccessDenied => 'Need notification access to auto-import transactions';
  @override String get smsImportEnabled => 'Auto import is on! I\'ll track your transactions 📩';

  @override String get noTransactions => 'Nothing here yet\nAdd your first transaction to get started';
  @override String get noBudgets => 'No budgets yet\nSet one up to track your spending';
  @override String get noGoals => 'No goals yet\nDream big — set your first goal!';
  @override String get noBills => 'No bills tracked\nAdd recurring bills so you never miss a payment';
  @override String get noAccounts => 'No accounts yet\nAdd one to start tracking';
  @override String get noCategories => 'No categories yet';
  @override String get noNotifications => 'All quiet here 🤫\nNo notifications yet';
  @override String noFilterResults(String filter) => 'No $filter notifications';

  @override String get exportSuccess => 'Report exported! 📄';
  @override String exportFailed(String error) => 'Export didn\'t work: $error';

  @override String get purchaseFailed => 'Purchase didn\'t go through — try again?';
  @override String get playNotAvailable => 'Google Play isn\'t available on this device';

  @override String errorWith(String detail) => 'Something went wrong: $detail';
  @override String get genericError => 'Oops, something went wrong 😅';

  @override String singleApproved(String amountStr) => 'Your transaction$amountStr has been tracked. I\'m on it! 💪';
  @override String allApproved(int count, String amountStr) => '$count transaction${count > 1 ? 's' : ''}$amountStr tracked while you were away. No worries, I handled it! 😎';
  @override String mixedResults(int approved, int reviewCount) => 'Tracked $approved transaction${approved > 1 ? 's' : ''}, but $reviewCount need${reviewCount == 1 ? 's' : ''} a quick look. Let\'s review together! 👀';
  @override String allNeedReview(int reviewCount) => '$reviewCount transaction${reviewCount > 1 ? 's' : ''} need${reviewCount == 1 ? 's' : ''} your review. Let\'s sort ${reviewCount == 1 ? 'it' : 'them'} out! 🤝';
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 📋 PROFESSIONAL — clean, formal, no emojis
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class ProfessionalTonePack extends TonePack {
  @override String get id => 'professional';
  @override String get name => 'Professional';
  @override String get description => 'Clean, formal & precise';
  @override String get emoji => '📋';

  @override String get txnAdded => 'Transaction recorded.';
  @override String get txnUpdated => 'Transaction updated.';
  @override String get txnDeleted => 'Transaction deleted.';
  @override String get txnFailed => 'Failed to save transaction. Please retry.';
  @override String get txnNotFound => 'Transaction not found.';

  @override String get enterAmount => 'Please enter a valid amount.';
  @override String get pickAccount => 'Please select an account.';
  @override String get pickCategory => 'Please select a category.';
  @override String get fillAllFields => 'All required fields must be completed.';
  @override String get invalidAmount => 'Invalid amount entered.';
  @override String get futureDate => 'Future dates are not permitted.';
  @override String get selectAccountAndCategory => 'Account and category are required.';

  @override String tripCreated(bool isTrip) => isTrip ? 'Trip created successfully.' : 'Split group created.';
  @override String tripUpdated(bool isTrip) => isTrip ? 'Trip updated.' : 'Group updated.';
  @override String tripDeleted(bool isTrip) => isTrip ? 'Trip deleted.' : 'Group deleted.';
  @override String tripFinalized(bool isTrip) => isTrip ? 'Trip finalized.' : 'Group closed.';
  @override String tripNameRequired(bool isTrip) => isTrip ? 'Trip name is required.' : 'Group name is required.';
  @override String get addParticipant => 'At least one participant is required.';
  @override String tripLimitReached(bool isTrip) => 'Free plan limit: 1 active ${isTrip ? 'trip' : 'group'}. Upgrade for more.';
  @override String expenseAddedToTrip(bool isTrip) => isTrip ? 'Expense linked to trip.' : 'Expense linked to group.';

  @override String get budgetCreated => 'Budget created.';
  @override String get budgetUpdated => 'Budget updated.';
  @override String get budgetDeleted => 'Budget deleted.';

  @override String get goalCreated => 'Goal created.';
  @override String get goalUpdated => 'Goal updated.';
  @override String get goalDeleted => 'Goal deleted.';

  @override String get accountCreated => 'Account added.';
  @override String get accountUpdated => 'Account updated.';
  @override String get accountDeleted => 'Account removed.';
  @override String get accountLocked => 'Account locked. Pro subscription required.';

  @override String get categoryCreated => 'Category added.';
  @override String get categoryDeleted => 'Category removed.';
  @override String get categoryNameRequired => 'Category name is required.';

  @override String get billAdded => 'Bill added. Reminders will be sent.';
  @override String get billPaid => 'Bill marked as paid.';
  @override String get billDeleted => 'Bill removed.';

  @override String get backupSuccess => 'Backup completed successfully.';
  @override String get backupFailed => 'Backup failed. Please try again.';
  @override String get restoreSuccess => 'Data restored successfully.';
  @override String get restoreFailed => 'Restore failed. Verify the backup file.';
  @override String get invalidBackupFile => 'Invalid backup file format.';
  @override String get corruptBackup => 'Backup file is corrupted.';

  @override String get settingsSaved => 'Settings saved.';
  @override String get reminderUpdated => 'Reminder time updated.';
  @override String toggledOn(String feature) => '$feature enabled.';
  @override String toggledOff(String feature) => '$feature disabled.';

  @override String get biometricFailed => 'Authentication failed.';
  @override String get incorrectPin => 'Incorrect PIN.';

  @override String get notificationAccessDenied => 'Notification access is required for auto-import.';
  @override String get smsImportEnabled => 'Auto-import enabled.';

  @override String get noTransactions => 'No transactions recorded.\nAdd your first entry.';
  @override String get noBudgets => 'No budgets configured.';
  @override String get noGoals => 'No goals set.';
  @override String get noBills => 'No recurring bills.';
  @override String get noAccounts => 'No accounts configured.';
  @override String get noCategories => 'No categories defined.';
  @override String get noNotifications => 'No notifications.';
  @override String noFilterResults(String filter) => 'No $filter notifications found.';

  @override String get exportSuccess => 'Report exported.';
  @override String exportFailed(String error) => 'Export failed: $error';

  @override String get purchaseFailed => 'Purchase failed. Please retry.';
  @override String get playNotAvailable => 'Google Play Services unavailable.';

  @override String errorWith(String detail) => 'Error: $detail';
  @override String get genericError => 'An error occurred.';

  @override String singleApproved(String amountStr) => 'Transaction$amountStr recorded automatically.';
  @override String allApproved(int count, String amountStr) => '$count transaction${count > 1 ? 's' : ''}$amountStr processed automatically.';
  @override String mixedResults(int approved, int reviewCount) => '$approved processed, $reviewCount require${reviewCount == 1 ? 's' : ''} review.';
  @override String allNeedReview(int reviewCount) => '$reviewCount transaction${reviewCount > 1 ? 's' : ''} pending review.';
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 🎮 PLAYFUL — fun, gamified, lots of emojis
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class PlayfulTonePack extends TonePack {
  @override String get id => 'playful';
  @override String get name => 'Playful';
  @override String get description => 'Fun, gamified & expressive';
  @override String get emoji => '🎮';

  @override String get txnAdded => 'Ka-ching! Transaction logged! 🎰';
  @override String get txnUpdated => 'Leveled up that transaction! ⬆️';
  @override String get txnDeleted => 'Poof! Transaction vanished! 💨';
  @override String get txnFailed => 'Uh oh, save failed! Boss fight? 🎮 Try again!';
  @override String get txnNotFound => 'Transaction went MIA 🕵️';

  @override String get enterAmount => 'How much gold? 💰 Enter the amount!';
  @override String get pickAccount => 'Choose your vault! 🏰';
  @override String get pickCategory => 'Tag it! What quest was this for? 🏷️';
  @override String get fillAllFields => 'Fill all the blanks to unlock! 🔓';
  @override String get invalidAmount => 'That number looks sus 🧐 Try again!';
  @override String get futureDate => 'No time machines allowed! ⏰ Pick today or before';
  @override String get selectAccountAndCategory => 'Pick a vault & quest type first! 🎯';

  @override String tripCreated(bool isTrip) => isTrip ? 'Adventure created! Let\'s explore! 🗺️' : 'Squad assembled! Let\'s split! ⚔️';
  @override String tripUpdated(bool isTrip) => isTrip ? 'Adventure updated! 🗺️' : 'Squad updated! ⚔️';
  @override String tripDeleted(bool isTrip) => isTrip ? 'Adventure disbanded 💔' : 'Squad disbanded 💔';
  @override String tripFinalized(bool isTrip) => isTrip ? 'Quest complete! 🏆' : 'Mission accomplished! 🏆';
  @override String tripNameRequired(bool isTrip) => isTrip ? 'Every adventure needs a name! 🗺️' : 'Name your squad! ⚔️';
  @override String get addParticipant => 'Recruit at least one party member! 🧙';
  @override String tripLimitReached(bool isTrip) => 'Free tier: 1 active ${isTrip ? 'adventure' : 'squad'}. Go Pro to unlock more! 🔑';
  @override String expenseAddedToTrip(bool isTrip) => isTrip ? 'Loot added to adventure! 💎' : 'Loot split with squad! 💎';

  @override String get budgetCreated => 'Shield activated! Budget is set! 🛡️';
  @override String get budgetUpdated => 'Shield upgraded! 🛡️';
  @override String get budgetDeleted => 'Shield dropped 🛡️';

  @override String get goalCreated => 'New quest accepted! 🎯';
  @override String get goalUpdated => 'Quest updated!';
  @override String get goalDeleted => 'Quest abandoned';

  @override String get accountCreated => 'New vault unlocked! 🏰';
  @override String get accountUpdated => 'Vault upgraded!';
  @override String get accountDeleted => 'Vault sealed';
  @override String get accountLocked => 'Vault locked! 🔒 Go Pro to unlock!';

  @override String get categoryCreated => 'New tag unlocked! 🏷️';
  @override String get categoryDeleted => 'Tag removed';
  @override String get categoryNameRequired => 'Tags need names! 🏷️';

  @override String get billAdded => 'Boss fight scheduled! I\'ll warn you! ⚔️🔔';
  @override String get billPaid => 'Boss defeated! Bill paid! 💥';
  @override String get billDeleted => 'Boss fight cancelled';

  @override String get backupSuccess => 'Save point created! 💾';
  @override String get backupFailed => 'Save failed! Try again! 💾';
  @override String get restoreSuccess => 'Game loaded! Welcome back! 🎮';
  @override String get restoreFailed => 'Load failed — corrupted save? 💾';
  @override String get invalidBackupFile => 'That\'s not a save file! 🤨';
  @override String get corruptBackup => 'Save file corrupted! 💀';

  @override String get settingsSaved => 'Config saved! ⚙️';
  @override String get reminderUpdated => 'Alarm set! ⏰';
  @override String toggledOn(String feature) => '$feature activated! ⚡';
  @override String toggledOff(String feature) => '$feature deactivated';

  @override String get biometricFailed => 'Identity check failed! 🕵️';
  @override String get incorrectPin => 'Wrong code! Try again, hero! 🔢';

  @override String get notificationAccessDenied => 'Need notification powers for auto-loot! 📩';
  @override String get smsImportEnabled => 'Auto-loot activated! I\'ll grab your transactions! 🎣';

  @override String get noTransactions => 'Empty inventory! 📦\nLog your first transaction to begin!';
  @override String get noBudgets => 'No shields yet! 🛡️\nSet a budget to defend your gold!';
  @override String get noGoals => 'No quests! 🎯\nSet a goal to start your journey!';
  @override String get noBills => 'No boss fights scheduled! ⚔️';
  @override String get noAccounts => 'No vaults! 🏰\nAdd one to stash your gold!';
  @override String get noCategories => 'No tags unlocked yet! 🏷️';
  @override String get noNotifications => 'Inbox empty! 📭\nAll clear, hero!';
  @override String noFilterResults(String filter) => 'No $filter alerts found!';

  @override String get exportSuccess => 'Scroll exported! 📜';
  @override String exportFailed(String error) => 'Scroll failed: $error';

  @override String get purchaseFailed => 'Purchase blocked! Try again! 🛒';
  @override String get playNotAvailable => 'Play Store not found on this realm! 🏪';

  @override String errorWith(String detail) => 'Glitch detected: $detail 🐛';
  @override String get genericError => 'Something glitched! 🐛';

  @override String singleApproved(String amountStr) => 'Auto-looted$amountStr! I got your back! ⚔️';
  @override String allApproved(int count, String amountStr) => '$count loot${count > 1 ? 's' : ''}$amountStr auto-collected while you were AFK! 🎮';
  @override String mixedResults(int approved, int reviewCount) => 'Grabbed $approved, but $reviewCount need${reviewCount == 1 ? 's' : ''} your call. Check \'em out! 🎯';
  @override String allNeedReview(int reviewCount) => '$reviewCount loot${reviewCount > 1 ? 's' : ''} need${reviewCount == 1 ? 's' : ''} sorting! Help me out! 🧙';
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 🧘 ZEN — calm, mindful, minimal
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class ZenTonePack extends TonePack {
  @override String get id => 'zen';
  @override String get name => 'Zen';
  @override String get description => 'Calm, mindful & minimal';
  @override String get emoji => '🧘';

  @override String get txnAdded => 'Noted.';
  @override String get txnUpdated => 'Updated.';
  @override String get txnDeleted => 'Released.';
  @override String get txnFailed => 'That didn\'t land. Try once more.';
  @override String get txnNotFound => 'Not found. It may have moved on.';

  @override String get enterAmount => 'An amount is needed.';
  @override String get pickAccount => 'Choose where this belongs.';
  @override String get pickCategory => 'Give it a purpose.';
  @override String get fillAllFields => 'A few things are still empty.';
  @override String get invalidAmount => 'The amount needs adjusting.';
  @override String get futureDate => 'Stay in the present.';
  @override String get selectAccountAndCategory => 'Account and category, please.';

  @override String tripCreated(bool isTrip) => isTrip ? 'Journey begins.' : 'Group formed.';
  @override String tripUpdated(bool isTrip) => 'Adjusted.';
  @override String tripDeleted(bool isTrip) => 'Let go.';
  @override String tripFinalized(bool isTrip) => isTrip ? 'Journey complete.' : 'Settled.';
  @override String tripNameRequired(bool isTrip) => 'It needs a name.';
  @override String get addParticipant => 'Add someone to share with.';
  @override String tripLimitReached(bool isTrip) => 'One at a time on the free path. Pro opens more.';
  @override String expenseAddedToTrip(bool isTrip) => 'Added.';

  @override String get budgetCreated => 'Boundary set.';
  @override String get budgetUpdated => 'Adjusted.';
  @override String get budgetDeleted => 'Released.';

  @override String get goalCreated => 'Intention set.';
  @override String get goalUpdated => 'Refined.';
  @override String get goalDeleted => 'Released.';

  @override String get accountCreated => 'Account opened.';
  @override String get accountUpdated => 'Adjusted.';
  @override String get accountDeleted => 'Closed.';
  @override String get accountLocked => 'This one is resting. Pro unlocks it.';

  @override String get categoryCreated => 'Added.';
  @override String get categoryDeleted => 'Removed.';
  @override String get categoryNameRequired => 'A name, please.';

  @override String get billAdded => 'Noted. You\'ll be reminded.';
  @override String get billPaid => 'Settled.';
  @override String get billDeleted => 'Released.';

  @override String get backupSuccess => 'Safely stored.';
  @override String get backupFailed => 'Couldn\'t save. Try again gently.';
  @override String get restoreSuccess => 'Restored. Welcome back.';
  @override String get restoreFailed => 'Couldn\'t restore. Check the file.';
  @override String get invalidBackupFile => 'This file doesn\'t feel right.';
  @override String get corruptBackup => 'The file seems damaged.';

  @override String get settingsSaved => 'Saved.';
  @override String get reminderUpdated => 'Reminder adjusted.';
  @override String toggledOn(String feature) => '$feature — on.';
  @override String toggledOff(String feature) => '$feature — off.';

  @override String get biometricFailed => 'Not recognized. Try again.';
  @override String get incorrectPin => 'Not quite. Try again.';

  @override String get notificationAccessDenied => 'Permission needed for quiet tracking.';
  @override String get smsImportEnabled => 'Quietly watching your transactions.';

  @override String get noTransactions => 'A clean slate.\nBegin when you\'re ready.';
  @override String get noBudgets => 'No boundaries yet.\nSet one when it feels right.';
  @override String get noGoals => 'No intentions yet.\nSet one when you\'re ready.';
  @override String get noBills => 'Nothing recurring.\nPeaceful.';
  @override String get noAccounts => 'No accounts yet.\nStart simply.';
  @override String get noCategories => 'No categories yet.';
  @override String get noNotifications => 'Silence.\nNothing needs attention.';
  @override String noFilterResults(String filter) => 'Nothing in $filter.';

  @override String get exportSuccess => 'Exported.';
  @override String exportFailed(String error) => 'Export issue: $error';

  @override String get purchaseFailed => 'Purchase didn\'t complete. Try again.';
  @override String get playNotAvailable => 'Play Store not available here.';

  @override String errorWith(String detail) => 'A hiccup: $detail';
  @override String get genericError => 'Something shifted. Try again.';

  @override String singleApproved(String amountStr) => 'Transaction$amountStr — quietly tracked.';
  @override String allApproved(int count, String amountStr) => '$count transaction${count > 1 ? 's' : ''}$amountStr — all handled in the background.';
  @override String mixedResults(int approved, int reviewCount) => '$approved tracked. $reviewCount await${reviewCount == 1 ? 's' : ''} your attention.';
  @override String allNeedReview(int reviewCount) => '$reviewCount await${reviewCount == 1 ? 's' : ''} your review.';
}
