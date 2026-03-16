import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/goal.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
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
    if (widget.goal?.colorValue != null) {
      _selectedColor = Color(widget.goal!.colorValue!);
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
    if (!_formKey.currentState!.validate()) return;

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
            ? 'Goal created successfully'
            : 'Goal updated successfully',
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;

    final targetAmount = double.tryParse(_amountController.text.trim()) ?? 0;
    final currentAmount =
        double.tryParse(_currentAmountController.text.trim()) ?? 0;
    final remaining = (targetAmount - currentAmount).clamp(0, double.infinity);
    final progress =
        targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        title: Text(
          widget.goal == null ? 'Add Goal' : 'Edit Goal',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _saveGoal,
            icon: const Icon(LucideIcons.save, size: 20),
            label: Text(widget.goal == null ? 'Create' : 'Update'),
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
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.cardHorizontal,
                  vertical: spacing.cardVertical,
                ),
                children: [
                  // Icon & Color Picker Section
                  _buildSectionHeader(
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
                        child: _buildIconPicker(color, textTheme, spacing),
                      ),
                      SizedBox(width: spacing.elementGap),
                      Expanded(
                        child: _buildColorPicker(color, textTheme, spacing),
                      ),
                    ],
                  ),

                  SizedBox(height: spacing.sectionGap * 1.5),

                  // Basic Information
                  _buildSectionHeader(
                    'Basic Information',
                    LucideIcons.info,
                    color,
                    textTheme,
                    spacing,
                  ),
                  SizedBox(height: spacing.elementGap),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Goal Name',
                      hintText: 'e.g., New Laptop, Vacation',
                      prefixIcon: const Icon(LucideIcons.goal),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(spacing.radiusMedium),
                      ),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  SizedBox(height: spacing.elementGap),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description (Optional)',
                      hintText: 'Add details about your goal',
                      prefixIcon: const Icon(LucideIcons.fileText),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(spacing.radiusMedium),
                      ),
                    ),
                    maxLines: 3,
                  ),

                  SizedBox(height: spacing.sectionGap * 1.5),

                  // Target Amount
                  _buildSectionHeader(
                    'Target Amount',
                    LucideIcons.indianRupee,
                    color,
                    textTheme,
                    spacing,
                  ),
                  SizedBox(height: spacing.elementGap),
                  TextFormField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: 'Target Amount',
                      hintText: '0',
                      prefixIcon: const Icon(LucideIcons.target),
                      prefixText: '₹',
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(spacing.radiusMedium),
                      ),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => v == null ||
                            double.tryParse(v.trim()) == null ||
                            double.parse(v.trim()) <= 0
                        ? 'Enter valid amount'
                        : null,
                    onChanged: (v) => setState(() {}),
                  ),

                  SizedBox(height: spacing.sectionGap * 1.5),

                  // Current Savings
                  _buildSectionHeader(
                    'Current Savings',
                    LucideIcons.piggyBank,
                    color,
                    textTheme,
                    spacing,
                  ),
                  SizedBox(height: spacing.elementGap),
                  TextFormField(
                    controller: _currentAmountController,
                    decoration: InputDecoration(
                      labelText: 'Current Amount',
                      hintText: '0',
                      prefixIcon: const Icon(LucideIcons.wallet),
                      prefixText: '₹',
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(spacing.radiusMedium),
                      ),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (v) => setState(() {}),
                  ),

                  SizedBox(height: spacing.elementGap * 1.5),

                  // Progress Summary Card
                  if (targetAmount > 0)
                    Container(
                      padding: EdgeInsets.all(spacing.cardInner),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _selectedColor.withValues(alpha: 0.15),
                            _selectedColor.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius:
                            BorderRadius.circular(spacing.radiusLarge),
                        border: Border.all(
                          color: _selectedColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Progress',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: color.onSurfaceVariant,
                                    ),
                                  ),
                                  SizedBox(height: spacing.elementGap * 0.5),
                                  Text(
                                    '${(progress * 100).toStringAsFixed(0)}%',
                                    style: textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: _selectedColor,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Remaining',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: color.onSurfaceVariant,
                                    ),
                                  ),
                                  SizedBox(height: spacing.elementGap * 0.5),
                                  Text(
                                    '₹${remaining.toStringAsFixed(0)}',
                                    style: textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: color.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: spacing.elementGap * 1.5),
                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(spacing.radiusSmall),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              backgroundColor: color.surfaceContainerHighest,
                              valueColor:
                                  AlwaysStoppedAnimation(_selectedColor),
                            ),
                          ),
                        ],
                      ),
                    ),

                  SizedBox(height: spacing.sectionGap * 1.5),

                  // Target Date
                  _buildSectionHeader(
                    'Target Date',
                    LucideIcons.calendar,
                    color,
                    textTheme,
                    spacing,
                  ),
                  SizedBox(height: spacing.elementGap),
                  _buildDateButton(context, color, textTheme, ctxt, spacing),

                  SizedBox(height: spacing.sectionGap * 5),
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: EdgeInsets.all(spacing.sectionGap),
            decoration: BoxDecoration(
              color: color.surface,
              boxShadow: [
                BoxShadow(
                  color: color.shadow.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color.primary),
        SizedBox(width: spacing.elementGap),
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildIconPicker(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return InkWell(
      onTap: _pickIcon,
      borderRadius:
          BorderRadius.horizontal(left: Radius.circular(spacing.radiusMedium)),
      child: Container(
        padding: EdgeInsets.all(spacing.cardInner),
        decoration: BoxDecoration(
          color: _selectedColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.horizontal(
              left: Radius.circular(spacing.radiusMedium)),
          border: Border.all(
            color: _selectedColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              IconHelper.getIconData(_selectedIcon),
              size: 48,
              color: _selectedColor,
            ),
            SizedBox(height: spacing.elementGap),
            Text(
              'Icon',
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

  Widget _buildColorPicker(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return InkWell(
      onTap: _pickColor,
      borderRadius:
          BorderRadius.horizontal(right: Radius.circular(spacing.radiusMedium)),
      child: Container(
        padding: EdgeInsets.all(spacing.cardInner),
        decoration: BoxDecoration(
          color: color.surfaceContainerLow,
          borderRadius: BorderRadius.horizontal(
              right: Radius.circular(spacing.radiusMedium)),
          border: Border.all(
            color: color.outlineVariant.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _selectedColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.outline.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
            ),
            SizedBox(height: spacing.elementGap),
            Text(
              'Color',
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

  Widget _buildDateButton(
    BuildContext context,
    ColorScheme color,
    TextTheme textTheme,
    AppLocalizations ctxt,
    AppSpacing spacing,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: _targetDate != null
            ? color.primaryContainer
            : color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(spacing.radiusLarge),
        border: Border.all(
          color: _targetDate != null
              ? color.primary.withValues(alpha: 0.5)
              : color.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: InkWell(
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
        borderRadius: BorderRadius.circular(spacing.radiusLarge),
        child: Padding(
          padding: EdgeInsets.all(spacing.cardInner),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(spacing.elementGap),
                decoration: BoxDecoration(
                  color: _targetDate != null
                      ? color.primary.withValues(alpha: 0.15)
                      : color.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(spacing.radiusSmall),
                ),
                child: Icon(
                  LucideIcons.calendar,
                  color: _targetDate != null
                      ? color.primary
                      : color.onSurfaceVariant,
                  size: 20,
                ),
              ),
              SizedBox(width: spacing.elementGap * 1.5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Target Date',
                      style: textTheme.bodySmall?.copyWith(
                        color: color.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: spacing.elementGap * 0.25),
                    Text(
                      _targetDate == null
                          ? 'Not set (Optional)'
                          : DateFormat('dd MMM yyyy', ctxt.localeName)
                              .format(_targetDate!),
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _targetDate != null
                            ? color.onPrimaryContainer
                            : color.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                size: 20,
                color: color.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
