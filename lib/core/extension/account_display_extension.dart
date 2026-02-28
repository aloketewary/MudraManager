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
      // For credit cards, lower/zero balance is good (less owed)
      return balance <= 0;
    }
    // For regular accounts, positive balance is good
    return balance >= 0;
  }
}
