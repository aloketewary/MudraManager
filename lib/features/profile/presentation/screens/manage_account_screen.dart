import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/extension/account_type_extenstion.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/dialog_utils.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/account/data/account_providers.dart';
import 'package:mudra_manager/features/account/presentation/screens/balance_history_screen.dart';
import 'package:mudra_manager/features/account/presentation/screens/reconciliation_screen.dart';
import 'package:mudra_manager/features/account/presentation/screens/investment_portfolio_screen.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:mudra_manager/shared/widgets/no_data_found.dart';
import 'package:mudra_manager/core/widgets/skeleton_loader.dart';

class ManageAccountScreen extends ConsumerStatefulWidget {
  const ManageAccountScreen({super.key});

  @override
  ConsumerState<ManageAccountScreen> createState() =>
      _ManageAccountScreenState();
}

class _ManageAccountScreenState extends ConsumerState<ManageAccountScreen> {
  Map<int, double> _balanceMap = {};
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      ref.read(accountServiceProvider).getAccountBalanceMap().then((val) {
        if (mounted) setState(() => _balanceMap = val);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final accountsAsync = ref.watch(accountsProvider);
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          ctxt.accounts_manageAccountsTitle,
          style: textTheme.titleLarge,
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus),
            onPressed: () {
              HapticFeedback.mediumImpact();
              context.push('/manage-accounts/add');
            },
            tooltip: ctxt.accounts_addAccountLabel,
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              HapticFeedback.mediumImpact();
              _showInfoBottomSheet(context, color, textTheme);
            },
          ),
        ],
      ),
      body: accountsAsync.when(
        data: (accounts) {
          if (accounts.isEmpty) {
            return NoDataFound(
              message: 'No accounts added yet',
              iconData: Icons.account_balance_wallet_outlined,
              action: ElevatedButton.icon(
                onPressed: () => context.push('/manage-accounts/add'),
                icon: const Icon(Icons.add),
                label: Text(ctxt.accounts_addAccountLabel),
              ),
            );
          }

          // Group accounts by type
          final grouped = <AccountType, List<Account>>{};
          for (final account in accounts) {
            grouped.putIfAbsent(account.accountType, () => []).add(account);
          }

          final totalBalance = _balanceMap.values.fold(0.0, (a, b) => a + b);

          return ListView(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.cardHorizontal,
              vertical: spacing.cardVertical,
            ),
            children: [
              // Total balance summary
              _buildSummaryCard(
                totalBalance,
                accounts.length,
                color,
                textTheme,
                spacing,
              ),
              SizedBox(height: spacing.sectionGap),

              // Grouped account sections
              ...grouped.entries.map((entry) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTypeHeader(entry.key, color, textTheme),
                    const SizedBox(height: 8),
                    _buildAccountGroup(
                      entry.value,
                      color,
                      textTheme,
                      ctxt,
                      spacing,
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              }),
            ],
          );
        },
        loading: () => ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: 5,
          itemBuilder: (context, index) => const SkeletonListTile(),
        ),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  // ── SUMMARY CARD ──
  Widget _buildSummaryCard(
    double totalBalance,
    int accountCount,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.primaryContainer,
            color.secondaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Balance',
            style: textTheme.labelLarge?.copyWith(
              color: color.onPrimaryContainer.withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: spacing.elementGap),
          CurrencyText(
            amount: totalBalance,
            compact: false,
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: color.onPrimaryContainer,
            ),
          ),
          SizedBox(height: spacing.sectionGap),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.cardHorizontal,
              vertical: spacing.cardVertical,
            ),
            decoration: BoxDecoration(
              color: color.onPrimaryContainer.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
            ),
            child: Text(
              '$accountCount accounts',
              style: textTheme.labelSmall?.copyWith(
                color: color.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── TYPE HEADER ──
  Widget _buildTypeHeader(
    AccountType type,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Icon(type.icon, size: 16, color: color.primary),
          const SizedBox(width: 8),
          Text(
            type.label,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: color.primary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── GROUPED ACCOUNT CARD ──
  Widget _buildAccountGroup(
    List<Account> accounts,
    ColorScheme color,
    TextTheme textTheme,
    AppLocalizations ctxt,
    AppSpacing spacing,
  ) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(),
      color: color.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        side: BorderSide(
          color: color.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: accounts.asMap().entries.map((entry) {
          final account = entry.value;
          final isLast = entry.key == accounts.length - 1;
          final accountColor =
              Color(account.colorValue ?? Colors.blue.toARGB32());
          final balance = _balanceMap[account.id] ?? 0.0;

          return Column(
            children: [
              InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showContextOptions(
                    context,
                    account,
                    balance,
                    accounts.length,
                    ctxt,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Hero(
                        tag: 'account_${account.id}',
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: accountColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            account.accountType.icon,
                            color: accountColor,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              account.name,
                              style: textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (account.accountNumber != null)
                              Text(
                                '•••• ${account.accountNumber}',
                                style: textTheme.bodySmall?.copyWith(
                                  color: color.onSurfaceVariant,
                                  letterSpacing: 1.2,
                                ),
                              ),
                          ],
                        ),
                      ),
                      CurrencyText(
                        amount: balance,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: balance >= 0 ? accountColor : color.error,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        LucideIcons.chevronRight,
                        color: color.onSurfaceVariant,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 60,
                  color: color.outlineVariant.withValues(alpha: 0.4),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── CONTEXT BOTTOM SHEET ──
  void _showContextOptions(
    BuildContext context,
    Account account,
    double balance,
    int totalAccounts,
    AppLocalizations ctxt,
  ) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.read(spacingProvider);
    final accountColor = Color(account.colorValue ?? Colors.blue.toARGB32());

    showModalBottomSheet(
      context: context,
      backgroundColor: color.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(spacing.radiusLarge)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: spacing.elementGap),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: color.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: spacing.sectionGap),
              // Account header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: spacing.cardInner),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(spacing.radiusMedium),
                      decoration: BoxDecoration(
                        color: accountColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(spacing.radiusMedium),
                      ),
                      child: Icon(
                        account.accountType.icon,
                        color: accountColor,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: spacing.elementGap + 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            account.name,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          CurrencyText(
                            amount: balance,
                            style: textTheme.bodyMedium?.copyWith(
                              color: accountColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: spacing.elementGap),
              const Divider(height: 1),
              _sheetOption(
                ctx,
                Icons.edit_outlined,
                'Edit Account',
                null,
                color.primary,
                () {
                  Navigator.pop(ctx);
                  context.push(
                    '/manage-accounts/add',
                    extra: {'account': account},
                  );
                },
              ),
              _sheetOption(
                ctx,
                Icons.history,
                'Balance History',
                null,
                color.primary,
                () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BalanceHistoryScreen(account: account),
                    ),
                  );
                },
              ),
              _sheetOption(
                ctx,
                Icons.verified_user_outlined,
                'Reconcile',
                'Match with bank statement',
                color.primary,
                () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReconciliationScreen(account: account),
                    ),
                  );
                },
              ),
              if (account.accountType == AccountType.investment)
                _sheetOption(
                  ctx,
                  Icons.trending_up,
                  'View Portfolio',
                  null,
                  color.primary,
                  () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            InvestmentPortfolioScreen(account: account),
                      ),
                    );
                  },
                ),
              const Divider(height: 1),
              _sheetOption(
                ctx,
                Icons.archive_outlined,
                'Archive',
                'Hide from active accounts',
                color.onSurfaceVariant,
                () {
                  Navigator.pop(ctx);
                  if (totalAccounts == 1) {
                    SnackbarService.warning(
                      ctxt.accounts_atLeastOneAccountRequired,
                    );
                  } else {
                    _showArchiveConfirmation(account, ctxt);
                  }
                },
              ),
              _sheetOption(
                ctx,
                Icons.delete_outline,
                'Delete',
                'Permanently remove account',
                color.error,
                () {
                  Navigator.pop(ctx);
                  _showDeleteConfirmation(account, ctxt);
                },
              ),
              SizedBox(height: spacing.elementGap),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetOption(
    BuildContext ctx,
    IconData icon,
    String title,
    String? subtitle,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: iconColor == Theme.of(ctx).colorScheme.error
            ? TextStyle(color: iconColor)
            : null,
      ),
      subtitle: subtitle != null ? Text(subtitle) : null,
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
    );
  }

  // ── ACTIONS ──

  Future<void> _showDeleteConfirmation(
    Account account,
    AppLocalizations ctxt,
  ) async {
    final confirmed = await DialogUtils.showDeleteConfirmation(
      context,
      title: ctxt.accounts_deleteAccountTitle,
      message: ctxt.accounts_deleteAccountMessage(account.name),
    );

    if (confirmed == true) {
      final isarService = ref.read(isarServiceProvider);
      final isar = await isarService.getInstance();
      await isar.writeTxn(() async {
        await isar.accounts.delete(account.id);
      });
      ref.invalidate(accountsProvider);
    }
  }

  Future<void> _showArchiveConfirmation(
    Account account,
    AppLocalizations ctxt,
  ) async {
    final confirmed = await DialogUtils.showConfirmation(
      context,
      title: ctxt.accounts_archiveAccountTitle,
      message: ctxt.accounts_archiveAccountMessage(account.name),
      icon: LucideIcons.archive,
    );

    if (confirmed == true) {
      final isarService = ref.read(isarServiceProvider);
      final isar = await isarService.getInstance();
      await isar.writeTxn(() async {
        account.isActive = false;
        await isar.accounts.put(account);
      });
      ref.invalidate(accountsProvider);

      if (mounted) {
        SnackbarService.success(
          ctxt.accounts_accountArchivedMessage(account.name),
        );
      }
    }
  }

  void _showInfoBottomSheet(
    BuildContext context,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: color.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
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
                Icon(
                  Icons.account_balance_wallet,
                  size: 64,
                  color: color.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'How Accounts Work',
                  style: textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  'Manage all your bank accounts, wallets, and cash in one place. Track balances and transactions across multiple accounts.',
                  style: textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
