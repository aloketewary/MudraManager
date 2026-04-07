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
import 'package:mudra_manager/features/gamification/models/gamification_enum.dart';

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
  late AccountType _selectedType;
  late Color _selectedColor;
  String? _selectedCurrency;
  bool _saving = false;

  bool get _isEditing => widget.account != null;

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
    _accountNumberController = TextEditingController(
      text: widget.account?.accountNumber ?? widget.accountNumber ?? '',
    );
    _balanceController = TextEditingController(
      text: widget.account?.initialBalance.toString() ?? '',
    );
    _selectedType = widget.account?.accountType ?? AccountType.cash;
    _selectedColor = widget.account?.colorValue != null
        ? Color(widget.account!.colorValue!)
        : const Color(0xFF2196F3);
    _selectedCurrency = widget.account?.currencyCode;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _accountNumberController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: () {
            HapticFeedback.mediumImpact();
            context.pop();
          },
        ),
        title: Text(
          _isEditing ? 'Edit Account' : 'New Account',
        ),
        actions: [
          TextButton(
            onPressed: _saving
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    _saveAccount(widget.account?.id);
                  },
            child: _saving
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color.primary,
                    ),
                  )
                : Text(
                    _isEditing ? 'Update' : 'Create',
                    style: textTheme.titleSmall?.copyWith(
                      color: color.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.only(
            left: spacing.cardHorizontal,
            right: spacing.cardHorizontal,
            top: spacing.cardVertical,
            bottom: MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight + spacing.sectionGap,
          ),
          children: [
            _buildHeroPreview(
              color,
              textTheme,
              spacing,
            ),
            SizedBox(height: spacing.sectionGap),
            _sectionLabel('Account Type', textTheme),
            SizedBox(
              height: spacing.sectionGap,
            ),
            _buildTypeGrid(
              color,
              textTheme,
              spacing,
            ),
            SizedBox(height: spacing.sectionGap),
            _sectionLabel('Details', textTheme),
            SizedBox(height: spacing.sectionGap),
            _buildDetailsCard(
              color,
              textTheme,
              spacing,
            ),
            SizedBox(height: spacing.sectionGap),
            _sectionLabel('Color', textTheme),
            SizedBox(height: spacing.sectionGap),
            _buildColorSection(
              color,
              textTheme,
              spacing,
            ),
            SizedBox(height: spacing.sectionGap),
            _sectionLabel('Currency', textTheme),
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
  ) {
    final name = _nameController.text.trim();
    final number = _accountNumberController.text.trim();
    final balance = double.tryParse(_balanceController.text) ?? 0.0;
    final isCreditCard = _selectedType == AccountType.creditCard;

    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _selectedColor.withValues(alpha: 0.2),
            _selectedColor.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _selectedColor.withValues(alpha: 0.18),
                    _selectedColor.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _selectedColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _selectedColor.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  _selectedType.icon,
                  size: 28,
                  color: _selectedColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'Account Name' : name,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: name.isEmpty
                            ? color.onSurfaceVariant.withValues(alpha: 0.4)
                            : color.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _selectedColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
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
                          const SizedBox(width: 8),
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
                    const SizedBox(height: 10),
                    Text(
                      isCreditCard ? 'Outstanding' : 'Balance',
                      style: textTheme.labelSmall?.copyWith(
                        color: color.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                    Text(
                      formatCurrency(balance, code: _selectedCurrency, decimals: 2),
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: _selectedColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
  ) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.4,
      children: AccountType.values.map((type) {
        final isSelected = _selectedType == type;
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _selectedType = type);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? _selectedColor.withValues(alpha: 0.12)
                  : color.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
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
                const SizedBox(height: 6),
                Text(
                  type.label,
                  style: textTheme.labelSmall?.copyWith(
                    color: isSelected ? _selectedColor : color.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── DETAILS CARD ──
  Widget _buildDetailsCard(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    final isCreditCard = _selectedType == AccountType.creditCard;

    return Card(
      elevation: 0,
      color: color.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        side: BorderSide(
          color: color.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Account Name',
              prefixIcon: Icon(
                LucideIcons.wallet,
                size: 18,
                color: _selectedColor,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: spacing.cardHorizontal,
                vertical: spacing.cardVertical,
              ),
            ),
            style: textTheme.bodyLarge,
            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
          ),
          Divider(
            height: 1,
            indent: 48,
            color: color.outlineVariant.withValues(alpha: 0.3),
          ),
          SizedBox(
            height: spacing.elementGap,
          ),
          TextFormField(
            controller: _accountNumberController,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Last 4 digits',
              helperText: 'For SMS auto-matching',
              helperStyle: textTheme.labelSmall?.copyWith(
                color: color.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              prefixIcon: Icon(
                LucideIcons.hash,
                size: 18,
                color: _selectedColor,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            style: textTheme.bodyLarge,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Required';
              if (v.length < 4) return 'At least 4 digits';
              if (v.length > 4) return 'Only last 4 digits';
              return null;
            },
          ),
          Divider(
            height: 1,
            indent: 48,
            color: color.outlineVariant.withValues(alpha: 0.3),
          ),
          SizedBox(
            height: spacing.elementGap,
          ),
          TextFormField(
            controller: _balanceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: isCreditCard ? 'Outstanding amount' : 'Initial balance',
              helperText: isCreditCard ? 'Enter 0 if card is paid off' : null,
              helperStyle: textTheme.labelSmall?.copyWith(
                color: color.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              prefixIcon: Icon(
                currencyIcon(_selectedCurrency),
                size: 18,
                color: _selectedColor,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            style: textTheme.bodyLarge,
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
        ],
      ),
    );
  }

  // ── COLOR SECTION ──
  Widget _buildColorSection(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
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
                spacing: 10,
                runSpacing: 10,
                children: _quickColors.map((c) {
                  final isSelected = _selectedColor.toARGB32() == c.toARGB32();
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _selectedColor = c);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
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
                  );
                }).toList(),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
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
          ],
        ),
      ),
    );
  }

  // ── HELPERS ──

  Widget _sectionLabel(String text, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
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
    final baseCurrency = baseCurrencyAsync.valueOrNull ?? 'INR';
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
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                  context, oldCode ?? baseCurrency, picked, color, textTheme, spacing,
                );
                if (confirmed != true) return;
              }

              setState(() {
                _selectedCurrency = newIsBase ? null : picked;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
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
                  const SizedBox(width: 14),
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
                            context, displayCode, baseCurrency, color, textTheme, spacing,
                          );
                          if (confirmed == true) {
                            setState(() => _selectedCurrency = null);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(spacing.radiusSmall),
                          ),
                          child: Text(
                            'Reset to $baseCurrency',
                            style: textTheme.labelSmall?.copyWith(
                              color: color.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Icon(
                    Icons.chevron_right,
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
                ? 'Transactions in this account use your base currency.'
                : 'Transactions will be recorded in $displayCode and converted to $baseCurrency for totals.',
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(ctx).padding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: color.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: spacing.sectionGap),
            Icon(LucideIcons.triangleAlert, size: 36, color: color.error),
            SizedBox(height: spacing.elementGap * 1.5),
            Text(
              'Change Currency?',
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                  Text(fromCode, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: spacing.elementGap * 1.5),
                    child: Icon(LucideIcons.arrowRight, size: 18, color: color.error),
                  ),
                  Text(toCode, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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
                  _infoRow('Existing balances will NOT be converted automatically.', color, textTheme),
                  SizedBox(height: spacing.elementGap),
                  _infoRow('New transactions will use the new currency.', color, textTheme),
                  SizedBox(height: spacing.elementGap),
                  _infoRow('You may need to manually adjust the balance.', color, textTheme),
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
                        borderRadius: BorderRadius.circular(spacing.radiusMedium),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                SizedBox(width: spacing.elementGap * 1.5),
                Expanded(
                  child: FilledButton(
                    onPressed: () => ctx.pop(true),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(spacing.radiusMedium),
                      ),
                    ),
                    child: const Text('Change'),
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

  Future<void> _saveAccount(Id? id) async {
    // ── Entitlement check (new accounts only) ──
    if (!_isEditing) {
      final canCreate = await ref.read(canCreateAccountProvider.future);
      if (!canCreate) {
        SnackbarService.warning(
          'Free plan allows up to 3 accounts. Upgrade to Pro for unlimited.',
        );
        return;
      }
    }

    if (!_formKey.currentState!.validate()) return;

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

      await isar.writeTxn(() async {
        await isar.accounts.put(account);
      });

      if (isNew) {
        final gamificationService =
            await ref.read(gamificationServiceInitProvider.future);
        await gamificationService.track(GamificationEvent.accountCreated);
      }

      if (mounted) {
        invalidateAll(ref);
        context.pop(true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _CurrencyPickerInline extends StatefulWidget {
  final String selected;
  const _CurrencyPickerInline({required this.selected});

  @override
  State<_CurrencyPickerInline> createState() => _CurrencyPickerInlineState();
}

class _CurrencyPickerInlineState extends State<_CurrencyPickerInline> {
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
                hintText: 'Search currency...',
                prefixIcon: const Icon(Icons.search, size: 20),
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
                      ? Icon(Icons.check_circle, color: color.primary)
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
