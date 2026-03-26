import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/entitlement/entitlement_feature.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/core/services/widget_service.dart';
import 'package:mudra_manager/core/utils/icon_helper.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/account/data/account_access_provider.dart';
import 'package:mudra_manager/features/account/data/account_providers.dart';
import 'package:mudra_manager/features/category/data/category_provider.dart';
import 'package:mudra_manager/features/transactions/data/transaction_provider.dart';

class QuickAddTransactionSheet extends ConsumerStatefulWidget {
  const QuickAddTransactionSheet({super.key});

  @override
  ConsumerState<QuickAddTransactionSheet> createState() =>
      _QuickAddTransactionSheetState();
}

class _QuickAddTransactionSheetState
    extends ConsumerState<QuickAddTransactionSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isExpense = true;
  Account? _selectedAccount;
  Category? _selectedCategory;
  final AppLog _log = AppLog(getLogger(), 'QuickAddSheet');

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final ctxt = AppLocalizations.of(context)!;
    _log.i('Quick add: Starting transaction save');

    if (_amountController.text.isEmpty ||
        double.tryParse(_amountController.text) == null) {
      _log.w('Quick add: Invalid amount entered');
      SnackbarService.error(ctxt.transaction_enterValidAmountError);
      return;
    }
    if (_selectedAccount == null) {
      _log.w('Quick add: No account selected');
      SnackbarService.error(ctxt.transaction_selectOneAccountErrorText);
      return;
    }
    if (_selectedCategory == null) {
      _log.w('Quick add: No category selected');
      SnackbarService.error(ctxt.transaction_selectOneCategoryErrorText);
      return;
    }

    final txn = Transaction.create(
      date: DateTime.now(),
      amount: double.parse(_amountController.text),
      isExpense: _isExpense,
      description: _noteController.text,
    );

    txn.account.value = _selectedAccount;
    txn.category.value = _selectedCategory;

    _log.i(
      'Quick add: Saving ${_isExpense ? "expense" : "income"} of ₹${txn.amount}',
    );
    await ref.read(transactionProvider).addTransaction(txn);
    await WidgetService.updateWidget(ref);
    _log.i('Quick add: Widget updated after transaction');

    if (mounted) {
      Navigator.pop(context);
      SnackbarService.success('Transaction added successfully');
      _log.i('Quick add: Transaction saved successfully');
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final accountsAsync = ref.watch(frequencySortedAccountsProvider);

    final type = _isExpense ? CategoryType.expense : CategoryType.income;
    final categoriesAsync = ref.watch(frequencySortedCategoriesProvider(type));

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: color.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Quick Add',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Expense/Income Toggle
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: true,
                label: Text('Expense'),
                icon: Icon(Icons.remove_circle_outline),
              ),
              ButtonSegment(
                value: false,
                label: Text('Income'),
                icon: Icon(Icons.add_circle_outline),
              ),
            ],
            selected: {_isExpense},
            onSelectionChanged: (Set<bool> selection) {
              setState(() {
                _isExpense = selection.first;
                _selectedCategory = null;
              });
            },
          ),
          const SizedBox(height: 16),

          // Amount
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            autofocus: true,
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              prefixText: '₹ ',
              hintText: '0',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Account
          Text('Account', style: textTheme.labelLarge),
          const SizedBox(height: 8),
          accountsAsync.when(
            data: (accounts) {
              // Auto-select most-used account
              if (_selectedAccount == null && accounts.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _selectedAccount == null) {
                    setState(() => _selectedAccount = accounts.first);
                  }
                });
              }
              return SizedBox(
                height: 60,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: accounts.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final acc = accounts[i];
                    final selected = _selectedAccount?.id == acc.id;
                    final unlockedIds = ref.watch(unlockedAccountIdsProvider);
                    final isUnlocked =
                        unlockedIds.valueOrNull?.contains(acc.id) ?? true;

                    return GestureDetector(
                      onTap: () {
                        if (isUnlocked) {
                          setState(() => _selectedAccount = acc);
                        } else {
                          HapticFeedback.mediumImpact();
                          _showUnlockPrompt(context, accounts.length);
                        }
                      },
                      child: Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? color.primaryContainer
                                  : isUnlocked
                                      ? color.surfaceContainerHighest
                                      : color.surfaceContainerHighest
                                          .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: selected
                                  ? Border.all(color: color.primary, width: 2)
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.account_balance_wallet,
                                  size: 20,
                                  color: isUnlocked
                                      ? (selected
                                          ? color.onPrimaryContainer
                                          : color.onSurface)
                                      : color.onSurfaceVariant
                                          .withValues(alpha: 0.4),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  acc.name,
                                  style: textTheme.labelSmall?.copyWith(
                                    color: isUnlocked
                                        ? (selected
                                            ? color.onPrimaryContainer
                                            : color.onSurface)
                                        : color.onSurfaceVariant
                                            .withValues(alpha: 0.4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isUnlocked)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Icon(
                                LucideIcons.lock,
                                size: 10,
                                color: color.primary,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const SizedBox(
              height: 60,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const SizedBox(
              height: 60,
              child: Text('Error loading accounts'),
            ),
          ),
          const SizedBox(height: 16),

          // Category
          Text('Category', style: textTheme.labelLarge),
          const SizedBox(height: 8),
          categoriesAsync.when(
            data: (categories) {
              final filtered = categories
                  .where((c) => c.parentCategory.value == null)
                  .toList();
              // Auto-select most-used category
              if (_selectedCategory == null && filtered.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _selectedCategory == null) {
                    setState(() => _selectedCategory = filtered.first);
                  }
                });
              }
              return SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final cat = filtered[i];
                    final selected = _selectedCategory?.id == cat.id;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: Container(
                        width: 80,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: selected
                              ? color.primaryContainer
                              : color.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: selected
                              ? Border.all(color: color.primary, width: 2)
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              IconHelper.iconFromName(
                                cat.iconName ?? 'category',
                              ),
                              color: Color(
                                cat.colorValue ?? color.primary.toARGB32(),
                              ),
                              size: 24,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              cat.name,
                              style: textTheme.labelSmall?.copyWith(
                                color: selected
                                    ? color.onPrimaryContainer
                                    : color.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const SizedBox(
              height: 80,
              child: Text('Error loading categories'),
            ),
          ),
          const SizedBox(height: 16),

          // Note
          TextField(
            controller: _noteController,
            decoration: InputDecoration(
              hintText: 'Add note (optional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Save Button
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Save Transaction',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showUnlockPrompt(BuildContext context, int totalAccounts) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: color.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Icon(LucideIcons.lock, size: 40, color: color.primary),
              const SizedBox(height: 16),
              Text(
                'Unlock all $totalAccounts accounts',
                style:
                    textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Free plan includes ${FreeTierLimits.maxAccounts} accounts. '
                'Upgrade to Pro to use all your accounts.',
                style: textTheme.bodyMedium
                    ?.copyWith(color: color.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context); // close quick add too
                    context.push(AppRoutes.upgrade);
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.sparkles, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Upgrade to Pro',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Maybe later',
                  style: textTheme.bodyMedium
                      ?.copyWith(color: color.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
