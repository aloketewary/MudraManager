import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/account.dart';

extension AccountTypeX on AccountType {
  String get label {
    switch (this) {
      case AccountType.bank:
        return 'Bank';
      case AccountType.cash:
        return 'Cash';
      case AccountType.creditCard:
        return 'Credit Card';
      case AccountType.eWallet:
        return 'E-Wallet';
      case AccountType.investment:
        return 'Investment';
      case AccountType.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case AccountType.bank:
        return LucideIcons.landmark;
      case AccountType.cash:
        return LucideIcons.banknote;
      case AccountType.creditCard:
        return LucideIcons.creditCard;
      case AccountType.eWallet:
        return LucideIcons.wallet;
      case AccountType.investment:
        return LucideIcons.trendingUp;
      case AccountType.other:
        return LucideIcons.ellipsis;
    }
  }
}
