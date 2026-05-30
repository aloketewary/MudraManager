import 'package:mudra_manager/core/tone/tone_provider.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/features/account/data/account_providers.dart';
import 'package:mudra_manager/shared/widgets/account_display_card.dart';

class AccountSelectorBottomSheet extends ConsumerWidget {
  final Account? selectedAccount;
  final Function(Account) onAccountSelected;

  const AccountSelectorBottomSheet({
    super.key,
    this.selectedAccount,
    required this.onAccountSelected,
  });

  static Future<Account?> show(
    BuildContext context, {
    Account? selectedAccount,
  }) {
    return showModalBottomSheet<Account>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Tone.current.borderRadius * 2)),
      ),
      builder: (context) => AccountSelectorBottomSheet(
        selectedAccount: selectedAccount,
        onAccountSelected: (account) => Navigator.pop(context, account),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);
    final accountService = ref.watch(accountServiceProvider);
    final textTheme = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select Account',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: accountsAsync.when(
              data: (accounts) {
                if (accounts.isEmpty) {
                  return Center(
                    child: Text(
                      BuddyMessages.noAccounts,
                      style: textTheme.bodyMedium,
                    ),
                  );
                }
                return ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: accounts.length,
                  itemBuilder: (context, index) {
                    final account = accounts[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: FutureBuilder<double>(
                        future: accountService.getAccountBalance(account.id),
                        builder: (context, snapshot) {
                          final balance = snapshot.data ?? 0.0;
                          return AccountDisplayCard(
                            title: account.name,
                            amount: formatCurrency(balance, decimals: 0),
                            accountType: account.accountType,
                            startColor: Colors.blue,
                            endColor: Colors.blue.shade100,
                            isSelected: selectedAccount?.id == account.id,
                            accountNumber: account.accountNumber,
                            callbackAction: () => onAccountSelected(account),
                          );
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 4,
                itemBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: AccountCardSkeleton(),
                ),
              ),
              error: (e, _) => Center(child: Text(BuddyMessages.errorWith('$e'))),
            ),
          ),
        ],
      ),
    );
  }
}
