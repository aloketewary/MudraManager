import 'dart:ui';

import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/currency/currency_provider.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/entitlement/entitlement_provider.dart';
import 'package:mudra_manager/core/extension/account_type_extenstion.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/simple_color_picker.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/account/data/account_providers.dart';
import 'package:mudra_manager/features/gamification/models/gamification_enum.dart';
import 'package:mudra_manager/core/state/app_screen_state.dart';
import 'package:mudra_manager/shared/templates/screen_shell.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';

class AccountForm extends ConsumerStatefulWidget {
  final Account? account;
  final String? accountNumber;
  final String? bankName;

  const AccountForm({
    super.key,
    this.account,
    this.accountNumber,
    this.bankName,
  });

  @override
  ConsumerState<AccountForm> createState() => _AccountFormState();
}

class _AccountFormState extends ConsumerState<AccountForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _accountNumberController;
  late TextEditingController _balanceController;
  late TextEditingController _creditLimitController;
  late FocusNode _nameFocusNode;
  late FocusNode _accountNumberFocusNode;
  late FocusNode _balanceFocusNode;
  late FocusNode _creditLimitFocusNode;
  late AccountType _selectedType;
  late Color _selectedColor;
  String? _selectedCurrency;
  bool _saving = false;
  int? _statementDay;
  int? _dueDay;

  bool get _isEditing => widget.account != null;
  AppLocalizations get ctxt => AppLocalizations.of(context)!;

  // Subset from SimpleColorPickerDialog's palette
  static const _quickColors = [
    Color(0xFFE53935), // Red
    Color(0xFFE91E63), // Pink
    Color(0xFF9C27B0), // Purple
    Color(0xFF3F51B5), // Indigo
    Color(0xFF2196F3), // Blue
    Color(0xFF00BCD4), // Cyan
    Color(0xFF009688), // Teal
    Color(0xFF4CAF50), // Green
    Color(0xFFFF9800), // Orange
    Color(0xFF795548), // Brown
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.account?.name ?? widget.bankName ?? '',
    );
    _nameFocusNode = FocusNode();
    _accountNumberController = TextEditingController(
      text: widget.account?.accountNumber ?? widget.accountNumber ?? '',
    );
    _accountNumberFocusNode = FocusNode();
    _balanceController = TextEditingController(
      text: widget.account?.initialBalance.toString() ?? '',
    );
    _balanceFocusNode = FocusNode();
    _creditLimitController = TextEditingController(
      text: widget.account?.creditLimit?.toString() ?? '',
    );
    _creditLimitFocusNode = FocusNode();
    _statementDay = widget.account?.statementDay;
    _dueDay = widget.account?.dueDay;
    _selectedType = widget.account?.accountType ?? AccountType.cash;
    _selectedColor = widget.account?.colorValue != null
        ? Color(widget.account!.colorValue!)
        : const Color(0xFF2196F3);
    _selectedCurrency = widget.account?.currencyCode;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    _accountNumberController.dispose();
    _accountNumberFocusNode.dispose();
    _balanceController.dispose();
    _balanceFocusNode.dispose();
    _creditLimitController.dispose();
    _creditLimitFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return ScreenShell(
      config: ScreenShellConfig(
        title: _isEditing ? ctxt.account_editTitle : ctxt.account_newTitle,
        appBarMode: AppBarMode.standard,
        enableRefresh: false,
      ),
      leading: IconButton(
        icon: const Icon(LucideIcons.x),
        onPressed: () {
          HapticFeedback.mediumImpact();
          context.pop();
        },
      ),
      actions: ScreenActions.build(
        trailing: ScreenTextAction(
          id: 'save_account',
          label: _isEditing ? ctxt.common_update : ctxt.common_create,
          onTap:
              _saving ? null : () => _saveAccount(widget.account?.id, spacing),
          isLoading: _saving,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.only(
            left: spacing.cardHorizontal,
            right: spacing.cardHorizontal,
            top: spacing.cardVertical,
            bottom: MediaQuery.of(context).padding.bottom +
                kBottomNavigationBarHeight +
                spacing.sectionGap,
          ),
          children: [
            _buildHeroPreview(
              color,
              textTheme,
              spacing,
              ctxt,
              isDark,
              reduceMotion,
            ),
            SizedBox(height: spacing.sectionGap),
            _buildTypeHeader(ctxt.account_typeLabel, color, textTheme, spacing, _selectedType.icon),
            SizedBox(
              height: spacing.sectionGap,
            ),
            _buildTypeGrid(
              color,
              textTheme,
              spacing,
              reduceMotion,
            ),
            SizedBox(height: spacing.sectionGap),
            _buildTypeHeader(ctxt.account_detailsLabel, color, textTheme, spacing, LucideIcons.form),
            SizedBox(height: spacing.sectionGap),
            _buildDetailsCard(
              color,
              textTheme,
              spacing,
              isDark,
            ),
            SizedBox(height: spacing.sectionGap),
            _buildTypeHeader(ctxt.account_colorLabel, color, textTheme, spacing, LucideIcons.palette),
            SizedBox(height: spacing.sectionGap),
            _buildColorSection(
              color,
              textTheme,
              spacing,
              reduceMotion,
            ),
            SizedBox(height: spacing.sectionGap),
            _buildTypeHeader(ctxt.account_currencyLabel, color, textTheme, spacing, LucideIcons.wallet),
            SizedBox(height: spacing.sectionGap),
            _buildCurrencySelector(color, textTheme, spacing),
          ],
        ),
      ),
    );
  }

  // ── HERO PREVIEW (live) ──
  Widget _buildHeroPreview(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
    bool isDark,
    bool reduceMotion,
  ) {
    final name = _nameController.text.trim();
    final number = _accountNumberController.text.trim();
    final balance = double.tryParse(_balanceController.text) ?? 0.0;
    final isCreditCard = _selectedType == AccountType.creditCard;

    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.8, -0.5),
            radius: 1.2,
            colors: [
              _selectedColor.withValues(alpha: isDark ? 0.25 : 0.2),
              _selectedColor.withValues(alpha: isDark ? 0.15 : 0.08),
              color.surface.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          border: Border.all(
            color: color.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Stack(
          children: [
            // Ambient glow behind content
            Positioned(
              right: -40,
              top: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _selectedColor.withValues(alpha: isDark ? 0.2 : 0.15),
                      _selectedColor.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Padding(
                  padding: EdgeInsets.all(spacing.cardInner + spacing.elementGap),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Identity block
                      _buildIdentityBlock(
                        color,
                        textTheme,
                        spacing,
                        ctxt,
                        isDark,
                        name,
                        number,
                      ),
                      SizedBox(height: spacing.sectionGap),
                      // Row with account type icon + details
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Account type icon with glass container
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: _selectedColor.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _selectedColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Icon(
                              _selectedType.icon,
                              size: 28,
                              color: _selectedColor,
                            ),
                          ),
                          SizedBox(width: spacing.sectionGap),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: spacing.elementGap,
                                        vertical: spacing.elementGapUltraMin,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _selectedColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(spacing.radiusMedium),
                                        border: Border.all(
                                          color: _selectedColor.withValues(alpha: 0.2),
                                        ),
                                      ),
                                      child: Text(
                                        _selectedType.label,
                                        style: textTheme.labelSmall?.copyWith(
                                          color: _selectedColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    if (number.isNotEmpty) ...[
                                      SizedBox(width: spacing.elementGap),
                                      Text(
                                        '•••• $number',
                                        style: textTheme.labelSmall?.copyWith(
                                          color: color.onSurfaceVariant,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                SizedBox(height: spacing.elementGap),
                                Text(
                                  isCreditCard
                                      ? ctxt.account_outstanding
                                      : ctxt.account_balance,
                                  style: textTheme.labelSmall?.copyWith(
                                    color: color.onSurfaceVariant.withValues(alpha: 0.6),
                                  ),
                                ),
                                Semantics(
                                  label: ctxt.account_balance,
                                  excludeSemantics: balance == 0,
                                  child: CurrencyText(
                                    amount: balance,
                                    currencyCode: _selectedCurrency,
                                    compact: false,
                                    fixedLength: 2,
                                    style: textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: _selectedColor,
                                    ),
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
          ],
        ),
      ),
    );
  }

  // ── IDENTITY BLOCK (glass surface like ProfileScreen) ──
  Widget _buildIdentityBlock(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
    bool isDark,
    String name,
    String number,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: color.surface.withValues(alpha: isDark ? 0.1 : 0.15),
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(
          color: color.outlineVariant.withValues(alpha: isDark ? 0.2 : 0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.cardHorizontalMax,
              vertical: spacing.elementGap,
            ),
            decoration: BoxDecoration(
              color: _selectedColor.withValues(alpha: isDark ? 0.08 : 0.06),
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    name.isEmpty ? ctxt.account_name : name,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (number.isNotEmpty) ...[
            SizedBox(height: spacing.elementGapMin),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: spacing.elementGap * 1.5,
                vertical: spacing.elementGapUltraMin + 2,
              ),
              decoration: BoxDecoration(
                color: color.onSurfaceVariant.withValues(alpha: spacing.opacitySubtle),
                borderRadius: BorderRadius.circular(spacing.radiusSmall),
              ),
              child: Text(
                '•••• $number',
                style: textTheme.bodySmall?.copyWith(
                  color: color.onSurfaceVariant,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── TYPE HEADER ──
  Widget _buildTypeHeader(
    String headerText,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    IconData headerIcon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Container(
            width: spacing.elementGapMin,
            height: 20,
            decoration: BoxDecoration(
              color: _selectedColor,
              borderRadius: BorderRadius.circular(spacing.elementGapMin / 2),
            ),
          ),
          SizedBox(width: spacing.elementGapMin),
          Container(
            padding: EdgeInsets.all(spacing.elementGap),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _selectedColor.withValues(alpha: 0.12),
                  _selectedColor.withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(spacing.radiusSmall),
            ),
            child: Icon(
              headerIcon,
              size: 16,
              color: _selectedColor,
            ),
          ),
          SizedBox(width: spacing.elementGap),
          Expanded(
            child: Text(
              headerText,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: color.onSurface,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── ACCOUNT TYPE GRID (2×3) ──
  Widget _buildTypeGrid(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    bool reduceMotion,
  ) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: spacing.elementGap,
      crossAxisSpacing: spacing.elementGap,
      childAspectRatio: 1.4,
      children: AccountType.values.map((type) {
        final isSelected = _selectedType == type;
        return Semantics(
          label: '${type.label}${isSelected ? ' selected' : ''}',
          button: true,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _selectedType = type);
            },
            child: AnimatedContainer(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isSelected
                    ? _selectedColor.withValues(alpha: 0.12)
                    : color.surfaceContainerLow,
                borderRadius: BorderRadius.circular(spacing.radiusMedium),
                border: Border.all(
                  color: isSelected
                      ? _selectedColor
                      : color.outlineVariant.withValues(alpha: 0.3),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    type.icon,
                    size: 22,
                    color: isSelected ? _selectedColor : color.onSurfaceVariant,
                  ),
                  SizedBox(height: spacing.elementGapMin),
                  Text(
                    type.label,
                    style: textTheme.labelSmall?.copyWith(
                      color:
                          isSelected ? _selectedColor : color.onSurfaceVariant,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── DETAILS FIELDS ──
  Widget _buildDetailsCard(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    bool isDark,
  ) {
    final isCreditCard = _selectedType == AccountType.creditCard;

    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: color.surface.withValues(alpha: isDark ? 0.6 : 0.7),
      labelText: ctxt.account_name,
      prefixIcon: Icon(LucideIcons.wallet, size: 18, color: _selectedColor),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        borderSide: BorderSide(color: color.outlineVariant.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        borderSide: BorderSide(color: _selectedColor, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        borderSide: BorderSide(color: color.outlineVariant.withValues(alpha: 0.3)),
      ),
    );

    return Column(
      children: [
        _glassTextField(
          controller: _nameController,
          focusNode: _nameFocusNode,
          decoration: inputDecoration.copyWith(labelText: ctxt.account_name),
          textTheme: textTheme,
          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        ),
        SizedBox(height: spacing.sectionGap),
        _glassTextField(
          controller: _accountNumberController,
          focusNode: _accountNumberFocusNode,
          keyboardType: TextInputType.number,
          decoration: inputDecoration.copyWith(
            labelText: ctxt.account_last4,
            helperText: ctxt.account_last4Helper,
            helperStyle: textTheme.labelSmall?.copyWith(
              color: color.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            prefixIcon: Icon(LucideIcons.hash, size: 18, color: _selectedColor),
          ),
          textTheme: textTheme,
          validator: (v) {
            if (v == null || v.isEmpty) return ctxt.common_required;
            if (v.length < 4) return ctxt.account_min4;
            if (v.length > 4) return ctxt.account_max4;
            return null;
          },
        ),
        SizedBox(height: spacing.sectionGap),
        _glassTextField(
          controller: _balanceController,
          focusNode: _balanceFocusNode,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: inputDecoration.copyWith(
            labelText: isCreditCard ? ctxt.account_outstanding : ctxt.account_initialBalance,
            helperText: isCreditCard ? ctxt.account_cardPaidOff : null,
            helperStyle: textTheme.labelSmall?.copyWith(
              color: color.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            prefixIcon: Icon(currencyIcon(_selectedCurrency), size: 18, color: _selectedColor),
          ),
          textTheme: textTheme,
          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
        ),
        if (isCreditCard) ...[
          SizedBox(height: spacing.sectionGap),
          _glassTextField(
            controller: _creditLimitController,
            focusNode: _creditLimitFocusNode,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: inputDecoration.copyWith(
              labelText: ctxt.account_creditLimit,
              prefixIcon: Icon(LucideIcons.gauge, size: 18, color: _selectedColor),
            ),
            textTheme: textTheme,
          ),
          SizedBox(height: spacing.sectionGap),
          Row(
            children: [
              Expanded(
                child: _buildDayPicker(
                  label: ctxt.account_statementDay,
                  value: _statementDay,
                  icon: LucideIcons.calendarRange,
                  onChanged: (v) => setState(() => _statementDay = v),
                  color: color,
                  textTheme: textTheme,
                  spacing: spacing,
                  isDark: isDark,
                ),
              ),
              SizedBox(width: spacing.elementGap),
              Expanded(
                child: _buildDayPicker(
                  label: ctxt.account_dueDay,
                  value: _dueDay,
                  icon: LucideIcons.calendarClock,
                  onChanged: (v) => setState(() => _dueDay = v),
                  color: color,
                  textTheme: textTheme,
                  spacing: spacing,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _glassTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required InputDecoration decoration,
    required TextTheme textTheme,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        onChanged: (_) => setState(() {}),
        decoration: decoration,
        style: textTheme.bodyLarge,
        validator: validator,
      ),
    );
  }

  // ── DAY PICKER (for credit card statement/due day) ──
  Widget _buildDayPicker({
    required String label,
    required int? value,
    required IconData icon,
    required ValueChanged<int?> onChanged,
    required ColorScheme color,
    required TextTheme textTheme,
    required AppSpacing spacing,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: InputDecorator(
        decoration: InputDecoration(
          filled: true,
          fillColor: color.surface.withValues(alpha: isDark ? 0.6 : 0.7),
          labelText: label,
          prefixIcon: Icon(icon, size: 18, color: _selectedColor),
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int?>(
            value: value,
            isExpanded: true,
            isDense: true,
            hint: Text('—', style: textTheme.bodyLarge),
            items: [
              DropdownMenuItem<int?>(
                value: null,
                child: Text('—', style: textTheme.bodyLarge),
              ),
              ...List.generate(31, (i) => i + 1).map(
                (day) => DropdownMenuItem(
                  value: day,
                  child: Text('$day', style: textTheme.bodyLarge),
                ),
              ),
            ],
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  // ── COLOR SECTION ──
  Widget _buildColorSection(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    bool reduceMotion,
  ) {
    return Card(
      elevation: 0,
      color: color.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        side: BorderSide(
          color: color.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.cardInner),
        child: Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: spacing.elementGap,
                runSpacing: spacing.elementGap,
                children: _quickColors.map((c) {
                  final isSelected = _selectedColor.toARGB32() == c.toARGB32();
                  return Semantics(
                    label: '${c.toString()}${isSelected ? ' selected' : ''}',
                    button: true,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _selectedColor = c);
                      },
                      child: AnimatedContainer(
                        duration: reduceMotion
                            ? Duration.zero
                            : const Duration(milliseconds: 200),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(
                                  color: color.onSurface,
                                  width: 2.5,
                                )
                              : null,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: c.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                  ),
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(
                                LucideIcons.check,
                                color: Colors.white,
                                size: 16,
                              )
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(width: spacing.elementGap),
            Semantics(
              label: ctxt.quickAdd_moreOptions,
              button: true,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _pickColor();
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.outlineVariant,
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    LucideIcons.ellipsis,
                    size: 16,
                    color: color.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildCurrencySelector(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    final baseCurrencyAsync = ref.watch(baseCurrencyProvider);
    final baseCurrency = baseCurrencyAsync.value ?? 'INR';
    final displayCode = _selectedCurrency ?? baseCurrency;
    final meta = kCurrencies[displayCode];
    final isBase = _selectedCurrency == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 0,
          color: color.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(spacing.radiusMedium),
            side: BorderSide(
              color: color.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(spacing.radiusMedium),
            onTap: () async {
              HapticFeedback.lightImpact();
              final picked = await showModalBottomSheet<String>(
                context: context,
                isScrollControlled: true,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(spacing.radiusSmall * 2),
                  ),
                ),
                builder: (_) => _CurrencyPickerInline(selected: displayCode),
              );
              if (picked == null) return;
              final newIsBase = picked == baseCurrency;
              final oldCode = _selectedCurrency;

              // Warn if editing existing account and currency is changing
              if (_isEditing && oldCode != (newIsBase ? null : picked)) {
                if (!context.mounted) return;
                final confirmed = await _showCurrencyChangeWarning(
                  context,
                  oldCode ?? baseCurrency,
                  picked,
                  color,
                  textTheme,
                  spacing,
                );
                if (confirmed != true) return;
              }

              setState(() {
                _selectedCurrency = newIsBase ? null : picked;
              });
            },
            child: Padding(
              padding: EdgeInsets.all(spacing.cardInner),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _selectedColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      meta?.symbol ?? displayCode,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _selectedColor,
                      ),
                    ),
                  ),
                  SizedBox(width: spacing.elementGap * 1.5),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayCode,
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          isBase
                              ? '${meta?.name ?? ''} (base currency)'
                              : meta?.name ?? '',
                          style: textTheme.bodySmall?.copyWith(
                            color: color.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isBase && _isEditing)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () async {
                          HapticFeedback.lightImpact();
                          final confirmed = await _showCurrencyChangeWarning(
                            context,
                            displayCode,
                            baseCurrency,
                            color,
                            textTheme,
                            spacing,
                          );
                          if (confirmed == true) {
                            setState(() => _selectedCurrency = null);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color.primary.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(spacing.radiusSmall),
                          ),
                          child: Text(
                            ctxt.account_resetTo(baseCurrency),
                            style: textTheme.labelSmall?.copyWith(
                              color: color.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Icon(
                    LucideIcons.chevronRight,
                    color: color.onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: spacing.elementGap),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: spacing.elementGap),
          child: Text(
            isBase
                ? ctxt.account_baseCurrencyInfo
                : ctxt.account_foreignCurrencyInfo(displayCode, baseCurrency),
            style: textTheme.bodySmall?.copyWith(
              color: color.onSurfaceVariant.withValues(alpha: 0.6),
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Future<bool?> _showCurrencyChangeWarning(
    BuildContext context,
    String fromCode,
    String toCode,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return showModalBottomSheet<bool>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(spacing.radiusSmall * 2),
        ),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          24 + MediaQuery.of(ctx).padding.bottom,
        ),
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
            SizedBox(height: spacing.sectionGap),
            Icon(LucideIcons.triangleAlert, size: 36, color: color.error),
            SizedBox(height: spacing.elementGap * 1.5),
            Text(
              ctxt.account_changeCurrency,
              style:
                  textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: spacing.elementGap),
            // From → To
            Container(
              padding: EdgeInsets.all(spacing.cardInner),
              decoration: BoxDecoration(
                color: color.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(spacing.radiusMedium),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    fromCode,
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing.elementGap * 1.5,
                    ),
                    child: Icon(
                      LucideIcons.arrowRight,
                      size: 18,
                      color: color.error,
                    ),
                  ),
                  Text(
                    toCode,
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            SizedBox(height: spacing.sectionGap),
            Container(
              padding: EdgeInsets.all(spacing.cardInner),
              decoration: BoxDecoration(
                color: color.error.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(spacing.radiusMedium),
                border: Border.all(color: color.error.withValues(alpha: 0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow(
                    ctxt.account_warningNoConvert,
                    color,
                    textTheme,
                  ),
                  SizedBox(height: spacing.elementGap),
                  _infoRow(
                    ctxt.account_warningNewCurrency,
                    color,
                    textTheme,
                  ),
                  SizedBox(height: spacing.elementGap),
                  _infoRow(
                    ctxt.account_warningManualAdjust,
                    color,
                    textTheme,
                  ),
                ],
              ),
            ),
            SizedBox(height: spacing.sectionGap),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => ctx.pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(spacing.radiusMedium),
                      ),
                    ),
                    child: Text(AppLocalizations.of(context)!.common_cancel),
                  ),
                ),
                SizedBox(width: spacing.elementGap * 1.5),
                Expanded(
                  child: FilledButton(
                    onPressed: () => ctx.pop(true),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(spacing.radiusMedium),
                      ),
                    ),
                    child: Text(ctxt.common_change),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String text, ColorScheme color, TextTheme textTheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(LucideIcons.dot, size: 16, color: color.onSurfaceVariant),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: textTheme.bodySmall?.copyWith(
              color: color.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  void _pickColor() async {
    final c = await showDialog<Color>(
      context: context,
      builder: (_) => SimpleColorPickerDialog(initialColor: _selectedColor),
    );
    if (c != null) setState(() => _selectedColor = c);
  }

  Future<void> _saveAccount(Id? id, AppSpacing spacing) async {
    // ── Entitlement check (new accounts only) ──
    if (!_isEditing) {
      final canCreate = await ref.read(canCreateAccountProvider.future);
      if (!canCreate) {
        SnackbarService.warning(
          'Free plan allows up to 3 accounts. Upgrade to Pro for unlimited.',
          spacing,
        );
        return;
      }
    }

    if (!_formKey.currentState!.validate()) {
      // Focus first invalid field
      if (_nameController.text.trim().isNotEmpty) {
        FocusScope.of(context).requestFocus(_accountNumberFocusNode);
      } else {
        FocusScope.of(context).requestFocus(_nameFocusNode);
      }
      return;
    }

    setState(() => _saving = true);

    try {
      final isarService = ref.read(isarServiceProvider);
      final isar = await isarService.getInstance();

      final accountName = _nameController.text.trim();
      final accountNumber = _accountNumberController.text.trim();

      final existingName =
          await isar.accounts.filter().nameEqualTo(accountName).findFirst();
      if (existingName != null && existingName.id != id) {
        SnackbarService.warning(
          'Account with name "$accountName" already exists',
          spacing,
        );
        return;
      }

      if (accountNumber.isNotEmpty) {
        final existingNum = await isar.accounts
            .filter()
            .accountNumberEqualTo(accountNumber)
            .findFirst();
        if (existingNum != null && existingNum.id != id) {
          SnackbarService.warning(
            'Account with number "$accountNumber" already exists',
            spacing,
          );
          return;
        }
      }

      final account = widget.account ?? Account();
      final isNew = widget.account == null;

      account
        ..name = accountName
        ..initialBalance = double.tryParse(_balanceController.text) ?? 0.0
        ..accountType = _selectedType
        ..accountNumber = accountNumber.isEmpty ? null : accountNumber
        ..colorValue = _selectedColor.toARGB32()
        ..currencyCode = _selectedCurrency
        ..isActive = true;

      if (_selectedType == AccountType.creditCard) {
        account
          ..statementDay = _statementDay
          ..dueDay = _dueDay
          ..creditLimit = double.tryParse(_creditLimitController.text);
      } else {
        account
          ..statementDay = null
          ..dueDay = null
          ..creditLimit = null;
      }

      await isar.writeTxn(() async {
        await isar.accounts.put(account);
      });

      if (isNew) {
        final gamificationService =
            await ref.read(gamificationServiceInitProvider.future);
        await gamificationService.track(GamificationEvent.accountCreated);
      }

      ref.invalidate(accountsProvider);
      ref.invalidate(allAccountsProvider);
      ref.invalidate(frequencySortedAccountsProvider);
      if (context.mounted) context.pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _CurrencyPickerInline extends ConsumerStatefulWidget {
  final String selected;
  const _CurrencyPickerInline({required this.selected});

  @override
  ConsumerState<_CurrencyPickerInline> createState() =>
      _CurrencyPickerInlineState();
}

class _CurrencyPickerInlineState extends ConsumerState<_CurrencyPickerInline> {
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
    final ctxt = AppLocalizations.of(context)!;
    final spacing = ref.watch(spacingProvider);

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
                hintText: ctxt.common_searchCurrency,
                prefixIcon: const Icon(LucideIcons.search, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(spacing.radiusSmall),
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
