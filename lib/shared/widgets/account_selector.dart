import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/features/account/data/account_providers.dart';

class AccountSelector extends ConsumerWidget {
  final Account? selectedAccount;
  final Function(Account) onAccountSelected;
  final String? accountNumber;
  final String? bankName;

  const AccountSelector({
    super.key,
    required this.selectedAccount,
    required this.onAccountSelected,
    this.accountNumber,
    this.bankName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);

    return ref.watch(accountsProvider).when(
          data: (accounts) {
            final matchedAccount = accountNumber != null
                ? accounts
                    .where((a) =>
                        a.accountNumber?.contains(accountNumber!) == true,)
                    .firstOrNull
                : null;
            final showAddButton =
                accountNumber != null && matchedAccount == null;

            return SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: accounts.length + (showAddButton ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (showAddButton && index == accounts.length) {
                    return _AddAccountButton(
                      accountNumber: accountNumber!,
                      bankName: bankName,
                      color: color,
                      textTheme: textTheme,
                    );
                  }

                  final account = accounts[index];
                  final isSelected = selectedAccount?.id == account.id;

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      onAccountSelected(account);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8,),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.primaryContainer
                            : color.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(spacing.radiusSmall),
                        border: isSelected
                            ? Border.all(color: color.primary, width: 2)
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getAccountIcon(account.accountType),
                            size: 20,
                            color: isSelected
                                ? color.onPrimaryContainer
                                : color.onSurface,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            account.name,
                            style: textTheme.labelSmall?.copyWith(
                              color: isSelected
                                  ? color.onPrimaryContainer
                                  : color.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            account.accountNumber ?? '',
                            style: textTheme.labelSmall?.copyWith(
                              color: isSelected
                                  ? color.onPrimaryContainer
                                  : color.onSurface,
                            ),
                          ),
                          if (account.currencyCode != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              account.currencyCode!,
                              style: textTheme.labelSmall?.copyWith(
                                color: isSelected
                                    ? color.primary
                                    : color.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
          loading: () => SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, __) => const AccountCardSkeleton(),
            ),
          ),
          error: (_, __) =>
              SizedBox(height: 60, child: Text(BuddyMessages.genericError)),
        );
  }

  IconData _getAccountIcon(AccountType type) {
    switch (type) {
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
        return LucideIcons.dollarSign;
    }
  }
}

class _AddAccountButton extends ConsumerWidget {
  final String accountNumber;
  final String? bankName;
  final ColorScheme color;
  final TextTheme textTheme;

  const _AddAccountButton({
    required this.accountNumber,
    required this.bankName,
    required this.color,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);

    return GestureDetector(
      onTap: () => context.push(
        '/manage-accounts/add',
        extra: {
          'accountNumber': accountNumber,
          'bankName': bankName,
        },
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.surface,
          borderRadius: BorderRadius.circular(spacing.radiusSmall),
          border: Border.all(color: color.error, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.circlePlus, size: 20, color: color.error),
            const SizedBox(height: 4),
            Text(
              bankName != null && bankName!.isNotEmpty
                  ? '$bankName\n****$accountNumber'
                  : '****$accountNumber',
              style: textTheme.labelSmall?.copyWith(
                color: color.error,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
