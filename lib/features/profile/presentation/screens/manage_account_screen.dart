import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/extension/account_type_extenstion.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/utils/dialog_utils.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/account/data/account_providers.dart';

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
      final balanceMap = ref
          .watch(accountServiceProvider)
          .getAccountBalanceMap();
      balanceMap.then(
        (val) => {
          setState(() {
            _balanceMap = val;
          }),
        },
      );
      _initialized = true;
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
      ),
      body: accountsAsync.when(
        data: (accounts) {
          if (accounts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 64,
                    color: color.onSurface,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No accounts added yet',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: accounts.length + 1,
            itemBuilder: (context, index) {
              if (accounts.length != index) {
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
                      showArchiveConfirmation(context, ref, account);
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
                );
              } else {
                return const Padding(padding: EdgeInsets.only(bottom: 80.0));
              }
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/manage-accounts/add');
        },
        icon: const Icon(Icons.add),
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
  ) async {
    final isarService = ref.read(isarServiceProvider);
    final isar = await isarService.getInstance();
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    final ctxt = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctxt.accounts_archiveAccountTitle),
        content: Text(ctxt.accounts_archiveAccountMessage(account.name)),
        actions: [
          OutlinedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              context.pop(false);
            },
            child: Text(
              ctxt.accounts_cancelLabel,
              style: textTheme.titleMedium?.copyWith(color: color.onSurface),
            ),
          ),
          OutlinedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              context.pop(true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: color.secondary),
            child: Text(
              ctxt.accounts_archiveLabel,
              style: textTheme.titleMedium?.copyWith(color: color.onPrimary),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await isar.writeTxn(() async {
        account.isActive = false;
        await isar.accounts.put(account);
      });
      ref.invalidate(accountsProvider);

      SnackbarService.success(
        ctxt.accounts_accountArchivedMessage(account.name),
      );
    }
  }
}

class _AccountListCard extends StatelessWidget {
  final Account account;
  final String balance;
  final VoidCallback onEdit;
  final VoidCallback onArchive;
  final VoidCallback onRemove;

  const _AccountListCard({
    required this.account,
    required this.balance,
    required this.onEdit,
    required this.onArchive,
    required this.onRemove,
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
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                  SizedBox(
                    height: 24,
                    child: PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        color: color.onSurfaceVariant,
                      ),
                      padding: EdgeInsets.zero,
                      onSelected: (value) {
                        if (value == 'edit') onEdit();
                        if (value == 'archive') onArchive();
                        if (value == 'delete') onRemove();
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, color: color.primary),
                              const SizedBox(width: 8),
                              const Text('Edit'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'archive',
                          child: Row(
                            children: [
                              Icon(Icons.archive, color: color.primary),
                              const SizedBox(width: 8),
                              const Text('Archive'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: color.error),
                              const SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(color: color.error),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
