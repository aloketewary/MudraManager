import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/db/models/account.dart'
    show Account, GetAccountCollection;
import 'package:mudra_manager/providers/account_providers.dart';
import 'package:mudra_manager/providers/isar_provider.dart';
import 'package:mudra_manager/theme/app_colors.dart';
import 'package:mudra_manager/util/account_type_extension.dart';
import 'package:mudra_manager/util/dialog_utils.dart';
import 'package:mudra_manager/util/snackbar_service.dart';

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
      final balanceMap =
          ref.watch(accountServiceProvider).getAccountBalanceMap();
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
    var color = Theme.of(context).colorScheme;
    final accountsAsync = ref.watch(accountsProvider);
    var textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text("Manage Accounts", style: textTheme.titleLarge),
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
            padding: EdgeInsets.all(16),
            itemCount: accounts.length + 1,
            itemBuilder: (context, index) {
              if (accounts.length != index) {
                final account = accounts[index];
                return _AccountListCard(
                  account: account,
                  balance: _balanceMap[account.id]?.toStringAsFixed(2) ?? '0.0',
                  isDark: isDark,
                  onArchive: () {
                    if (accounts.length == 1) {
                      SnackbarService.warning(
                        'At least 1 account required to continue',
                      );
                    } else {
                      showArchiveConfirmation(context, ref, account);
                    }
                  },
                  onEdit: () {
                    context.push('/manage-accounts/add', extra: {'account': account});
                  },
                  onRemove: () => showDeleteConfirmation(context, ref, account),
                );
              } else {
                return Padding(padding: EdgeInsets.only(bottom: 80.0));
              }
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/manage-accounts/add');
        },
        icon: const Icon(Icons.add),
        label: Text("Add Account"),
      ),
    );
  }

  Future<void> showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    Account account,
  ) async {
    final confirmed = await DialogUtils.showDeleteConfirmation(
      context,
      title: 'Delete Account',
      message: 'Are you sure you want to delete "${account.name}"?',
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
    var textTheme = Theme.of(context).textTheme;
    var color = Theme.of(context).colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Archive Account'),
            content: Text(
              'Are you sure you want to archive "${account.name}"?',
            ),
            actions: [
              OutlinedButton(
                onPressed: () {
              HapticFeedback.mediumImpact();
              context.pop(false);
            },
                child: Text(
                  'Cancel',
                  style: textTheme.titleMedium?.copyWith(
                    color: color.onSurface,
                  ),
                ),
              ),
              OutlinedButton(
                onPressed: () {
              HapticFeedback.mediumImpact();
              context.pop(true);
            },
                style: ElevatedButton.styleFrom(
                  backgroundColor: color.secondary,
                ),
                child: Text(
                  'Archive',
                  style: textTheme.titleMedium?.copyWith(
                    color: color.onPrimary,
                  ),
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

      SnackbarService.success('"${account.name}" archived');
    }
  }
}

class _AccountListCard extends StatelessWidget {
  final Account account;
  final String balance;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onArchive;
  final VoidCallback onRemove;

  const _AccountListCard({
    required this.account,
    required this.balance,
    required this.isDark,
    required this.onEdit,
    required this.onArchive,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final accountColor = Color(account.colorValue ?? Colors.blue.value);
    final gradientColors = AppColors.glassGradient(accountColor, isDark);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accountColor.withValues(alpha: 0.3), width: 1.5),
        boxShadow: AppColors.glassShadow(accountColor, isDark),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: accountColor.withValues(alpha: 0.15), blurRadius: 12, offset: Offset(0, 4))],
                  ),
                  child: Icon(
                    account.accountType.icon,
                    color: accountColor,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.name,
                        style: textTheme.titleMedium?.copyWith(
                          color: accountColor,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '•••• ${account.accountNumber ?? "XXXX"}',
                        style: textTheme.bodyMedium?.copyWith(
                          color: accountColor.withValues(alpha: 0.75),
                          letterSpacing: 2,
                          fontSize: 13,
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
                      style: textTheme.titleLarge?.copyWith(
                        color: accountColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 24,
                      child: PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_horiz,
                          color: accountColor.withValues(alpha: 0.7),
                        ),
                        padding: EdgeInsets.zero,
                        onSelected: (value) {
                          if (value == 'edit') onEdit();
                          if (value == 'archive') onArchive();
                          if (value == 'delete') onRemove();
                        },
                        itemBuilder:
                            (context) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, color: color.secondary),
                                    const SizedBox(width: 8),
                                    const Text('Edit'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'archive',
                                child: Row(
                                  children: [
                                    Icon(Icons.archive, color: color.secondary),
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
      ),
    );
  }
}
