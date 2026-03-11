import 'package:flutter/material.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/extension/account_type_extenstion.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/features/account/data/account_providers.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:mudra_manager/features/transactions/data/transaction_provider.dart';
import 'package:mudra_manager/shared/widgets/animated_balance.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';

class AnimatedSwipeableAccountCards extends ConsumerStatefulWidget {
  const AnimatedSwipeableAccountCards({super.key});

  @override
  ConsumerState<AnimatedSwipeableAccountCards> createState() =>
      _AnimatedSwipeableAccountCardsState();
}

class _AnimatedSwipeableAccountCardsState
    extends ConsumerState<AnimatedSwipeableAccountCards> {
  int _currentPage = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);
    final isGuestMode = ref.watch(guestModeProvider);
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    final ctxt = AppLocalizations.of(context)!;

    return accountsAsync.when(
      data: (accounts) {
        if (accounts.isEmpty) {
          return Center(child: Text(ctxt.common_noAccountsYet));
        }

        final transactionService = ref.watch(transactionProvider);
        final transactionsFuture = transactionService.getAll();

        return FutureBuilder<List<Transaction>>(
          future: transactionsFuture,
          builder: (context, transactionsSnapshot) {
            if (!transactionsSnapshot.hasData) {
              return const SizedBox(
                height: 250,
                child: AccountCardSkeleton(),
              );
            }

            final balanceMapFuture =
                ref.watch(accountServiceProvider).getAccountBalanceMap();

            return FutureBuilder<Map<int, double>>(
              future: balanceMapFuture,
              builder: (context, snapshot) {
                final balanceMap = snapshot.data ?? {};

                // Calculate total balance (regular accounts - credit card debt)
                final totalBalance = GuestModeUtil.applyGuestMode(
                  accounts.fold<double>(0, (sum, acc) {
                    final balance = balanceMap[acc.id] ?? 0;
                    // For credit cards, subtract the debt (positive balance = owed)
                    // For regular accounts, add the balance
                    return acc.accountType == AccountType.creditCard
                        ? sum - balance
                        : sum + balance;
                  }),
                  isGuestMode,
                );
                final currentAccount = accounts[_currentPage];
                final currentBalance = GuestModeUtil.applyGuestMode(
                  balanceMap[currentAccount.id] ?? 0,
                  isGuestMode,
                );

                return SizedBox(
                  height: 250,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Totale Balance
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'Total Balance',
                          style: textTheme.titleMedium?.copyWith(
                            color: color.onSurface,
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: AnimatedBalance(
                          value: totalBalance,
                          style: textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: color.onSurface,
                          ),
                          compact: false,
                          fixedStringLength: 0,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Horizontal Scrolling Cards with Peek Effect
                      SizedBox(
                        height: 100,
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) {
                            setState(() {
                              _currentPage = index;
                            });
                          },
                          itemCount: accounts.length,
                          itemBuilder: (context, index) {
                            final account = accounts[index];

                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(account.colorValue ?? 0xFF6B4CE6),
                                    Color(account.colorValue ?? 0xFF6B4CE6)
                                        .withValues(alpha: 0.85),
                                  ],
                                ),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Color(account.colorValue ?? 0xFF6B4CE6)
                                            .withValues(alpha: 0.3),
                                    blurRadius: 16,
                                    offset: const Offset(0, -4),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                        account.name,
                                        style: textTheme.titleMedium?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        ' - ${account.accountType.label.toUpperCase()}',
                                        style: textTheme.labelSmall?.copyWith(
                                          color: Colors.white.withValues(alpha: 0.7),
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      AnimatedBalance(
                                        value: currentBalance,
                                        compact: false,
                                        fixedStringLength: 0,
                                        duration: const Duration(milliseconds: 300),
                                        style: textTheme.titleLarge?.copyWith(
                                          color: Colors.white,
                                          letterSpacing: 2,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        account.accountNumber?.substring(
                                                account.accountNumber!.length >=
                                                        4
                                                    ? account.accountNumber!
                                                            .length -
                                                        4
                                                    : 0,) ??
                                            '0000',
                                        style: textTheme.titleSmall?.copyWith(
                                          color: Colors.white
                                              .withValues(alpha: 0.5),
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Icon(
                                        account.accountType.icon,
                                        color:
                                            Colors.white.withValues(alpha: 0.5),
                                        size: 40,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Page Indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          accounts.length,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentPage == index ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? color.primary
                                  : color.onSurface.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
      loading: () => const SizedBox(
        height: 250,
        child: AccountCardSkeleton(),
      ),
      error: (e, st) =>
          Center(child: Text(ctxt.common_errorText(e.toString()))),
    );
  }
}
