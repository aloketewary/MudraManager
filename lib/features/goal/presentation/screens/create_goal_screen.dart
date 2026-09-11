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
import 'package:mudra_manager/core/state/app_screen_state.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/goal/data/goal_provider.dart';
import 'package:mudra_manager/features/goal/domain/goal_enums.dart';
import 'package:mudra_manager/shared/templates/screen_shell.dart';
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
  int _step = 0;

  double get _target =>
      double.tryParse(_targetController.text.trim().replaceAll(',', '')) ?? 0;
  double get _current =>
      double.tryParse(_currentController.text.trim().replaceAll(',', '')) ?? 0;
  double get _remaining => (_target - _current).clamp(0, double.infinity);

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

  Future<void> _create(AppSpacing spacing) async {
    if (_saving) return;
    final ctxt = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate()) return;

    if (_current > _target) {
      SnackbarService.warning(ctxt.goal_currentExceedsTarget, spacing);
      return;
    }

    setState(() => _saving = true);

    try {
      final canCreate = await ref.read(canCreateGoalProvider.future);
      if (!canCreate) {
        SnackbarService.warning(ctxt.goal_freePlanLimit, spacing);
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
      SnackbarService.success(BuddyMessages.goalCreated, spacing);
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _saving = false);
      SnackbarService.error(e.toString(), spacing);
    }
  }

  GoalType? _inferGoalType(String value) {
    final name = value.trim().toLowerCase();

    const houseKeywords = [
      'house',
      'home',
      'apartment',
      'flat',
      'mortgage',
      'down payment',
      'renovation',
    ];
    const vehicleKeywords = [
      'car',
      'vehicle',
      'auto',
      'bike',
      'motorcycle',
      'scooter',
    ];
    const travelKeywords = [
      'trip',
      'travel',
      'vacation',
      'holiday',
      'flight',
      'tour',
    ];
    const educationKeywords = [
      'course',
      'education',
      'college',
      'school',
      'tuition',
      'degree',
      'class',
    ];
    const weddingKeywords = [
      'wedding',
      'marriage',
      'engagement',
    ];

    bool containsAny(List<String> keywords) =>
        keywords.any((keyword) => name.contains(keyword));

    if (containsAny(houseKeywords)) return GoalType.house;
    if (containsAny(vehicleKeywords)) return GoalType.vehicle;
    if (containsAny(travelKeywords)) return GoalType.travel;
    if (containsAny(educationKeywords)) return GoalType.education;
    if (containsAny(weddingKeywords)) return GoalType.wedding;
    return null;
  }

  bool _canContinueForStep(int step) {
    if (step == 0) return _nameController.text.trim().isNotEmpty;
    if (step == 1) return _target > 0;
    return _current <= _target;
  }

  void _nextStep() {
    if (!_canContinueForStep(_step)) {
      _formKey.currentState?.validate();
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
      0 => ctxt.goal_goalName,
      1 => ctxt.goal_target,
      _ => ctxt.goal_currentSavings,
    };
  }

  InputDecoration _fieldDecoration({
    required String label,
    required ColorScheme color,
    required AppSpacing spacing,
    String? hintText,
    Widget? prefixIcon,
    Color? fillColor,
    String? counterText,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(spacing.radiusMedium),
      borderSide: BorderSide(
        color: color.outlineVariant.withValues(alpha: 0.5),
      ),
    );
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      filled: true,
      fillColor: fillColor ?? color.surfaceContainerLow,
      prefixIcon: prefixIcon,
      prefixIconConstraints: prefixIcon == null
          ? null
          : const BoxConstraints(minWidth: 0, minHeight: 0),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        borderSide: BorderSide(color: color.primary, width: 1.5),
      ),
      counterText: counterText,
    );
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
      _ => _buildStartingPointStep(color, textTheme, spacing, ctxt),
    };
  }

  Widget _buildIdentityStep(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    return Column(
      key: const ValueKey('identity-step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ctxt.goal_whatSavingFor,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: spacing.elementGapMin),
        Text(
          ctxt.goal_giveGoalName,
          style: textTheme.bodyMedium?.copyWith(
            color: color.onSurfaceVariant,
          ),
        ),
        SizedBox(height: spacing.sectionGap),
        TextFormField(
          controller: _nameController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          onChanged: (value) {
            _selectedType = _inferGoalType(value);
            setState(() {});
          },
          decoration: _fieldDecoration(
            label: ctxt.goal_goalName,
            hintText: ctxt.goal_whatSavingFor,
            color: color,
            spacing: spacing,
          ),
          validator: (v) =>
              v == null || v.trim().isEmpty ? ctxt.goal_giveGoalName : null,
        ),
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
      key: const ValueKey('target-step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ctxt.goal_target,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: spacing.elementGapMin),
        Text(
          ctxt.goal_targetAmount,
          style: textTheme.bodyMedium?.copyWith(
            color: color.onSurfaceVariant,
          ),
        ),
        SizedBox(height: spacing.sectionGap),
        TextFormField(
          controller: _targetController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.next,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: color.primary,
          ),
          onChanged: (_) => setState(() {}),
          decoration: _fieldDecoration(
            label: ctxt.goal_targetAmount,
            hintText: '0',
            color: color,
            spacing: spacing,
            fillColor: color.primaryContainer.withValues(alpha: 0.24),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 12, right: 4),
              child: CurrencyBadge(code: BaseCurrency.code, size: 32),
            ),
          ).copyWith(
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(spacing.radiusLarge),
              borderSide: BorderSide(color: color.primary, width: 1.5),
            ),
          ),
          validator: (v) {
            final value = double.tryParse(
                  v?.trim().replaceAll(',', '') ?? '',
                ) ??
                0;
            return value <= 0 ? ctxt.goal_enterValidTarget : null;
          },
        ),
        SizedBox(height: spacing.sectionGap),
        _buildTargetDate(color, textTheme, spacing, ctxt),
        if (_target > 0) ...[
          SizedBox(height: spacing.sectionGap * 1.5),
          _buildProjection(color, textTheme, spacing, ctxt),
        ],
      ],
    );
  }

  Widget _buildStartingPointStep(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    return Column(
      key: const ValueKey('starting-step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ctxt.goal_currentSavings,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: spacing.elementGapMin),
        Text(
          ctxt.goal_alreadySaved,
          style: textTheme.bodyMedium?.copyWith(
            color: color.onSurfaceVariant,
          ),
        ),
        SizedBox(height: spacing.sectionGap),
        TextFormField(
          controller: _currentController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.next,
          onChanged: (_) => setState(() {}),
          decoration: _fieldDecoration(
            label: ctxt.goal_currentSavings,
            hintText: '0',
            color: color,
            spacing: spacing,
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 12, right: 4),
              child: CurrencyBadge(code: BaseCurrency.code, size: 32),
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
        SizedBox(height: spacing.sectionGap),
        TextFormField(
          controller: _whyController,
          textCapitalization: TextCapitalization.sentences,
          maxLength: 80,
          decoration: _fieldDecoration(
            label: ctxt.goal_whyOptional,
            hintText: ctxt.goal_whyHint,
            color: color,
            spacing: spacing,
            counterText: '',
          ),
        ),
        if (_target > 0) ...[
          SizedBox(height: spacing.sectionGap * 1.5),
          _buildProjection(color, textTheme, spacing, ctxt),
        ],
      ],
    );
  }

  Widget _buildWizardActions(
    ColorScheme color,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    final canContinue = _canContinueForStep(_step) && !_saving;
    final isLastStep = _step == 2;
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
          top: BorderSide(
            color: color.outlineVariant.withValues(alpha: 0.25),
          ),
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
                    ? (isLastStep ? () => _create(spacing) : _nextStep)
                    : null,
                icon: Icon(
                  isLastStep ? LucideIcons.check : LucideIcons.arrowRight,
                  size: 18,
                ),
                label: Text(
                  isLastStep ? ctxt.goal_createGoal : ctxt.common_next,
                ),
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
        customAppBar: _CreateGoalAppBar(
          title: ctxt.goal_newGoalTitle,
          step: _step,
          stepLabel: _stepLabel(ctxt),
          spacing: spacing,
        ),
        enableRefresh: false,
      ),
      actions: ScreenActions.empty,
      body: Form(
        key: _formKey,
        child: Stack(
          children: [
            ListView(
              padding: EdgeInsets.fromLTRB(
                spacing.cardHorizontal,
                spacing.cardVertical,
                spacing.cardHorizontal,
                spacing.cardInner * 4,
              ),
              children: [
                _buildGoalPreview(color, textTheme, spacing, ctxt),
                SizedBox(height: spacing.sectionGap * 1.5),
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
      ),
    );
  }

  Widget _buildGoalPreview(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    final goalName = _nameController.text.trim();
    final selectedType = _selectedType ?? GoalType.custom;

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
        border: Border.all(
          color: color.primary.withValues(alpha: 0.22),
        ),
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
              selectedType.icon,
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
                  _goalTypeLabel(selectedType, ctxt),
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
                amount: _target,
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

class _CreateGoalAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _CreateGoalAppBar({
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
