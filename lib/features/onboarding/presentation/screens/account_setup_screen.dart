import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:isar_community/isar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/user_profile.dart';
import 'package:mudra_manager/core/extension/localization_extenstion.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
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

  int _step = 0; // 0 = name, 1 = account
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _accountController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_step == 0) {
      if (_nameController.text.trim().isEmpty) {
        SnackbarService.error('Name is required');
        return;
      }
      HapticFeedback.lightImpact();
      setState(() => _step = 1);
    } else {
      _completeSetup();
    }
  }

  void _prevStep() {
    if (_step > 0) {
      HapticFeedback.lightImpact();
      setState(() => _step = 0);
    } else {
      context.go('/onboarding');
    }
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
    HapticFeedback.mediumImpact();

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
    final publicTransport = Category.create(
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

    final entertainment = Category.create(
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

      groceries.parentCategory.value = food;
      restaurant.parentCategory.value = food;
      fuel.parentCategory.value = transport;
      publicTransport.parentCategory.value = transport;
      clothing.parentCategory.value = shopping;
      electronics.parentCategory.value = shopping;
      electricity.parentCategory.value = bills;
      internet.parentCategory.value = bills;

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
    final spacing = ref.watch(spacingProvider);
    final ctxt = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = color.primary;

    return Scaffold(
      backgroundColor: color.surface,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ── TOP BAR ──
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.cardHorizontal,
                  vertical: spacing.cardVerticalMin,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        LucideIcons.chevronLeft,
                        color: color.onSurfaceVariant,
                      ),
                      onPressed: _prevStep,
                    ),
                    const Spacer(),
                    // Step indicator
                    Row(
                      children: List.generate(2, (i) {
                        final active = i <= _step;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: active ? 28 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: active
                                ? accent
                                : color.onSurfaceVariant.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // ── CONTENT ──
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.cardHorizontalMax + 8,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.05, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: _step == 0
                        ? _buildNameStep(
                            color,
                            textTheme,
                            spacing,
                            ctxt,
                            accent,
                            isDark,
                          )
                        : _buildAccountStep(
                            color,
                            textTheme,
                            spacing,
                            ctxt,
                            accent,
                            isDark,
                          ),
                  ),
                ),
              ),

              // ── BOTTOM BUTTONS ──
              Padding(
                padding: EdgeInsets.fromLTRB(
                  spacing.cardHorizontalMax + 8,
                  spacing.cardVertical,
                  spacing.cardHorizontalMax + 8,
                  spacing.cardVerticalMax + 8,
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _nextStep,
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(spacing.radiusMedium),
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
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _step == 0
                                        ? 'Continue'
                                        : ctxt.translate('onboard_GetStarted'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (_step == 1) ...[
                                    const SizedBox(width: 8),
                                    const Icon(
                                      LucideIcons.arrowRight,
                                      size: 18,
                                    ),
                                  ],
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Restore backup link
                    TextButton.icon(
                      onPressed: _isLoading ? null : _restoreBackup,
                      icon: Icon(
                        LucideIcons.archiveRestore,
                        size: 16,
                        color: color.onSurfaceVariant,
                      ),
                      label: Text(
                        'Restore from Backup',
                        style: textTheme.labelLarge?.copyWith(
                          color: color.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── STEP 1: NAME ──
  Widget _buildNameStep(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
    Color accent,
    bool isDark,
  ) {
    return Column(
      key: const ValueKey('name_step'),
      children: [
        const SizedBox(height: 32),
        // Hero icon
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutBack,
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) => Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Transform.scale(scale: value, child: child),
          ),
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: accent.withValues(alpha: 0.25),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: isDark ? 0.15 : 0.12),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accent.withValues(alpha: isDark ? 0.2 : 0.14),
                    accent.withValues(alpha: isDark ? 0.08 : 0.05),
                  ],
                ),
              ),
              child: Icon(LucideIcons.userRound, size: 48, color: accent),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          ctxt.translate('onboard_howShouldWeCallYou'),
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: color.onSurface,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          ctxt.translate('onboard_enterYourNameToPersonalizeYourExperience'),
          style: textTheme.bodyLarge?.copyWith(
            color: color.onSurfaceVariant,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 36),
        // Name field in grouped card
        Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: color.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(spacing.radiusMedium),
            side: BorderSide(
              color: color.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: ctxt.translate('onboard_enterYourName'),
                icon: Icon(LucideIcons.userRound, color: accent, size: 20),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _nextStep(),
            ),
          ),
        ),
      ],
    );
  }

  // ── STEP 2: ACCOUNT ──
  Widget _buildAccountStep(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
    Color accent,
    bool isDark,
  ) {
    return Column(
      key: const ValueKey('account_step'),
      children: [
        const SizedBox(height: 32),
        // Hero icon
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutBack,
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) => Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Transform.scale(scale: value, child: child),
          ),
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.25),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4CAF50)
                      .withValues(alpha: isDark ? 0.15 : 0.12),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF4CAF50)
                        .withValues(alpha: isDark ? 0.2 : 0.14),
                    const Color(0xFF4CAF50)
                        .withValues(alpha: isDark ? 0.08 : 0.05),
                  ],
                ),
              ),
              child: const Icon(
                LucideIcons.wallet,
                size: 48,
                color: Color(0xFF4CAF50),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          ctxt.translate('onboard_setupYourFirstAccount'),
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: color.onSurface,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          ctxt.translate('onboard_letsCreateYourFirstAccount'),
          style: textTheme.bodyLarge?.copyWith(
            color: color.onSurfaceVariant,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 36),
        // Account fields in grouped card
        Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: color.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(spacing.radiusMedium),
            side: BorderSide(
              color: color.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Account name
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: TextFormField(
                  controller: _accountController,
                  decoration: InputDecoration(
                    hintText: 'e.g., Cash, Bank',
                    icon: const Icon(
                      LucideIcons.wallet,
                      color: Color(0xFF4CAF50),
                      size: 20,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    label: Text(ctxt.translate('onboard_accountName')),
                  ),
                  validator: (v) => v?.trim().isEmpty ?? true
                      ? 'Account name is required'
                      : null,
                  textInputAction: TextInputAction.next,
                ),
              ),
              Divider(
                height: 1,
                indent: 52,
                color: color.outlineVariant.withValues(alpha: 0.4),
              ),
              // Balance
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: TextFormField(
                  controller: _balanceController,
                  decoration: InputDecoration(
                    hintText: '0',
                    icon: const Icon(
                      LucideIcons.indianRupee,
                      color: Color(0xFF4CAF50),
                      size: 20,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    label: Text(ctxt.onboard_initialBalance),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v?.trim().isEmpty ?? true) return 'Balance is required';
                    if (double.tryParse(v!) == null) {
                      return 'Enter valid number';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _nextStep(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Info hint
        Row(
          children: [
            Icon(
              LucideIcons.info,
              size: 14,
              color: color.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 6),
            Text(
              ctxt.onboard_youCanUpdateOtherDetailsLaterAsWell,
              style: textTheme.bodySmall?.copyWith(
                color: color.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
