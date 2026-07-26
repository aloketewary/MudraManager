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
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/core/state/app_screen_state.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:mudra_manager/core/utils/refresh_helper.dart';
import 'package:mudra_manager/features/budget/data/budget_constraint_provider.dart';
import 'package:mudra_manager/features/dashboard/data/today_card_analytics.dart';
import 'package:mudra_manager/shared/templates/screen_shell.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:mudra_manager/shared/widgets/no_data_found.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:mudra_manager/shared/widgets/type_section_header.dart';

class AdaptiveBudgetDashboard extends ConsumerStatefulWidget {
  const AdaptiveBudgetDashboard({super.key});

  @override
  ConsumerState<AdaptiveBudgetDashboard> createState() =>
      _AdaptiveBudgetDashboardState();
}

class _AdaptiveBudgetDashboardState
    extends ConsumerState<AdaptiveBudgetDashboard>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    TodayCardAnalytics.recordDestinationOpened(destination: 'budget');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(budgetConstraintsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctxt = AppLocalizations.of(context)!;
    final spacing = ref.watch(spacingProvider);

    return ScreenShell(
      config: ScreenShellConfig(
        title: ctxt.budget_dashboardPageTitle,
        appBarMode: AppBarMode.standard,
        enableRefresh: false,
      ),
      actions: ScreenActions.build(
        appBar: [
          ScreenAction(
            id: 'add_budget',
            label: ctxt.common_add,
            icon: LucideIcons.plus,
            onTap: () {
              HapticFeedback.mediumImpact();
              context.push(AppRoutes.addBudget);
            },
          ),
        ],
      ),
      body: ref.watch(budgetConstraintsProvider).when(
            data: (snapshots) {
              if (snapshots.isEmpty) {
                return NoDataFound(
                  message: BuddyMessages.noBudgets,
                  iconData: LucideIcons.shieldAlert,
                  action: ElevatedButton.icon(
                    onPressed: () => context.push(AppRoutes.addBudget),
                    icon: const Icon(LucideIcons.plus),
                    label: Text(ctxt.common_add),
                  ),
                );
              }
              return _BudgetConstraintList(snapshots: snapshots);
            },
            loading: () => ListView(
              padding: EdgeInsets.symmetric(
                horizontal: spacing.cardHorizontal,
                vertical: spacing.cardVertical,
              ),
              children: List.generate(4, (_) => const BudgetCardSkeleton()),
            ),
            error: (_, __) => Center(child: Text(BuddyMessages.genericError)),
          ),
    );
  }
}

class _BudgetConstraintList extends ConsumerWidget {
  final List<BudgetConstraintSnapshot> snapshots;

  const _BudgetConstraintList({required this.snapshots});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final ctxt = AppLocalizations.of(context)!;

    final needsAttention = snapshots
        .where((s) => s.urgency != BudgetConstraintUrgency.withinLimit)
        .toList();
    final healthy = snapshots
        .where((s) => s.urgency == BudgetConstraintUrgency.withinLimit)
        .toList();

    return RefreshIndicator(
      onRefresh: () => RefreshHelper.withMinDuration(() async {
        ref.invalidate(budgetConstraintsProvider);
      }),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: spacing.cardHorizontal,
          vertical: spacing.cardVertical,
        ),
        children: [
          const _PortfolioHeroCard(),
          SizedBox(height: spacing.elementGap * 2),

          if (needsAttention.isNotEmpty) ...[
            TypeSectionHeader(
              label: ctxt.budget_highlightLabel,
              icon: LucideIcons.triangleAlert,
              accentColor: Colors.amber.shade700,
            ),
            SizedBox(height: spacing.elementGap),
            ...needsAttention.map(
              (s) => Padding(
                padding: EdgeInsets.only(bottom: spacing.elementGap),
                child: _BudgetConstraintCard(snapshot: s),
              ),
            ),
            SizedBox(height: spacing.elementGap),
          ],

          if (healthy.isNotEmpty) ...[
            TypeSectionHeader(
              label: ctxt.budget_onTrackSection,
              icon: LucideIcons.shieldCheck,
              accentColor: color.primary,
            ),
            SizedBox(height: spacing.elementGap),
            ...healthy.map(
              (s) => Padding(
                padding: EdgeInsets.only(bottom: spacing.elementGap),
                child: _BudgetConstraintCard(snapshot: s),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── PORTFOLIO HERO CARD (one glow per screen) ──

class _PortfolioHeroCard extends ConsumerWidget {
  const _PortfolioHeroCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;
    final isDark = color.brightness == Brightness.dark;

    return ref.watch(budgetPortfolioProvider).when(
          data: (portfolio) {
            final hasBreaches = portfolio.breachedCount > 0;
            final accent = hasBreaches ? color.error : color.primary;

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
                  Row(
                    children: [
                      Icon(LucideIcons.wallet, size: 14, color: accent),
                      SizedBox(width: spacing.elementGapMin),
                      Text(
                        ctxt.budget_totalBudget,
                        style: textTheme.labelLarge?.copyWith(color: accent),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing.elementGap),
                  CurrencyText(
                    amount: portfolio.totalRemaining,
                    fixedLength: 0,
                    suffixText: ctxt.budget_remaining.toLowerCase(),
                    style: textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: color.onSurface,
                    ),
                  ),
                  SizedBox(height: spacing.elementGap * 1.5),
                  Row(
                    children: [
                      _statPill(
                        icon: LucideIcons.layoutGrid,
                        label: '${portfolio.totalBudgets} ${ctxt.budget_activeBudgets}',
                        color: accent,
                        spacing: spacing,
                        textTheme: textTheme,
                      ),
                      if (portfolio.breachedCount > 0) ...[
                        SizedBox(width: spacing.elementGap),
                        _statPill(
                          icon: LucideIcons.circleAlert,
                          label: '${portfolio.breachedCount} breached',
                          color: color.error,
                          spacing: spacing,
                          textTheme: textTheme,
                        ),
                      ],
                      if (portfolio.paceRiskCount > 0) ...[
                        SizedBox(width: spacing.elementGap),
                        _statPill(
                          icon: LucideIcons.clock,
                          label: '${portfolio.paceRiskCount} pace risk',
                          color: Colors.amber.shade700,
                          spacing: spacing,
                          textTheme: textTheme,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
  }

  Widget _statPill({
    required IconData icon,
    required String label,
    required Color color,
    required AppSpacing spacing,
    required TextTheme textTheme,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.elementGap,
        vertical: spacing.elementGapMin,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(spacing.radiusSmall),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          SizedBox(width: spacing.elementGapMin),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── BUDGET CONSTRAINT CARD ──

class _BudgetConstraintCard extends ConsumerWidget {
  final BudgetConstraintSnapshot snapshot;

  const _BudgetConstraintCard({required this.snapshot});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;
    final ctxt = AppLocalizations.of(context)!;

    final accent = _accentColor(color, brightness);

    return Container(
      decoration: BoxDecoration(
        color: color.surface.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(spacing.radiusMedium + 4),
        border: Border.all(
          color: snapshot.isBreached
              ? accent.withValues(alpha: 0.4)
              : color.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: color.onSurface.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(spacing.radiusMedium + 4),
          onTap: () {
            HapticFeedback.lightImpact();
            context.push(AppRoutes.budgetDetails, extra: snapshot.budgetId);
          },
          child: Padding(
            padding: EdgeInsets.all(spacing.cardInner),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Budget name
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(spacing.elementGap),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(spacing.radiusSmall),
                      ),
                      child: Icon(
                        snapshot.isBreached
                            ? LucideIcons.triangleAlert
                            : LucideIcons.wallet,
                        size: 16,
                        color: accent,
                      ),
                    ),
                    SizedBox(width: spacing.elementGap),
                    Expanded(
                      child: Text(
                        snapshot.budgetName,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing.elementGap),

                // 2. Hero: remaining/over amount
                _buildHero(textTheme, accent, ctxt),
                SizedBox(height: spacing.elementGapMin),

                // 3. Spent context
                if (!snapshot.isUnknown) ...[
                  _buildSpentContext(textTheme, color, ctxt),
                  SizedBox(height: spacing.elementGap),
                ],

                // 4. Forecast (single line — evidence)
                if (!snapshot.isUnknown) ...[
                  _buildForecast(textTheme, color, accent, ctxt),
                  SizedBox(height: spacing.elementGapMin),
                ],

                // 5. Recovery signal (single line — action)
                if (snapshot.recoverySignal != null) ...[
                  _buildRecovery(textTheme, accent, ctxt),
                  SizedBox(height: spacing.elementGap),
                ],

                // Unknown state
                if (snapshot.isUnknown) ...[
                  SizedBox(height: spacing.elementGap),
                  Text(
                    ctxt.budget_insufficientData,
                    style: textTheme.bodySmall?.copyWith(
                      color: color.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  SizedBox(height: spacing.elementGap),
                ],

                // 6. Progress bar (thin, subordinate)
                if (!snapshot.isUnknown) ...[
                  _buildProgressBar(spacing, color, accent),
                ],

                // 7. Action
                SizedBox(height: spacing.elementGap),
                _buildAction(context, ref, spacing, color, textTheme, ctxt),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero(TextTheme textTheme, Color accent, AppLocalizations ctxt) {
    if (snapshot.isUnknown) {
      return CurrencyText(
        amount: snapshot.limit,
        fixedLength: 0,
        compact: false,
        suffixText: 'limit',
        style: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w900,
          color: accent,
        ),
      );
    }

    return CurrencyText(
      amount: snapshot.remaining.abs(),
      fixedLength: 0,
      compact: false,
      suffixText: snapshot.isBreached ? ctxt.budget_over : ctxt.budget_left,
      style: (snapshot.isBreached
              ? textTheme.headlineMedium
              : textTheme.headlineSmall)
          ?.copyWith(
        fontWeight: FontWeight.w900,
        color: accent,
      ),
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
          style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
        ),
        CurrencyText(
          amount: snapshot.spent,
          fixedLength: 0,
          compact: true,
          style: textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: color.onSurface,
          ),
        ),
        Text(
          ' of ',
          style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
        ),
        CurrencyText(
          amount: snapshot.limit,
          fixedLength: 0,
          compact: true,
          style: textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: color.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildForecast(
    TextTheme textTheme,
    ColorScheme color,
    Color accent,
    AppLocalizations ctxt,
  ) {
    // Breached: "At current pace: already breached"
    // Pace risk: "At current pace: limit reached in X days"
    // Healthy: "Current pace below limit"
    final String text;
    final Color textColor;

    if (snapshot.isBreached) {
      text = ctxt.budget_alreadyBreached;
      textColor = accent;
    } else if (snapshot.isForecastVisible) {
      text = ctxt.budget_forecastBreach(snapshot.daysUntilLimit!);
      textColor = accent;
    } else {
      text = ctxt.budget_paceBelowLimit;
      textColor = color.onSurfaceVariant;
    }

    return Text(
      text,
      style: textTheme.bodySmall?.copyWith(
        color: textColor,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildRecovery(
    TextTheme textTheme,
    Color accent,
    AppLocalizations ctxt,
  ) {
    final text = snapshot.isBreached
        ? '${ctxt.budget_reduceBy} ${formatCurrency(snapshot.dailyGap.abs(), code: BaseCurrency.code)}/day'
        : '${ctxt.budget_spendAtMost} ${formatCurrency(snapshot.remainingDailyAllowance, code: BaseCurrency.code)}/day';

    return Text(
      text,
      style: textTheme.labelSmall?.copyWith(
        color: accent,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildProgressBar(AppSpacing spacing, ColorScheme color, Color accent) {
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
          style: TextStyle(
            fontSize: 11,
            color: color.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAction(
    BuildContext context,
    WidgetRef ref,
    AppSpacing spacing,
    ColorScheme color,
    TextTheme textTheme,
    AppLocalizations ctxt,
  ) {
    // CTA resolves the displayed state
    final (String label, IconData icon, VoidCallback onTap) = switch (snapshot.urgency) {
      BudgetConstraintUrgency.breached ||
      BudgetConstraintUrgency.imminentBreach ||
      BudgetConstraintUrgency.approachingBreach => (
        ctxt.budget_reviewSpending,
        LucideIcons.search,
        () => context.push(AppRoutes.budgetDetails, extra: snapshot.budgetId),
      ),
      BudgetConstraintUrgency.unknown => (
        ctxt.budget_fixData,
        LucideIcons.plus,
        () => context.push(AppRoutes.addTransaction),
      ),
      _ => (
        ctxt.budget_viewDetails,
        LucideIcons.arrowRight,
        () => context.push(AppRoutes.budgetDetails, extra: snapshot.budgetId),
      ),
    };

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(spacing.radiusSmall),
          ),
        ),
      ),
    );
  }

  Color _accentColor(ColorScheme color, Brightness brightness) {
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
