import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:mudra_manager/core/db/models/goal.dart';
import 'package:mudra_manager/core/db/extensions/field_encryption_ext.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/state/app_screen_state.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:mudra_manager/core/utils/dialog_utils.dart';
import 'package:mudra_manager/core/utils/safe_date_format.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/goal/data/goal_provider.dart';
import 'package:mudra_manager/features/goal/domain/goal_enums.dart';
import 'package:mudra_manager/shared/templates/screen_shell.dart';
import 'package:mudra_manager/shared/widgets/currency_badge.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';

class EditGoalScreen extends ConsumerStatefulWidget {
  final Goal goal;
  const EditGoalScreen({super.key, required this.goal});

  @override
  ConsumerState<EditGoalScreen> createState() => _EditGoalScreenState();
}

class _EditGoalScreenState extends ConsumerState<EditGoalScreen> {
  late TextEditingController _nameController;
  late TextEditingController _whyController;
  late GoalType _goalType;
  late DateTime? _targetDate;
  late double _targetAmount;

  bool _saving = false;
  bool _adjustingTarget = false;
  late TextEditingController _targetController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.goal.name);
    _whyController = TextEditingController(text: widget.goal.description ?? '');
    _goalType = widget.goal.goalType;
    _targetDate = widget.goal.targetDate;
    _targetAmount = widget.goal.targetAmount;
    _targetController =
        TextEditingController(text: _targetAmount.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _whyController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  double get _remaining =>
      (_targetAmount - widget.goal.currentAmount).clamp(0, double.infinity);

  double? get _neededPerMonth {
    if (_targetDate == null || _remaining <= 0) return null;
    final daysLeft = _targetDate!.difference(DateTime.now()).inDays;
    if (daysLeft <= 0) return null;
    return _remaining / (daysLeft / 30).clamp(0.1, double.infinity);
  }

  double get _avgMonthlyPace {
    final contributions = widget.goal.contributions;
    if (contributions.isEmpty) return 0;
    final total = contributions.fold(0.0, (sum, c) => sum + c.amount);
    final first =
        contributions.reduce((a, b) => a.date.isBefore(b.date) ? a : b).date;
    final months = DateTime.now().difference(first).inDays / 30;
    if (months < 1) return total;
    return total / months;
  }

  DateTime? get _projectedCompletion {
    final pace = _avgMonthlyPace;
    if (pace <= 0 || _remaining <= 0) return null;
    final monthsNeeded = _remaining / pace;
    return DateTime.now().add(Duration(days: (monthsNeeded * 30).ceil()));
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_nameController.text.trim().isEmpty) {
      SnackbarService.warning(
        AppLocalizations.of(context)!.goal_giveGoalName,
      );
      return;
    }

    // Validate target not below current savings
    if (_targetAmount < widget.goal.currentAmount) {
      SnackbarService.warning(
        AppLocalizations.of(context)!.goal_targetBelowSaved,
      );
      return;
    }

    setState(() => _saving = true);

    final goal = widget.goal
      ..name = _nameController.text.trim()
      ..targetAmount = _targetAmount
      ..targetDate = _targetDate
      ..goalType = _goalType
      ..description = _whyController.text.trim().isEmpty
          ? null
          : _whyController.text.trim();

    await ref.read(goalServiceProvider).updateGoal(goal);
    // Decrypt back so in-memory object stays readable
    goal.decryptFields();

    HapticFeedback.mediumImpact();
    SnackbarService.success(BuddyMessages.goalUpdated);
    if (mounted) context.pop();
  }

  Future<void> _deleteGoal() async {
    final ctxt = AppLocalizations.of(context)!;
    final confirmed = await DialogUtils.showDeleteConfirmation(
      context,
      title: ctxt.goal_deleteGoalTitle,
    );
    if (confirmed == true && mounted) {
      await ref.read(goalServiceProvider).deleteGoal(widget.goal.id);
      SnackbarService.success(BuddyMessages.goalDeleted);
      if (mounted) context.pop();
    }
  }

  Future<void> _markCompleted() async {
    final goal = widget.goal
      ..currentAmount = widget.goal.targetAmount
      ..isActive = false;
    await ref.read(goalServiceProvider).updateGoal(goal);
    goal.decryptFields();
    SnackbarService.success(BuddyMessages.goalUpdated);
    if (mounted) context.pop();
  }

  Future<void> _archiveGoal() async {
    final goal = widget.goal..isActive = false;
    await ref.read(goalServiceProvider).updateGoal(goal);
    goal.decryptFields();
    SnackbarService.success(BuddyMessages.goalUpdated);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;

    return ScreenShell(
      config: ScreenShellConfig(
        title: ctxt.goal_editGoalTitle,
        appBarMode: AppBarMode.standard,
        enableRefresh: false,
      ),
      actions: ScreenActions.build(
        trailing: ScreenTextAction(
          id: 'save_goal',
          label: ctxt.goal_updateGoal,
          onTap: !_saving ? _save : null,
          isLoading: _saving,
        ),
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.cardHorizontal,
          vertical: spacing.cardVertical,
        ),
        children: [
          // ═══ SECTION A: GOAL IDENTITY ═══
          _sectionHeader(ctxt.goal_sectionIdentity, textTheme),
          SizedBox(height: spacing.elementGap),

          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: ctxt.goal_goalName,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(spacing.radiusMedium),
              ),
            ),
          ),
          SizedBox(height: spacing.elementGap),

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
          SizedBox(height: spacing.elementGap),

          // Goal Type selector
          _buildGoalTypeRow(color, textTheme, spacing, ctxt),

          SizedBox(height: spacing.sectionGap * 1.5),

          // ═══ SECTION B: TARGET ═══
          _sectionHeader(ctxt.goal_target, textTheme),
          SizedBox(height: spacing.elementGap),

          // Target amount with "Adjust" pattern
          _buildTargetAdjust(color, textTheme, spacing, ctxt),
          SizedBox(height: spacing.elementGap),

          // Target date
          _buildTargetDate(color, textTheme, spacing, ctxt),

          SizedBox(height: spacing.sectionGap * 1.5),

          // ═══ SECTION C: CURRENT STATE (read-only) ═══
          _sectionHeader(ctxt.goal_sectionCurrentState, textTheme),
          SizedBox(height: spacing.elementGap),
          _buildCurrentState(color, textTheme, spacing, ctxt),

          SizedBox(height: spacing.sectionGap * 1.5),

          // ═══ SECTION D: PROJECTION (read-only) ═══
          _sectionHeader(ctxt.goal_sectionProjection, textTheme),
          SizedBox(height: spacing.elementGap),
          _buildProjection(color, textTheme, spacing, ctxt),

          SizedBox(height: spacing.sectionGap * 2),

          // ═══ SECTION E: DANGER ZONE ═══
          _buildDangerZone(color, textTheme, spacing, ctxt),

          SizedBox(height: spacing.sectionGap * 3),
        ],
      ),
    );
  }

  Widget _sectionHeader(String text, TextTheme textTheme) {
    return Text(
      text,
      style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
    );
  }

  Widget _buildGoalTypeRow(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    return Wrap(
      spacing: spacing.elementGapMin,
      runSpacing: spacing.elementGapMin,
      children: GoalType.values.map((type) {
        final isSelected = _goalType == type;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _goalType = type);
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
                  size: spacing.iconXS,
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

  Widget _buildTargetAdjust(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    if (!_adjustingTarget) {
      return Container(
        padding: EdgeInsets.all(spacing.cardInner),
        decoration: BoxDecoration(
          color: color.surfaceContainerLow,
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          border: Border.all(color: color.outlineVariant),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ctxt.goal_currentTarget,
                    style: textTheme.labelSmall
                        ?.copyWith(color: color.onSurfaceVariant),
                  ),
                  const SizedBox(height: 2),
                  CurrencyText(
                    amount: _targetAmount,
                    fixedLength: 0,
                    compact: false,
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _adjustingTarget = true),
              child: Text(ctxt.goal_adjustTarget),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        TextFormField(
          controller: _targetController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: InputDecoration(
            labelText: ctxt.goal_targetAmount,
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 12, right: 4),
              child: CurrencyBadge(
                code: widget.goal.currencyCode ?? BaseCurrency.code,
                size: 32,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
            ),
            suffixIcon: IconButton(
              icon: Icon(LucideIcons.check, size: 20, color: color.primary),
              onPressed: () {
                final newTarget = double.tryParse(
                  _targetController.text.trim().replaceAll(',', ''),
                );
                if (newTarget != null && newTarget > 0) {
                  setState(() {
                    _targetAmount = newTarget;
                    _adjustingTarget = false;
                  });
                }
              },
            ),
          ),
        ),
        // Warning if target below current savings
        if ((double.tryParse(
                  _targetController.text.trim().replaceAll(',', ''),
                ) ??
                _targetAmount) <
            widget.goal.currentAmount) ...[
          SizedBox(height: spacing.elementGapMin),
          Text(
            ctxt.goal_targetBelowSaved,
            style: textTheme.bodySmall?.copyWith(color: color.error),
          ),
        ],
      ],
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
              color: color.onSurfaceVariant,
            ),
            SizedBox(width: spacing.elementGap),
            Expanded(
              child: Text(
                _targetDate != null
                    ? safeDateFormat('MMM yyyy', ctxt.localeName)
                        .format(_targetDate!)
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

  Widget _buildCurrentState(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    final sortedContribs = widget.goal.contributions.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final lastContrib = sortedContribs.isNotEmpty ? sortedContribs.first : null;

    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(color: color.outlineVariant),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ctxt.goal_saved,
                style: textTheme.labelSmall
                    ?.copyWith(color: color.onSurfaceVariant),
              ),
              CurrencyText(
                currencyCode: widget.goal.currencyCode,
                amount: widget.goal.currentAmount,
                fixedLength: 0,
                compact: false,
                style: textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          if (lastContrib != null) ...[
            SizedBox(height: spacing.elementGap),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  ctxt.goal_lastContribution,
                  style: textTheme.labelSmall
                      ?.copyWith(color: color.onSurfaceVariant),
                ),
                Row(
                  children: [
                    CurrencyText(
                      currencyCode: widget.goal.currencyCode,
                      amount: lastContrib.amount,
                      fixedLength: 0,
                      compact: true,
                      style: textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      ' · ${_timeAgo(lastContrib.date, ctxt)}',
                      style: textTheme.bodySmall
                          ?.copyWith(color: color.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
          ],
          if (sortedContribs.length > 1) ...[
            SizedBox(height: spacing.elementGap),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  // Navigate to contribution history
                },
                child: Text(
                  ctxt.goal_viewHistory,
                  style: textTheme.labelSmall?.copyWith(color: color.primary),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProjection(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    final pace = _avgMonthlyPace;
    final projected = _projectedCompletion;

    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(color: color.outlineVariant),
      ),
      child: Column(
        children: [
          _projectionRow(
            ctxt.goal_suffixLeft,
            _remaining,
            color,
            textTheme,
          ),
          if (_neededPerMonth != null) ...[
            SizedBox(height: spacing.elementGap),
            _projectionRow(
              ctxt.goal_neededPerMonth,
              _neededPerMonth!,
              color,
              textTheme,
              suffix: '/mo',
            ),
          ],
          if (pace > 0) ...[
            SizedBox(height: spacing.elementGap),
            _projectionRow(
              ctxt.goal_currentAvgMonth,
              pace,
              color,
              textTheme,
              suffix: '/mo',
            ),
          ],
          if (projected != null) ...[
            SizedBox(height: spacing.elementGap),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  ctxt.goal_forecastLabel,
                  style: textTheme.labelSmall
                      ?.copyWith(color: color.onSurfaceVariant),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      safeDateFormat('MMM yyyy', ctxt.localeName)
                          .format(projected),
                      style: textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      ctxt.goal_basedOnAvg(
                        formatCurrency(pace,
                            code: widget.goal.currencyCode, decimals: 0,),
                      ),
                      style: textTheme.labelSmall?.copyWith(
                        color: color.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _projectionRow(
    String label,
    double amount,
    ColorScheme color,
    TextTheme textTheme, {
    String? suffix,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(color: color.onSurfaceVariant),
        ),
        CurrencyText(
          currencyCode: widget.goal.currencyCode,
          amount: amount,
          fixedLength: 0,
          compact: true,
          suffixText: suffix,
          style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildDangerZone(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(color: color.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          _dangerAction(
            icon: LucideIcons.archive,
            label: ctxt.goal_archive,
            color: color,
            textTheme: textTheme,
            spacing: spacing,
            onTap: _archiveGoal,
          ),
          Divider(height: 1, color: color.error.withValues(alpha: 0.15)),
          _dangerAction(
            icon: LucideIcons.circleCheck,
            label: ctxt.goal_markComplete,
            color: color,
            textTheme: textTheme,
            spacing: spacing,
            onTap: _markCompleted,
          ),
          Divider(height: 1, color: color.error.withValues(alpha: 0.15)),
          _dangerAction(
            icon: LucideIcons.trash2,
            label: ctxt.goal_deleteGoal,
            color: color,
            textTheme: textTheme,
            spacing: spacing,
            onTap: _deleteGoal,
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _dangerAction({
    required IconData icon,
    required String label,
    required ColorScheme color,
    required TextTheme textTheme,
    required AppSpacing spacing,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final actionColor = isDestructive ? color.error : color.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(spacing.radiusMedium),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.cardInner,
          vertical: spacing.cardInner,
        ),
        child: Row(
          children: [
            Icon(icon, size: spacing.iconSM, color: actionColor),
            SizedBox(width: spacing.elementGap),
            Text(
              label,
              style: textTheme.bodyMedium?.copyWith(color: actionColor),
            ),
          ],
        ),
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

  String _timeAgo(DateTime date, AppLocalizations ctxt) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return ctxt.common_today;
    if (diff.inDays == 1) return ctxt.common_yesterday;
    return ctxt.goal_daysAgo(diff.inDays);
  }
}
