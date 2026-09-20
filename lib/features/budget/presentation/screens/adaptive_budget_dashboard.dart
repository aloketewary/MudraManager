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
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:mudra_manager/core/utils/refresh_helper.dart';
import 'package:mudra_manager/core/utils/safe_date_format.dart';
import 'package:mudra_manager/features/budget/data/budget_constraint_provider.dart';
import 'package:mudra_manager/features/budget/data/budget_service_provider.dart';
import 'package:mudra_manager/features/dashboard/data/today_card_analytics.dart';
import 'package:mudra_manager/shared/templates/screen_shell.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:mudra_manager/shared/widgets/no_data_found.dart';
import 'package:mudra_manager/shared/widgets/safe_text.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:mudra_manager/shared/widgets/type_section_header.dart';

class AdaptiveBudgetDashboard extends ConsumerStatefulWidget {
  const AdaptiveBudgetDashboard({super.key});

  @override
  ConsumerState<AdaptiveBudgetDashboard> createState() =>
      _AdaptiveBudgetDashboardState();
}

class _AdaptiveBudgetDashboardState
    extends ConsumerState<AdaptiveBudgetDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      ref.read(budgetRefreshProvider.notifier).refresh(
            BudgetRefreshReason.navigation,
          );
    });
    TodayCardAnalytics.recordDestinationOpened(destination: 'budget');
  }

  @override
  Widget build(BuildContext context) {
    final ctxt = AppLocalizations.of(context)!;
    final spacing = ref.watch(spacingProvider);

    return ScreenShell(
      config: ScreenShellConfig(
        title: ctxt.budget_dashboardPageTitle,
        appBarMode: AppBarMode.none,
        enableRefresh: false,
        customAppBar: _BudgetHomeStyleAppBar(
          title: ctxt.budget_dashboardPageTitle,
          bottomHeight: spacing.cardInner * 3 + spacing.sectionGap,
          onAddBudget: () {
            HapticFeedback.mediumImpact();
            context.push(AppRoutes.addBudget);
          },
        ),
      ),
      body: ref.watch(budgetConstraintsProvider).when(
            skipLoadingOnRefresh: false,
            skipError: false,
            data: (snapshots) {
              return _BudgetConstraintList(snapshots: snapshots);
            },
            loading: () => ListView(
              padding: EdgeInsets.symmetric(
                horizontal: spacing.cardHorizontal,
                vertical: spacing.cardVertical,
              ),
              children: List.generate(4, (_) => const BudgetCardSkeleton()),
            ),
            error: (_, __) => Center(
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

bool _requiresAttention(BudgetConstraintSnapshot snapshot) {
  return switch (snapshot.urgency) {
    BudgetConstraintUrgency.breached ||
    BudgetConstraintUrgency.imminentBreach ||
    BudgetConstraintUrgency.approachingBreach ||
    BudgetConstraintUrgency.nearLimit =>
      true,
    BudgetConstraintUrgency.unknown ||
    BudgetConstraintUrgency.withinLimit =>
      false,
  };
}

class _BudgetConstraintList extends ConsumerWidget {
  final List<BudgetConstraintSnapshot> snapshots;

  const _BudgetConstraintList({required this.snapshots});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final ctxt = AppLocalizations.of(context)!;

    final needsAttention = snapshots.where(_requiresAttention).toList();
    final unknown = snapshots.where((s) => s.isUnknown).toList();
    final healthy =
        snapshots.where((s) => !_requiresAttention(s) && !s.isUnknown).toList();

    return RefreshIndicator(
      onRefresh: () => RefreshHelper.withMinDuration(() async {
        ref.read(budgetRefreshProvider.notifier).refresh(
              BudgetRefreshReason.manual,
            );
        try {
          await Future.wait([
            ref.read(budgetConstraintsProvider.future),
            ref.read(budgetHistoryProvider.future),
          ]);
        } catch (_) {
          // Provider exposes error/retry state; pull-to-refresh must settle.
        }
      }),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: spacing.cardHorizontal,
          vertical: spacing.cardVertical,
        ),
        children: [
          if (snapshots.isNotEmpty)
            _BudgetSectionHeading(
              label: 'My Budgets',
              spacing: spacing,
            ),
          if (snapshots.isEmpty)
            NoDataFound(
              message: BuddyMessages.noBudgets,
              iconData: LucideIcons.shieldAlert,
              action: ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  context.push(AppRoutes.addBudget);
                },
                icon: const Icon(LucideIcons.plus),
                label: Text(ctxt.common_add),
              ),
            ),
          if (needsAttention.isNotEmpty) ...[
            TypeSectionHeader(
              label: '${ctxt.budget_highlightLabel} (${needsAttention.length})',
              icon: LucideIcons.triangleAlert,
              accentColor: color.error,
            ),
            SizedBox(height: spacing.elementGap),
            ...needsAttention.map(
              (snapshot) => Padding(
                padding: EdgeInsets.only(bottom: spacing.elementGap),
                child: _BudgetConstraintCard(
                  snapshot: snapshot,
                  sectionAccent: color.error,
                ),
              ),
            ),
          ],
          if (healthy.isNotEmpty)
            ...healthy.map(
              (snapshot) => Padding(
                padding: EdgeInsets.only(bottom: spacing.elementGap),
                child: _BudgetConstraintCard(
                  snapshot: snapshot,
                  sectionAccent: color.primary,
                ),
              ),
            ),
          if (unknown.isNotEmpty) ...[
            TypeSectionHeader(
              label: '${ctxt.budget_insufficientData} (${unknown.length})',
              icon: LucideIcons.circleHelp,
              accentColor: color.onSurfaceVariant,
            ),
            SizedBox(height: spacing.elementGap),
            ...unknown.map(
              (snapshot) => Padding(
                padding: EdgeInsets.only(bottom: spacing.elementGap),
                child: _BudgetConstraintCard(
                  snapshot: snapshot,
                  sectionAccent: color.onSurfaceVariant,
                ),
              ),
            ),
          ],
          const _BudgetHistorySection(),
          SizedBox(
            height: MediaQuery.of(context).padding.bottom +
                kBottomNavigationBarHeight +
                16,
          ),
        ],
      ),
    );
  }
}

class _BudgetSectionHeading extends StatelessWidget {
  final String label;
  final AppSpacing spacing;

  const _BudgetSectionHeading({
    required this.label,
    required this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        0,
        spacing.cardVertical,
        0,
        spacing.elementGap,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _BudgetHistorySection extends ConsumerWidget {
  const _BudgetHistorySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;

    return ref.watch(budgetHistoryProvider).when(
          skipLoadingOnRefresh: false,
          skipError: false,
          loading: () => Padding(
            padding: EdgeInsets.only(top: spacing.sectionGap),
            child: const BudgetCardSkeleton(),
          ),
          error: (_, __) => Padding(
            padding: EdgeInsets.only(top: spacing.sectionGap),
            child: OutlinedButton.icon(
              onPressed: () => ref
                  .read(budgetRefreshProvider.notifier)
                  .refresh(BudgetRefreshReason.retry),
              icon: const Icon(LucideIcons.rotateCcw),
              label: Text(ctxt.common_retry),
            ),
          ),
          data: (entries) {
            if (entries.isEmpty) {
              return Padding(
                padding: EdgeInsets.only(top: spacing.sectionGap),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BudgetSectionHeading(
                      label: 'Budget History',
                      spacing: spacing,
                    ),
                    Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: spacing.cardHorizontal,
                      ),
                      padding: EdgeInsets.all(spacing.cardInner),
                      decoration: BoxDecoration(
                        color: color.surfaceContainerLow,
                        borderRadius:
                            BorderRadius.circular(spacing.radiusMedium),
                        border: Border.all(
                          color: color.outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.history,
                            size: spacing.iconMD,
                            color: color.onSurfaceVariant,
                          ),
                          SizedBox(width: spacing.elementGap),
                          Expanded(
                            child: Text(
                              'No completed budgets',
                              style: textTheme.bodyMedium?.copyWith(
                                color: color.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.only(top: spacing.sectionGap),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BudgetSectionHeading(
                    label: 'Budget History',
                    spacing: spacing,
                  ),
                  ...entries.map(
                    (entry) => _BudgetHistoryCard(
                      entry: entry,
                      spacing: spacing,
                      color: color,
                      textTheme: textTheme,
                      ctxt: ctxt,
                    ),
                  ),
                ],
              ),
            );
          },
        );
  }
}

class _BudgetHistoryCard extends StatelessWidget {
  final BudgetHistoryEntry entry;
  final AppSpacing spacing;
  final ColorScheme color;
  final TextTheme textTheme;
  final AppLocalizations ctxt;

  const _BudgetHistoryCard({
    required this.entry,
    required this.spacing,
    required this.color,
    required this.textTheme,
    required this.ctxt,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = entry.status == BudgetPeriodStatus.exceeded
        ? color.error
        : entry.status == BudgetPeriodStatus.met
            ? color.primary
            : color.onSurfaceVariant;
    final status = entry.status == null
        ? 'Unknown'
        : entry.status == BudgetPeriodStatus.exceeded
            ? 'Exceeded'
            : 'Met';
    final recurrence = entry.recurrence.name;
    final sourceNote = switch (entry.valueSource) {
      BudgetHistoryValueSource.persisted => null,
      BudgetHistoryValueSource.legacyBestAvailable => 'Legacy best available',
      BudgetHistoryValueSource.unknown => 'Historical limit unavailable',
    };

    return Card(
      margin: EdgeInsets.only(bottom: spacing.elementGap),
      elevation: 0,
      color: color.surfaceContainerLow,
      child: Padding(
        padding: EdgeInsets.all(spacing.cardInner),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    entry.budgetName.safe(),
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  status,
                  style: textTheme.labelMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.elementGapMin),
            Text(
              '${safeDateFormat('dd MMM yyyy', ctxt.localeName).format(entry.periodStart)}'
              ' - '
              '${safeDateFormat('dd MMM yyyy', ctxt.localeName).format(entry.periodEnd)}',
              style: textTheme.bodySmall?.copyWith(
                color: color.onSurfaceVariant,
              ),
            ),
            SizedBox(height: spacing.elementGapMin),
            Text(
              '${ctxt.budget_recurrenceText}: $recurrence',
              style: textTheme.bodySmall?.copyWith(
                color: color.onSurfaceVariant,
              ),
            ),
            if (sourceNote != null) ...[
              SizedBox(height: spacing.elementGapMin),
              Text(
                sourceNote,
                style: textTheme.bodySmall?.copyWith(
                  color: color.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            SizedBox(height: spacing.elementGap),
            Row(
              children: [
                Expanded(
                  child: CurrencyText(
                    amount: entry.spent,
                    fixedLength: 0,
                    suffixText: ctxt.budget_spent.toLowerCase(),
                    style: textTheme.bodyMedium,
                  ),
                ),
                Expanded(
                  child: entry.limitIsKnown
                      ? CurrencyText(
                          amount: entry.limit,
                          fixedLength: 0,
                          suffixText: ctxt.budget_limit.toLowerCase(),
                          style: textTheme.bodyMedium,
                        )
                      : Text(
                          'Limit unavailable',
                          style: textTheme.bodyMedium?.copyWith(
                            color: color.onSurfaceVariant,
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetHomeStyleAppBar extends ConsumerWidget
    implements PreferredSizeWidget {
  const _BudgetHomeStyleAppBar({
    required this.title,
    required this.bottomHeight,
    required this.onAddBudget,
  });

  final String title;
  final double bottomHeight;
  final VoidCallback onAddBudget;

  @override
  Size get preferredSize => Size.fromHeight(80 + bottomHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final ctxt = AppLocalizations.of(context)!;
    final portfolio = ref.watch(budgetPortfolioProvider).value;

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
        preferredSize: Size.fromHeight(bottomHeight),
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
                child: _BudgetHeaderAmount(
                  label: ctxt.budget_remaining,
                  amount: portfolio?.totalRemaining ?? 0,
                  color: color,
                  textTheme: textTheme,
                  spacing: spacing,
                ),
              ),
              SizedBox(width: spacing.elementGap * 2),
              Expanded(
                child: _BudgetHeaderAmount(
                  label: ctxt.budget_spent,
                  amount: portfolio?.totalSpent ?? 0,
                  color: color,
                  textTheme: textTheme,
                  spacing: spacing,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: spacing.cardInner),
          child: IconButton(
            onPressed: onAddBudget,
            tooltip: ctxt.common_add,
            icon: const Icon(LucideIcons.plus),
            style: IconButton.styleFrom(
              foregroundColor: color.onPrimary,
              backgroundColor: color.primary,
              minimumSize: Size.square(spacing.touchTargetSmall),
              maximumSize: Size.square(spacing.touchTargetSmall),
              padding: EdgeInsets.zero,
              shape: const CircleBorder(),
            ),
          ),
        ),
      ],
    );
  }
}

class _BudgetHeaderAmount extends StatelessWidget {
  const _BudgetHeaderAmount({
    required this.label,
    required this.amount,
    required this.color,
    required this.textTheme,
    required this.spacing,
  });

  final String label;
  final double amount;
  final ColorScheme color;
  final TextTheme textTheme;
  final AppSpacing spacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
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
          compact: false,
          fixedLength: 0,
          style: textTheme.headlineMedium?.copyWith(
            color: color.onSurface,
            fontWeight: FontWeight.w500,
            height: 1,
          ),
        ),
      ],
    );
  }
}

// ── BUDGET CONSTRAINT CARD ──

class _BudgetConstraintCard extends StatelessWidget {
  final BudgetConstraintSnapshot snapshot;
  final Color sectionAccent;

  const _BudgetConstraintCard({
    required this.snapshot,
    required this.sectionAccent,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = ProviderScope.containerOf(context).read(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;
    final accent = _accentColor(color);
    final progress = snapshot.percentage.clamp(0.0, 1.0).toDouble();
    final percent = (progress * 100).round();
    final radius = spacing.radiusMedium + spacing.elementGapMin;

    return Container(
      decoration: BoxDecoration(
        color: color.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: color.outlineVariant.withValues(alpha: 0.72),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: () {
            HapticFeedback.mediumImpact();
            context.push(AppRoutes.budgetDetails, extra: snapshot.budgetId);
          },
          child: Padding(
            padding: EdgeInsets.all(spacing.elementGap),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BudgetVisual(
                  icon: snapshot.isBreached
                      ? LucideIcons.triangleAlert
                      : LucideIcons.wallet,
                  accent: accent,
                  spacing: spacing,
                  color: color,
                ),
                SizedBox(width: spacing.elementGap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              snapshot.budgetName.safe(),
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              _showBudgetActions(context, snapshot);
                            },
                            tooltip: 'Budget actions',
                            icon: Icon(
                              LucideIcons.ellipsis,
                              size: spacing.iconMD,
                              color: color.onSurfaceVariant,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(
                              minWidth: spacing.touchTargetSmall,
                              minHeight: spacing.touchTargetSmall,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      SizedBox(height: spacing.elementGapMin),
                      CurrencyText(
                        amount: snapshot.isUnknown
                            ? snapshot.limit
                            : snapshot.remaining.abs(),
                        fixedLength: 0,
                        compact: false,
                        suffixText: snapshot.isUnknown
                            ? 'limit'
                            : snapshot.isBreached
                                ? ctxt.budget_over
                                : ctxt.budget_left,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: accent,
                        ),
                      ),
                      SizedBox(height: spacing.elementGapMin),
                      if (!snapshot.isUnknown) ...[
                        Row(
                          children: [
                            Text(
                              '${ctxt.budget_spent} ',
                              style: textTheme.bodySmall?.copyWith(
                                color: color.onSurfaceVariant,
                              ),
                            ),
                            Flexible(
                              child: CurrencyText(
                                amount: snapshot.spent,
                                fixedLength: 0,
                                compact: true,
                                style: textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              ' / ',
                              style: textTheme.bodySmall?.copyWith(
                                color: color.onSurfaceVariant,
                              ),
                            ),
                            Flexible(
                              child: CurrencyText(
                                amount: snapshot.limit,
                                fixedLength: 0,
                                compact: true,
                                style: textTheme.bodySmall?.copyWith(
                                  color: color.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: spacing.elementGap),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            semanticsLabel:
                                '${snapshot.budgetName.safe()} progress',
                            value: progress,
                            minHeight: spacing.progressThin,
                            backgroundColor: color.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation(accent),
                          ),
                        ),
                        SizedBox(height: spacing.elementGapMin),
                        Row(
                          children: [
                            Text(
                              '$percent%',
                              style: textTheme.labelSmall?.copyWith(
                                color: color.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: spacing.elementGap),
                            Expanded(
                              child: Text(
                                _forecastLabel(ctxt, color, accent),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.labelSmall?.copyWith(
                                  color: accent == color.onSurface
                                      ? color.onSurfaceVariant
                                      : accent,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else
                        Text(
                          ctxt.budget_insufficientData,
                          style: textTheme.bodySmall?.copyWith(
                            color: color.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      if (snapshot.recoverySignal != null &&
                          !snapshot.isUnknown) ...[
                        SizedBox(height: spacing.elementGapMin),
                        Text(
                          _recoveryLabel(ctxt),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelSmall?.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
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
        return sectionAccent == color.onSurface ? color.primary : sectionAccent;
    }
  }

  String _forecastLabel(
    AppLocalizations ctxt,
    ColorScheme color,
    Color accent,
  ) {
    if (snapshot.isBreached) return ctxt.budget_alreadyBreached;
    if (snapshot.isForecastVisible) {
      return ctxt.budget_forecastBreach(snapshot.daysUntilLimit!);
    }
    return ctxt.budget_paceBelowLimit;
  }

  String _recoveryLabel(AppLocalizations ctxt) {
    if (snapshot.isBreached) {
      return '${ctxt.budget_reduceBy} ${formatCurrency(snapshot.dailyGap.abs(), code: BaseCurrency.code)}/day';
    }
    return '${ctxt.budget_spendAtMost} ${formatCurrency(snapshot.remainingDailyAllowance, code: BaseCurrency.code)}/day';
  }
}

class _BudgetVisual extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final ColorScheme color;
  final AppSpacing spacing;

  const _BudgetVisual({
    required this.icon,
    required this.accent,
    required this.color,
    required this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: spacing.cardInner * 5,
      height: spacing.cardInner * 4,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
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
      child: Icon(icon, color: accent, size: spacing.iconXL),
    );
  }
}

Future<void> _showBudgetActions(
  BuildContext context,
  BudgetConstraintSnapshot snapshot,
) async {
  final color = Theme.of(context).colorScheme;
  final textTheme = Theme.of(context).textTheme;
  final spacing = ProviderScope.containerOf(context).read(spacingProvider);
  final ctxt = AppLocalizations.of(context)!;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => SafeArea(
      child: Container(
        padding: EdgeInsets.fromLTRB(
          spacing.cardInner,
          spacing.elementGap,
          spacing.cardInner,
          spacing.cardInner,
        ),
        decoration: BoxDecoration(
          color: color.surfaceContainerHigh,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(spacing.radiusLarge),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: spacing.cardInner * 2,
              height: spacing.elementGapMin,
              decoration: BoxDecoration(
                color: color.primary,
                borderRadius: BorderRadius.circular(spacing.radiusSmall),
              ),
            ),
            SizedBox(height: spacing.elementGap),
            Row(
              children: [
                _BudgetVisual(
                  icon: snapshot.isBreached
                      ? LucideIcons.triangleAlert
                      : LucideIcons.wallet,
                  accent: snapshot.isBreached ? color.error : color.primary,
                  spacing: spacing,
                  color: color,
                ),
                SizedBox(width: spacing.elementGap),
                Expanded(
                  child: Text(
                    snapshot.budgetName.safe(),
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            Divider(height: spacing.sectionGap),
            _budgetAction(
              sheetContext,
              icon: LucideIcons.walletCards,
              label: ctxt.budget_viewDetails,
              color: color,
              spacing: spacing,
              onTap: () => context.push(
                AppRoutes.budgetDetails,
                extra: snapshot.budgetId,
              ),
            ),
            if (snapshot.isUnknown)
              _budgetAction(
                sheetContext,
                icon: LucideIcons.plus,
                label: ctxt.budget_fixData,
                color: color,
                spacing: spacing,
                onTap: () => context.push(AppRoutes.addTransaction),
              ),
            _budgetAction(
              sheetContext,
              icon: LucideIcons.pencil,
              label: ctxt.common_edit,
              color: color,
              spacing: spacing,
              onTap: () => context.push(
                AppRoutes.addBudget,
                extra: {'budgetId': snapshot.budgetId},
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _budgetAction(
  BuildContext sheetContext, {
  required IconData icon,
  required String label,
  required ColorScheme color,
  required AppSpacing spacing,
  required VoidCallback onTap,
}) {
  return Material(
    type: MaterialType.transparency,
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: spacing.touchTargetSmall,
        height: spacing.touchTargetSmall,
        decoration: BoxDecoration(
          color: color.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(spacing.radiusSmall),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: spacing.iconSM, color: color.primary),
      ),
      title: Text(label),
      trailing: Icon(
        LucideIcons.chevronRight,
        size: spacing.iconSM,
        color: color.onSurfaceVariant,
      ),
      onTap: () {
        Navigator.pop(sheetContext);
        HapticFeedback.mediumImpact();
        onTap();
      },
    ),
  );
}
