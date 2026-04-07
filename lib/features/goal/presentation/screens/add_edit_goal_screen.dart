import 'package:mudra_manager/shared/widgets/currency_badge.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';

import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:mudra_manager/core/db/models/goal.dart';
import 'package:mudra_manager/core/entitlement/entitlement_provider.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/tone/tone_provider.dart';
import 'package:mudra_manager/core/utils/icon_helper.dart';
import 'package:mudra_manager/core/utils/simple_color_picker.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/goal/data/goal_provider.dart';

import 'package:mudra_manager/features/profile/presentation/widgets/icon_picker_bottom_sheet.dart';

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

  Future<void> _saveGoal() async {
    if (_saving) return;
    if (widget.goal == null) {
      final canCreate = await ref.read(canCreateGoalProvider.future);
      if (!canCreate) {
        SnackbarService.warning(
          'Free plan allows up to 2 goals. Upgrade to Pro for unlimited.',
        );
        return;
      }
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final goal = widget.goal ?? Goal();
    goal.name = _nameController.text.trim();
    goal.targetAmount = double.parse(_amountController.text.trim());
    goal.currentAmount = double.parse(
      _currentAmountController.text.trim().isEmpty
          ? '0'
          : _currentAmountController.text.trim(),
    );
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

    if (mounted) {
      HapticFeedback.mediumImpact();
      SnackbarService.success(
        widget.goal == null
            ? Tone.current.goalCreated
            : Tone.current.goalUpdated,
      );
      context.pop();
    }
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
          _isEditing ? 'Edit Goal' : 'New Goal',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildHero(color, textTheme, spacing),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: spacing.cardHorizontalMax,
                vertical: spacing.cardVertical,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAppearanceSection(color, textTheme, spacing),
                  SizedBox(height: spacing.sectionGap * 1.5),
                  _buildNameField(color, textTheme, spacing),
                  SizedBox(height: spacing.sectionGap * 1.5),
                  _buildTargetAmountSection(color, textTheme, spacing),
                  SizedBox(height: spacing.sectionGap * 1.5),
                  _buildCurrentSavingsSection(color, textTheme, spacing),
                  SizedBox(height: spacing.sectionGap * 1.5),
                  _buildTargetDateSection(color, textTheme, spacing, ctxt),
                  if (_target > 0 && _targetDate != null) ...[
                    SizedBox(height: spacing.sectionGap),
                    _buildSmartInsight(color, textTheme, spacing),
                  ],
                  if (_target > 0 && _targetDate != null) ...[
                    SizedBox(height: spacing.sectionGap),
                    _buildGoalHealth(color, textTheme, spacing),
                  ],
                  SizedBox(height: spacing.sectionGap * 1.5),
                  _buildDescriptionSection(color, textTheme, spacing),
                  SizedBox(height: spacing.sectionGap * 5),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: MediaQuery.of(context).viewInsets.bottom > 0
          ? null
          : _buildStickyButton(color, textTheme, spacing),
    );
  }

  Widget _buildHero(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    final name = _nameController.text.trim();
    final displayName = name.isEmpty ? 'Your Goal' : name;

    return Container(
      padding: EdgeInsets.fromLTRB(
        spacing.cardHorizontalMax,
        spacing.sectionGap,
        spacing.cardHorizontalMax,
        spacing.sectionGap * 1.5,
      ),
      decoration: const BoxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                ),
                child: Icon(
                  IconHelper.getIconData(_selectedIcon),
                  color: Colors.white,
                  size: 28,
                ),
              ),
              SizedBox(width: spacing.elementGap * 1.5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_target > 0)
                      Text(
                        '${formatCurrency(_current, code: _selectedCurrency, decimals: 0)} / ${formatCurrency(_target, code: _selectedCurrency, decimals: 0)}',
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                  ],
                ),
              ),
              if (_target > 0)
                Text(
                  '${(_progress * 100).toStringAsFixed(0)}%',
                  style: textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          SizedBox(height: spacing.elementGap * 1.5),
          ClipRRect(
            borderRadius: BorderRadius.circular(spacing.radiusSmall),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: _progress),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (_, value, __) => LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.25),
                valueColor: const AlwaysStoppedAnimation(Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // BATCH 3
  Widget _buildAppearanceSection(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(
          'Appearance',
          LucideIcons.palette,
          color,
          textTheme,
          spacing,
        ),
        SizedBox(height: spacing.elementGap),
        Row(
          children: [
            Expanded(
              child: _appearanceTile(
                onTap: _pickIcon,
                child: Icon(
                  IconHelper.getIconData(_selectedIcon),
                  size: 36,
                  color: _selectedColor,
                ),
                label: 'Icon',
                color: color,
                textTheme: textTheme,
                spacing: spacing,
                isLeft: true,
              ),
            ),
            SizedBox(width: spacing.elementGap),
            Expanded(
              child: _appearanceTile(
                onTap: _pickColor,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _selectedColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.outline.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                ),
                label: 'Color',
                color: color,
                textTheme: textTheme,
                spacing: spacing,
                isLeft: false,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _appearanceTile({
    required VoidCallback onTap,
    required Widget child,
    required String label,
    required ColorScheme color,
    required TextTheme textTheme,
    required AppSpacing spacing,
    required bool isLeft,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(spacing.radiusMedium),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: spacing.cardInner),
        decoration: BoxDecoration(
          color: isLeft
              ? _selectedColor.withValues(alpha: 0.1)
              : color.surfaceContainerLow,
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          border: Border.all(
            color: isLeft
                ? _selectedColor.withValues(alpha: 0.3)
                : color.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          children: [
            child,
            SizedBox(height: spacing.elementGap),
            Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: color.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(
    String title,
    IconData icon,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _selectedColor),
        SizedBox(width: spacing.elementGap),
        Text(
          title,
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // BATCH 4
  Widget _buildNameField(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Goal Name', LucideIcons.goal, color, textTheme, spacing),
        SizedBox(height: spacing.elementGap),
        TextFormField(
          controller: _nameController,
          autofocus: !_isEditing,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'e.g., Trip to Goa, New Laptop',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
              borderSide: BorderSide(color: _selectedColor, width: 2),
            ),
          ),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Give your goal a name' : null,
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  // BATCH 5
  Widget _buildTargetAmountSection(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    final chips = [10000, 25000, 50000, 100000, 500000];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(
          'Target Amount',
          currencyIcon(_selectedCurrency),
          color,
          textTheme,
          spacing,
        ),
        SizedBox(height: spacing.elementGap),
        TextFormField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
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
          validator: (v) => v == null ||
                  double.tryParse(v.trim()) == null ||
                  double.parse(v.trim()) <= 0
              ? 'Enter a valid target amount'
              : null,
          onChanged: (_) => setState(() {}),
        ),
        SizedBox(height: spacing.elementGap),
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
      ],
    );
  }

  // BATCH 6
  Widget _buildCurrentSavingsSection(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    final reachedGoal = _current > 0 && _target > 0 && _current >= _target;
    final overTarget = _current > 0 && _target > 0 && _current > _target;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(
          'Already Saved',
          LucideIcons.piggyBank,
          color,
          textTheme,
          spacing,
        ),
        SizedBox(height: spacing.elementGap),
        TextFormField(
          controller: _currentAmountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
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
          onChanged: (_) => setState(() {}),
        ),
        if (reachedGoal) ...[
          SizedBox(height: spacing.elementGap),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.cardInner,
              vertical: spacing.elementGap,
            ),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
              border: Border.all(
                color: Colors.green.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Text('🎉', style: TextStyle(fontSize: 20)),
                SizedBox(width: spacing.elementGap),
                Expanded(
                  child: Text(
                    overTarget
                        ? "You've exceeded your target!"
                        : "You've already reached this goal!",
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else if (_target > 0 && _current > 0) ...[
          SizedBox(height: spacing.elementGap),
          Text(
            '${formatCurrency(_remaining, code: _selectedCurrency, decimals: 0)} more to go',
            style: textTheme.bodySmall?.copyWith(
              color: color.onSurfaceVariant,
            ),
          ),
        ],
      ],
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
          'Target Date',
          LucideIcons.calendar,
          color,
          textTheme,
          spacing,
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
                            ? 'Set a target date (optional)'
                            : DateFormat('dd MMM yyyy', ctxt.localeName)
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
                          '$_daysLeft days left',
                          style: textTheme.bodySmall?.copyWith(
                            color: color.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                if (_targetDate != null)
                  IconButton(
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

  // BATCH 8
  Widget _buildSmartInsight(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    if (_remaining <= 0 || _daysLeft <= 0) return const SizedBox.shrink();

    final daily =
        formatCurrency(_dailyNeeded, code: _selectedCurrency, decimals: 0);
    final monthly =
        formatCurrency(_monthlyNeeded, code: _selectedCurrency, decimals: 0);

    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        color: _selectedColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(color: _selectedColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.lightbulb, size: 16, color: _selectedColor),
              SizedBox(width: spacing.elementGap),
              Text(
                'Smart Insight',
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _selectedColor,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.elementGap),
          _insightRow('Save $daily/day to reach your goal', textTheme, color),
          SizedBox(height: spacing.elementGapMin),
          _insightRow('Or $monthly/month', textTheme, color),
        ],
      ),
    );
  }

  Widget _insightRow(String text, TextTheme textTheme, ColorScheme color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: _selectedColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: textTheme.bodySmall?.copyWith(
              color: color.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  // BATCH 9
  Widget _buildGoalHealth(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    if (_remaining <= 0) {
      return _healthChip(
        icon: LucideIcons.partyPopper,
        label: 'Goal Reached!',
        subtitle: Tone.current.goalMilestone100(_nameController.text.trim()),
        chipColor: Colors.green,
        textTheme: textTheme,
        spacing: spacing,
      );
    }

    if (_daysLeft <= 0) return const SizedBox.shrink();

    // Classify health based on daily savings needed
    final Color healthColor;
    final String label;
    final String subtitle;
    final IconData icon;

    if (_dailyNeeded <= 0) {
      return const SizedBox.shrink();
    } else if (_dailyNeeded < _target * 0.005) {
      // Very achievable — less than 0.5% of target per day
      healthColor = Colors.green;
      label = 'On Track';
      subtitle = 'This goal is very achievable 👍';
      icon = LucideIcons.circleCheck;
    } else if (_dailyNeeded < _target * 0.02) {
      // Moderate
      healthColor = Colors.orange;
      label = 'Needs Effort';
      subtitle = 'Needs a bit more saving discipline';
      icon = LucideIcons.triangleAlert;
    } else {
      // Aggressive
      healthColor = Colors.red.shade400;
      label = 'Ambitious';
      subtitle = 'Consider extending the deadline';
      icon = LucideIcons.circleAlert;
    }

    return _healthChip(
      icon: icon,
      label: label,
      subtitle: subtitle,
      chipColor: healthColor,
      textTheme: textTheme,
      spacing: spacing,
    );
  }

  Widget _healthChip({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color chipColor,
    required TextTheme textTheme,
    required AppSpacing spacing,
  }) {
    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(color: chipColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: chipColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: chipColor),
          ),
          SizedBox(width: spacing.elementGap * 1.5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: chipColor,
                  ),
                ),
                Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: chipColor.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // BATCH 10
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
            'Add a note (optional)',
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
              'Note',
              LucideIcons.fileText,
              color,
              textTheme,
              spacing,
            ),
            const Spacer(),
            IconButton(
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
            hintText: 'What\'s this goal about?',
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

  // BATCH 11
  Widget _buildStickyButton(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    final enabled = _isFormValid && !_saving;

    return Container(
      padding: EdgeInsets.fromLTRB(
        spacing.cardHorizontalMax,
        spacing.elementGap,
        spacing.cardHorizontalMax,
        spacing.sectionGap + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: color.surface,
        boxShadow: [
          BoxShadow(
            color: color.shadow.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: FilledButton(
        onPressed: enabled ? _saveGoal : null,
        style: FilledButton.styleFrom(
          backgroundColor: _selectedColor,
          disabledBackgroundColor: _selectedColor.withValues(alpha: 0.3),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(spacing.radiusMedium),
          ),
        ),
        child: _saving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                _isEditing ? 'Update Goal' : 'Create Goal',
                style: textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
