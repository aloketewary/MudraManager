import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/db/models/account.dart'
    show Account, GetAccountCollection;
import 'package:mudra_manager/providers/account_providers.dart';
import 'package:mudra_manager/providers/isar_provider.dart';
import 'package:mudra_manager/screens/dashboard/dashboard_animated_card.dart'
    show AnimatedAccountCard;
import 'package:mudra_manager/screens/profile/account_form.dart'
    show AccountForm;

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

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          "Manage Accounts",
          style: textTheme.titleLarge?.copyWith(color: color.onPrimary),
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
            itemCount: accounts.length + 1,
            itemBuilder: (context, index) {
              if (accounts.length != index) {
                final account = accounts[index];
                return AnimatedAccountCard(
                  totalBalance:
                      _balanceMap[account.id]?.toStringAsFixed(2) ?? '0.0',
                  accountNumber:
                      'xxxx xxxx xxxx ${account.accountNumber ?? 'xxxx'}',
                  accountName: account.name,
                  backgroundColor: color.primary,
                  accentColor: Color(
                    account.colorValue ?? Colors.redAccent.toARGB32(),
                  ),
                  accountType: account.accountType,
                  onArchive: () {
                    if (accounts.length == 1) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'At least 1 accounts required to continue',
                          ),
                        ),
                      );
                    } else {
                      showArchiveConfirmation(context, ref, account);
                    }
                  },
                  onEdit: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AccountForm(account: account),
                      ),
                    );
                  },
                  onRemove: () {},
                  showMenu: true,
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
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const AccountForm()));
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
    final isarService = ref.read(isarServiceProvider);
    final isar = await isarService.getInstance();
    var textTheme = Theme.of(context).textTheme;
    var color = Theme.of(context).colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Account'),
            content: Text('Are you sure you want to delete "${account.name}"?'),
            actions: [
              OutlinedButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(
                  'Cancel',
                  style: textTheme.titleMedium?.copyWith(
                    color: color.onSurface,
                  ),
                ),
              ),
              OutlinedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: color.error),
                child: Text(
                  'Delete',
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
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(
                  'Cancel',
                  style: textTheme.titleMedium?.copyWith(
                    color: color.onSurface,
                  ),
                ),
              ),
              OutlinedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('"${account.name}" archived')));
    }
  }
}
