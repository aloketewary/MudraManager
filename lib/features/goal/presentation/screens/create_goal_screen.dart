import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:mudra_manager/core/db/models/goal.dart';
import 'package:mudra_manager/core/entitlement/entitlement_provider.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/goal/data/goal_provider.dart';
import 'package:mudra_manager/features/goal/domain/goal_enums.dart';
import 'package:mudra_manager/shared/widgets/currency_badge.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';

class CreateGoalScreen extends ConsumerStatefulWidget {
  const CreateGoalScreen({super.key});

  @override
  ConsumerState<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends ConsumerState<CreateGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  final _currentController = TextEditingController();
  final _whyController = TextEditingController();

  GoalType? _selectedType;
  DateTime? _targetDate;
  bool _saving = false;

  double get _target =>
      double.tryParse(_targetController.text.trim().replaceAll(',', '')) ?? 0;
  double get _current =>
      double.tryParse(_currentController.text.trim().replaceAll(',', '')) ?? 0;
  double get _remaining => (_target - _current).clamp(0, double.infinity);
  bool get _isFormValid =>
      _nameController.text.trim().isNotEmpty && _target > 0;

  double? get _neededPerMonth {
    if (_targetDate == null || _remaining <= 0) return null;
    final daysLeft = _targetDate!.difference(DateTime.now()).inDays;
    if (daysLeft <= 0) return null;
    final months = (daysLeft / 30).clamp(0.1, double.infinity);
    return _remaining / months;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _currentController.dispose();
    _whyController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_saving) return;
    final ctxt = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate()) return;

    if (_current > _target) {
      SnackbarService.warning(ctxt.goal_currentExceedsTarget);
      return;
    }

    setState(() => _saving = true);

    try {
      final canCreate = await ref.read(canCreateGoalProvider.future);
      if (!canCreate) {
        SnackbarService.warning(ctxt.goal_freePlanLimit);
        setState(() => _saving = false);
        return;
      }

      final goal = Goal()
        ..name = _nameController.text.trim()
        ..targetAmount = _target
        ..currentAmount = _current
        ..targetDate = _targetDate
        ..goalType = _selectedType ?? GoalType.custom
        ..description = _whyController.text.trim().isEmpty
            ? null
            : _whyController.text.trim();

      await ref.read(goalServiceProvider).addGoal(goal);

      HapticFeedback.mediumImpact();
      SnackbarService.success(BuddyMessages.goalCreated);
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _saving = false);
      SnackbarService.error(e.toString());
    }
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
          ctxt.goal_newGoalTitle,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: (_isFormValid && !_saving) ? _create : null,
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
                    ctxt.goal_createGoal,
                    style: textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
          ),
          SizedBox(width: spacing.cardHorizontal),
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
            // ── Goal Type (optional) ──
            _buildGoalTypeGrid(color, textTheme, spacing, ctxt),
            SizedBox(height: spacing.sectionGap),

            // ── Goal Name ──
            TextFormField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: ctxt.goal_goalName,
                hintText: ctxt.goal_whatSavingFor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                ),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? ctxt.goal_giveGoalName : null,
            ),
            SizedBox(height: spacing.sectionGap),

            // ── Why? (optional) ──
            TextFormField(
              controller: _whyController,
              textCapitalization: TextCapitalization.sentences,
              maxLength: 80,
              decoration: InputDecoration(
                labelText: ctxt.goal_whyOptional,
                hintText: ctxt.goal_whyHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                ),
                counterText: '',
              ),
            ),
            SizedBox(height: spacing.sectionGap),

            // ── Target Amount ──
            TextFormField(
              controller: _targetController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: ctxt.goal_targetAmount,
                hintText: '0',
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 12, right: 4),
                  child: CurrencyBadge(code: BaseCurrency.code, size: 32),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 0,
                  minHeight: 0,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                ),
              ),
              validator: (v) {
                final val = double.tryParse(
                      v?.trim().replaceAll(',', '') ?? '',
                    ) ??
                    0;
                return val <= 0 ? ctxt.goal_enterValidTarget : null;
              },
            ),
            SizedBox(height: spacing.sectionGap),

            // ── Target Date (optional) ──
            _buildTargetDate(color, textTheme, spacing, ctxt),
            SizedBox(height: spacing.sectionGap),

            // ── Current Savings ──
            TextFormField(
              controller: _currentController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: ctxt.goal_currentSavings,
                hintText: '0',
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 12, right: 4),
                  child: CurrencyBadge(code: BaseCurrency.code, size: 32),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 0,
                  minHeight: 0,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                ),
              ),
              validator: (v) {
                final current = double.tryParse(
                      v?.trim().replaceAll(',', '') ?? '',
                    ) ??
                    0;
                if (current > 0 && _target > 0 && current > _target) {
                  return ctxt.goal_currentExceedsTarget;
                }
                return null;
              },
            ),

            // ── Live Projection ──
            if (_target > 0) ...[
              SizedBox(height: spacing.sectionGap * 1.5),
              _buildProjection(color, textTheme, spacing, ctxt),
            ],

            SizedBox(height: spacing.sectionGap * 3),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalTypeGrid(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    final types = GoalType.values;

    return Wrap(
      spacing: spacing.elementGap,
      runSpacing: spacing.elementGap,
      children: types.map((type) {
        final isSelected = _selectedType == type;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              _selectedType = _selectedType == type ? null : type;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: spacing.elementGap,
              vertical: spacing.elementGapMin,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.primaryContainer
                  : color.surfaceContainerLow,
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
              border: Border.all(
                color: isSelected ? color.primary : color.outlineVariant,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  type.icon,
                  size: spacing.iconSM,
                  color: isSelected ? color.primary : color.onSurfaceVariant,
                ),
                SizedBox(width: spacing.elementGapMin),
                Text(
                  _goalTypeLabel(type, ctxt),
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? color.primary : color.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTargetDate(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    return InkWell(
      onTap: () async {
        HapticFeedback.lightImpact();
        final picked = await showDatePicker(
          context: context,
          initialDate:
              _targetDate ?? DateTime.now().add(const Duration(days: 365)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 36500)),
        );
        if (picked != null) setState(() => _targetDate = picked);
      },
      borderRadius: BorderRadius.circular(spacing.radiusMedium),
      child: Container(
        padding: EdgeInsets.all(spacing.cardInner),
        decoration: BoxDecoration(
          color: color.surfaceContainerLow,
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          border: Border.all(color: color.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(
              LucideIcons.calendar,
              size: spacing.iconSM,
              color:
                  _targetDate != null ? color.primary : color.onSurfaceVariant,
            ),
            SizedBox(width: spacing.elementGap),
            Expanded(
              child: Text(
                _targetDate != null
                    ? _formatDate(_targetDate!)
                    : ctxt.goal_setTargetDate,
                style: textTheme.bodyLarge?.copyWith(
                  color: _targetDate != null
                      ? color.onSurface
                      : color.onSurfaceVariant,
                ),
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
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjection(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(color: color.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ctxt.goal_suffixLeft,
                style: textTheme.labelSmall
                    ?.copyWith(color: color.onSurfaceVariant),
              ),
              CurrencyText(
                amount: _remaining,
                fixedLength: 0,
                compact: false,
                style: textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          if (_neededPerMonth != null) ...[
            SizedBox(height: spacing.elementGap),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  ctxt.goal_neededPerMonth,
                  style: textTheme.labelSmall
                      ?.copyWith(color: color.onSurfaceVariant),
                ),
                CurrencyText(
                  amount: _neededPerMonth!,
                  fixedLength: 0,
                  compact: true,
                  suffixText: '/mo',
                  style: textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _goalTypeLabel(GoalType type, AppLocalizations ctxt) {
    return switch (type) {
      GoalType.house => ctxt.goal_typeHouse,
      GoalType.vehicle => ctxt.goal_typeVehicle,
      GoalType.travel => ctxt.goal_typeTravel,
      GoalType.education => ctxt.goal_typeEducation,
      GoalType.wedding => ctxt.goal_typeWedding,
      GoalType.custom => ctxt.goal_typeCustom,
    };
  }

  String _formatDate(DateTime date) {
    final months = date.difference(DateTime.now()).inDays ~/ 30;
    final formatted = '${_monthName(date.month)} ${date.year}';
    if (months > 0) return '$formatted ($months mo)';
    return formatted;
  }

  String _monthName(int month) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[month - 1];
  }
}
