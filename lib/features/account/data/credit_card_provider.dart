import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/providers/collection_watchers.dart';
import 'package:mudra_manager/features/account/data/account_providers.dart';

class CreditCardSummary {
  final Account account;
  final double outstanding;
  final int? daysUntilDue;

  const CreditCardSummary({
    required this.account,
    required this.outstanding,
    this.daysUntilDue,
  });
}

final creditCardSummariesProvider =
    FutureProvider.autoDispose<List<CreditCardSummary>>((ref) async {
  ref.watch(transactionChangeProvider);
  ref.watch(accountChangeProvider);

  final accountService = ref.watch(accountServiceProvider);
  final accounts = await ref.watch(allAccountsProvider.future);

  final cards = accounts
      .where((a) => a.accountType == AccountType.creditCard && a.isActive)
      .toList();

  final summaries = <CreditCardSummary>[];
  final now = DateTime.now();

  for (final card in cards) {
    final balance = await accountService.getAccountBalance(card.id);
    // For credit cards, negative balance = outstanding (money owed)
    final outstanding = balance < 0 ? balance.abs() : 0.0;

    int? daysUntilDue;
    if (card.dueDay != null) {
      var dueDate = DateTime(now.year, now.month, card.dueDay!);
      if (dueDate.isBefore(now) || dueDate.isAtSameMomentAs(now)) {
        // Due date passed this month, look at next month
        dueDate = DateTime(now.year, now.month + 1, card.dueDay!);
      }
      daysUntilDue = dueDate.difference(DateTime(now.year, now.month, now.day)).inDays;
    }

    summaries.add(CreditCardSummary(
      account: card,
      outstanding: outstanding,
      daysUntilDue: daysUntilDue,
    ),);
  }

  return summaries;
});
