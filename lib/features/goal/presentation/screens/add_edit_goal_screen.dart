import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/core/utils/safe_date_format.dart';
import 'package:mudra_manager/shared/widgets/currency_badge.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:mudra_manager/core/db/models/goal.dart';
import 'package:mudra_manager/core/entitlement/entitlement_provider.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:mudra_manager/core/utils/icon_helper.dart';
import 'package:mudra_manager/core/utils/simple_color_picker.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/goal/data/goal_provider.dart';

import 'package:mudra_manager/features/profile/presentation/widgets/icon_picker_bottom_sheet.dart';
import 'package:mudra_manager/shared/widgets/widgets.dart';

class AddEditGoalScreen extends ConsumerStatefulWidget {
  final Goal? goal;

  const AddEditGoalScreen({super.key, this.goal});

  @override
  ConsumerState<AddEditGoalScreen> createState() => _AddEditGoalScreenState();
}

class _AddEditGoalScreenState extends ConsumerState<AddEditGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late TextEditingController _currentAmountController;
  late TextEditingController _descriptionController;
  DateTime? _targetDate;
  String _selectedIcon = 'savings';
  Color _selectedColor = Colors.blue;
  String? _selectedCurrency;
  bool _descriptionExpanded = false;
  bool _saving = false;

  // ── Computed helpers ──
  bool get _isEditing => widget.goal != null;
  double get _target => double.tryParse(_amountController.text.trim()) ?? 0;
  double get _current =>
      double.tryParse(_currentAmountController.text.trim()) ?? 0;
  double get _remaining => (_target - _current).clamp(0, double.infinity);
  double get _progress =>
      _target > 0 ? (_current / _target).clamp(0.0, 1.0) : 0.0;

  int get _daysLeft =>
      _targetDate != null ? _targetDate!.difference(DateTime.now()).inDays : 0;

  double get _dailyNeeded =>
      (_daysLeft > 0 && _remaining > 0) ? _remaining / _daysLeft : 0;

  double get _monthlyNeeded => (_daysLeft > 0 && _remaining > 0)
      ? _remaining / (_daysLeft / 30).clamp(0.1, double.infinity)
      : 0;

  bool get _isFormValid =>
      _nameController.text.trim().isNotEmpty && _target > 0;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.goal?.name);
    _amountController = TextEditingController(
      text: widget.goal?.targetAmount.toString(),
    );
    _currentAmountController = TextEditingController(
      text: widget.goal?.currentAmount.toString(),
    );
    _descriptionController =
        TextEditingController(text: widget.goal?.description);
    _targetDate = widget.goal?.targetDate;
    _selectedIcon = widget.goal?.iconName ?? 'savings';
    _selectedCurrency = widget.goal?.currencyCode;
    if (widget.goal?.colorValue != null) {
      _selectedColor = Color(widget.goal!.colorValue!);
    }
    if (widget.goal?.description?.isNotEmpty == true) {
      _descriptionExpanded = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _currentAmountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _pickIcon() async {
    HapticFeedback.lightImpact();
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => IconPickerBottomSheet(backgroundColor: _selectedColor),
    );
    if (result != null) setState(() => _selectedIcon = result);
  }

  void _pickColor() async {
    HapticFeedback.lightImpact();
    final color = await showDialog<Color>(
      context: context,
      builder: (_) => SimpleColorPickerDialog(initialColor: _selectedColor),
    );
    if (color != null) setState(() => _selectedColor = color);
  }

  Future<void> _saveGoal(AppSpacing spacing) async {
    if (_saving) return;
    if (widget.goal == null) {
      final limitMsg = AppLocalizations.of(context)!.goal_freePlanLimit;
      final canCreate = await ref.read(canCreateGoalProvider.future);
      if (!canCreate) {
        SnackbarService.warning(limitMsg, spacing);
        return;
      }
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final router = GoRouter.of(context);
    final goal = widget.goal ?? Goal();
    goal.name = _nameController.text.trim();
    goal.targetAmount =
        double.tryParse(_amountController.text.trim().replaceAll(',', '')) ?? 0;
    goal.currentAmount = double.tryParse(
          _currentAmountController.text.trim().replaceAll(',', ''),
        ) ??
        0;
    goal.targetDate = _targetDate;
    goal.iconName = _selectedIcon;
    goal.colorValue = _selectedColor.toARGB32();
    goal.currencyCode = _selectedCurrency;
    goal.description = _descriptionController.text.trim().isEmpty
        ? null
        : _descriptionController.text.trim();

    final service = ref.read(goalServiceProvider);
    if (widget.goal == null) {
      await service.addGoal(goal);
    } else {
      await service.updateGoal(goal);
    }
    ref.invalidate(goalsProvider);

    HapticFeedback.mediumImpact();
    SnackbarService.success(
      widget.goal == null
          ? BuddyMessages.goalCreated
          : BuddyMessages.goalUpdated,
          spacing
    );
    router.pop();
  }

  // ── BUILD (scaffold) ── will call sub-builders ──

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
          _isEditing ? ctxt.goal_editGoalTitle : ctxt.goal_newGoalTitle,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => (_isFormValid && !_saving) ? _saveGoal(spacing) : null,
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
                    _isEditing ? ctxt.goal_updateGoal : ctxt.goal_createGoal,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
          SizedBox(width: spacing.cardHorizontal),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildHero(
                    color,
                    textTheme,
                    spacing,
                    ctxt,
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing.cardHorizontalMax,
                      vertical: spacing.cardVertical,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildNameField(color, textTheme, spacing),
                        SizedBox(height: spacing.sectionGap),
                        _sectionLabel(ctxt.goal_amount, textTheme),
                        SizedBox(height: spacing.elementGap),
                        _buildAmountFields(color, textTheme, spacing),
                        SizedBox(height: spacing.sectionGap * 1.5),
                        _buildTargetDateSection(
                          color,
                          textTheme,
                          spacing,
                          ctxt,
                        ),
                        if (_target > 0 && _targetDate != null) ...[
                          SizedBox(height: spacing.sectionGap),
                          _buildCombinedInsight(color, textTheme, spacing),
                        ],
                        SizedBox(height: spacing.sectionGap * 1.5),
                        _sectionLabel(ctxt.goal_appearance, textTheme),
                        SizedBox(height: spacing.sectionGap),
                        _buildAppearanceCard(
                          color,
                          textTheme,
                          spacing,
                          ctxt,
                        ),
                        SizedBox(height: spacing.sectionGap * 1.5),
                        _buildDescriptionSection(color, textTheme, spacing),
                        SizedBox(height: spacing.sectionGap * 2),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    final name = _nameController.text.trim();
    final displayName =
        name.isEmpty ? AppLocalizations.of(context)!.goal_yourGoal : name;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Emotional context
    final emotionLine = _progress >= 1.0
        ? ctxt.goal_emotionReached
        : _progress >= 0.5
            ? ctxt.goal_emotionProgress
            : _target > 0 && _current > 0
                ? ctxt.goal_emotionMoreToGo(
                    formatCurrency(
                      _remaining,
                      code: _selectedCurrency,
                      decimals: 0,
                    ),
                  )
                : _target > 0
                    ? ctxt.goal_emotionSetTarget
                    : ctxt.goal_emotionWhatSaving;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontal,
        vertical: spacing.cardVertical,
      ),
      padding: EdgeInsets.all(spacing.cardInner + spacing.elementGapMin),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _selectedColor.withValues(alpha: isDark ? 0.2 : 0.12),
            _selectedColor.withValues(alpha: isDark ? 0.08 : 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(color: _selectedColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(spacing.elementGap * 0.75),
                decoration: BoxDecoration(
                  color: _selectedColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(spacing.radiusSmall),
                ),
                child: Icon(
                  IconHelper.getIconData(_selectedIcon),
                  color: _selectedColor,
                  size: 24,
                ),
              ),
              SizedBox(width: spacing.elementGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: spacing.elementGapUltraMin),
                    Text(
                      emotionLine,
                      style: textTheme.bodySmall?.copyWith(
                        color: _selectedColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_target > 0) ...[
            SizedBox(height: spacing.elementGap),
            // Human-readable amounts
            Row(
              children: [
                if (_current > 0) ...[
                  CurrencyText(
                    amount: _current,
                    showSign: false,
                    compact: false,
                    showCode: false,
                    fixedLength: 0,
                    suffixText: ctxt.goal_saved.toLowerCase(),
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _selectedColor,
                    ),
                  ),
                  Text(
                    '  •  ',
                    style: textTheme.bodySmall
                        ?.copyWith(color: color.outlineVariant),
                  ),
                ],
                Text(
                  '${(_progress * 100).toStringAsFixed(0)}% done',
                  style: textTheme.bodySmall
                      ?.copyWith(color: _selectedColor.withValues(alpha: 0.7)),
                ),
              ],
            ),
            SizedBox(height: spacing.elementGap),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(spacing.radiusSmall),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: _progress),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                builder: (_, value, __) => Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: _selectedColor.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(spacing.radiusSmall),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: value.clamp(0.0, 1.0),
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _selectedColor.withValues(alpha: 0.6),
                              _selectedColor,
                            ],
                          ),
                          borderRadius:
                              BorderRadius.circular(spacing.radiusSmall),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: spacing.elementGapMin),
            Align(
              alignment: Alignment.centerLeft,
              child: CurrencyText(
                amount: _remaining,
                showSign: false,
                compact: false,
                showCode: false,
                fixedLength: 0,
                suffixText: ctxt.budget_left.toLowerCase(),
                style: textTheme.bodySmall
                    ?.copyWith(color: color.onSurfaceVariant),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── SECTION LABEL ──
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

  // ── NAME FIELD ──
  Widget _buildNameField(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    final ctxt = AppLocalizations.of(context)!;
    return TextFormField(
      controller: _nameController,
      autofocus: !_isEditing,
      textCapitalization: TextCapitalization.words,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: ctxt.goal_whatSavingFor,
        prefixIcon: Icon(
          IconHelper.getIconData(_selectedIcon),
          size: 20,
          color: _selectedColor,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          borderSide: BorderSide(color: _selectedColor, width: 2),
        ),
      ),
      style: textTheme.bodyLarge,
      validator: (v) =>
          v == null || v.trim().isEmpty ? ctxt.goal_giveGoalName : null,
    );
  }

  // ── AMOUNT FIELDS (target + chips + saved + live progress) ──
  Widget _buildAmountFields(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    final ctxt = AppLocalizations.of(context)!;
    final reachedGoal = _current > 0 && _target > 0 && _current >= _target;
    final chips = [10000, 25000, 50000, 100000, 500000];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Target
        TextFormField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: ctxt.goal_targetAmount,
            hintText: '0',
            prefix: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: CurrencyBadge(
                code: _selectedCurrency ?? BaseCurrency.code,
                size: 14,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
              borderSide: BorderSide(color: _selectedColor, width: 2),
            ),
          ),
          style: textTheme.bodyLarge,
          validator: (v) => v == null ||
                  (double.tryParse(v.trim().replaceAll(',', '')) ?? 0) <= 0
              ? ctxt.goal_enterValidTarget
              : null,
        ),
        SizedBox(height: spacing.elementGap),
        // Quick chips
        Wrap(
          spacing: spacing.elementGap,
          runSpacing: spacing.elementGapMin,
          children: chips.map((v) {
            final label = v >= 100000
                ? '${(v / 100000).toStringAsFixed(v % 100000 == 0 ? 0 : 1)}L'
                : '${(v / 1000).toStringAsFixed(0)}K';
            final isSelected = _target == v.toDouble();
            return ChoiceChip(
              label: Text(
                '${currencySymbol(_selectedCurrency)}$label',
                style: textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : color.onSurfaceVariant,
                ),
              ),
              selected: isSelected,
              selectedColor: _selectedColor,
              backgroundColor: color.surfaceContainerLow,
              side: BorderSide(
                color: isSelected
                    ? _selectedColor
                    : color.outlineVariant.withValues(alpha: 0.5),
              ),
              onSelected: (_) {
                HapticFeedback.selectionClick();
                _amountController.text = v.toString();
                setState(() {});
              },
            );
          }).toList(),
        ),
        SizedBox(height: spacing.sectionGap),
        // Already saved
        TextFormField(
          controller: _currentAmountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: ctxt.goal_alreadySaved,
            hintText: '0',
            prefix: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: CurrencyBadge(
                code: _selectedCurrency ?? BaseCurrency.code,
                size: 14,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
              borderSide: BorderSide(color: _selectedColor, width: 2),
            ),
          ),
          style: textTheme.bodyLarge,
        ),
        // Live feedback text
        if (_target > 0 && _current > 0) ...[
          SizedBox(height: spacing.elementGap),
          Text(
            reachedGoal
                ? (_current > _target
                    ? ctxt.goal_exceededTarget
                    : ctxt.goal_alreadyReached)
                : ctxt.goal_progressLeft(
                    (_progress * 100).toStringAsFixed(0),
                    formatCurrency(
                      _remaining,
                      code: _selectedCurrency,
                      decimals: 0,
                    ),
                  ),
            style: textTheme.bodySmall?.copyWith(
              color: reachedGoal
                  ? FinanceColors.statusGood
                  : color.onSurfaceVariant,
              fontWeight: reachedGoal ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ],
    );
  }

  // ── APPEARANCE CARD (compact — icon + color dots in one card) ──
  static const _quickColors = [
    Color(0xFFE53935),
    Color(0xFFE91E63),
    Color(0xFF9C27B0),
    Color(0xFF3F51B5),
    Color(0xFF2196F3),
    Color(0xFF00BCD4),
    Color(0xFF009688),
    Color(0xFF4CAF50),
    Color(0xFFFF9800),
    Color(0xFF795548),
  ];

  Widget _buildAppearanceCard(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    return Card(
      elevation: 0,
      color: color.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        side: BorderSide(color: color.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.cardInner),
        child: Column(
          children: [
            // Icon row
            InkWell(
              onTap: _pickIcon,
              borderRadius: BorderRadius.circular(spacing.radiusSmall),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: spacing.elementGap),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(spacing.elementGap * 0.75),
                      decoration: BoxDecoration(
                        color: _selectedColor.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(spacing.radiusSmall),
                      ),
                      child: Icon(
                        IconHelper.getIconData(_selectedIcon),
                        size: 22,
                        color: _selectedColor,
                      ),
                    ),
                    SizedBox(width: spacing.elementGap * 1.5),
                    Expanded(
                      child: Text(ctxt.goal_icon, style: textTheme.bodyLarge),
                    ),
                    Icon(
                      LucideIcons.chevronRight,
                      size: 18,
                      color: color.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            Divider(
              height: 1,
              color: color.outlineVariant.withValues(alpha: 0.3),
            ),
            // Color row
            Padding(
              padding: EdgeInsets.symmetric(vertical: spacing.elementGap),
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _quickColors.map((c) {
                        final isSelected =
                            _selectedColor.toARGB32() == c.toARGB32();
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
                                    size: 14,
                                  )
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
                        border:
                            Border.all(color: color.outlineVariant, width: 1.5),
                      ),
                      child: Icon(
                        LucideIcons.ellipsis,
                        size: 14,
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
    );
  }

  // ── MERGED INSIGHT + HEALTH (conversational) ──
  Widget _buildCombinedInsight(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    if (_remaining <= 0 || _daysLeft <= 0) return const SizedBox.shrink();
    final ctxt = AppLocalizations.of(context)!;

    final daily =
        formatCurrency(_dailyNeeded, code: _selectedCurrency, decimals: 0);
    final monthly =
        formatCurrency(_monthlyNeeded, code: _selectedCurrency, decimals: 0);

    // Health classification
    final Color healthColor;
    final String healthLabel;
    final IconData healthIcon;
    if (_dailyNeeded < _target * 0.005) {
      healthColor = FinanceColors.statusGood;
      healthLabel = AppLocalizations.of(context)!.goal_onTrack;
      healthIcon = LucideIcons.circleCheck;
    } else if (_dailyNeeded < _target * 0.02) {
      healthColor = FinanceColors.statusWarning;
      healthLabel = AppLocalizations.of(context)!.goal_needsEffort;
      healthIcon = LucideIcons.triangleAlert;
    } else {
      healthColor = FinanceColors.statusDanger;
      healthLabel = AppLocalizations.of(context)!.goal_ambitious;
      healthIcon = LucideIcons.circleAlert;
    }

    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        color: healthColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(color: healthColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(healthIcon, size: 18, color: healthColor),
              SizedBox(width: spacing.elementGap),
              Text(
                healthLabel,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: healthColor,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.elementGap),
          Text(
            ctxt.goal_paceDaily(daily, monthly),
            style: textTheme.bodySmall
                ?.copyWith(color: color.onSurface, height: 1.5),
          ),
          if (_daysLeft > 0) ...[
            SizedBox(height: spacing.elementGapMin),
            Text(
              ctxt.goal_daysRemaining(_daysLeft),
              style:
                  textTheme.labelSmall?.copyWith(color: color.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }

  // BATCH 7
  Widget _buildTargetDateSection(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(
          AppLocalizations.of(context)!.goal_targetDateLabel,
          textTheme,
        ),
        SizedBox(height: spacing.elementGap),
        InkWell(
          onTap: () async {
            HapticFeedback.lightImpact();
            final picked = await showDatePicker(
              context: context,
              initialDate:
                  _targetDate ?? DateTime.now().add(const Duration(days: 365)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 3650)),
            );
            if (picked != null) setState(() => _targetDate = picked);
          },
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          child: Container(
            padding: EdgeInsets.all(spacing.cardInner),
            decoration: BoxDecoration(
              color: _targetDate != null
                  ? _selectedColor.withValues(alpha: 0.08)
                  : color.surfaceContainerLow,
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
              border: Border.all(
                color: _targetDate != null
                    ? _selectedColor.withValues(alpha: 0.4)
                    : color.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.calendar,
                  color: _targetDate != null
                      ? _selectedColor
                      : color.onSurfaceVariant,
                  size: 22,
                ),
                SizedBox(width: spacing.elementGap * 1.5),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _targetDate == null
                            ? AppLocalizations.of(context)!.goal_setTargetDate
                            : safeDateFormat('dd MMM yyyy', ctxt.localeName)
                                .format(_targetDate!),
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _targetDate != null
                              ? color.onSurface
                              : color.onSurfaceVariant,
                        ),
                      ),
                      if (_targetDate != null && _daysLeft > 0)
                        Text(
                          ctxt.goal_daysLeft(_daysLeft),
                          style: textTheme.bodySmall?.copyWith(
                            color: color.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                if (_targetDate != null)
                  IconButton(
                    tooltip: 'Close',
                    icon: Icon(
                      LucideIcons.x,
                      size: 18,
                      color: color.onSurfaceVariant,
                    ),
                    onPressed: () => setState(() => _targetDate = null),
                    visualDensity: VisualDensity.compact,
                  )
                else
                  Icon(
                    LucideIcons.chevronRight,
                    size: 18,
                    color: color.onSurfaceVariant,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    if (!_descriptionExpanded) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => setState(() => _descriptionExpanded = true),
          icon: Icon(LucideIcons.plus, size: 16, color: color.onSurfaceVariant),
          label: Text(
            AppLocalizations.of(context)!.goal_addNote,
            style: textTheme.bodySmall?.copyWith(
              color: color.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _sectionLabel(
              AppLocalizations.of(context)!.goal_note,
              textTheme,
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Chevronup',
              icon: Icon(
                LucideIcons.chevronUp,
                size: 16,
                color: color.onSurfaceVariant,
              ),
              onPressed: () => setState(() => _descriptionExpanded = false),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        SizedBox(height: spacing.elementGap),
        TextFormField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.goal_whatsThisAbout,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
              borderSide: BorderSide(color: _selectedColor, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  // BATCH 10
}
