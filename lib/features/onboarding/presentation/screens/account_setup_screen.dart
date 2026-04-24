import 'dart:async' show Timer;

import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/tone/tone_provider.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/shared/widgets/currency_badge.dart';
import 'package:mudra_manager/core/currency/currency_provider.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
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
  final _accountController = TextEditingController();
  final _balanceController = TextEditingController(text: '0');

  int _step = 0;
  bool _isLoading = false;
  bool _startFresh = false;
  final Set<String> _selectedPackIds = {'com.mudra.pack.default'};
  String _selectedCurrency = 'INR';

  // Starter transaction state
  final _starterControllers = <String, TextEditingController>{};
  static const _starterItems = [
    ('onboard_starterCoffee', 'coffee', LucideIcons.coffee),
    ('onboard_starterTransport', 'car', LucideIcons.car),
    ('onboard_starterLunch', 'utensils', LucideIcons.utensils),
    ('onboard_starterGroceries', 'shoppingCart', LucideIcons.shoppingCart),
  ];

  // Typewriter animation for account name hint
  static const _hintExamples = ['Cash', 'Wallet', 'SBI Bank', 'Paytm', 'GPay'];
  String _animatedHint = '';
  int _hintIndex = 0;
  int _charIndex = 0;
  bool _isDeleting = false;
  bool _hintPaused = false;
  Timer? _typewriterTimer;

  @override
  void initState() {
    super.initState();
    _accountController.addListener(_onAccountTextChanged);
  }

  void _onAccountTextChanged() {
    if (_accountController.text.isNotEmpty) {
      _stopTypewriter();
    } else if (_typewriterTimer == null) {
      _startTypewriter();
    }
  }

  void _startTypewriter() {
    _typewriterTimer?.cancel();
    _hintIndex = 0;
    _charIndex = 0;
    _isDeleting = false;
    _hintPaused = false;
    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 80), _tick);
  }

  void _stopTypewriter() {
    _typewriterTimer?.cancel();
    _typewriterTimer = null;
    if (mounted) setState(() => _animatedHint = '');
  }

  int _pauseCounter = 0;

  void _tick(Timer timer) {
    if (!mounted) { timer.cancel(); return; }

    final word = _hintExamples[_hintIndex];

    // Handle pause after full word
    if (_hintPaused) {
      _pauseCounter++;
      if (_pauseCounter > 18) { // ~1.5s pause (18 * 80ms)
        _hintPaused = false;
        _isDeleting = true;
        _pauseCounter = 0;
      }
      return;
    }

    if (!_isDeleting) {
      // Typing forward
      if (_charIndex <= word.length) {
        setState(() => _animatedHint = word.substring(0, _charIndex));
        _charIndex++;
      } else {
        _hintPaused = true;
      }
    } else {
      // Deleting
      if (_charIndex > 0) {
        _charIndex--;
        setState(() => _animatedHint = word.substring(0, _charIndex));
      } else {
        _isDeleting = false;
        _hintIndex = (_hintIndex + 1) % _hintExamples.length;
      }
    }
  }

  @override
  void dispose() {
    _typewriterTimer?.cancel();
    _accountController.removeListener(_onAccountTextChanged);
    _nameController.dispose();
    _accountController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_step == 0) {
      if (_nameController.text.trim().isEmpty) {
        SnackbarService.error(BuddyMessages.categoryNameRequired);
        return;
      }
      HapticFeedback.lightImpact();
      setState(() => _step = 1);
    } else if (_step == 1) {
      // Currency step — just advance
      HapticFeedback.lightImpact();
      setState(() => _step = 2);
      if (_accountController.text.isEmpty) _startTypewriter();
    } else if (_step == 2) {
      if (!_formKey.currentState!.validate()) return;
      HapticFeedback.lightImpact();
      _stopTypewriter();
      setState(() => _step = 3);
    } else if (_step == 3) {
      HapticFeedback.lightImpact();
      setState(() => _step = 4);
    } else if (_step == 4) {
      HapticFeedback.lightImpact();
      setState(() => _step = 5);
      // Initialize starter controllers
      for (final item in _starterItems) {
        _starterControllers.putIfAbsent(item.$1, () => TextEditingController());
      }
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
      if (!context.mounted) return;
      final data = await BackupService.restoreEncryptedBackup(
        context,
        isar,
        password,
      );

      if (data != null) {
        SharedPrefsUtil.instance.setOnboardingComplete();
        SnackbarService.success(BuddyMessages.restoreSuccess);
        if (context.mounted) context.go(AppRoutes.home);
      }
    } catch (e) {
      if (context.mounted) {
        SnackbarService.error(BuddyMessages.restoreFailed);
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
            ..currencyCode = _selectedCurrency
            ..initialBalance = double.tryParse(_balanceController.text.trim()) ?? 0.0,
        );
      });

      if (!_startFresh && _selectedPackIds.isNotEmpty) {
        await CategoryManagementService.installPacks(
          _selectedPackIds.toList(),
        );
      }

      // Set base currency
      final currencyService = await ref.read(currencyServiceProvider.future);
      await currencyService.setBaseCurrency(_selectedCurrency);

      SharedPrefsUtil.instance.setOnboardingComplete();
      // Stamp install date for trial period
      await ref.read(entitlementServiceProvider).stampInstallDate();

      // Save starter transactions if any amounts were entered
      if (_starterControllers.isNotEmpty) {
        await _saveStarterTransactions(isar);
      }

      if (context.mounted) {
        context.go(AppRoutes.home);
      }
    } catch (e) {
      if (context.mounted) {
        SnackbarService.error(BuddyMessages.genericError);
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
                      children: List.generate(6, (i) {
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
                  child: switch (_step) {
                    0 => _buildNameStep(color, textTheme, spacing, ctxt, accent, isDark),
                    1 => _buildCurrencyStep(color, textTheme, spacing, accent, isDark, ctxt),
                    2 => _buildAccountStep(color, textTheme, spacing, ctxt, accent, isDark),
                    3 => _buildToneStep(color, textTheme, spacing, isDark, accent, ctxt),
                    4 => _buildPackPickerStep(color, textTheme, spacing, isDark, accent, ctxt),
                    _ => _buildStarterTxnStep(color, textTheme, spacing, ctxt, accent, isDark),
                  },
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
                                    _step < 5
                                        ? ctxt.onboard_continue
                                        : ctxt.translate('onboard_GetStarted'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (_step == 5) ...[
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
                          ctxt.onboard_restoreFromBackup,
                          style: textTheme.labelLarge?.copyWith(
                            color: color.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                    if (_step == 5) ...[
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _isLoading ? null : _completeSetup,
                        child: Text(
                          ctxt.onboard_skipAddLater,
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
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: ctxt.translate('onboard_enterYourName'),
              prefixIcon: Icon(LucideIcons.userRound, color: accent, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(spacing.radiusMedium),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(spacing.radiusMedium),
                borderSide: BorderSide(color: accent, width: 2),
              ),
            ),
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => _nextStep(),
          ),
        ],
      ),
    );
  }

  // ── STEP 2: CURRENCY ──
  Widget _buildCurrencyStep(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    Color accent,
    bool isDark,
    AppLocalizations ctxt,
  ) {
    // Popular currencies shown at top
    const popular = ['INR', 'USD', 'EUR', 'GBP', 'AED', 'SGD', 'CAD', 'AUD'];
    final popularMetas =
        popular.map((c) => kCurrencies[c]).whereType<CurrencyMeta>().toList();

    return SingleChildScrollView(
      key: const ValueKey('currency_step'),
      padding: EdgeInsets.symmetric(horizontal: spacing.cardHorizontalMax + 8),
      child: Column(
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
                child: CurrencyBadge(
                  code: _selectedCurrency,
                  size: 36,
                  color: accent,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            BuddyMessages.currencyPickerTitle,
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: color.onSurface,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            BuddyMessages.currencyPickerSubtitle,
            style: textTheme.bodyLarge?.copyWith(
              color: color.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: popularMetas.map((c) {
              final isSelected = _selectedCurrency == c.code;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _selectedCurrency = c.code);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accent.withValues(alpha: isDark ? 0.2 : 0.12)
                        : color.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? accent.withValues(alpha: 0.5)
                          : color.outlineVariant.withValues(alpha: 0.4),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        c.symbol,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? accent : color.onSurface,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        c.code,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? accent : color.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () async {
              final picked = await showModalBottomSheet<String>(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (_) => _AllCurrenciesSheet(
                  selected: _selectedCurrency,
                ),
              );
              if (picked != null) {
                setState(() => _selectedCurrency = picked);
              }
            },
            icon: Icon(LucideIcons.globe, size: 16, color: accent),
            label: Text(
              ctxt.onboard_browseAllCurrencies,
              style: textTheme.labelLarge?.copyWith(color: accent),
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
              Expanded(
                child: Text(
                  ctxt.onboard_currencyWarning,
                  style: textTheme.bodySmall?.copyWith(
                    color: color.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── STEP 3: ACCOUNT ──
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
                  color: color.primary.withValues(alpha: 0.25),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        color.primary.withValues(alpha: isDark ? 0.15 : 0.12),
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
                      color.primary.withValues(alpha: isDark ? 0.2 : 0.14),
                      color.primary.withValues(alpha: isDark ? 0.08 : 0.05),
                    ],
                  ),
                ),
                child: Icon(
                  LucideIcons.wallet,
                  size: 48,
                  color: color.primary,
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
          TextFormField(
            controller: _accountController,
            decoration: InputDecoration(
              labelText: ctxt.translate('onboard_accountName'),
              hintText: _typewriterTimer != null ? _animatedHint : ctxt.onboard_accountHint,
              prefixIcon: Icon(LucideIcons.wallet, color: color.primary, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(spacing.radiusMedium)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(spacing.radiusMedium),
                borderSide: BorderSide(color: color.primary, width: 2),
              ),
            ),
            validator: (v) => v?.trim().isEmpty ?? true
                ? ctxt.onboard_accountNameRequired
                : null,
            textInputAction: TextInputAction.next,
          ),
          SizedBox(height: spacing.sectionGap),
          TextFormField(
            controller: _balanceController,
            decoration: InputDecoration(
              labelText: ctxt.onboard_initialBalance,
              hintText: '0',
              prefixIcon: Icon(currencyIcon(_selectedCurrency), color: color.primary, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(spacing.radiusMedium)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(spacing.radiusMedium),
                borderSide: BorderSide(color: color.primary, width: 2),
              ),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) {
              if (v?.trim().isEmpty ?? true) {
                return ctxt.onboard_balanceRequired;
              }
              if (double.tryParse(v!) == null) {
                return ctxt.onboard_enterValidNumber;
              }
              return null;
            },
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _nextStep(),
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

// ── STEP 3: TONE PICKER ──
  Widget _buildToneStep(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    bool isDark,
    Color accent,
    AppLocalizations ctxt,
  ) {
    final activeTone = ref.watch(tonePackProvider);

    return SingleChildScrollView(
      key: const ValueKey('tone_step'),
      padding: EdgeInsets.symmetric(horizontal: spacing.cardHorizontalMax + 8),
      child: Column(
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
                  color: color.tertiary.withValues(alpha: 0.25),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        color.tertiary.withValues(alpha: isDark ? 0.15 : 0.12),
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
                      color.tertiary.withValues(alpha: isDark ? 0.2 : 0.14),
                      color.tertiary.withValues(alpha: isDark ? 0.08 : 0.05),
                    ],
                  ),
                ),
                child: Icon(
                  LucideIcons.messageCircleHeart,
                  size: 48,
                  color: color.tertiary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            ctxt.onboard_toneTitle,
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: color.onSurface,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            ctxt.onboard_toneDesc,
            style: textTheme.bodyLarge?.copyWith(
              color: color.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          ...allTonePacks.map((tone) {
            final isSelected = activeTone.id == tone.id;
            final toneColor = isSelected ? color.tertiary : color.onSurface;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  ref.read(tonePackProvider.notifier).select(tone);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(spacing.radiusMedium),
                    color: isSelected
                        ? color.tertiary.withValues(alpha: isDark ? 0.15 : 0.08)
                        : color.surfaceContainerLow,
                    border: Border.all(
                      color: isSelected
                          ? color.tertiary.withValues(alpha: 0.5)
                          : color.outlineVariant.withValues(alpha: 0.4),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            tone.emoji,
                            style: const TextStyle(fontSize: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tone.name,
                                  style: textTheme.bodyLarge?.copyWith(
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: toneColor,
                                  ),
                                ),
                                Text(
                                  tone.description,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: color.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            isSelected
                                ? LucideIcons.circleCheck
                                : LucideIcons.circle,
                            color: isSelected
                                ? color.tertiary
                                : color.outlineVariant,
                            size: 22,
                          ),
                        ],
                      ),
                      if (isSelected) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: color.tertiary.withValues(alpha: 0.08),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.messageSquareQuote,
                                size: 14,
                                color: color.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '"${tone.txnAdded}"',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: color.onSurfaceVariant,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── STEP 4: PACK PICKER ──
  Widget _buildPackPickerStep(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    bool isDark,
    Color accent,
    AppLocalizations ctxt,
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
                color: color.tertiary.withValues(alpha: 0.25),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.tertiary.withValues(alpha: isDark ? 0.15 : 0.12),
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
                    color.tertiary.withValues(alpha: isDark ? 0.2 : 0.14),
                    color.tertiary.withValues(alpha: isDark ? 0.08 : 0.05),
                  ],
                ),
              ),
              child: Icon(
                LucideIcons.layoutGrid,
                size: 48,
                color: color.tertiary,
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
                ctxt.onboard_categoriesTitle,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color.onSurface,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                ctxt.onboard_categoriesDesc,
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
                            ctxt.onboard_startFresh,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            ctxt.onboard_startFreshDesc,
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

  // ── STEP 5: STARTER TRANSACTIONS ──
  Widget _buildStarterTxnStep(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
    Color accent,
    bool isDark,
  ) {
    return SingleChildScrollView(
      key: const ValueKey('starter_step'),
      padding: EdgeInsets.symmetric(horizontal: spacing.cardHorizontalMax + 8),
      child: Column(
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
                child: Icon(LucideIcons.receiptText, size: 48, color: accent),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            ctxt.onboard_whatDidYouSpend,
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: color.onSurface,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            ctxt.onboard_addFewToStart,
            style: textTheme.bodyLarge?.copyWith(
              color: color.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          ..._starterItems.map((item) {
            final controller = _starterControllers[item.$1]!;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(spacing.radiusMedium),
                    ),
                    child: Icon(item.$3, size: 20, color: accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      ctxt.translate(item.$1),
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    child: TextField(
                      controller: controller,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.end,
                      decoration: InputDecoration(
                        hintText: '0',
                        prefixText: '\u20b9 ',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(spacing.radiusSmall),
                          borderSide: BorderSide(
                            color: color.outlineVariant.withValues(alpha: 0.4),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(spacing.radiusSmall),
                          borderSide: BorderSide(color: accent, width: 2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _saveStarterTransactions(Isar isar) async {
    final account = await isar.accounts.where().findFirst();
    if (account == null) return;

    final categories = await isar.categorys.where().findAll();
    final now = DateTime.now();
    final txns = <Transaction>[];

    for (final item in _starterItems) {
      final controller = _starterControllers[item.$1];
      if (controller == null) continue;
      final amount = double.tryParse(controller.text.replaceAll(',', ''));
      if (amount == null || amount <= 0) continue;

      final cat = _matchCategory(categories, item.$2);
      final txn = Transaction.create(
        date: now,
        amount: amount,
        isExpense: true,
        description: '',
      );
      txn.account.value = account;
      if (cat != null) txn.category.value = cat;
      txns.add(txn);
    }

    if (txns.isEmpty) return;

    await isar.writeTxn(() async {
      for (final txn in txns) {
        await isar.transactions.put(txn);
        await txn.account.save();
        await txn.category.save();
      }
    });

    await SharedPrefsUtil.instance.setStarterTxnsOffered();
  }

  Category? _matchCategory(List<Category> categories, String iconHint) {
    // Try matching by icon name first
    final byIcon = categories.where(
      (c) => c.iconName?.toLowerCase() == iconHint.toLowerCase(),
    ).firstOrNull;
    if (byIcon != null) return byIcon;

    // Fallback: match by common names
    final nameMap = {
      'coffee': ['coffee', 'cafe', 'tea', 'beverage'],
      'car': ['transport', 'travel', 'auto', 'cab', 'uber', 'ola'],
      'utensils': ['food', 'lunch', 'dinner', 'restaurant', 'eating'],
      'shoppingCart': ['grocery', 'groceries', 'shopping', 'supermarket'],
    };
    final keywords = nameMap[iconHint] ?? [];
    for (final kw in keywords) {
      final match = categories.where(
        (c) => c.name.toLowerCase().contains(kw),
      ).firstOrNull;
      if (match != null) return match;
    }
    return categories.firstOrNull;
  }
}

class _AllCurrenciesSheet extends StatefulWidget {
  final String selected;
  const _AllCurrenciesSheet({required this.selected});

  @override
  State<_AllCurrenciesSheet> createState() => _AllCurrenciesSheetState();
}

class _AllCurrenciesSheetState extends State<_AllCurrenciesSheet> {
  String _query = '';

  List<CurrencyMeta> get _filtered {
    final all = kCurrencies.values.toList();
    if (_query.isEmpty) return all;
    final q = _query.toLowerCase();
    return all
        .where(
          (c) =>
              c.code.toLowerCase().contains(q) ||
              c.name.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) => Column(
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.common_searchCurrency,
                prefixIcon: const Icon(LucideIcons.search, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: color.outlineVariant),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: _filtered.length,
              itemBuilder: (context, i) {
                final c = _filtered[i];
                final isSelected = c.code == widget.selected;
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.primary.withValues(alpha: 0.12)
                          : color.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      c.symbol,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? color.primary : color.onSurface,
                      ),
                    ),
                  ),
                  title: Text(c.code),
                  subtitle: Text(c.name, style: textTheme.bodySmall),
                  trailing: isSelected
                      ? Icon(LucideIcons.circleCheck, color: color.primary)
                      : null,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).pop(c.code);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
