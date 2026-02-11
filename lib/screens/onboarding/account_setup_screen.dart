import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/db/models/account.dart';
import 'package:mudra_manager/db/models/category.dart';
import 'package:mudra_manager/db/models/user_profile.dart';
import 'package:mudra_manager/providers/isar_provider.dart';
import 'package:mudra_manager/providers/shared_preference_provider.dart';
import 'package:mudra_manager/util/snackbar_service.dart';

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

    final categories = [
      Category.create(name: 'Salary', categoryType: CategoryType.income)
        ..iconName = 'attach_money'
        ..colorValue = Colors.green.toARGB32(),
      Category.create(name: 'Investment', categoryType: CategoryType.income)
        ..iconName = 'trending_up'
        ..colorValue = Colors.teal.toARGB32(),
      Category.create(name: 'Food', categoryType: CategoryType.expense)
        ..iconName = 'fastfood'
        ..colorValue = Colors.orange.toARGB32(),
      Category.create(name: 'Transport', categoryType: CategoryType.expense)
        ..iconName = 'directions_car'
        ..colorValue = Colors.purple.toARGB32(),
      Category.create(name: 'Shopping', categoryType: CategoryType.expense)
        ..iconName = 'shopping_bag'
        ..colorValue = Colors.red.toARGB32(),
    ];

    await isar.writeTxn(() => isar.categorys.putAll(categories));
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
                  child: Icon(Icons.account_circle, size: 48, color: color.onPrimaryContainer),
                ),
                const SizedBox(height: 24),
                Text(
                  'Set Up Your Account',
                  style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Let\'s personalize your experience',
                  style: textTheme.bodyLarge?.copyWith(color: color.onSurfaceVariant),
                ),
                const SizedBox(height: 40),
                
                // Name Field
                Text('Your Name', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Enter your name',
                    prefixIcon: Icon(Icons.person_outline, color: color.primary),
                  ),
                  validator: (v) => v?.trim().isEmpty ?? true ? 'Name is required' : null,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 24),
                
                // Account Name Field
                Text('First Account', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _accountController,
                  decoration: InputDecoration(
                    hintText: 'e.g., Cash, Bank',
                    prefixIcon: Icon(Icons.wallet, color: color.primary),
                  ),
                  validator: (v) => v?.trim().isEmpty ?? true ? 'Account name is required' : null,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 24),
                
                // Balance Field
                Text('Initial Balance', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _balanceController,
                  decoration: InputDecoration(
                    hintText: '0',
                    prefixIcon: Icon(Icons.currency_rupee, color: color.primary),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v?.trim().isEmpty ?? true) return 'Balance is required';
                    if (double.tryParse(v!) == null) return 'Enter valid number';
                    return null;
                  },
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _completeSetup(),
                ),
                const SizedBox(height: 12),
                Text(
                  'You can add more accounts later',
                  style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
                ),
                const SizedBox(height: 40),
                
                // Continue Button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _completeSetup,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
