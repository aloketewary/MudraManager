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
import 'package:mudra_manager/features/goal/domain/goal_health.dart';
import 'package:mudra_manager/shared/templates/screen_shell.dart';
import 'package:mudra_manager/shared/widgets/currency_badge.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:mudra_manager/shared/widgets/finance_v2/finance_progress_bar.dart';
import 'package:mudra_manager/shared/widgets/safe_text.dart';

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
  int _step = 0;
  late TextEditingController _targetController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.goal.name.safe());
    _whyController =
        TextEditingController(text: widget.goal.description.safe());
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

  /// Recent pace (90-day rolling, lifetime fallback) — same calculation
  /// used by GoalDetailsScreen and GoalScreen, so the number shown here
  /// matches everywhere else in the app.
  double get _avgMonthlyPace => GoalHealth.recentMonthlyPace(widget.goal);

  /// Predicted completion date, live-reactive to the in-progress target
  /// edit (so previewing a higher target pushes the date out immediately).
  /// Uses the same confidence gate as GoalStateMachine.predictedCompletion
  /// (3+ contributions, 30+ days elapsed) so this screen doesn't show a
  /// confident forecast off a single early deposit while other screens
  /// correctly withhold it.
  DateTime? get _projectedCompletion {
    final elapsed = DateTime.now().difference(widget.goal.creationDate).inDays;
    if (widget.goal.contributions.length < 3 || elapsed < 30) return null;

    final pace = _avgMonthlyPace;
    if (pace <= 0 || _remaining <= 0) return null;
    final monthsNeeded = _remaining / pace;
    return DateTime.now().add(Duration(days: (monthsNeeded * 30).ceil()));
  }

  Future<void> _save(AppSpacing spacing) async {
    if (_saving) return;
    if (_nameController.text.trim().isEmpty) {
      SnackbarService.warning(
        AppLocalizations.of(context)!.goal_giveGoalName,
        spacing,
      );
      return;
    }

    // Validate target not below current savings
    if (_targetAmount < widget.goal.currentAmount) {
      SnackbarService.warning(
        AppLocalizations.of(context)!.goal_targetBelowSaved,
        spacing,
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
    SnackbarService.success(BuddyMessages.goalUpdated, spacing);
    if (mounted) context.pop();
  }

  Future<void> _deleteGoal(AppSpacing spacing) async {
    final ctxt = AppLocalizations.of(context)!;
    HapticFeedback.mediumImpact();
    final confirmed = await DialogUtils.showDeleteConfirmation(
      context,
      spacing,
      title: ctxt.goal_deleteGoalTitle,
    );
    if (confirmed == true && mounted) {
      await ref.read(goalServiceProvider).deleteGoal(widget.goal.id);
      SnackbarService.success(BuddyMessages.goalDeleted, spacing);
      if (mounted) context.pop();
    }
  }

  Future<void> _markCompleted(AppSpacing spacing) async {
    final ctxt = AppLocalizations.of(context)!;
    HapticFeedback.mediumImpact();
    final confirmed = await DialogUtils.showConfirmation(
      context,
      spacing,
      title: ctxt.goal_markComplete,
      message: ctxt.goal_markCompleteConfirmMessage,
      icon: LucideIcons.circleCheck,
    );
    if (confirmed != true || !mounted) return;

    final goal = widget.goal
      ..currentAmount = widget.goal.targetAmount
      ..isActive = false;
    await ref.read(goalServiceProvider).updateGoal(goal);
    goal.decryptFields();
    SnackbarService.success(BuddyMessages.goalUpdated, spacing);
    if (mounted) context.pop();
  }

  Future<void> _archiveGoal(AppSpacing spacing) async {
    final ctxt = AppLocalizations.of(context)!;
    HapticFeedback.mediumImpact();
    final confirmed = await DialogUtils.showConfirmation(
      context,
      spacing,
      title: ctxt.goal_archive,
      message: ctxt.goal_archiveConfirmMessage,
      icon: LucideIcons.archive,
    );
    if (confirmed != true || !mounted) return;

    final goal = widget.goal..isActive = false;
    await ref.read(goalServiceProvider).updateGoal(goal);
    goal.decryptFields();
    SnackbarService.success(BuddyMessages.goalUpdated, spacing);
    if (mounted) context.pop();
  }

  bool _canContinueForStep(int step) {
    if (step == 0) return _nameController.text.trim().isNotEmpty;
    if (step == 1) return _targetAmount >= widget.goal.currentAmount;
    return true;
  }

  void _nextStep(AppSpacing spacing) {
    if (!_canContinueForStep(_step)) {
      if (_step == 0) {
        SnackbarService.warning(
          AppLocalizations.of(context)!.goal_giveGoalName,
          spacing,
        );
      } else {
        SnackbarService.warning(
          AppLocalizations.of(context)!.goal_targetBelowSaved,
          spacing,
        );
      }
      return;
    }
    FocusScope.of(context).unfocus();
    HapticFeedback.lightImpact();
    setState(() => _step = (_step + 1).clamp(0, 2));
  }

  void _previousStep() {
    FocusScope.of(context).unfocus();
    HapticFeedback.lightImpact();
    setState(() => _step = (_step - 1).clamp(0, 2));
  }

  String _stepLabel(AppLocalizations ctxt) {
    return switch (_step) {
      0 => ctxt.goal_sectionIdentity,
      1 => ctxt.goal_target,
      _ => ctxt.goal_sectionCurrentState,
    };
  }

  Widget _buildStepContent(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    return switch (_step) {
      0 => _buildIdentityStep(color, textTheme, spacing, ctxt),
      1 => _buildTargetStep(color, textTheme, spacing, ctxt),
      _ => _buildReviewStep(color, textTheme, spacing, ctxt),
    };
  }

  Widget _buildIdentityStep(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    return Column(
      key: const ValueKey('edit-identity-step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ctxt.goal_sectionIdentity,
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        SizedBox(height: spacing.elementGapMin),
        Text(
          ctxt.goal_editGoalTitle,
          style: textTheme.bodyMedium?.copyWith(color: color.onSurfaceVariant),
        ),
        SizedBox(height: spacing.sectionGap),
        TextFormField(
          controller: _nameController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          onChanged: (_) => setState(() {}),
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
        SizedBox(height: spacing.sectionGap),
        _buildGoalTypeRow(color, textTheme, spacing, ctxt),
      ],
    );
  }

  Widget _buildTargetStep(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    return Column(
      key: const ValueKey('edit-target-step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ctxt.goal_target,
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        SizedBox(height: spacing.elementGapMin),
        Text(
          ctxt.goal_targetAmount,
          style: textTheme.bodyMedium?.copyWith(color: color.onSurfaceVariant),
        ),
        SizedBox(height: spacing.sectionGap),
        _buildTargetAdjust(color, textTheme, spacing, ctxt),
        SizedBox(height: spacing.elementGap),
        _buildTargetDate(color, textTheme, spacing, ctxt),
        if (_targetAmount >= widget.goal.currentAmount) ...[
          SizedBox(height: spacing.sectionGap * 1.5),
          _buildProjection(color, textTheme, spacing, ctxt),
        ],
      ],
    );
  }

  Widget _buildReviewStep(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    return Column(
      key: const ValueKey('edit-review-step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ctxt.goal_sectionCurrentState,
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        SizedBox(height: spacing.elementGapMin),
        Text(
          ctxt.goal_sectionProjection,
          style: textTheme.bodyMedium?.copyWith(color: color.onSurfaceVariant),
        ),
        SizedBox(height: spacing.sectionGap),
        _buildReviewSummary(color, textTheme, spacing, ctxt),
        SizedBox(height: spacing.sectionGap * 1.5),
        _buildDangerZone(color, textTheme, spacing, ctxt),
      ],
    );
  }

  Widget _buildReviewSummary(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    final progress = _targetAmount <= 0
        ? 0.0
        : (widget.goal.currentAmount / _targetAmount)
            .clamp(0.0, 1.0)
            .toDouble();
    final goalColor = widget.goal.colorValue == null
        ? color.primary
        : Color(widget.goal.colorValue!);
    final pace = _avgMonthlyPace;
    final projected = _projectedCompletion;
    final sortedContribs = widget.goal.contributions.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final lastContrib = sortedContribs.isNotEmpty ? sortedContribs.first : null;

    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(spacing.radiusLarge),
        border: Border.all(color: color.outlineVariant.withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ctxt.goal_saved,
                      style: textTheme.labelSmall?.copyWith(
                        color: color.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: spacing.elementGapMin),
                    CurrencyText(
                      currencyCode: widget.goal.currencyCode,
                      amount: widget.goal.currentAmount,
                      fixedLength: 0,
                      compact: false,
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    ctxt.goal_target,
                    style: textTheme.labelSmall?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: spacing.elementGapMin),
                  CurrencyText(
                    currencyCode: widget.goal.currencyCode,
                    amount: _targetAmount,
                    fixedLength: 0,
                    compact: true,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: goalColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: spacing.elementGap),
          FinanceProgressBar(
            value: progress,
            fillColor: goalColor,
            trackColor: color.surfaceContainerHighest,
            stripeColor: goalColor.withValues(alpha: 0.2),
            height: spacing.progressNormal,
            semanticLabel: '${widget.goal.name} progress',
          ),
          SizedBox(height: spacing.sectionGap),
          Row(
            children: [
              Expanded(
                child: _reviewMetric(
                  label: ctxt.goal_suffixLeft,
                  value: CurrencyText(
                    currencyCode: widget.goal.currencyCode,
                    amount: _remaining,
                    fixedLength: 0,
                    compact: true,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  textTheme: textTheme,
                  color: color,
                ),
              ),
              _reviewMetricDivider(color, spacing),
              Expanded(
                child: _reviewMetric(
                  label: ctxt.goal_currentAvgMonth,
                  value: pace > 0
                      ? CurrencyText(
                          currencyCode: widget.goal.currencyCode,
                          amount: pace,
                          fixedLength: 0,
                          compact: true,
                          suffixText: '/mo',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : Text(
                          '-',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                  textTheme: textTheme,
                  color: color,
                ),
              ),
              _reviewMetricDivider(color, spacing),
              Expanded(
                child: _reviewMetric(
                  label: ctxt.goal_targetDateLabel,
                  value: Text(
                    _targetDate == null
                        ? ctxt.goal_targetDate
                        : safeDateFormat('MMM yyyy', ctxt.localeName)
                            .format(_targetDate!),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  textTheme: textTheme,
                  color: color,
                ),
              ),
            ],
          ),
          if (projected != null || lastContrib != null) ...[
            SizedBox(height: spacing.sectionGap),
            Divider(
              height: 1,
              color: color.outlineVariant.withValues(alpha: 0.55),
            ),
            SizedBox(height: spacing.elementGap),
          ],
          if (projected != null)
            Row(
              children: [
                Icon(
                  LucideIcons.trendingUp,
                  size: spacing.iconSM,
                  color: goalColor,
                ),
                SizedBox(width: spacing.elementGapMin),
                Expanded(
                  child: Text(
                    '${ctxt.goal_forecastLabel}: ${safeDateFormat('MMM yyyy', ctxt.localeName).format(projected)}',
                    style: textTheme.bodySmall?.copyWith(
                      color: color.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          if (projected != null && lastContrib != null)
            SizedBox(height: spacing.elementGapMin),
          if (lastContrib != null)
            Row(
              children: [
                Icon(
                  LucideIcons.clock3,
                  size: spacing.iconSM,
                  color: color.onSurfaceVariant,
                ),
                SizedBox(width: spacing.elementGapMin),
                Expanded(
                  child: Text(
                    '${ctxt.goal_lastContribution}: ${formatCurrency(lastContrib.amount, code: widget.goal.currencyCode, decimals: 0)} · ${_timeAgo(lastContrib.date, ctxt)}',
                    style: textTheme.bodySmall?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          if (sortedContribs.length > 1) ...[
            SizedBox(height: spacing.elementGapMin),
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

  Widget _reviewMetric({
    required String label,
    required Widget value,
    required TextTheme textTheme,
    required ColorScheme color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.labelSmall?.copyWith(color: color.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        value,
      ],
    );
  }

  Widget _reviewMetricDivider(ColorScheme color, AppSpacing spacing) {
    return Container(
      width: 1,
      height: spacing.touchTargetSmall,
      margin: EdgeInsets.symmetric(horizontal: spacing.elementGapMin),
      color: color.outlineVariant.withValues(alpha: 0.55),
    );
  }

  Widget _buildEditPreview(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    final goalName = _nameController.text.trim();

    return AnimatedContainer(
      duration: spacing.animFast,
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.primaryContainer.withValues(alpha: 0.72),
            color.surfaceContainerHigh,
          ],
        ),
        borderRadius: BorderRadius.circular(spacing.radiusLarge),
        border: Border.all(color: color.primary.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: color.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: spacing.touchTargetSmall,
            height: spacing.touchTargetSmall,
            decoration: BoxDecoration(
              color: color.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
            ),
            alignment: Alignment.center,
            child: Icon(
              _goalType.icon,
              color: color.primary,
              size: spacing.iconLG,
            ),
          ),
          SizedBox(width: spacing.elementGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goalName.isEmpty ? ctxt.goal_yourGoal : goalName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: spacing.elementGapMin),
                Text(
                  _goalTypeLabel(_goalType, ctxt),
                  style: textTheme.bodySmall?.copyWith(
                    color: color.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: spacing.elementGap),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                ctxt.goal_target,
                style: textTheme.labelSmall?.copyWith(
                  color: color.onSurfaceVariant,
                ),
              ),
              SizedBox(height: spacing.elementGapMin),
              CurrencyText(
                currencyCode: widget.goal.currencyCode,
                amount: _targetAmount,
                fixedLength: 0,
                compact: false,
                style: textTheme.titleMedium?.copyWith(
                  color: color.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWizardActions(
    ColorScheme color,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    final isLastStep = _step == 2;
    final canContinue = _canContinueForStep(_step) && !_saving;

    return Container(
      padding: EdgeInsets.fromLTRB(
        spacing.cardHorizontal,
        spacing.elementGap,
        spacing.cardHorizontal,
        spacing.elementGap,
      ),
      decoration: BoxDecoration(
        color: color.surface.withValues(alpha: 0.96),
        border: Border(
          top: BorderSide(color: color.outlineVariant.withValues(alpha: 0.25)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_step > 0)
              TextButton.icon(
                onPressed: _previousStep,
                icon: const Icon(LucideIcons.arrowLeft, size: 18),
                label: Text(ctxt.common_back),
              )
            else
              SizedBox(width: spacing.touchTargetSmall),
            SizedBox(width: spacing.elementGap),
            Expanded(
              child: FilledButton.icon(
                onPressed: canContinue
                    ? (isLastStep
                        ? () => _save(spacing)
                        : () => _nextStep(spacing))
                    : null,
                icon: Icon(
                  isLastStep ? LucideIcons.check : LucideIcons.arrowRight,
                  size: 18,
                ),
                label:
                    Text(isLastStep ? ctxt.goal_updateGoal : ctxt.common_next),
                style: FilledButton.styleFrom(
                  backgroundColor: color.primary,
                  foregroundColor: color.onPrimary,
                  minimumSize: Size(double.infinity, spacing.touchTarget),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(spacing.radiusLarge),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;

    return ScreenShell(
      config: ScreenShellConfig(
        appBarMode: AppBarMode.none,
        customAppBar: _EditGoalAppBar(
          title: ctxt.goal_editGoalTitle,
          step: _step,
          stepLabel: _stepLabel(ctxt),
          spacing: spacing,
        ),
        enableRefresh: false,
      ),
      actions: ScreenActions.empty,
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.fromLTRB(
              spacing.cardHorizontal,
              spacing.cardVertical,
              spacing.cardHorizontal,
              spacing.touchTarget + spacing.cardInner * 2,
            ),
            children: [
              if (_step < 2) ...[
                _buildEditPreview(color, textTheme, spacing, ctxt),
                SizedBox(height: spacing.sectionGap * 1.5),
              ],
              AnimatedSwitcher(
                duration: spacing.animNormal,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: _buildStepContent(color, textTheme, spacing, ctxt),
              ),
              SizedBox(height: spacing.touchTarget + spacing.cardInner),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildWizardActions(color, spacing, ctxt),
          ),
        ],
      ),
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
                        formatCurrency(
                          pace,
                          code: widget.goal.currencyCode,
                          decimals: 0,
                        ),
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
        color: color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(color: color.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: Column(
        children: [
          _dangerAction(
            icon: LucideIcons.archive,
            label: ctxt.goal_archive,
            color: color,
            textTheme: textTheme,
            spacing: spacing,
            onTap: () => _archiveGoal(spacing),
          ),
          Divider(
            height: 1,
            color: color.outlineVariant.withValues(alpha: 0.55),
          ),
          _dangerAction(
            icon: LucideIcons.circleCheck,
            label: ctxt.goal_markComplete,
            color: color,
            textTheme: textTheme,
            spacing: spacing,
            onTap: () => _markCompleted(spacing),
          ),
          Divider(
            height: 1,
            color: color.outlineVariant.withValues(alpha: 0.55),
          ),
          _dangerAction(
            icon: LucideIcons.trash2,
            label: ctxt.goal_deleteGoal,
            color: color,
            textTheme: textTheme,
            spacing: spacing,
            onTap: () => _deleteGoal(spacing),
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

class _EditGoalAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _EditGoalAppBar({
    required this.title,
    required this.step,
    required this.stepLabel,
    required this.spacing,
  });

  final String title;
  final int step;
  final String stepLabel;
  final AppSpacing spacing;

  @override
  Size get preferredSize => Size.fromHeight(80 + spacing.cardInner * 2.5);

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppBar(
      automaticallyImplyLeading: true,
      backgroundColor: color.surfaceContainerHigh,
      foregroundColor: color.onSurface,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.surfaceContainerHigh,
              color.primaryContainer.withValues(alpha: 0.72),
            ],
          ),
        ),
      ),
      scrolledUnderElevation: 0,
      toolbarHeight: 80,
      titleSpacing: spacing.cardInner,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(spacing.radiusLarge + spacing.elementGap),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      title: Text(
        title,
        style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(spacing.cardInner * 2.5),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            spacing.cardInner,
            0,
            spacing.cardInner,
            spacing.cardInner,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    stepLabel,
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${step + 1} / 3',
                    style: textTheme.labelMedium?.copyWith(
                      color: color.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              SizedBox(height: spacing.elementGap),
              Row(
                children: List.generate(
                  3,
                  (index) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: index == 2 ? 0 : spacing.elementGapMin,
                      ),
                      child: AnimatedContainer(
                        duration: spacing.animFast,
                        height: spacing.progressThin,
                        decoration: BoxDecoration(
                          color: index <= step
                              ? color.primary
                              : color.surfaceContainerHighest,
                          borderRadius:
                              BorderRadius.circular(spacing.radiusSmall),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
