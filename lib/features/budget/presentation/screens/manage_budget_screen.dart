import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:mudra_manager/core/db/models/budget.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:mudra_manager/core/utils/dialog_utils.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/budget/data/budget_service_provider.dart';
import 'package:mudra_manager/shared/templates/screen_shell.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';

/// Budget management screen — read-first, action-second.
/// Shows current constraint status and allows adjustments.
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
        title: _budget.name,
        appBarMode: AppBarMode.standard,
        enableRefresh: false,
      ),
      body: progressAsync.when(
        data: (budgets) {
          final match = budgets
              .where((b) => b.budget.id == _budget.id)
              .firstOrNull;
          if (match == null) {
            return Center(child: Text(l10n.budget_dashboardNotFoundText));
          }
          return _buildBody(match, spacing, color, textTheme, l10n);
        },
        loading: () => ListView(
          padding: EdgeInsets.symmetric(
            horizontal: spacing.cardHorizontal,
            vertical: spacing.cardVertical,
          ),
          children: List.generate(3, (_) => const BudgetCardSkeleton()),
        ),
        error: (e, _) => Center(child: Text(BuddyMessages.errorWith('$e'))),
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
    final spent = progress.spent;
    final limit = _budget.amount;
    final remaining = limit - spent;
    final isOver = remaining < 0;
    final pct = limit > 0 ? (spent / limit).clamp(0.0, 1.5) : 0.0;
    final days = _budget.endDate.difference(DateTime.now()).inDays + 1;
    final dailyAllowance = days > 0 && remaining > 0 ? remaining / days : 0.0;

    final heroColor = isOver
        ? color.error
        : pct > 0.8
            ? color.error.withValues(alpha: 0.8)
            : color.onSurface;
    final isDark = color.brightness == Brightness.dark;

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontal,
        vertical: spacing.cardVertical,
      ),
      children: [
        // ── HERO CARD: REMAINING + SPENT + PROGRESS (one glow per screen) ──
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.all(spacing.cardInner),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                heroColor.withValues(alpha: isDark ? 0.20 : 0.12),
                color.surface,
              ],
            ),
            borderRadius: BorderRadius.circular(spacing.radiusMedium),
            border: Border.all(color: heroColor.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: heroColor.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              CurrencyText(
                amount: remaining.abs(),
                style: textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: heroColor,
                ),
              ),
              SizedBox(height: spacing.elementGapMin),
              Text(
                isOver ? l10n.budget_over : l10n.budget_left,
                style: textTheme.bodyMedium?.copyWith(
                  color: heroColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: spacing.elementGap),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${l10n.budget_spent} ',
                    style: textTheme.bodyMedium?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                  ),
                  CurrencyText(
                    amount: spent,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    ' of ',
                    style: textTheme.bodyMedium?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                  ),
                  CurrencyText(
                    amount: limit,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: spacing.elementGap * 1.5),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  semanticsLabel: 'Budget progress',
                  value: pct.clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: color.outlineVariant.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation(heroColor),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: spacing.elementGap * 2),

        // ── ADJUST LIMIT ──
        _buildSection(
          icon: LucideIcons.settings2,
          title: l10n.budget_limit,
          spacing: spacing,
          color: color,
          textTheme: textTheme,
          child: Row(
            children: [
              CurrencyText(
                amount: limit,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _showAdjustLimitSheet(
                  limit, spacing, color, textTheme, l10n,
                ),
                icon: const Icon(LucideIcons.pencil, size: 14),
                label: Text(l10n.budget_adjustLimit),
              ),
            ],
          ),
        ),
        SizedBox(height: spacing.elementGap),

        // ── DAILY ALLOWANCE ──
        if (!isOver && days > 0)
          _buildSection(
            icon: LucideIcons.calendar,
            title: l10n.budget_remainingAllowance,
            spacing: spacing,
            color: color,
            textTheme: textTheme,
            child: Row(
              children: [
                CurrencyText(
                  amount: dailyAllowance,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '/${l10n.budget_perDay}',
                  style: textTheme.bodyMedium?.copyWith(
                    color: color.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  '$days ${l10n.budget_days} ${l10n.budget_left}',
                  style: textTheme.bodySmall?.copyWith(
                    color: color.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        SizedBox(height: spacing.elementGap),

        // ── PERIOD ──
        _buildSection(
          icon: LucideIcons.calendarDays,
          title: l10n.budget_duration,
          spacing: spacing,
          color: color,
          textTheme: textTheme,
          child: Text(
            '${DateFormat.yMMMd(l10n.localeName).format(progress.startDate)} – ${DateFormat.yMMMd(l10n.localeName).format(progress.endDate)}',
            style: textTheme.bodyMedium,
          ),
        ),
        SizedBox(height: spacing.elementGap),

        // ── CATEGORIES ──
        _buildSection(
          icon: LucideIcons.tags,
          title: l10n.budget_categoriesTitle,
          spacing: spacing,
          color: color,
          textTheme: textTheme,
          child: Wrap(
            spacing: spacing.elementGap,
            runSpacing: spacing.elementGapMin,
            children: progress.categorySpendings.map((cs) {
              return Chip(
                label: Text(cs.category.name),
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
        ),
        SizedBox(height: spacing.sectionGap * 2),

        // ── DANGER ZONE ──
        _buildDangerZone(spacing, color, textTheme, l10n),
        SizedBox(height: spacing.sectionGap * 2),
      ],
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required AppSpacing spacing,
    required ColorScheme color,
    required TextTheme textTheme,
    required Widget child,
  }) {
    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(color: color.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.onSurface.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color.onSurfaceVariant),
              SizedBox(width: spacing.elementGapMin),
              Text(
                title,
                style: textTheme.labelMedium?.copyWith(
                  color: color.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.elementGap),
          child,
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
    final controller = TextEditingController(text: currentLimit.toInt().toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: color.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(spacing.radiusSmall),
        ),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: spacing.sectionGap,
          right: spacing.sectionGap,
          top: spacing.sectionGap,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + spacing.sectionGap,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.budget_adjustLimit,
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: spacing.sectionGap),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              decoration: InputDecoration(
                prefixText: '${BaseCurrency.symbol} ',
                prefixStyle: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color.onSurfaceVariant,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
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
                  ref.invalidate(budgetsWithProgressProvider);

                  if (mounted) {
                    Navigator.pop(ctx);
                    HapticFeedback.mediumImpact();
                    SnackbarService.success(BuddyMessages.budgetUpdated, spacing);
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
    );
  }

  Widget _buildDangerZone(
    AppSpacing spacing,
    ColorScheme color,
    TextTheme textTheme,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        color: color.errorContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(color: color.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.triangleAlert, size: 14, color: color.error),
              SizedBox(width: spacing.elementGapMin),
              Text(
                l10n.budget_dangerZone,
                style: textTheme.labelMedium?.copyWith(
                  color: color.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.elementGap),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _archiveBudget(l10n, spacing),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: color.onSurfaceVariant,
                    side: BorderSide(color: color.outlineVariant),
                  ),
                  child: Text(l10n.budget_archive),
                ),
              ),
              SizedBox(width: spacing.elementGap),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _deleteBudget(l10n, spacing),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: color.error,
                    side: BorderSide(color: color.error.withValues(alpha: 0.5)),
                  ),
                  child: Text(l10n.budget_buttonDeleteActionText),
                ),
              ),
            ],
          ),
        ],
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
      if (mounted) {
        ref.invalidate(budgetsWithProgressProvider);
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
      if (mounted) {
        ref.invalidate(budgetsWithProgressProvider);
        context.pop();
      }
    }
  }
}
