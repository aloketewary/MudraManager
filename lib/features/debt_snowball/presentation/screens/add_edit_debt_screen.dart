import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:mudra_manager/core/db/models/debt.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/simple_color_picker.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/debt_snowball/data/debt_provider.dart';
import 'package:mudra_manager/shared/widgets/currency_badge.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';

class AddEditDebtScreen extends ConsumerStatefulWidget {
  final Debt? debt;

  const AddEditDebtScreen({super.key, this.debt});

  @override
  ConsumerState<AddEditDebtScreen> createState() => _AddEditDebtScreenState();
}

class _AddEditDebtScreenState extends ConsumerState<AddEditDebtScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _balanceController;
  late TextEditingController _rateController;
  late TextEditingController _minPaymentController;
  late TextEditingController _extraPaymentController;
  Color _selectedColor = const Color(0xFFE53935);
  bool _saving = false;

  bool get _isEditing => widget.debt != null;

  @override
  void initState() {
    super.initState();
    final debt = widget.debt;
    _nameController = TextEditingController(text: debt?.name);
    _balanceController =
        TextEditingController(text: debt?.balance.toStringAsFixed(0));
    _rateController =
        TextEditingController(text: debt?.interestRate.toString());
    _minPaymentController =
        TextEditingController(text: debt?.minimumPayment.toStringAsFixed(0));
    _extraPaymentController = TextEditingController(
      text: debt?.extraPayment != null
          ? debt!.extraPayment!.toStringAsFixed(0)
          : '',
    );
    if (debt?.colorValue != null) {
      _selectedColor = Color(debt!.colorValue!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _rateController.dispose();
    _minPaymentController.dispose();
    _extraPaymentController.dispose();
    super.dispose();
  }

  Future<void> _pickColor() async {
    HapticFeedback.lightImpact();
    final color = await showDialog<Color>(
      context: context,
      builder: (_) => SimpleColorPickerDialog(initialColor: _selectedColor),
    );
    if (color != null) setState(() => _selectedColor = color);
  }

  Future<void> _save(AppSpacing spacing, AppLocalizations ctxt) async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final router = GoRouter.of(context);

    final debt = widget.debt ?? Debt();
    debt.name = _nameController.text.trim();
    debt.balance =
        double.tryParse(_balanceController.text.trim().replaceAll(',', '')) ??
            0;
    debt.interestRate = double.tryParse(_rateController.text.trim()) ?? 0;
    debt.minimumPayment = double.tryParse(
          _minPaymentController.text.trim().replaceAll(',', ''),
        ) ??
        0;
    final extraText = _extraPaymentController.text.trim().replaceAll(',', '');
    debt.extraPayment = extraText.isEmpty ? null : double.tryParse(extraText);
    debt.iconName = 'debt';
    debt.colorValue = _selectedColor.toARGB32();

    final service = ref.read(debtServiceProvider);
    if (widget.debt == null) {
      await service.addDebt(debt);
    } else {
      await service.updateDebt(debt);
    }
    ref.invalidate(debtsProvider);

    if (!mounted) return;
    HapticFeedback.mediumImpact();
    SnackbarService.success(
      _isEditing ? '${debt.name} updated' : '${debt.name} added',
      spacing,
    );
    router.pop();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        title: Text(
          _isEditing ? ctxt.debt_editDebt : ctxt.debt_addDebt,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saving ? null : () => _save(spacing, ctxt),
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
                    _isEditing ? ctxt.common_update : ctxt.common_create,
                    style:
                        textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
          ),
          SizedBox(width: spacing.cardHorizontal),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(spacing.cardInner),
          children: [
            _buildHero(color, textTheme, spacing),
            SizedBox(height: spacing.sectionGap),
            _sectionLabel(ctxt.debt_name, textTheme),
            SizedBox(height: spacing.elementGap),
            TextFormField(
              controller: _nameController,
              autofocus: !_isEditing,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: ctxt.debt_nameHint,
                prefixIcon: Icon(LucideIcons.scale, size: 20, color: _selectedColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  borderSide: BorderSide(color: _selectedColor, width: 2),
                ),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? ctxt.debt_nameRequired : null,
            ),
            SizedBox(height: spacing.sectionGap),
            _sectionLabel(ctxt.debt_balance, textTheme),
            SizedBox(height: spacing.elementGap),
            _amountField(
              controller: _balanceController,
              hint: '0',
              spacing: spacing,
              textTheme: textTheme,
              validator: (v) {
                final val = double.tryParse((v ?? '').replaceAll(',', ''));
                return (val == null || val <= 0) ? ctxt.debt_balanceRequired : null;
              },
              onChanged: () => setState(() {}),
            ),
            SizedBox(height: spacing.sectionGap),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel(ctxt.debt_interestRate, textTheme),
                      SizedBox(height: spacing.elementGap),
                      TextFormField(
                        controller: _rateController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: '0',
                          suffixText: '%',
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(spacing.radiusMedium),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(spacing.radiusMedium),
                            borderSide:
                                BorderSide(color: _selectedColor, width: 2),
                          ),
                        ),
                        validator: (v) {
                          final val = double.tryParse(v ?? '');
                          return (val == null || val < 0)
                              ? ctxt.debt_interestRateRequired
                              : null;
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(width: spacing.elementGap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel(ctxt.debt_minimumPayment, textTheme),
                      SizedBox(height: spacing.elementGap),
                      _amountField(
                        controller: _minPaymentController,
                        hint: '0',
                        spacing: spacing,
                        textTheme: textTheme,
                        validator: (v) {
                          final val =
                              double.tryParse((v ?? '').replaceAll(',', ''));
                          return (val == null || val <= 0)
                              ? ctxt.debt_minimumPaymentRequired
                              : null;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.sectionGap),
            _sectionLabel(ctxt.debt_extraPaymentOptional, textTheme),
            SizedBox(height: spacing.elementGap),
            _amountField(
              controller: _extraPaymentController,
              hint: ctxt.debt_extraPaymentHint,
              spacing: spacing,
              textTheme: textTheme,
              required: false,
            ),
            SizedBox(height: spacing.sectionGap * 1.5),
            _sectionLabel(ctxt.goal_appearance, textTheme),
            SizedBox(height: spacing.elementGap),
            _buildColorPicker(color, spacing),
            SizedBox(height: spacing.sectionGap * 2),
          ],
        ),
      ),
    );
  }

  Widget _amountField({
    required TextEditingController controller,
    required String hint,
    required AppSpacing spacing,
    required TextTheme textTheme,
    String? Function(String?)? validator,
    VoidCallback? onChanged,
    bool required = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged != null ? (_) => onChanged() : null,
      decoration: InputDecoration(
        hintText: hint,
        prefix: Padding(
          padding: const EdgeInsets.only(right: 6),
          child: CurrencyBadge(code: BaseCurrency.code, size: 14),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          borderSide: BorderSide(color: _selectedColor, width: 2),
        ),
      ),
      validator: required ? validator : null,
    );
  }

  Widget _sectionLabel(String text, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: textTheme.titleSmall
            ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.3),
      ),
    );
  }

  Widget _buildHero(ColorScheme color, TextTheme textTheme, AppSpacing spacing) {
    final isDark = color.brightness == Brightness.dark;
    final name = _nameController.text.trim();
    final balance =
        double.tryParse(_balanceController.text.trim().replaceAll(',', '')) ?? 0;

    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _selectedColor.withValues(alpha: isDark ? 0.20 : 0.12),
            color.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(color: _selectedColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(spacing.elementGap),
            decoration: BoxDecoration(
              color: _selectedColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(spacing.radiusSmall),
            ),
            child: Icon(LucideIcons.scale, color: _selectedColor, size: 24),
          ),
          SizedBox(width: spacing.elementGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'New debt' : name,
                  style:
                      textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (balance > 0)
                  CurrencyText(
                    amount: balance,
                    fixedLength: 0,
                    style: textTheme.bodyMedium?.copyWith(
                      color: _selectedColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const _quickColors = [
    Color(0xFFE53935),
    Color(0xFFEF6C00),
    Color(0xFFF9A825),
    Color(0xFF2E7D32),
    Color(0xFF00838F),
    Color(0xFF1565C0),
    Color(0xFF6A1B9A),
    Color(0xFF616161),
  ];

  Widget _buildColorPicker(ColorScheme color, AppSpacing spacing) {
    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickColors.map((c) {
              final isSelected = _selectedColor.toARGB32() == c.toARGB32();
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _selectedColor = c);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: color.onSurface, width: 2.5)
                        : null,
                    boxShadow: isSelected
                        ? [BoxShadow(color: c.withValues(alpha: 0.4), blurRadius: 8)]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(LucideIcons.check, color: Colors.white, size: 14)
                      : null,
                ),
              );
            }).toList(),
          ),
        ),
        SizedBox(width: spacing.radiusMedium),
        GestureDetector(
          onTap: _pickColor,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color.outlineVariant, width: 1.5),
            ),
            child: Icon(
              LucideIcons.ellipsis,
              size: 14,
              color: color.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
