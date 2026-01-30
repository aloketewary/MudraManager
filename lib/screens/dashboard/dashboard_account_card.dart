import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:mudra_manager/db/models/account.dart' show AccountType;

class AccountCard {
  final String totalBalance;
  final String accountNumber;
  final Color backgroundColor;
  final Color accentColor;
  final String accountName;
  final AccountType accountType;

  const AccountCard({
    required this.totalBalance,
    required this.accountNumber,
    required this.backgroundColor,
    required this.accentColor,
    required this.accountName,
    required this.accountType,
  });
}

