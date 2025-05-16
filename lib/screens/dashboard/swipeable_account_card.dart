import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/db/models/account.dart';
import 'package:mudra_manager/l10n/app_localizations.dart';
import 'package:mudra_manager/providers/account_providers.dart';
import 'package:mudra_manager/screens/dashboard/dashboard_account_card.dart'
    show AccountCard;
import 'package:mudra_manager/screens/dashboard/dashboard_animated_card.dart'
    show AnimatedAccountCard;

class AnimatedSwipeableAccountCards extends ConsumerStatefulWidget {
  const AnimatedSwipeableAccountCards({super.key});

  @override
  ConsumerState<AnimatedSwipeableAccountCards> createState() =>
      _AnimatedSwipeableAccountCardsState();
}

class _AnimatedSwipeableAccountCardsState
    extends ConsumerState<AnimatedSwipeableAccountCards> {
  int currentIndex = 0;
  Offset _dragOffset = Offset.zero;
  Map<int, double> _balanceMap = {};
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final balanceMap =
          ref.watch(accountServiceProvider).getAccountBalanceMap();
      balanceMap.then(
        (val) => {
          if (mounted)
            {
              setState(() {
                _balanceMap = val;
              }),
            },
        },
      );
      _initialized = true;
    }
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += Offset(0, details.delta.dy);
    });
  }

  void _onVerticalDragEnd(DragEndDetails details, List<AccountCard> cards) {
    const threshold = 80;
    final velocity = details.velocity.pixelsPerSecond.dy;

    if (_dragOffset.dy > threshold || velocity > 700) {
      // Swipe down → next
      final nextIndex = (currentIndex + 1) % cards.length;
      setState(() {
        currentIndex = nextIndex;
        _dragOffset = Offset.zero;
      });
    // } else if (_dragOffset.dy < -threshold || velocity < -700) {
    //   // Swipe up → previous
    //   final prevIndex = (currentIndex - 1 + cards.length) % cards.length;
    //   setState(() {
    //     currentIndex = prevIndex;
    //     _dragOffset = Offset.zero;
    //   });
    } else {
      // Not enough, snap back
      setState(() {
        _dragOffset = Offset.zero;
      });
    }
  }

  int _getIndex(int offset, List<AccountCard> cards) {
    return (currentIndex + offset + cards.length) % cards.length;
  }

  @override
  Widget build(BuildContext context) {
    var color = Theme.of(context).colorScheme;
    final accountsAsync = ref.watch(accountsProvider);
    var size = MediaQuery.of(context).size;
    var ctxt = AppLocalizations.of(context)!;

    return accountsAsync.when(
      data: (accounts) {
        if (accounts.isEmpty) {
          return const Center(child: Text("No accounts yet"));
        }
        List<AccountCard> cards =
            accounts.map((account) {
              return AccountCard(
                totalBalance:
                    _balanceMap[account.id]?.toStringAsFixed(2) ?? '0.0',
                accountNumber:
                    'xxxx xxxx xxxx ${account.accountNumber ?? 'xxxx'}',
                backgroundColor: color.onSecondary,
                accentColor: Color(
                  account.colorValue ?? Colors.redAccent.toARGB32(),
                ),
                accountName: account.name,
                accountType: account.accountType,
              );
            }).toList();
        final textScale = MediaQuery.textScalerOf(context).textScaleFactor;
        final scale = textScale.clamp(1.0, 1.4);

        // Use accounts list instead of _cards
        return SizedBox(
          height: 280,
          width: size.width - 16,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // same layout logic as before, but with `accounts[_getIndex(...)]`
              // Previous card (behind)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                top: 2,
                left: 18,
                right: 18,
                child: AnimatedScale(
                  scale: 1,
                  duration: const Duration(milliseconds: 300),
                  child: AnimatedAccountCard(
                    totalBalance: cards[_getIndex(2, cards)].totalBalance,
                    accountNumber: cards[_getIndex(2, cards)].accountNumber,
                    backgroundColor: color.primary,
                    accentColor: cards[_getIndex(2, cards)].accentColor,
                    accountName: cards[_getIndex(2, cards)].accountName,
                    accountType: cards[_getIndex(2, cards)].accountType,
                    onArchive: () {},
                    onEdit: () {},
                    onRemove: () {},
                    showMenu: false,
                    isBehind: true,
                  ),
                ),
              ),

              // Next card (bottom)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                top: 8,
                left: 12,
                right: 12,
                child: AnimatedScale(
                  scale: 1,
                  duration: const Duration(milliseconds: 300),
                  child: AnimatedAccountCard(
                    totalBalance: cards[_getIndex(1, cards)].totalBalance,
                    accountNumber: cards[_getIndex(1, cards)].accountNumber,
                    backgroundColor: color.primary,
                    accentColor: cards[_getIndex(1, cards)].accentColor,
                    accountName: cards[_getIndex(1, cards)].accountName,
                    accountType: cards[_getIndex(1, cards)].accountType,
                    onArchive: () {},
                    onEdit: () {},
                    onRemove: () {},
                    showMenu: false,
                  ),
                ),
              ),

              // Current card (center, draggable)
              GestureDetector(
                onVerticalDragUpdate: _onVerticalDragUpdate,
                onVerticalDragEnd:
                    (dragDetails) => _onVerticalDragEnd(dragDetails, cards),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Transform.translate(
                    key: ValueKey<int>(currentIndex),
                    offset: _dragOffset,
                    child: AnimatedAccountCard(
                      totalBalance: cards[currentIndex].totalBalance,
                      accountNumber: cards[currentIndex].accountNumber,
                      backgroundColor: color.primary,
                      accentColor: cards[currentIndex].accentColor,
                      accountName: cards[currentIndex].accountName,
                      accountType: cards[currentIndex].accountType,
                      onArchive: () {},
                      onEdit: () {},
                      onRemove: () {},
                      showMenu: false,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading:
          () => AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Transform.translate(
              key: ValueKey<int>(currentIndex),
              offset: _dragOffset,
              child: AnimatedAccountCard(
                totalBalance: '---',
                accountNumber: '---',
                backgroundColor: Colors.grey,
                accentColor: color.primary,
                accountName: 'Loading',
                accountType: AccountType.cash,
                onArchive: () {},
                onEdit: () {},
                onRemove: () {},
                showMenu: false,
              ),
            ),
          ),
      error: (e, st) => Center(child: Text("Error: $e")),
    );
  }
}
