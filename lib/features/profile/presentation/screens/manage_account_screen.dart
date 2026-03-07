import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/keep/v1.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/extension/account_type_extenstion.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/utils/dialog_utils.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/account/data/account_providers.dart';
import 'package:mudra_manager/features/account/presentation/screens/balance_history_screen.dart';
import 'package:mudra_manager/features/account/presentation/screens/reconciliation_screen.dart';
import 'package:mudra_manager/features/account/presentation/screens/investment_portfolio_screen.dart';
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
        if (mounted) {
          setState(() => _balanceMap = val);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              final account = accounts[index];
              return _AccountListCard(
                account: account,
                balance: _balanceMap[account.id]?.toStringAsFixed(2) ?? '0.0',
                onArchive: () {
                  if (accounts.length == 1) {
                    SnackbarService.warning(
                      ctxt.accounts_atLeastOneAccountRequired,
                    );
                  } else {
                    showArchiveConfirmation(context, ref, account, ctxt);
                  }
                },
                onEdit: () {
                  context.push(
                    '/manage-accounts/add',
                    extra: {'account': account},
                  );
                },
                onRemove: () =>
                    showDeleteConfirmation(context, ref, account, ctxt),
                onViewHistory: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) =>
                          BalanceHistoryScreen(account: account),
                    ),
                  );
                },
                onReconcile: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) =>
                          ReconciliationScreen(account: account),
                    ),
                  );
                },
                onViewPortfolio: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) =>
                          InvestmentPortfolioScreen(account: account),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: 5,
          itemBuilder: (context, index) => const SkeletonListTile(),
        ),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/manage-accounts/add');
        },
        icon: const Icon(LucideIcons.plus),
        label: Text(ctxt.accounts_addAccountLabel),
      ),
    );
  }

  Future<void> showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
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

  Future<void> showArchiveConfirmation(
    BuildContext context,
    WidgetRef ref,
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
                Icon(Icons.account_balance_wallet, size: 64, color: color.primary),
                const SizedBox(height: 16),
                Text(
                  'How Accounts Work',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Manage all your bank accounts, wallets, and cash in one place. Track balances and transactions across multiple accounts.',
                  style: textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => ctx.pop(),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Got it'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountListCard extends StatelessWidget {
  final Account account;
  final String balance;
  final VoidCallback onEdit;
  final VoidCallback onArchive;
  final VoidCallback onRemove;
  final VoidCallback onViewHistory;
  final VoidCallback onReconcile;
  final VoidCallback onViewPortfolio;

  const _AccountListCard({
    required this.account,
    required this.balance,
    required this.onEdit,
    required this.onArchive,
    required this.onRemove,
    required this.onViewHistory,
    required this.onReconcile,
    required this.onViewPortfolio,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final accountColor = Color(account.colorValue ?? Colors.blue.toARGB32());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: color.surfaceContainerHighest,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          HapticFeedback.lightImpact();
          _showContextOptions(context);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Hero(
                tag: 'account_${account.id}',
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accountColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    account.accountType.icon,
                    color: accountColor,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      style: textTheme.titleMedium?.copyWith(
                        color: color.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '•••• ${account.accountNumber ?? "XXXX"}',
                      style: textTheme.bodySmall?.copyWith(
                        color: color.onSurfaceVariant,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    balance,
                    style: textTheme.titleMedium?.copyWith(
                      color: accountColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    LucideIcons.chevronRight,
                    color: color.onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContextOptions(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final accountColor = Color(account.colorValue ?? Colors.blue.toARGB32());

    showModalBottomSheet(
      context: context,
      backgroundColor: color.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: color.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: accountColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        account.accountType.icon,
                        color: accountColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
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
                          Text(
                            '₹$balance',
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
              const SizedBox(height: 8),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.edit_outlined, color: color.primary),
                title: const Text('Edit Account'),
                onTap: () {
                  Navigator.pop(ctx);
                  onEdit();
                },
              ),
              ListTile(
                leading: Icon(Icons.history, color: color.primary),
                title: const Text('Balance History'),
                onTap: () {
                  Navigator.pop(ctx);
                  onViewHistory();
                },
              ),
              ListTile(
                leading: Icon(Icons.verified_user_outlined, color: color.primary),
                title: const Text('Reconcile'),
                subtitle: const Text('Match with bank statement'),
                onTap: () {
                  Navigator.pop(ctx);
                  onReconcile();
                },
              ),
              if (account.accountType.name == 'investment')
                ListTile(
                  leading: Icon(Icons.trending_up, color: color.primary),
                  title: const Text('View Portfolio'),
                  onTap: () {
                    Navigator.pop(ctx);
                    onViewPortfolio();
                  },
                ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.archive_outlined, color: color.onSurfaceVariant),
                title: const Text('Archive'),
                subtitle: const Text('Hide from active accounts'),
                onTap: () {
                  Navigator.pop(ctx);
                  onArchive();
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: color.error),
                title: Text('Delete', style: TextStyle(color: color.error)),
                subtitle: const Text('Permanently remove account'),
                onTap: () {
                  Navigator.pop(ctx);
                  onRemove();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
