import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
          padding: EdgeInsets.symmetric(
            horizontal: spacing.cardHorizontal,
            vertical: spacing.cardVertical,
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
                      '₹ ${balance.toStringAsFixed(2)}',
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
                LucideIcons.indianRupee,
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
