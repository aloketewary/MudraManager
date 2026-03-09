import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/services/widget_service.dart';
import 'package:mudra_manager/features/account/data/account_providers.dart';
import 'package:mudra_manager/features/transactions/data/transaction_provider.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';

class TransferScreenNew extends ConsumerStatefulWidget {
  const TransferScreenNew({super.key});

  @override
  ConsumerState<TransferScreenNew> createState() => _TransferScreenNewState();
}

class _TransferScreenNewState extends ConsumerState<TransferScreenNew> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _amountFocus = FocusNode();
  
  Account? _fromAccount;
  Account? _toAccount;
  DateTime _date = DateTime.now();
  double _slideProgress = 0.0;
  
  // Cache balances to avoid repeated queries
  final Map<int, Future<double>> _balanceCache = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _amountFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _amountFocus.dispose();
    super.dispose();
  }
  
  Future<double> _getCachedBalance(int accountId) {
    return _balanceCache.putIfAbsent(
      accountId,
      () => ref.read(accountServiceProvider).getAccountBalance(accountId),
    );
  }

  void _swapAccounts() {
    HapticFeedback.mediumImpact();
    setState(() {
      final temp = _fromAccount;
      _fromAccount = _toAccount;
      _toAccount = temp;
    });
  }

  Future<void> _executeTransfer() async {
    if (_fromAccount == null || _toAccount == null) return;
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;

    HapticFeedback.heavyImpact();
    
    final service = ref.read(transactionProvider);
    await service.transfer(
      from: _fromAccount!,
      to: _toAccount!,
      amount: amount,
      date: _date,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    await WidgetService.updateWidget(ref);
    
    if (mounted) {
      invalidateAll(ref);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isGuestMode = ref.watch(guestModeProvider);
    final accountService = ref.watch(accountServiceProvider);

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        title: const Text('Transfer Money'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today, size: 20),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                HapticFeedback.lightImpact();
                setState(() => _date = picked);
              }
            },
          ),
        ],
      ),
      body: accountsAsync.when(
        data: (accounts) {
          if (accounts.isEmpty) {
            return Center(
              child: Text('No accounts available', style: textTheme.bodyLarge),
            );
          }

          // Auto-select first account if none selected
          if (_fromAccount == null && accounts.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _fromAccount = accounts.first);
            });
          }

          final fromBalance = _fromAccount != null
              ? _getCachedBalance(_fromAccount!.id)
              : Future.value(0.0);

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // FROM Card (Persistent)
                    _AccountCard(
                      label: 'FROM',
                      account: _fromAccount,
                      balance: fromBalance,
                      isGuestMode: isGuestMode,
                      onTap: () => _showAccountPicker(
                        context,
                        accounts.where((a) => a.id != _toAccount?.id).toList(),
                        (account) {
                          setState(() => _fromAccount = account);
                          _balanceCache.clear(); // Clear cache on account change
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Swap Button
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: color.primaryContainer,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: color.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: _fromAccount != null && _toAccount != null
                              ? _swapAccounts
                              : null,
                          icon: Icon(
                            Icons.swap_vert,
                            color: _fromAccount != null && _toAccount != null
                                ? color.onPrimaryContainer
                                : color.onSurfaceVariant.withValues(alpha: 0.3),
                          ),
                          iconSize: 32,
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // TO Card (Persistent)
                    _AccountCard(
                      label: 'TO',
                      account: _toAccount,
                      balance: _toAccount != null
                          ? _getCachedBalance(_toAccount!.id)
                          : Future.value(0.0),
                      isGuestMode: isGuestMode,
                      onTap: () => _showAccountPicker(
                        context,
                        accounts.where((a) => a.id != _fromAccount?.id).toList(),
                        (account) {
                          setState(() => _toAccount = account);
                          _balanceCache.clear(); // Clear cache on account change
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Amount Field (Center Focus)
                    RepaintBoundary(
                      child: TextField(
                        controller: _amountController,
                        focusNode: _amountFocus,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.center,
                        style: textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color.primary,
                        ),
                        decoration: InputDecoration(
                          hintText: '0.00',
                          prefixText: '₹ ',
                          prefixStyle: textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: color.primary.withValues(alpha: 0.5),
                          ),
                          border: InputBorder.none,
                          filled: true,
                          fillColor: color.primaryContainer.withValues(alpha: 0.3),
                          contentPadding: const EdgeInsets.symmetric(vertical: 24),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    
                    // Quick Amount Chips
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [500, 1000, 2000, 5000, 10000].map((amt) {
                        return ActionChip(
                          label: Text('₹$amt'),
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            _amountController.text = amt.toString();
                            setState(() {});
                          },
                          backgroundColor: color.surfaceContainerHigh,
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Note Field (Optional)
                    TextField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        labelText: 'Note (optional)',
                        hintText: 'Add a note',
                        prefixIcon: const Icon(Icons.note_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      maxLines: 2,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Date Display
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: color.onSurfaceVariant),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat.yMMMd().format(_date),
                            style: textTheme.bodyMedium?.copyWith(
                              color: color.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Slide to Transfer Button
              _SlideToTransferButton(
                enabled: _fromAccount != null &&
                    _toAccount != null &&
                    (_amountController.text.isNotEmpty &&
                        double.tryParse(_amountController.text) != null &&
                        double.parse(_amountController.text) > 0),
                onSlideComplete: _executeTransfer,
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showAccountPicker(
    BuildContext context,
    List<Account> accounts,
    Function(Account) onSelect,
  ) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final accountService = ref.watch(accountServiceProvider);
    final isGuestMode = ref.watch(guestModeProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: color.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Select Account',
                style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: accounts.length,
                  itemBuilder: (context, index) {
                    final account = accounts[index];
                    return _AccountPickerItem(
                      account: account,
                      isGuestMode: isGuestMode,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        onSelect(account);
                        ctx.pop();
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getAccountIcon(AccountType type) {
    switch (type) {
      case AccountType.bank:
        return Icons.account_balance;
      case AccountType.cash:
        return Icons.money;
      case AccountType.creditCard:
        return Icons.credit_card;
      case AccountType.eWallet:
        return Icons.account_balance_wallet;
      case AccountType.investment:
        return Icons.trending_up;
      case AccountType.other:
        return Icons.attach_money;
    }
  }
}

class _AccountCard extends StatelessWidget {
  final String label;
  final Account? account;
  final Future<double> balance;
  final bool isGuestMode;
  final VoidCallback onTap;

  const _AccountCard({
    required this.label,
    required this.account,
    required this.balance,
    required this.isGuestMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return RepaintBoundary(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: account != null
                ? color.primaryContainer.withValues(alpha: 0.3)
                : color.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: account != null
                  ? color.primary.withValues(alpha: 0.5)
                  : color.outline.withValues(alpha: 0.2),
              width: 2,
            ),
          ),
          child: account != null
              ? Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Color(
                        account!.colorValue ?? color.primary.toARGB32(),
                      ).withValues(alpha: 0.2),
                      child: Icon(
                        _getAccountIcon(account!.accountType),
                        color: Color(
                          account!.colorValue ?? color.primary.toARGB32(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: textTheme.labelSmall?.copyWith(
                              color: color.primary,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            account!.name,
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          FutureBuilder<double>(
                            future: balance,
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return Text(
                                  'Loading...',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: color.onSurfaceVariant,
                                  ),
                                );
                              }
                              final bal = GuestModeUtil.applyGuestMode(
                                snapshot.data!,
                                isGuestMode,
                              );
                              return Text(
                                'Available: ₹${bal.toStringAsFixed(2)}',
                                style: textTheme.bodySmall?.copyWith(
                                  color: color.onSurfaceVariant,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.edit, color: color.primary, size: 20),
                  ],
                )
              : Column(
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      size: 48,
                      color: color.onSurfaceVariant,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to select $label account',
                      style: textTheme.bodyMedium?.copyWith(
                        color: color.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  IconData _getAccountIcon(AccountType type) {
    switch (type) {
      case AccountType.bank:
        return Icons.account_balance;
      case AccountType.cash:
        return Icons.money;
      case AccountType.creditCard:
        return Icons.credit_card;
      case AccountType.eWallet:
        return Icons.account_balance_wallet;
      case AccountType.investment:
        return Icons.trending_up;
      case AccountType.other:
        return Icons.attach_money;
    }
  }
}

class _SlideToTransferButton extends StatefulWidget {
  final bool enabled;
  final VoidCallback onSlideComplete;

  const _SlideToTransferButton({
    required this.enabled,
    required this.onSlideComplete,
  });

  @override
  State<_SlideToTransferButton> createState() => _SlideToTransferButtonState();
}

class _SlideToTransferButtonState extends State<_SlideToTransferButton> {
  double _dragPosition = 0.0;
  bool _isCompleted = false;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.of(context).size.width - 32;
    final threshold = screenWidth - 80;

    return Container(
      margin: const EdgeInsets.all(16),
      height: 70,
      decoration: BoxDecoration(
        color: widget.enabled
            ? color.primaryContainer
            : color.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(35),
      ),
      child: Stack(
        children: [
          // Background Text
          Center(
            child: Text(
              _isCompleted ? 'Transferring...' : 'Slide to Transfer',
              style: textTheme.titleMedium?.copyWith(
                color: widget.enabled
                    ? color.onPrimaryContainer.withValues(alpha: 0.5)
                    : color.onSurfaceVariant.withValues(alpha: 0.3),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Draggable Button
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            left: _dragPosition,
            top: 5,
            bottom: 5,
            child: GestureDetector(
              onHorizontalDragUpdate: widget.enabled && !_isCompleted
                  ? (details) {
                      setState(() {
                        _dragPosition = (_dragPosition + details.delta.dx)
                            .clamp(0.0, threshold);
                      });
                      
                      // Haptic feedback at intervals
                      if (_dragPosition % 50 < 5) {
                        HapticFeedback.selectionClick();
                      }
                    }
                  : null,
              onHorizontalDragEnd: widget.enabled && !_isCompleted
                  ? (details) {
                      if (_dragPosition >= threshold * 0.9) {
                        setState(() => _isCompleted = true);
                        HapticFeedback.heavyImpact();
                        widget.onSlideComplete();
                      } else {
                        setState(() => _dragPosition = 0);
                      }
                    }
                  : null,
              child: Container(
                width: 60,
                decoration: BoxDecoration(
                  color: widget.enabled ? color.primary : color.surfaceContainerHigh,
                  shape: BoxShape.circle,
                  boxShadow: widget.enabled
                      ? [
                          BoxShadow(
                            color: color.primary.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  _isCompleted ? Icons.check : Icons.arrow_forward,
                  color: widget.enabled ? color.onPrimary : color.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _AccountPickerItem extends ConsumerWidget {
  final Account account;
  final bool isGuestMode;
  final VoidCallback onTap;

  const _AccountPickerItem({
    required this.account,
    required this.isGuestMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final balance = ref.watch(accountServiceProvider).getAccountBalance(account.id);

    return FutureBuilder<double>(
      future: balance,
      builder: (context, snapshot) {
        final bal = GuestModeUtil.applyGuestMode(
          snapshot.data ?? 0,
          isGuestMode,
        );
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Color(
              account.colorValue ?? color.primary.toARGB32(),
            ).withValues(alpha: 0.2),
            child: Icon(
              _getAccountIcon(account.accountType),
              color: Color(
                account.colorValue ?? color.primary.toARGB32(),
              ),
            ),
          ),
          title: Text(account.name),
          subtitle: snapshot.hasData
              ? Text('₹${bal.toStringAsFixed(2)}')
              : const Text('Loading...'),
          onTap: onTap,
        );
      },
    );
  }

  IconData _getAccountIcon(AccountType type) {
    switch (type) {
      case AccountType.bank:
        return Icons.account_balance;
      case AccountType.cash:
        return Icons.money;
      case AccountType.creditCard:
        return Icons.credit_card;
      case AccountType.eWallet:
        return Icons.account_balance_wallet;
      case AccountType.investment:
        return Icons.trending_up;
      case AccountType.other:
        return Icons.attach_money;
    }
  }
}
