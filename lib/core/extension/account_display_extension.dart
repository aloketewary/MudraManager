import 'package:mudra_manager/core/db/models/account.dart';

extension AccountDisplayExtension on Account {
  /// Returns appropriate balance label based on account type
  String getBalanceLabel() {
    switch (accountType) {
      case AccountType.creditCard:
        return 'Outstanding';
      case AccountType.bank:
      case AccountType.eWallet:
        return 'Balance';
      case AccountType.cash:
        return 'Cash';
      case AccountType.investment:
        return 'Value';
      default:
        return 'Balance';
    }
  }

  /// Returns true if balance is in good state for this account type
  bool isBalanceHealthy(double balance) {
    if (accountType == AccountType.creditCard) {
      // Credit-card balances are positive while debt is outstanding. A
      // zero/negative balance means the card is paid off or overpaid.
      return balance <= 0;
    }
    // For regular accounts, positive balance is good
    return balance >= 0;
  }
}
