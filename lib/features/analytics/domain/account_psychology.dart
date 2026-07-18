import 'package:mudra_manager/core/db/models/account.dart';

/// Domain-layer mapping of account type → psychological framing label.
/// Pure business rule, kept out of presentation so it stays testable
/// and reusable across screens (net worth, accounts list, etc).
extension AccountPsychologyX on AccountType {
  String psychologyLabel({required bool isAsset}) {
    if (isAsset) {
      switch (this) {
        case AccountType.bank:
          return 'Liquid Safety Net';
        case AccountType.cash:
          return 'Immediate Access';
        case AccountType.investment:
          return 'Growth Engine';
        case AccountType.eWallet:
          return 'Digital Reserve';
        default:
          return 'Available Funds';
      }
    }
    switch (this) {
      case AccountType.creditCard:
        return 'Revolving Credit';
      default:
        return 'Financial Obligation';
    }
  }
}
