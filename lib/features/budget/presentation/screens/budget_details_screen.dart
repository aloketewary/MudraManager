import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:mudra_manager/core/domain/budget_constraint_snapshot.dart';
import 'package:mudra_manager/core/domain/financial_states.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/budget_refresh_provider.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/core/state/app_screen_state.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:mudra_manager/core/utils/dialog_utils.dart';
import 'package:mudra_manager/core/utils/refresh_helper.dart';
import 'package:mudra_manager/core/utils/safe_date_format.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/budget/data/budget_constraint_provider.dart';
import 'package:mudra_manager/features/budget/data/budget_service_provider.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/permission_provider.dart';
import 'package:mudra_manager/shared/templates/screen_shell.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';

class BudgetDetailsScreen extends ConsumerWidget {
  final int budgetId;

  const BudgetDetailsScreen({super.key, required this.budgetId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctxt = AppLocalizations.of(context)!;
    final spacing = ref.watch(spacingProvider);

    return ref.watch(budgetConstraintByIdProvider(budgetId)).when(
          skipLoadingOnRefresh: false,
          skipError: false,
          data: (snapshot) {
            if (snapshot == null) {
              return ScreenShell(
                config: ScreenShellConfig(
                  customAppBar: _BudgetDetailsAppBar(
                    title: ctxt.budget_dashboardPageTitle,
                    spacing: spacing,
                    onBack: () => context.pop(),
                  ),
                  enableRefresh: false,
                ),
                actions: ScreenActions.empty,
                body: Center(child: Text(ctxt.budget_dashboardNotFoundText)),
              );
            }
            return _BudgetDetailShell(snapshot: snapshot);
          },
          loading: () => ScreenShell(
            config: ScreenShellConfig(
              customAppBar: _BudgetDetailsAppBar(
                title: ctxt.budget_dashboardPageTitle,
                spacing: spacing,
                onBack: () => context.pop(),
              ),
              enableRefresh: false,
            ),
            actions: ScreenActions.empty,
            body: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: spacing.cardHorizontal,
                vertical: spacing.cardVertical,
              ),
              children: List.generate(3, (_) => const BudgetCardSkeleton()),
            ),
          ),
          error: (e, _) => ScreenShell(
            config: ScreenShellConfig(
              customAppBar: _BudgetDetailsAppBar(
                title: ctxt.budget_dashboardPageTitle,
                spacing: spacing,
                onBack: () => context.pop(),
              ),
              enableRefresh: false,
            ),
            actions: ScreenActions.empty,
            body: Center(
              child: FilledButton.icon(
                onPressed: () => ref
                    .read(budgetRefreshProvider.notifier)
                    .refresh(BudgetRefreshReason.retry),
                icon: const Icon(LucideIcons.rotateCcw),
                label: Text(ctxt.common_retry),
              ),
            ),
          ),
        );
  }
}

class _BudgetDetailShell extends ConsumerWidget {
  final BudgetConstraintSnapshot snapshot;

  const _BudgetDetailShell({required this.snapshot});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctxt = AppLocalizations.of(context)!;
    final spacing = ref.watch(spacingProvider);

    return ScreenShell(
      config: ScreenShellConfig(
        customAppBar: _BudgetDetailsAppBar(
          title: snapshot.budgetName,
          spacing: spacing,
          onBack: () {
            HapticFeedback.lightImpact();
            context.pop();
          },
          remaining: snapshot.remaining.abs(),
          remainingLabel:
              snapshot.isBreached ? ctxt.budget_over : ctxt.budget_remaining,
          spent: snapshot.spent,
          spentLabel: ctxt.budget_spent,
          editLabel: ctxt.budget_buttonEditText,
          deleteLabel: ctxt.budget_delete,
          onEdit: () {
            HapticFeedback.lightImpact();
            context.push(
              AppRoutes.addBudget,
              extra: {'budgetId': snapshot.budgetId},
            );
          },
          onDelete: () async {
            HapticFeedback.mediumImpact();
            final confirmed = await DialogUtils.showDeleteConfirmation(
              context,
              spacing,
              title: '${ctxt.budget_delete} \'${snapshot.budgetName}\'',
            );
            if (confirmed == true && context.mounted) {
              await ref
                  .read(budgetServiceProvider)
                  .deleteBudget(snapshot.budgetId);
              ref.read(budgetRefreshProvider.notifier).refresh(
                    BudgetRefreshReason.budgetCrud,
                  );
              SnackbarService.success(BuddyMessages.budgetDeleted, spacing);
              if (context.mounted) context.pop();
            }
          },
        ),
        enableRefresh: false,
      ),
      actions: ScreenActions.empty,
      body: RefreshIndicator(
        onRefresh: () => RefreshHelper.withMinDuration(() async {
          ref.read(budgetRefreshProvider.notifier).refresh(
                BudgetRefreshReason.manual,
              );
          try {
            await ref.read(budgetConstraintsProvider.future);
          } catch (_) {
            // Error state renders retry; refresh indicator still settles.
          }
        }),
        child: _BudgetDetailBody(snapshot: snapshot),
      ),
    );
  }
}

class _BudgetDetailBody extends ConsumerWidget {
  final BudgetConstraintSnapshot snapshot;

  const _BudgetDetailBody({required this.snapshot});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;

    final accent = _accentColor(color);

    return Stack(
      children: [
        ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            spacing.cardHorizontalMax,
            spacing.sectionGap,
            spacing.cardHorizontalMax,
            spacing.cardInner * 5 +
                MediaQuery.of(context).padding.bottom +
                spacing.sectionGap,
          ),
          children: [
            _buildActions(context, spacing, color, ctxt),
            SizedBox(height: spacing.elementGap),
            // 1. Hero card (one glow per screen): period + remaining + spent
            _buildHeroCard(textTheme, color, accent, spacing, ctxt),

            // 2. Remaining daily allowance
            if (!snapshot.isUnknown &&
                !snapshot.isBreached &&
                snapshot.daysLeft > 0) ...[
              _buildAllowance(textTheme, color, spacing, ctxt),
              SizedBox(height: spacing.elementGap),
            ],

            // 3. Forecast (conditional)
            if (snapshot.isForecastVisible) ...[
              _buildForecast(textTheme, color, spacing, ctxt),
              SizedBox(height: spacing.elementGap),
            ],

            // 4. Pace block
            if (!snapshot.isUnknown) ...[
              _buildPaceCard(textTheme, color, spacing, accent, ctxt),
              SizedBox(height: spacing.elementGap),
            ],

            // 5. Recovery signal
            if (snapshot.recoverySignal != null) ...[
              _buildRecovery(textTheme, color, spacing, accent, ctxt),
              SizedBox(height: spacing.sectionGap),
            ],

            if (snapshot.isUnknown) ...[
              SizedBox(height: spacing.elementGap),
              Container(
                padding: EdgeInsets.all(spacing.cardInner),
                decoration: BoxDecoration(
                  color: color.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  border: Border.all(
                    color: color.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  ctxt.budget_insufficientData,
                  style: textTheme.bodyMedium?.copyWith(
                    color: color.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              SizedBox(height: spacing.sectionGap),
            ],

            if (!snapshot.isUnknown && snapshot.daysLeft > 0) ...[
              SizedBox(height: spacing.sectionGap),
              Center(
                child: Text(
                  ctxt.budget_daysRemaining(snapshot.daysLeft),
                  style: textTheme.bodySmall?.copyWith(
                    color: color.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: _buildPrimaryAction(context, ref, spacing, color, ctxt),
        ),
      ],
    );
  }

  // ── HERO CARD (glow, period + amount + spent + progress) ──
  Widget _buildHeroCard(
    TextTheme textTheme,
    ColorScheme color,
    Color accent,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    final isDark = color.brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: isDark ? 0.20 : 0.12),
            color.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBudgetVisual(accent, color, spacing),
          SizedBox(height: spacing.elementGap),
          _buildPeriod(textTheme, color, ctxt),
          SizedBox(height: spacing.elementGap),
          _buildHero(textTheme, accent, ctxt),
          SizedBox(height: spacing.elementGapMin),
          if (!snapshot.isUnknown) _buildSpentContext(textTheme, color, ctxt),
          if (!snapshot.isUnknown) ...[
            SizedBox(height: spacing.elementGap * 1.5),
            _buildProgressBar(spacing, color, accent, textTheme),
          ],
        ],
      ),
    );
  }

  Widget _buildBudgetVisual(
    Color accent,
    ColorScheme color,
    AppSpacing spacing,
  ) {
    return Container(
      width: double.infinity,
      height: spacing.sectionGap * 7,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.18),
            color.surfaceContainerHighest,
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        snapshot.isBreached ? LucideIcons.triangleAlert : LucideIcons.wallet,
        color: accent,
        size: spacing.iconXL * 2.2,
      ),
    );
  }

  Widget _buildPeriod(
    TextTheme textTheme,
    ColorScheme color,
    AppLocalizations ctxt,
  ) {
    final start = snapshot.periodStart;
    final end = snapshot.periodEnd;
    if (start == null || end == null) {
      return Text(
        ctxt.budget_duration,
        style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
      );
    }

    return Text(
      '${safeDateFormat('dd MMM', ctxt.localeName).format(start)}'
      ' – '
      '${safeDateFormat('dd MMM yyyy', ctxt.localeName).format(end)}',
      style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
    );
  }

  Widget _buildHero(TextTheme textTheme, Color accent, AppLocalizations ctxt) {
    if (snapshot.isUnknown) {
      return CurrencyText(
        amount: snapshot.limit,
        fixedLength: 0,
        compact: false,
        suffixText: 'limit',
        style: textTheme.displaySmall?.copyWith(
          fontWeight: FontWeight.w900,
          color: accent,
        ),
      );
    }

    // Breaches get even larger typography
    final style = snapshot.isBreached
        ? textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: accent,
          )
        : textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w900,
            color: accent,
          );

    return CurrencyText(
      amount: snapshot.remaining.abs(),
      fixedLength: 0,
      compact: false,
      suffixText: snapshot.isBreached ? ctxt.budget_over : ctxt.budget_left,
      style: style,
    );
  }

  Widget _buildSpentContext(
    TextTheme textTheme,
    ColorScheme color,
    AppLocalizations ctxt,
  ) {
    return Row(
      children: [
        Text(
          '${ctxt.budget_spent} ',
          style: textTheme.bodyMedium?.copyWith(color: color.onSurfaceVariant),
        ),
        CurrencyText(
          amount: snapshot.spent,
          fixedLength: 0,
          compact: false,
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: color.onSurface,
          ),
        ),
        Text(
          ' of ',
          style: textTheme.bodyMedium?.copyWith(color: color.onSurfaceVariant),
        ),
        CurrencyText(
          amount: snapshot.limit,
          fixedLength: 0,
          compact: false,
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: color.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildAllowance(
    TextTheme textTheme,
    ColorScheme color,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
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
      child: Row(
        children: [
          Icon(LucideIcons.calculator, size: 16, color: color.onSurfaceVariant),
          SizedBox(width: spacing.elementGap),
          CurrencyText(
            amount: snapshot.remainingDailyAllowance,
            fixedLength: 0,
            compact: false,
            suffixText: '/day ${ctxt.budget_remainingAllowance}',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: color.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecast(
    TextTheme textTheme,
    ColorScheme color,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.clock, size: 16, color: Colors.amber.shade700),
          SizedBox(width: spacing.elementGap),
          Expanded(
            child: Text(
              ctxt.budget_forecastBreach(snapshot.daysUntilLimit!),
              style: textTheme.bodyMedium?.copyWith(
                color: Colors.amber.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaceCard(
    TextTheme textTheme,
    ColorScheme color,
    AppSpacing spacing,
    Color accent,
    AppLocalizations ctxt,
  ) {
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
          Text(
            '${ctxt.budget_currentPace} ${formatCurrency(snapshot.currentDailySpend, code: BaseCurrency.code)}/day',
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: snapshot.dailyGap > 0 ? accent : color.onSurface,
            ),
          ),
          SizedBox(height: spacing.elementGapMin),
          Text(
            '${ctxt.budget_allowedPace} ${formatCurrency(snapshot.allowedDailySpend, code: BaseCurrency.code)}/day',
            style: textTheme.bodySmall?.copyWith(
              color: color.onSurfaceVariant,
            ),
          ),
          if (snapshot.dailyGap != 0) ...[
            SizedBox(height: spacing.elementGapMin),
            Text(
              snapshot.dailyGap > 0
                  ? '${ctxt.budget_exceedingBy} ${formatCurrency(snapshot.dailyGap, code: BaseCurrency.code)}/day'
                  : '${ctxt.budget_underBy} ${formatCurrency(snapshot.dailyGap.abs(), code: BaseCurrency.code)}/day',
              style: textTheme.labelMedium?.copyWith(
                color: snapshot.dailyGap > 0 ? accent : color.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecovery(
    TextTheme textTheme,
    ColorScheme color,
    AppSpacing spacing,
    Color accent,
    AppLocalizations ctxt,
  ) {
    final text = snapshot.isBreached
        ? '${ctxt.budget_reduceBy} ${formatCurrency(snapshot.dailyGap.abs(), code: BaseCurrency.code)}/day'
        : '${ctxt.budget_spendAtMost} ${formatCurrency(snapshot.remainingDailyAllowance, code: BaseCurrency.code)}/day';

    return Text(
      text,
      style: textTheme.bodySmall?.copyWith(
        color: accent,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildProgressBar(
    AppSpacing spacing,
    ColorScheme color,
    Color accent,
    TextTheme textTheme,
  ) {
    final pct = snapshot.percentage.clamp(0.0, 1.0);
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: color.outlineVariant.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(accent),
            ),
          ),
        ),
        SizedBox(width: spacing.elementGap),
        Text(
          '${(snapshot.percentage * 100).toStringAsFixed(0)}%',
          style: textTheme.labelSmall?.copyWith(
            color: color.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildActions(
    BuildContext context,
    AppSpacing spacing,
    ColorScheme color,
    AppLocalizations ctxt,
  ) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          HapticFeedback.lightImpact();
          context.push(AppRoutes.transactions);
        },
        icon: const Icon(LucideIcons.list, size: 16),
        label: Text(ctxt.budget_viewTransactions),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.outlineVariant),
          minimumSize: Size(double.infinity, spacing.touchTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(spacing.radiusLarge),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryAction(
    BuildContext context,
    WidgetRef ref,
    AppSpacing spacing,
    ColorScheme color,
    AppLocalizations ctxt,
  ) {
    final hasAutoTrack = ref.watch(smsPermissionGrantedProvider).value ?? false;

    return Container(
      padding: EdgeInsets.fromLTRB(
        spacing.cardHorizontal,
        spacing.elementGap,
        spacing.cardHorizontal,
        MediaQuery.of(context).padding.bottom + spacing.elementGap,
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
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              if (hasAutoTrack) {
                context.push(
                  AppRoutes.addBudget,
                  extra: {'budgetId': snapshot.budgetId},
                );
              } else {
                context.push(AppRoutes.addTransaction);
              }
            },
            icon: Icon(
              hasAutoTrack ? LucideIcons.pencil : LucideIcons.plus,
              size: 18,
            ),
            label: Text(
              hasAutoTrack
                  ? ctxt.budget_buttonEditText
                  : ctxt.budget_addExpense,
            ),
            style: FilledButton.styleFrom(
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

  Color _accentColor(ColorScheme color) {
    switch (snapshot.urgency) {
      case BudgetConstraintUrgency.breached:
        return color.error;
      case BudgetConstraintUrgency.imminentBreach:
      case BudgetConstraintUrgency.approachingBreach:
      case BudgetConstraintUrgency.nearLimit:
        return Colors.amber.shade700;
      case BudgetConstraintUrgency.unknown:
      case BudgetConstraintUrgency.withinLimit:
        return color.onSurface;
    }
  }
}

class _BudgetDetailsAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _BudgetDetailsAppBar({
    required this.title,
    required this.spacing,
    required this.onBack,
    this.remaining,
    this.remainingLabel,
    this.spent,
    this.spentLabel,
    this.editLabel,
    this.deleteLabel,
    this.onEdit,
    this.onDelete,
  });

  final String title;
  final AppSpacing spacing;
  final VoidCallback onBack;
  final double? remaining;
  final String? remainingLabel;
  final double? spent;
  final String? spentLabel;
  final String? editLabel;
  final String? deleteLabel;
  final VoidCallback? onEdit;
  final Future<void> Function()? onDelete;

  bool get _hasSummary => remaining != null && spent != null;

  @override
  Size get preferredSize => Size.fromHeight(
        80 + (_hasSummary ? spacing.cardInner * 2.5 : 0),
      );

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppBar(
      automaticallyImplyLeading: false,
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
      leading: Padding(
        padding: EdgeInsets.only(left: spacing.cardHorizontal),
        child: IconButton(
          onPressed: onBack,
          tooltip: 'Back',
          icon: const Icon(LucideIcons.arrowLeft),
        ),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      actions: [
        if (onEdit != null || onDelete != null)
          PopupMenuButton<String>(
            tooltip: 'Budget actions',
            onSelected: (value) {
              HapticFeedback.mediumImpact();
              if (value == 'edit') {
                onEdit?.call();
              } else if (value == 'delete') {
                onDelete?.call();
              }
            },
            itemBuilder: (context) => [
              if (onEdit != null)
                PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(LucideIcons.pen, size: 18),
                      SizedBox(width: spacing.elementGap),
                      Text(editLabel ?? ''),
                    ],
                  ),
                ),
              if (onDelete != null)
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(LucideIcons.trash2, size: 18, color: color.error),
                      SizedBox(width: spacing.elementGap),
                      Text(deleteLabel ?? ''),
                    ],
                  ),
                ),
            ],
            icon: const Icon(LucideIcons.ellipsis),
          ),
        SizedBox(width: spacing.cardHorizontal),
      ],
      bottom: _hasSummary
          ? PreferredSize(
              preferredSize: Size.fromHeight(spacing.cardInner * 2.5),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  spacing.cardInner,
                  0,
                  spacing.cardInner,
                  spacing.cardInner,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _headerAmount(
                        context,
                        remainingLabel ?? '',
                        remaining!,
                      ),
                    ),
                    SizedBox(width: spacing.elementGap * 2),
                    Expanded(
                      child: _headerAmount(
                        context,
                        'Spent',
                        spent!,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _headerAmount(BuildContext context, String label, double amount) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: color.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: spacing.elementGapMin),
        CurrencyText(
          amount: amount,
          currencyCode: BaseCurrency.code,
          compact: false,
          fixedLength: 0,
          style: textTheme.titleLarge?.copyWith(
            color: color.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
