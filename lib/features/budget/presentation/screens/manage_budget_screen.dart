import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:mudra_manager/core/db/models/budget.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/budget_refresh_provider.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/state/app_screen_state.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:mudra_manager/core/utils/dialog_utils.dart';
import 'package:mudra_manager/core/utils/refresh_helper.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/budget/data/budget_service_provider.dart';
import 'package:mudra_manager/shared/templates/screen_shell.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';

/// Budget management screen. Read-first, action-second.
class ManageBudgetScreen extends ConsumerStatefulWidget {
  final Budget budget;

  const ManageBudgetScreen({super.key, required this.budget});

  @override
  ConsumerState<ManageBudgetScreen> createState() => _ManageBudgetScreenState();
}

class _ManageBudgetScreenState extends ConsumerState<ManageBudgetScreen> {
  late Budget _budget;

  @override
  void initState() {
    super.initState();
    _budget = widget.budget;
  }

  @override
  Widget build(BuildContext context) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final progressAsync = ref.watch(budgetsWithProgressProvider);

    return ScreenShell(
      config: ScreenShellConfig(
        appBarMode: AppBarMode.none,
        customAppBar: _ManageBudgetAppBar(
          title: l10n.budget_buttonEditText,
          budgetName: _budget.name,
          spacing: spacing,
        ),
        enableRefresh: false,
      ),
      actions: ScreenActions.empty,
      body: progressAsync.when(
        skipLoadingOnRefresh: false,
        skipError: false,
        data: (budgets) {
          final match =
              budgets.where((b) => b.budget.id == _budget.id).firstOrNull;
          if (match == null) {
            return Center(child: Text(l10n.budget_dashboardNotFoundText));
          }
          return Stack(
            children: [
              RefreshIndicator(
                onRefresh: () => RefreshHelper.withMinDuration(() async {
                  ref.read(budgetRefreshProvider.notifier).refresh(
                        BudgetRefreshReason.manual,
                      );
                  try {
                    await ref.read(budgetsWithProgressProvider.future);
                  } catch (_) {
                    // Provider exposes retry state; refresh indicator settles.
                  }
                }),
                child: _buildBody(match, spacing, color, textTheme, l10n),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: _buildUpdateAction(spacing, color, textTheme, l10n),
              ),
            ],
          );
        },
        loading: () => ListView(
          padding: EdgeInsets.symmetric(
            horizontal: spacing.cardHorizontal,
            vertical: spacing.cardVertical,
          ),
          children: List.generate(3, (_) => const BudgetCardSkeleton()),
        ),
        error: (e, _) => Center(
          child: FilledButton.icon(
            onPressed: () => ref
                .read(budgetRefreshProvider.notifier)
                .refresh(BudgetRefreshReason.retry),
            icon: const Icon(LucideIcons.rotateCcw),
            label: Text(l10n.common_retry),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BudgetWithProgress progress,
    AppSpacing spacing,
    ColorScheme color,
    TextTheme textTheme,
    AppLocalizations l10n,
  ) {
    final snapshot = progress.snapshot;
    final spent = snapshot.spent;
    final limit = snapshot.limit;
    final remaining = snapshot.remaining;
    final isOver = snapshot.status == BudgetPeriodStatus.exceeded;
    final percentage = snapshot.percentage;
    final days =
        snapshot.periodEnd.difference(snapshot.evaluationDate).inDays + 1;
    final dailyAllowance = days > 0 && remaining > 0 ? remaining / days : 0.0;
    final isNearLimit = !isOver && percentage >= 0.8;
    final accent = isOver
        ? color.error
        : isNearLimit
            ? color.error.withValues(alpha: 0.88)
            : color.primary;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontal,
        vertical: spacing.cardVertical,
      ),
      children: [
        _buildPremiumHero(
          remaining: remaining,
          spent: spent,
          limit: limit,
          percentage: percentage,
          isOver: isOver,
          accent: accent,
          spacing: spacing,
          color: color,
          textTheme: textTheme,
          l10n: l10n,
        ),
        SizedBox(height: spacing.sectionGap * 1.5),
        _buildDetailsPanel(
          limit: limit,
          dailyAllowance: dailyAllowance,
          days: days,
          startDate: progress.startDate,
          endDate: progress.endDate,
          isOver: isOver,
          spacing: spacing,
          color: color,
          textTheme: textTheme,
          l10n: l10n,
        ),
        SizedBox(height: spacing.sectionGap * 1.5),
        _buildCategoriesPanel(
          progress: progress,
          spacing: spacing,
          color: color,
          textTheme: textTheme,
          l10n: l10n,
        ),
        SizedBox(height: spacing.sectionGap * 2),
        _buildDangerZone(spacing, color, textTheme, l10n),
        SizedBox(height: spacing.sectionGap * 2),
        SizedBox(height: spacing.touchTarget + spacing.cardInner * 2),
      ],
    );
  }

  Widget _buildPremiumHero({
    required double remaining,
    required double spent,
    required double limit,
    required double percentage,
    required bool isOver,
    required Color accent,
    required AppSpacing spacing,
    required ColorScheme color,
    required TextTheme textTheme,
    required AppLocalizations l10n,
  }) {
    final heroBackground = color.surfaceContainerHigh;
    final heroForeground = color.onSurface;
    final heroMuted = color.onSurfaceVariant;
    final progress = percentage.clamp(0.0, 1.0);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.primaryContainer.withValues(alpha: 0.72),
            heroBackground,
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
      child: Padding(
        padding: EdgeInsets.all(spacing.cardInner + 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(spacing.elementGapMin + 2),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(spacing.radiusSmall),
                  ),
                  child: Icon(
                    isOver ? LucideIcons.triangleAlert : LucideIcons.wallet,
                    size: 18,
                    color: accent,
                  ),
                ),
                SizedBox(width: spacing.elementGap),
                Expanded(
                  child: Text(
                    isOver ? l10n.budget_over : l10n.budget_left,
                    style: textTheme.labelLarge?.copyWith(
                      color: heroForeground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _buildHeroPill(
                  label: isOver ? l10n.budget_over : l10n.budget_left,
                  accent: accent,
                  spacing: spacing,
                  textTheme: textTheme,
                ),
              ],
            ),
            SizedBox(height: spacing.sectionGap * 1.5),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CurrencyText(
                        amount: remaining.abs(),
                        style: textTheme.displayMedium?.copyWith(
                          color: heroForeground,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.8,
                          height: 1.0,
                        ),
                      ),
                      SizedBox(height: spacing.elementGapMin),
                      Text(
                        isOver
                            ? l10n.budget_over
                            : l10n.budget_remainingAllowance,
                        style: textTheme.bodyMedium?.copyWith(
                          color: heroMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: spacing.sectionGap),
                      Row(
                        children: [
                          _buildHeroInlineMetric(
                            label: l10n.budget_spent,
                            amount: spent,
                            color: heroForeground,
                            muted: heroMuted,
                            textTheme: textTheme,
                          ),
                          Container(
                            width: 1,
                            height: 28,
                            margin: EdgeInsets.symmetric(
                              horizontal: spacing.elementGap,
                            ),
                            color: heroMuted.withValues(alpha: 0.35),
                          ),
                          _buildHeroInlineMetric(
                            label: l10n.budget_limit,
                            amount: limit,
                            color: heroForeground,
                            muted: heroMuted,
                            textTheme: textTheme,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: spacing.sectionGap),
                SizedBox(
                  width: 98,
                  height: 98,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 8,
                          backgroundColor: heroMuted.withValues(alpha: 0.18),
                          valueColor: AlwaysStoppedAnimation(accent),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(percentage * 100).toStringAsFixed(0)}%',
                            style: textTheme.titleLarge?.copyWith(
                              color: heroForeground,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            l10n.budget_spent,
                            style: textTheme.labelSmall?.copyWith(
                              color: heroMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.sectionGap * 1.25),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                semanticsLabel: 'Budget progress',
                value: progress,
                minHeight: 7,
                backgroundColor: heroMuted.withValues(alpha: 0.18),
                valueColor: AlwaysStoppedAnimation(accent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroInlineMetric({
    required String label,
    required double amount,
    required Color color,
    required Color muted,
    required TextTheme textTheme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: muted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        CurrencyText(
          amount: amount,
          fixedLength: 0,
          style: textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroPill({
    required String label,
    required Color accent,
    required AppSpacing spacing,
    required TextTheme textTheme,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.elementGap,
        vertical: spacing.elementGapMin,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: textTheme.labelSmall?.copyWith(
          color: accent,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildDetailsPanel({
    required double limit,
    required double dailyAllowance,
    required int days,
    required DateTime startDate,
    required DateTime endDate,
    required bool isOver,
    required AppSpacing spacing,
    required ColorScheme color,
    required TextTheme textTheme,
    required AppLocalizations l10n,
  }) {
    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(spacing.radiusMedium + 4),
        border: Border.all(color: color.outlineVariant.withValues(alpha: 0.28)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildDetailCell(
                  icon: LucideIcons.settings2,
                  label: l10n.budget_limit,
                  color: color,
                  spacing: spacing,
                  textTheme: textTheme,
                  value: CurrencyText(
                    amount: limit,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  action: TextButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _showAdjustLimitSheet(
                        limit,
                        spacing,
                        color,
                        textTheme,
                        l10n,
                      );
                    },
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(l10n.budget_adjustLimit),
                  ),
                ),
              ),
              SizedBox(width: spacing.sectionGap),
              Expanded(
                child: _buildDetailCell(
                  icon: LucideIcons.calendar,
                  label: l10n.budget_remainingAllowance,
                  color: color,
                  spacing: spacing,
                  textTheme: textTheme,
                  value: isOver
                      ? Text(
                          l10n.budget_over,
                          style: textTheme.titleMedium?.copyWith(
                            color: color.error,
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Flexible(
                              child: CurrencyText(
                                amount: dailyAllowance,
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.4,
                                ),
                              ),
                            ),
                            Text(
                              '/${l10n.budget_perDay}',
                              style: textTheme.bodySmall?.copyWith(
                                color: color.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                  action: !isOver
                      ? _buildQuietLabel(
                          '$days ${l10n.budget_days} ${l10n.budget_left}',
                          color,
                          textTheme,
                        )
                      : null,
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: spacing.sectionGap),
            child: Divider(
              height: 1,
              color: color.outlineVariant.withValues(alpha: 0.38),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                LucideIcons.calendarDays,
                size: 17,
                color: color.primary,
              ),
              SizedBox(width: spacing.elementGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.budget_duration,
                      style: textTheme.labelSmall?.copyWith(
                        color: color.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: spacing.elementGapMin),
                    Text(
                      '${DateFormat.yMMMd(l10n.localeName).format(startDate)} - '
                      '${DateFormat.yMMMd(l10n.localeName).format(endDate)}',
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
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

  Widget _buildDetailCell({
    required IconData icon,
    required String label,
    required ColorScheme color,
    required AppSpacing spacing,
    required TextTheme textTheme,
    required Widget value,
    Widget? action,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color.primary),
            SizedBox(width: spacing.elementGapMin),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelSmall?.copyWith(
                  color: color.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: spacing.elementGap),
        value,
        if (action != null) ...[
          SizedBox(height: spacing.elementGapMin),
          action,
        ],
      ],
    );
  }

  Widget _buildQuietLabel(
    String label,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: textTheme.labelSmall?.copyWith(
        color: color.onSurfaceVariant,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildCategoriesPanel({
    required BudgetWithProgress progress,
    required AppSpacing spacing,
    required ColorScheme color,
    required TextTheme textTheme,
    required AppLocalizations l10n,
  }) {
    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(spacing.radiusMedium + 4),
        border: Border.all(color: color.outlineVariant.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.tags, size: 17, color: color.primary),
              SizedBox(width: spacing.elementGap),
              Text(
                l10n.budget_categoriesTitle,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.sectionGap),
          if (progress.categorySpendings.isEmpty)
            Text(
              l10n.budget_categoriesTitle,
              style: textTheme.bodyMedium?.copyWith(
                color: color.onSurfaceVariant,
              ),
            )
          else
            Wrap(
              spacing: spacing.elementGapMin,
              runSpacing: spacing.elementGapMin,
              children: progress.categorySpendings.map((cs) {
                return _buildCategoryTag(
                  cs.category.name,
                  color,
                  spacing,
                  textTheme,
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryTag(
    String label,
    ColorScheme color,
    AppSpacing spacing,
    TextTheme textTheme,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.elementGap,
        vertical: spacing.elementGapMin + 1,
      ),
      decoration: BoxDecoration(
        color: color.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(color: color.outlineVariant.withValues(alpha: 0.34)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.primary,
            ),
          ),
          SizedBox(width: spacing.elementGapMin),
          Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              color: color.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showAdjustLimitSheet(
    double currentLimit,
    AppSpacing spacing,
    ColorScheme color,
    TextTheme textTheme,
    AppLocalizations l10n,
  ) {
    final controller = TextEditingController(text: currentLimit.toString());

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: color.surfaceContainerHigh,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(spacing.radiusMedium + 4),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: spacing.sectionGap,
            right: spacing.sectionGap,
            top: spacing.elementGap,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + spacing.sectionGap,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: color.primary.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              SizedBox(height: spacing.sectionGap),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(spacing.elementGap),
                    decoration: BoxDecoration(
                      color: color.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(spacing.radiusSmall),
                    ),
                    child: Icon(
                      LucideIcons.settings2,
                      size: 18,
                      color: color.primary,
                    ),
                  ),
                  SizedBox(width: spacing.elementGap),
                  Expanded(
                    child: Text(
                      l10n.budget_adjustLimit,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: spacing.sectionGap),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                decoration: InputDecoration(
                  labelText: l10n.budget_limit,
                  prefixText: '${BaseCurrency.symbol} ',
                  prefixStyle: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color.onSurfaceVariant,
                  ),
                ),
              ),
              SizedBox(height: spacing.sectionGap),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final newAmount = double.tryParse(
                      controller.text.trim().replaceAll(',', ''),
                    );
                    if (newAmount == null || newAmount <= 0) return;

                    _budget.amount = newAmount;
                    final service = ref.read(budgetServiceProvider);
                    await service.save(_budget);
                    ref.read(budgetRefreshProvider.notifier).refresh(
                          BudgetRefreshReason.budgetCrud,
                        );

                    if (mounted) {
                      Navigator.pop(ctx);
                      HapticFeedback.mediumImpact();
                      SnackbarService.success(
                        BuddyMessages.budgetUpdated,
                        spacing,
                      );
                      setState(() {});
                    }
                  },
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: spacing.cardInner),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(spacing.radiusMedium),
                    ),
                  ),
                  child: Text(
                    l10n.budget_updateButtonText,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color.onPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(controller.dispose);
  }

  Widget _buildUpdateAction(
    AppSpacing spacing,
    ColorScheme color,
    TextTheme textTheme,
    AppLocalizations l10n,
  ) {
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
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () {
              HapticFeedback.mediumImpact();
              _showAdjustLimitSheet(
                _budget.amount,
                spacing,
                color,
                textTheme,
                l10n,
              );
            },
            icon: const Icon(LucideIcons.check, size: 18),
            label: Text(l10n.budget_updateButtonText),
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
      ),
    );
  }

  Widget _buildDangerZone(
    AppSpacing spacing,
    ColorScheme color,
    TextTheme textTheme,
    AppLocalizations l10n,
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
            label: l10n.budget_archive,
            color: color,
            textTheme: textTheme,
            spacing: spacing,
            onTap: () => _archiveBudget(l10n, spacing),
          ),
          Divider(
            height: 1,
            color: color.outlineVariant.withValues(alpha: 0.55),
          ),
          _dangerAction(
            icon: LucideIcons.trash2,
            label: l10n.budget_buttonDeleteActionText,
            color: color,
            textTheme: textTheme,
            spacing: spacing,
            onTap: () => _deleteBudget(l10n, spacing),
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

  Future<void> _archiveBudget(AppLocalizations l10n, AppSpacing spacing) async {
    HapticFeedback.mediumImpact();
    final confirmed = await DialogUtils.showConfirmation(
      context,
      spacing,
      title: l10n.budget_archive,
      message: l10n.budget_archiveConfirm,
      confirmText: l10n.budget_archive,
      cancelText: l10n.budget_buttonCancelActionText,
      icon: LucideIcons.archive,
    );

    if (confirmed == true) {
      final service = ref.read(budgetServiceProvider);
      await service.archiveBudget(_budget.id);
      ref.read(budgetRefreshProvider.notifier).refresh(
            BudgetRefreshReason.budgetCrud,
          );
      if (mounted) {
        SnackbarService.success(BuddyMessages.budgetUpdated, spacing);
        context.pop();
      }
    }
  }

  Future<void> _deleteBudget(AppLocalizations l10n, AppSpacing spacing) async {
    HapticFeedback.mediumImpact();
    final confirmed = await DialogUtils.showDeleteConfirmation(
      context,
      spacing,
      title: l10n.budget_buttonDeleteTitleText,
      message: l10n.budget_buttonDeleteBodyText,
      cancelText: l10n.budget_buttonCancelActionText,
      deleteText: l10n.budget_buttonDeleteActionText,
    );

    if (confirmed == true) {
      final service = ref.read(budgetServiceProvider);
      await service.deleteBudget(_budget.id);
      ref.read(budgetRefreshProvider.notifier).refresh(
            BudgetRefreshReason.budgetCrud,
          );
      if (mounted) {
        context.pop();
      }
    }
  }
}

class _ManageBudgetAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _ManageBudgetAppBar({
    required this.title,
    required this.budgetName,
    required this.spacing,
  });

  final String title;
  final String budgetName;
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
                  Expanded(
                    child: Text(
                      budgetName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  SizedBox(width: spacing.elementGap),
                  Text(
                    '1 / 1',
                    style: textTheme.labelMedium?.copyWith(
                      color: color.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              SizedBox(height: spacing.elementGap),
              AnimatedContainer(
                duration: spacing.animFast,
                height: spacing.progressThin,
                decoration: BoxDecoration(
                  color: color.primary,
                  borderRadius: BorderRadius.circular(spacing.radiusSmall),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
