import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/user_profile.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';
import 'package:mudra_manager/core/services/backup_restore_service.dart';
import 'package:mudra_manager/core/utils/dialog_utils.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';

class AccountSetupScreen extends ConsumerStatefulWidget {
  const AccountSetupScreen({super.key});

  @override
  ConsumerState<AccountSetupScreen> createState() => _AccountSetupScreenState();
}

class _AccountSetupScreenState extends ConsumerState<AccountSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _accountController = TextEditingController(text: 'Cash');
  final _balanceController = TextEditingController(text: '0');

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _accountController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _restoreBackup() async {
    try {
      final password = await DialogUtils.showPasswordDialog(
        context,
        isRestore: true,
      );
      if (password == null) return;

      setState(() => _isLoading = true);

      final isar = await ref.read(isarServiceProvider).getInstance();
      final data = await BackupService.restoreEncryptedBackup(
        context,
        isar,
        password,
      );

      if (data != null) {
        SharedPrefsUtil.instance.setOnboardingComplete();
        if (mounted) {
          SnackbarService.success('Backup restored successfully');
          context.go('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarService.error('Restore failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _completeSetup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final isar = await ref.read(isarServiceProvider).getInstance();

      await isar.writeTxn(() async {
        await isar.userProfiles.put(
          UserProfile()..name = _nameController.text.trim(),
        );

        await isar.accounts.put(
          Account()
            ..name = _accountController.text.trim()
            ..accountType = AccountType.cash
            ..colorValue = Colors.green.toARGB32()
            ..accountNumber = '0000'
            ..initialBalance = double.parse(_balanceController.text.trim()),
        );
      });

      await _createDefaultCategories(isar);
      SharedPrefsUtil.instance.setOnboardingComplete();

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        SnackbarService.error('Setup failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _createDefaultCategories(Isar isar) async {
    final existing = await isar.categorys.where().findAll();
    if (existing.isNotEmpty) return;

    // Income categories
    final salary =
        Category.create(name: 'Salary', categoryType: CategoryType.income)
          ..iconName = 'attach_money'
          ..colorValue = Colors.green.toARGB32();
    final business =
        Category.create(name: 'Business', categoryType: CategoryType.income)
          ..iconName = 'business'
          ..colorValue = Colors.teal.toARGB32();
    final investment =
        Category.create(name: 'Investment', categoryType: CategoryType.income)
          ..iconName = 'trending_up'
          ..colorValue = Colors.blue.toARGB32();
    final other =
        Category.create(name: 'Other Income', categoryType: CategoryType.income)
          ..iconName = 'account_balance_wallet'
          ..colorValue = Colors.lightGreen.toARGB32();

    // Expense categories with subcategories
    final food =
        Category.create(name: 'Food', categoryType: CategoryType.expense)
          ..iconName = 'restaurant'
          ..colorValue = Colors.orange.toARGB32();
    final groceries =
        Category.create(name: 'Groceries', categoryType: CategoryType.expense)
          ..iconName = 'shopping_cart'
          ..colorValue = Colors.deepOrange.toARGB32();
    final restaurant =
        Category.create(name: 'Restaurant', categoryType: CategoryType.expense)
          ..iconName = 'fastfood'
          ..colorValue = Colors.orangeAccent.toARGB32();

    final transport =
        Category.create(name: 'Transport', categoryType: CategoryType.expense)
          ..iconName = 'directions_car'
          ..colorValue = Colors.purple.toARGB32();
    final fuel =
        Category.create(name: 'Fuel', categoryType: CategoryType.expense)
          ..iconName = 'local_gas_station'
          ..colorValue = Colors.deepPurple.toARGB32();
    final publicTransport =
        Category.create(
            name: 'Public Transport',
            categoryType: CategoryType.expense,
          )
          ..iconName = 'directions_bus'
          ..colorValue = Colors.purpleAccent.toARGB32();

    final shopping =
        Category.create(name: 'Shopping', categoryType: CategoryType.expense)
          ..iconName = 'shopping_bag'
          ..colorValue = Colors.red.toARGB32();
    final clothing =
        Category.create(name: 'Clothing', categoryType: CategoryType.expense)
          ..iconName = 'checkroom'
          ..colorValue = Colors.redAccent.toARGB32();
    final electronics =
        Category.create(name: 'Electronics', categoryType: CategoryType.expense)
          ..iconName = 'devices'
          ..colorValue = Colors.pink.toARGB32();

    final bills =
        Category.create(name: 'Bills', categoryType: CategoryType.expense)
          ..iconName = 'receipt'
          ..colorValue = Colors.brown.toARGB32();
    final electricity =
        Category.create(name: 'Electricity', categoryType: CategoryType.expense)
          ..iconName = 'bolt'
          ..colorValue = Colors.amber.toARGB32();
    final internet =
        Category.create(name: 'Internet', categoryType: CategoryType.expense)
          ..iconName = 'wifi'
          ..colorValue = Colors.blueGrey.toARGB32();

    final entertainment =
        Category.create(
            name: 'Entertainment',
            categoryType: CategoryType.expense,
          )
          ..iconName = 'movie'
          ..colorValue = Colors.indigo.toARGB32();
    final healthcare =
        Category.create(name: 'Healthcare', categoryType: CategoryType.expense)
          ..iconName = 'local_hospital'
          ..colorValue = Colors.cyan.toARGB32();
    final education =
        Category.create(name: 'Education', categoryType: CategoryType.expense)
          ..iconName = 'school'
          ..colorValue = Colors.lime.toARGB32();

    await isar.writeTxn(() async {
      // Save parent categories first
      await isar.categorys.putAll([
        salary,
        business,
        investment,
        other,
        food,
        transport,
        shopping,
        bills,
        entertainment,
        healthcare,
        education,
      ]);

      // Set up subcategories
      groceries.parentCategory.value = food;
      restaurant.parentCategory.value = food;
      fuel.parentCategory.value = transport;
      publicTransport.parentCategory.value = transport;
      clothing.parentCategory.value = shopping;
      electronics.parentCategory.value = shopping;
      electricity.parentCategory.value = bills;
      internet.parentCategory.value = bills;

      // Save subcategories
      await isar.categorys.putAll([
        groceries,
        restaurant,
        fuel,
        publicTransport,
        clothing,
        electronics,
        electricity,
        internet,
      ]);

      // Save relationships
      await groceries.parentCategory.save();
      await restaurant.parentCategory.save();
      await fuel.parentCategory.save();
      await publicTransport.parentCategory.save();
      await clothing.parentCategory.save();
      await electronics.parentCategory.save();
      await electricity.parentCategory.save();
      await internet.parentCategory.save();
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: color.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.account_circle,
                    size: 48,
                    color: color.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Set Up Your Account',
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Let\'s personalize your experience',
                  style: textTheme.bodyLarge?.copyWith(
                    color: color.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 40),

                // Name Field
                Text(
                  'Your Name',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Enter your name',
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: color.primary,
                    ),
                  ),
                  validator: (v) =>
                      v?.trim().isEmpty ?? true ? 'Name is required' : null,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 24),

                // Account Name Field
                Text(
                  'First Account',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _accountController,
                  decoration: InputDecoration(
                    hintText: 'e.g., Cash, Bank',
                    prefixIcon: Icon(Icons.wallet, color: color.primary),
                  ),
                  validator: (v) => v?.trim().isEmpty ?? true
                      ? 'Account name is required'
                      : null,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 24),

                // Balance Field
                Text(
                  'Initial Balance',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _balanceController,
                  decoration: InputDecoration(
                    hintText: '0',
                    prefixIcon: Icon(
                      Icons.currency_rupee,
                      color: color.primary,
                    ),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) {
                    if (v?.trim().isEmpty ?? true) return 'Balance is required';
                    if (double.tryParse(v!) == null)
                      return 'Enter valid number';
                    return null;
                  },
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _completeSetup(),
                ),
                const SizedBox(height: 12),
                Text(
                  'You can add more accounts later',
                  style: textTheme.bodySmall?.copyWith(
                    color: color.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 40),

                // Continue Button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _completeSetup,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: color.onPrimary,
                            ),
                          )
                        : const Text('Get Started'),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _restoreBackup,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.restore),
                    label: const Text('Restore from Backup'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
