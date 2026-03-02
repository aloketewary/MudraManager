import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/features/account/data/account_providers.dart';
import 'package:mudra_manager/features/dashboard/presentation/widgets/dashboard_account_card.dart';
import 'package:mudra_manager/features/dashboard/presentation/widgets/dashboard_animated_card.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';

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
  AccountType? _selectedType;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final balanceMap = ref
          .watch(accountServiceProvider)
          .getAccountBalanceMap();
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
      // Limit drag to max 120 pixels down
      final newOffset = _dragOffset.dy + details.delta.dy;
      _dragOffset = Offset(0, newOffset.clamp(0, 120));
    });
  }

  void _onVerticalDragEnd(DragEndDetails details, List<AccountCard> cards) {
    const threshold = 80;
    final velocity = details.velocity.pixelsPerSecond.dy;

    if (_dragOffset.dy > threshold || velocity > 700) {
      final nextIndex = (currentIndex + 1) % cards.length;
      setState(() {
        currentIndex = nextIndex;
        _dragOffset = Offset.zero;
      });
    } else {
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
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final accountsAsync = ref.watch(accountsProvider);
    final isGuestMode = ref.watch(guestModeProvider);
    final size = MediaQuery.of(context).size;
    final ctxt = AppLocalizations.of(context)!;

    return accountsAsync.when(
      data: (accounts) {
        if (accounts.isEmpty) {
          return Center(child: Text(ctxt.common_noAccountsYet));
        }

        // Get unique account types
        final types = accounts.map((a) => a.accountType).toSet().toList();

        // Filter accounts by selected type
        final filteredAccounts = _selectedType == null
            ? accounts
            : accounts.where((a) => a.accountType == _selectedType).toList();

        if (currentIndex >= filteredAccounts.length) {
          currentIndex = 0;
        }

        final List<AccountCard> cards = filteredAccounts.map((account) {
          final balance = _balanceMap[account.id] ?? 0.0;
          final displayBalance = GuestModeUtil.applyGuestMode(balance, isGuestMode);
          return AccountCard(
            totalBalance: displayBalance.toStringAsFixed(2),
            accountNumber: 'xxxx xxxx xxxx ${account.accountNumber ?? 'xxxx'}',
            backgroundColor: color.onSecondary,
            accentColor: Color(
              account.colorValue ?? Colors.redAccent.toARGB32(),
            ),
            accountName: account.name,
            accountType: account.accountType,
          );
        }).toList();

        return Column(
          children: [
            // Cards stack
            SizedBox(
              height: 240,
              width: size.width - 16,
              child: Stack(
                children: [
                  if (cards.length > 2)
                    Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: Transform.scale(
                        scale: 0.92,
                        child: Container(
                          height: 220,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                cards[_getIndex(2, cards)].accentColor
                                    .withValues(alpha: 0.7),
                                cards[_getIndex(2, cards)].accentColor
                                    .withValues(alpha: 0.5),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                  if (cards.length > 1)
                    Positioned(
                      top: 8,
                      left: 8,
                      right: 8,
                      child: Transform.scale(
                        scale: 0.96,
                        child: Container(
                          height: 230,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                cards[_getIndex(1, cards)].accentColor
                                    .withValues(alpha: 0.8),
                                cards[_getIndex(1, cards)].accentColor
                                    .withValues(alpha: 0.6),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: GestureDetector(
                      onVerticalDragUpdate: cards.length > 1 ? _onVerticalDragUpdate : null,
                      onVerticalDragEnd: cards.length > 1 ? (dragDetails) =>
                          _onVerticalDragEnd(dragDetails, cards) : null,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Transform.translate(
                          key: ValueKey<int>(currentIndex),
                          offset: _dragOffset,
                          child: AnimatedAccountCard(
                            totalBalance: cards[currentIndex].totalBalance,
                            accountNumber: cards[currentIndex].accountNumber,
                            backgroundColor: color.surface,
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
                  ),
                ],
              ),
            ),

            // Filter chips below cards
            if (types.length > 1)
              Container(
                height: 40,
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        selected: _selectedType == null,
                        label: const Text('All'),
                        onSelected: (selected) {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _selectedType = null;
                            currentIndex = 0;
                          });
                        },
                      ),
                    ),
                    ...types.map(
                      (type) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FilterChip(
                          selected: _selectedType == type,
                          label: Text(type.name.toUpperCase()),
                          onSelected: (selected) {
                            HapticFeedback.lightImpact();
                            setState(() {
                              _selectedType = selected ? type : null;
                              currentIndex = 0;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
      loading: () => SizedBox(
        height: 220,
        child: AnimatedAccountCard(
          totalBalance: '---',
          accountNumber: '---',
          backgroundColor: color.surfaceContainerHighest,
          accentColor: color.primary,
          accountName: ctxt.common_loading,
          accountType: AccountType.cash,
          onArchive: () {},
          onEdit: () {},
          onRemove: () {},
          showMenu: false,
        ),
      ),
      error: (e, st) =>
          Center(child: Text(ctxt.common_errorText(e.toString()))),
    );
  }
}
