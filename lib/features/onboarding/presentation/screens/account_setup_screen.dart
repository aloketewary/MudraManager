import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/user_profile.dart';
import 'package:mudra_manager/core/entitlement/entitlement_provider.dart';
import 'package:mudra_manager/core/extension/localization_extenstion.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/services/backup_restore_service.dart';
import 'package:mudra_manager/core/utils/dialog_utils.dart';
import 'package:mudra_manager/core/utils/icon_helper.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/category/data/category_management_service.dart';
import 'package:mudra_manager/plugins/category_packs/category_pack.dart';
import 'package:mudra_manager/core/router/app_routes.dart';

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

  int _step = 0; // 0 = name, 1 = account, 2 = pack picker
  bool _isLoading = false;
  bool _startFresh = false;
  final Set<String> _selectedPackIds = {'com.mudra.pack.default'};

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
    } else if (_step == 1) {
      if (!_formKey.currentState!.validate()) return;
      HapticFeedback.lightImpact();
      setState(() => _step = 2);
    } else {
      _completeSetup();
    }
  }

  void _prevStep() {
    if (_step > 0) {
      HapticFeedback.lightImpact();
      setState(() => _step--);
    } else {
      context.go(AppRoutes.onboarding);
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
          context.go(AppRoutes.home);
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

      if (!_startFresh && _selectedPackIds.isNotEmpty) {
        await CategoryManagementService.installPacks(
          _selectedPackIds.toList(),
        );
      }

      SharedPrefsUtil.instance.setOnboardingComplete();
      // Stamp install date for trial period
      await ref.read(entitlementServiceProvider).stampInstallDate();

      if (mounted) {
        context.go(AppRoutes.home);
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
                    Row(
                      children: List.generate(3, (i) {
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
                      : _step == 1
                          ? _buildAccountStep(
                              color,
                              textTheme,
                              spacing,
                              ctxt,
                              accent,
                              isDark,
                            )
                          : _buildPackPickerStep(
                              color,
                              textTheme,
                              spacing,
                              isDark,
                              accent,
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
                                    _step < 2
                                        ? 'Continue'
                                        : ctxt.translate('onboard_GetStarted'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (_step == 2) ...[
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
                    if (_step < 2) ...[
                      const SizedBox(height: 12),
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
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: spacing.cardHorizontalMax + 8),
      child: Column(
        key: const ValueKey('name_step'),
        children: [
          const SizedBox(height: 32),
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
      ),
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
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: spacing.cardHorizontalMax + 8),
      child: Column(
        key: const ValueKey('account_step'),
        children: [
          const SizedBox(height: 32),
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
                      if (v?.trim().isEmpty ?? true) {
                        return 'Balance is required';
                      }
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
      ),
    );
  }

  // ── STEP 3: PACK PICKER ──
  Widget _buildPackPickerStep(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    bool isDark,
    Color accent,
  ) {
    final packs = CategoryPackRegistry.visible;

    return Column(
      key: const ValueKey('pack_step'),
      children: [
        const SizedBox(height: 24),
        // Hero
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
                color: const Color(0xFF9C27B0).withValues(alpha: 0.25),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9C27B0)
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
                    const Color(0xFF9C27B0)
                        .withValues(alpha: isDark ? 0.2 : 0.14),
                    const Color(0xFF9C27B0)
                        .withValues(alpha: isDark ? 0.08 : 0.05),
                  ],
                ),
              ),
              child: const Icon(
                LucideIcons.layoutGrid,
                size: 48,
                color: Color(0xFF9C27B0),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding:
              EdgeInsets.symmetric(horizontal: spacing.cardHorizontalMax + 8),
          child: Column(
            children: [
              Text(
                'Choose Your Categories',
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color.onSurface,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Pick packs that match your lifestyle. You can change these later.',
                style: textTheme.bodyLarge?.copyWith(
                  color: color.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Start Fresh toggle
        Padding(
          padding:
              EdgeInsets.symmetric(horizontal: spacing.cardHorizontalMax + 8),
          child: Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            color: _startFresh
                ? accent.withValues(alpha: 0.1)
                : color.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
              side: BorderSide(
                color: _startFresh
                    ? accent.withValues(alpha: 0.4)
                    : color.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _startFresh = !_startFresh;
                  if (_startFresh) _selectedPackIds.clear();
                  if (!_startFresh) {
                    _selectedPackIds.add('com.mudra.pack.default');
                  }
                });
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.sparkles,
                      color: _startFresh ? accent : color.onSurfaceVariant,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Start Fresh',
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'No categories — add your own later',
                            style: textTheme.bodySmall?.copyWith(
                              color: color.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _startFresh
                          ? LucideIcons.circleCheck
                          : LucideIcons.circle,
                      color: _startFresh ? accent : color.outlineVariant,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Pack grid
        Expanded(
          child: AnimatedOpacity(
            opacity: _startFresh ? 0.4 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: _startFresh,
              child: GridView.builder(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.cardHorizontalMax + 8,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.6,
                ),
                itemCount: packs.length,
                itemBuilder: (context, index) {
                  final pack = packs[index];
                  final selected = _selectedPackIds.contains(pack.id);
                  final packColor = Color(pack.color);

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        if (selected) {
                          _selectedPackIds.remove(pack.id);
                        } else {
                          _selectedPackIds.add(pack.id);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(spacing.radiusMedium),
                        color: selected
                            ? packColor.withValues(alpha: isDark ? 0.2 : 0.1)
                            : color.surfaceContainerLow,
                        border: Border.all(
                          color: selected
                              ? packColor.withValues(alpha: 0.5)
                              : color.outlineVariant.withValues(alpha: 0.4),
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: packColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  IconHelper.iconFromName(pack.icon),
                                  size: 16,
                                  color: packColor,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                selected
                                    ? LucideIcons.circleCheck
                                    : LucideIcons.circle,
                                size: 18,
                                color:
                                    selected ? packColor : color.outlineVariant,
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            pack.name,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: color.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            pack.description,
                            style: textTheme.bodySmall?.copyWith(
                              color: color.onSurfaceVariant,
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
            ),
          ),
        ),
      ],
    );
  }
}
