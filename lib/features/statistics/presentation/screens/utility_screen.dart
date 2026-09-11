import 'package:mudra_manager/core/extension/localization_extenstion.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:mudra_manager/shared/widgets/no_data_found.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:mudra_manager/features/dashboard/data/priority_alert_provider.dart';
import 'package:mudra_manager/features/budget/data/budget_service_provider.dart';
import 'package:mudra_manager/features/goal/data/goal_provider.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mudra_manager/features/transactions/data/bill_control_center_provider.dart';
import 'package:mudra_manager/features/trip/data/trip_provider.dart';
import 'package:mudra_manager/features/credit_card/data/credit_card_provider.dart';
import 'package:mudra_manager/features/statistics/data/adaptive_utility_provider.dart';

class UtilityScreen extends ConsumerStatefulWidget {
  final bool isTabActive;
  const UtilityScreen({super.key, this.isTabActive = false});

  @override
  ConsumerState<UtilityScreen> createState() => UtilityScreenState();
}

class UtilityScreenState extends ConsumerState<UtilityScreen> {
  List<String> _hiddenUtilities = [];
  List<String> _dismissedAttentionItems = [];
  bool _isLoading = true;
  Key _animKey = UniqueKey();
  bool _showingAdvisoryExpanded = false;

  // Grouped utility definitions
  static const _activeMoney = [
    _UtilityDef(
      id: 'recurring',
      titleKey: 'title_bills',
      subtitleKey: 'budget_upcomingRecurring',
      icon: LucideIcons.repeat,
      route: AppRoutes.recurringTransactions,
      section: _Section.active,
    ),
    _UtilityDef(
      id: 'trips',
      titleKey: 'title_groups',
      subtitleKey: 'budget_tripsAndSplits',
      icon: LucideIcons.users,
      route: AppRoutes.trips,
      section: _Section.active,
    ),
    _UtilityDef(
      id: 'credit_cards',
      titleKey: 'cc_title',
      subtitleKey: 'cc_utilitySubtitle',
      icon: LucideIcons.creditCard,
      route: AppRoutes.creditCardBills,
      section: _Section.active,
    ),
  ];

  static const _planning = [
    _UtilityDef(
      id: 'budgets',
      titleKey: 'title_budgets',
      subtitleKey: 'budget_spendingLimits',
      icon: LucideIcons.chartPie,
      route: AppRoutes.budgetDashboard,
      section: _Section.planning,
    ),
    _UtilityDef(
      id: 'goals',
      titleKey: 'title_goals',
      subtitleKey: 'budget_savingsProgress',
      icon: LucideIcons.target,
      route: AppRoutes.goalScreen,
      section: _Section.planning,
    ),
  ];

  static const _insights = [
    _UtilityDef(
      id: 'monthly_recap',
      titleKey: 'title_monthlyRecap',
      subtitleKey: 'recap_yourMonthAtGlance',
      icon: LucideIcons.calendarCheck,
      route: AppRoutes.monthlyRecap,
      section: _Section.insights,
    ),
    _UtilityDef(
      id: 'monthly_comparison',
      titleKey: 'title_compareMonths',
      subtitleKey: 'recap_trackProgressOverTime',
      icon: LucideIcons.arrowLeftRight,
      route: AppRoutes.monthlyComparison,
      section: _Section.insights,
    ),
    _UtilityDef(
      id: 'tax_estimation',
      titleKey: 'tax_title',
      subtitleKey: 'utility_taxSubtitle',
      icon: LucideIcons.landmark,
      route: AppRoutes.taxEstimation,
      section: _Section.insights,
    ),
    _UtilityDef(
      id: 'debt_snowball',
      titleKey: 'debt_title',
      subtitleKey: 'debt_utilitySubtitle',
      icon: LucideIcons.snowflake,
      route: AppRoutes.debtSnowball,
      section: _Section.insights,
    ),
  ];

  List<_UtilityDef> get _allUtilities => [
        ..._activeMoney,
        ..._planning,
        ..._insights,
      ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  @override
  void didUpdateWidget(covariant UtilityScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isTabActive && !oldWidget.isTabActive) {
      setState(() => _animKey = UniqueKey());
    }
  }

  // For reduced motion support - cached for build performance
  bool cachedReducedMotion = false;

  bool get _isReducedMotion {
    try {
      return MediaQuery.of(context).disableAnimations;
    } catch (_) {
      return cachedReducedMotion;
    }
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final hidden = prefs.getStringList('hidden_utilities') ?? [];
    final dismissed = prefs.getStringList('dismissed_attention_items') ?? [];
    if (mounted) {
      setState(() {
        _hiddenUtilities = hidden;
        _dismissedAttentionItems = dismissed;
        _isLoading = false;
      });
    }
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('hidden_utilities', _hiddenUtilities);
    await prefs.setStringList(
      'dismissed_attention_items',
      _dismissedAttentionItems,
    );
  }

  void _dismissAttentionItem(String itemId) {
    setState(() {
      _dismissedAttentionItems.add(itemId);
    });
    _savePreferences();
  }

  bool _isVisible(String id) => !_hiddenUtilities.contains(id);

  void showCustomizeSheet() => _showCustomizeSheet();

  void _showCustomizeSheet() {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.read(spacingProvider);
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: color.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(spacing.radiusSmall * 2),
        ),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.6,
          padding: EdgeInsets.only(bottom: spacing.sectionGap),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(spacing.cardInner + spacing.elementGap),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: color.onSurfaceVariant.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(height: spacing.sectionGap),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.settings2,
                          color: color.primary,
                          size: 22,
                        ),
                        SizedBox(width: spacing.elementGap),
                        Text(
                          l10n.utility_customizeUtilities,
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            setModalState(() => _hiddenUtilities = []);
                            setState(() {});
                            _savePreferences();
                            SnackbarService.info(
                              BuddyMessages.settingsSaved,
                              spacing,
                            );
                          },
                          child: Text(
                            AppLocalizations.of(context)!.common_reset,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.cardHorizontal,
                  ),
                  children: _allUtilities.map((u) {
                    final visible = _isVisible(u.id);
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        color: color.surfaceContainerLow,
                        border: Border(
                          bottom: BorderSide(
                            color: color.outlineVariant.withValues(alpha: 0.22),
                          ),
                        ),
                      ),
                      child: SwitchListTile(
                        value: visible,
                        onChanged: (v) {
                          HapticFeedback.selectionClick();
                          setModalState(() {
                            if (v) {
                              _hiddenUtilities.remove(u.id);
                            } else {
                              _hiddenUtilities.add(u.id);
                            }
                          });
                          setState(() {});
                          _savePreferences();
                        },
                        secondary: Icon(u.icon, color: color.primary, size: 22),
                        title: Text(
                          l10n.translate(u.titleKey),
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          l10n.translate(u.subtitleKey),
                          style: textTheme.bodySmall?.copyWith(
                            color: color.onSurfaceVariant,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final gap = spacing.elementGap;
          final columns = constraints.maxWidth >= 360 ? 2 : 1;
          final width = columns == 2
              ? (constraints.maxWidth - gap) / 2
              : constraints.maxWidth;

          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.cardHorizontalMax,
              vertical: spacing.cardVerticalMax,
            ),
            child: Wrap(
              spacing: gap,
              runSpacing: gap,
              children: List.generate(
                6,
                (_) => SizedBox(
                  width: width,
                  child: SkeletonLoader(
                    width: double.infinity,
                    height: 176,
                    borderRadius: BorderRadius.circular(spacing.radiusLarge),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    final activeVisible = _activeMoney.where((u) => _isVisible(u.id)).toList();
    final planningVisible = _planning.where((u) => _isVisible(u.id)).toList();
    final insightsVisible = _insights.where((u) => _isVisible(u.id)).toList();

    final hasAny = activeVisible.isNotEmpty ||
        planningVisible.isNotEmpty ||
        insightsVisible.isNotEmpty;

    if (!hasAny) {
      return NoDataFound(
        message: BuddyMessages.noData,
        iconData: LucideIcons.layoutGrid,
        action: FilledButton.icon(
          onPressed: _showCustomizeSheet,
          icon: const Icon(LucideIcons.plus),
          label: Text(l10n.utility_addUtilities),
        ),
      );
    }

    return KeyedSubtree(
      key: _animKey,
      child: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.cardHorizontal,
          vertical: spacing.cardVertical,
        ),
        children: [
          // Contextual attention stays above the tool grid.
          _buildAdvisoryLayer(color, textTheme, spacing, l10n),
          _buildPriorityAlert(color, textTheme, spacing),

          if (planningVisible.isNotEmpty) ...[
            _sectionHeader(
              l10n.section_planning,
              LucideIcons.compass,
              color.primary,
              textTheme,
              spacing,
              count: planningVisible.length,
            ),
            SizedBox(height: spacing.elementGap),
            _buildPlanningGroup(
              planningVisible,
              color,
              textTheme,
              spacing,
              l10n,
            ),
            SizedBox(height: spacing.sectionGap),
          ],

          if (activeVisible.isNotEmpty) ...[
            _sectionHeader(
              l10n.section_activeMoney,
              LucideIcons.zap,
              color.error,
              textTheme,
              spacing,
              count: activeVisible.length,
            ),
            SizedBox(height: spacing.elementGap),
            _buildUtilityGroup(activeVisible, color, textTheme, spacing, l10n),
            SizedBox(height: spacing.sectionGap),
          ],

          if (insightsVisible.isNotEmpty) ...[
            _sectionHeader(
              l10n.section_insights,
              LucideIcons.lightbulb,
              color.secondary,
              textTheme,
              spacing,
              count: insightsVisible.length,
            ),
            SizedBox(height: spacing.elementGap),
            _buildUtilityGroup(
              insightsVisible,
              color,
              textTheme,
              spacing,
              l10n,
            ),
          ],

          SizedBox(
            height: MediaQuery.of(context).padding.bottom +
                kBottomNavigationBarHeight +
                16,
          ),
        ],
      ),
    );
  }


  Widget _buildAdvisoryLayer(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations l10n,
  ) {
    return Consumer(
      builder: (context, ref, _) {
        final adaptiveStateAsync = ref.watch(adaptiveUtilityProvider);

        return adaptiveStateAsync.when(
          data: (adaptiveState) {
            final attentionItems = adaptiveState.attentionItems
                .where((item) => !_dismissedAttentionItems.contains(item.id))
                .toList();

            if (attentionItems.isEmpty) return const SizedBox.shrink();

            final shouldShowAdvisory = adaptiveState.shouldShowAdvisory;
            if (!shouldShowAdvisory) return const SizedBox.shrink();

            return Padding(
              padding: EdgeInsets.only(bottom: spacing.sectionGap),
              child: Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                color: color.surfaceContainerHigh,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  side: BorderSide(color: color.primary.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    // Advisory Header
                    Semantics(
                      label: _showingAdvisoryExpanded
                          ? l10n.utility_advisoryCollapseSemantic(
                              attentionItems.length,
                            )
                          : l10n.utility_advisoryExpandSemantic(
                              attentionItems.length,
                            ),
                      button: true,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _showingAdvisoryExpanded =
                                !_showingAdvisoryExpanded;
                          });
                        },
                        borderRadius: BorderRadius.circular(
                          spacing.radiusMedium,
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(spacing.cardInner),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(spacing.elementGap),
                                decoration: BoxDecoration(
                                  color: color.primary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  LucideIcons.lightbulb,
                                  color: color.primary,
                                  size: 18,
                                ),
                              ),
                              SizedBox(width: spacing.elementGap * 1.5),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.utility_financialAdvisory,
                                      style: textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w500,
                                        color: color.primary,
                                      ),
                                    ),
                                    Text(
                                      l10n.utility_nItemsNeedAttention(
                                        attentionItems.length,
                                      ),
                                      style: textTheme.bodySmall?.copyWith(
                                        color: color.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              AnimatedRotation(
                                duration: spacing.animFast,
                                turns: _showingAdvisoryExpanded ? 0.5 : 0,
                                child: Icon(
                                  LucideIcons.chevronDown,
                                  size: 16,
                                  color: color.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Expandable Advisory Items
                    if (_showingAdvisoryExpanded) ...[
                      Divider(
                        height: 1,
                        color: color.outlineVariant.withValues(alpha: 0.5),
                      ),
                      ...attentionItems.take(3).map(
                            (item) => _buildAdvisoryItem(
                              item,
                              color,
                              textTheme,
                              spacing,
                            ),
                          ),
                      if (attentionItems.length > 3)
                        Padding(
                          padding: EdgeInsets.all(spacing.cardInner),
                          child: Text(
                            l10n.utility_nMoreItems(attentionItems.length - 3),
                            style: textTheme.bodySmall?.copyWith(
                              color: color.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (error, stack) => const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildAdvisoryItem(
    AttentionItem item,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    final itemColor = _getAttentionColor(item.type, color);

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        context.push(item.actionRoute);
      },
      child: Padding(
        padding: EdgeInsets.all(spacing.cardInner),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(spacing.elementGap * 0.75),
              decoration: BoxDecoration(
                color: itemColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getAttentionIcon(item.type),
                color: itemColor,
                size: 14,
              ),
            ),
            SizedBox(width: spacing.elementGap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.message.isNotEmpty)
                    Text(
                      item.message,
                      style: textTheme.bodySmall?.copyWith(
                        color: color.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (item.type != AttentionType.critical)
              IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _dismissAttentionItem(item.id);
                },
                icon: Icon(
                  LucideIcons.x,
                  size: 16,
                  color: color.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                padding: EdgeInsets.all(spacing.elementGap * 0.5),
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              ),
            Icon(
              LucideIcons.chevronRight,
              size: 14,
              color: color.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Color _getAttentionColor(AttentionType type, ColorScheme color) {
    switch (type) {
      case AttentionType.critical:
        return color.error;
      case AttentionType.warning:
        return color.tertiary;
      case AttentionType.info:
        return color.primary;
      case AttentionType.insight:
        return color.secondary;
    }
  }

  IconData _getAttentionIcon(AttentionType type) {
    switch (type) {
      case AttentionType.critical:
        return LucideIcons.alertTriangle;
      case AttentionType.warning:
        return LucideIcons.alertCircle;
      case AttentionType.info:
        return LucideIcons.info;
      case AttentionType.insight:
        return LucideIcons.trendingUp;
    }
  }

  Widget _sectionHeader(
    String title,
    IconData icon,
    Color accent,
    TextTheme textTheme,
    AppSpacing spacing, {
    int staggerIndex = 0,
    int? count,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: spacing.elementGap),
      child: Row(
        children: [
          Container(
            width: spacing.touchTargetSmall,
            height: spacing.touchTargetSmall,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
              border: Border.all(color: accent.withValues(alpha: 0.20)),
            ),
            child: Icon(icon, size: spacing.iconSM, color: accent),
          ),
          SizedBox(width: spacing.elementGap),
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ),
          if (count != null)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: spacing.elementGap,
                vertical: spacing.elementGapMin,
              ),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(spacing.radiusLarge),
                border: Border.all(color: accent.withValues(alpha: 0.18)),
              ),
              child: Text(
                '$count',
                style: textTheme.labelMedium?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          SizedBox(width: spacing.elementGapMin),
          Icon(
            LucideIcons.arrowRight,
            size: spacing.iconSM,
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant
                .withValues(alpha: 0.62),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(
          duration: _isReducedMotion ? Duration.zero : 180.ms,
          delay: _isReducedMotion ? Duration.zero : (50 * staggerIndex).ms,
        )
        .slideX(
          begin: -0.08,
          end: 0,
          duration: _isReducedMotion ? Duration.zero : 180.ms,
          delay: _isReducedMotion ? Duration.zero : (50 * staggerIndex).ms,
          curve: Curves.easeOutCubic,
        );
  }

  Widget _buildPriorityAlert(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Consumer(
      builder: (context, ref, _) {
        final alertAsync = ref.watch(priorityAlertProvider);
        return alertAsync.maybeWhen(
          data: (alerts) {
            if (alerts.isEmpty) return const SizedBox.shrink();

            return Padding(
              padding: EdgeInsets.only(bottom: spacing.sectionGap),
              child: Column(
                children: alerts.map((alert) {
                  final alertColor = alert.type == AlertType.urgent
                      ? color.error
                      : alert.type == AlertType.warning
                          ? color.tertiary
                          : color.primary;

                  return Padding(
                    padding: EdgeInsets.only(bottom: spacing.elementGap),
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        context.push(alert.route);
                      },
                      borderRadius: BorderRadius.circular(spacing.radiusMedium),
                      child: Container(
                        padding: EdgeInsets.all(spacing.cardInner),
                        decoration: BoxDecoration(
                          color: alertColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(
                            spacing.radiusMedium,
                          ),
                          border: Border.all(
                            color: alertColor.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(spacing.elementGap),
                              decoration: BoxDecoration(
                                color: alertColor.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                alert.type == AlertType.urgent
                                    ? LucideIcons.circleAlert
                                    : LucideIcons.triangleAlert,
                                color: alertColor,
                                size: 18,
                              ),
                            ),
                            SizedBox(width: spacing.elementGap * 1.5),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    alert.title,
                                    style: textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    alert.message,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: color.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              LucideIcons.chevronRight,
                              size: 16,
                              color: color.onSurfaceVariant.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          },
          orElse: () => const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildPlanningGroup(
    List<_UtilityDef> utilities,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations l10n,
  ) {
    return Consumer(
      builder: (context, ref, _) {
        final budgetsAsync = ref.watch(budgetsWithProgressProvider);
        final goalsAsync = ref.watch(goalsProvider);
        final budgets = budgetsAsync.value;
        final activeGoals = goalsAsync.value
            ?.where((goal) => goal.isActive && goal.progressPercent < 1.0)
            .toList();

        if (budgets == null && activeGoals == null) {
          return _buildUtilityGroup(utilities, color, textTheme, spacing, l10n);
        }

        final visibleBudget =
            utilities.where((u) => u.id == 'budgets').firstOrNull;
        final visibleGoal = utilities.where((u) => u.id == 'goals').firstOrNull;
        final children = <Widget>[];

        if (visibleBudget != null) {
          final totalLimit = budgets?.fold<double>(
            0,
            (sum, progress) => sum + progress.snapshot.limit,
          );
          final totalSpent = budgets?.fold<double>(
            0,
            (sum, progress) => sum + progress.spent,
          );
          final budgetProgress = totalLimit != null && totalLimit > 0
              ? (totalSpent! / totalLimit).clamp(0.0, 1.0)
              : null;

          children.add(
            _buildPlanningRow(
              visibleBudget,
              color,
              textTheme,
              spacing,
              l10n,
              progress: budgetProgress,
              detail: totalLimit != null && totalSpent != null
                  ? _ProgressDetail(current: totalSpent, target: totalLimit)
                  : null,
              semanticValue: budgetProgress == null
                  ? null
                  : '${(budgetProgress * 100).round()}%',
            ),
          );
        }

        if (visibleGoal != null) {
          final topGoal = activeGoals?.isNotEmpty == true
              ? activeGoals!.reduce(
                  (a, b) => a.progressPercent > b.progressPercent ? a : b,
                )
              : null;

          children.add(
            _buildPlanningRow(
              visibleGoal,
              color,
              textTheme,
              spacing,
              l10n,
              progress: topGoal?.progressPercent,
              detail: topGoal == null
                  ? null
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          topGoal.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelSmall?.copyWith(
                            color: color.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: spacing.elementGapMin),
                        _ProgressDetail(
                          current: topGoal.currentAmount,
                          target: topGoal.targetAmount,
                          currencyCode: topGoal.currencyCode,
                        ),
                      ],
                    ),
              semanticValue: topGoal == null
                  ? null
                  : '${(topGoal.progressPercent * 100).round()}%',
            ),
          );
        }

        return _buildUtilityCardGrid(children, spacing);
      },
    );
  }

  Widget _buildPlanningRow(
    _UtilityDef item,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations l10n, {
    double? progress,
    Widget? detail,
    String? semanticValue,
  }) {
    return _buildUtilityCard(
      item,
      _accentForUtility(item, color),
      color,
      textTheme,
      spacing,
      l10n,
      progress: progress,
      detail: detail,
      semanticValue: semanticValue,
    );
  }

  Color _accentForUtility(_UtilityDef item, ColorScheme color) {
    return switch (item.id) {
      'recurring' => color.tertiary,
      'trips' => color.secondary,
      'credit_cards' => color.error,
      'budgets' => color.primary,
      'goals' => color.tertiary,
      'monthly_recap' => color.secondary,
      'monthly_comparison' => color.primary,
      'tax_estimation' => color.error,
      'debt_snowball' => color.tertiary,
      _ => color.primary,
    };
  }

  Widget _buildUtilityGroup(
    List<_UtilityDef> utilities,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations l10n,
  ) {
    return Consumer(
      builder: (context, ref, _) {
        final billData = utilities.any((item) => item.id == 'recurring')
            ? ref.watch(billControlCenterProvider).value
            : null;
        final activeTrips = utilities.any((item) => item.id == 'trips')
            ? ref.watch(activeTripsProvider).value
            : null;
        final creditCards = utilities.any((item) => item.id == 'credit_cards')
            ? ref.watch(creditCardBillsProvider).value
            : null;

        return _buildUtilityCardGrid(
          utilities.map((item) {
            Widget? topRight;
            Widget? detail;
            String? semanticValue;

            switch (item.id) {
              case 'recurring' when billData != null:
                topRight = _utilityMetricText(
                  '${billData.activeExpenseCount}',
                  color,
                  textTheme,
                );
                detail = _UtilityMetricDetail(
                  value: CurrencyText(
                    amount: billData.expenseUpcomingTotal,
                    compact: true,
                    fixedLength: 0,
                    style: textTheme.labelLarge?.copyWith(
                      color: color.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  label: l10n.translate(item.subtitleKey),
                  color: color.onSurface,
                  textTheme: textTheme,
                  spacing: spacing,
                );
                semanticValue =
                    '${billData.activeExpenseCount} bills, ${billData.expenseUpcomingTotal} upcoming total';
              case 'trips' when activeTrips != null:
                topRight = _utilityMetricText(
                  '${activeTrips.length}',
                  color,
                  textTheme,
                );
                semanticValue = '${activeTrips.length} active trips';
              case 'credit_cards' when creditCards != null:
                topRight = _utilityMetricText(
                  '${creditCards.summary.cardCount}',
                  color,
                  textTheme,
                );
                detail = _UtilityMetricDetail(
                  value: CurrencyText(
                    amount: creditCards.summary.totalOutstanding,
                    compact: true,
                    fixedLength: 0,
                    style: textTheme.labelLarge?.copyWith(
                      color: color.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  label: l10n.translate(item.subtitleKey),
                  color: color.onSurface,
                  textTheme: textTheme,
                  spacing: spacing,
                );
                semanticValue =
                    '${creditCards.summary.cardCount} cards, ${creditCards.summary.totalOutstanding} outstanding';
            }

            return _buildUtilityCard(
              item,
              _accentForUtility(item, color),
              color,
              textTheme,
              spacing,
              l10n,
              topRight: topRight,
              detail: detail,
              semanticValue: semanticValue,
            );
          }).toList(),
          spacing,
        );
      },
    );
  }

  Widget _utilityMetricText(
    String value,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    return Text(
      value,
      style: textTheme.titleMedium?.copyWith(
        color: color.onSurface,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildUtilityCardGrid(List<Widget> cards, AppSpacing spacing) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = spacing.sectionGap;
        final columns = constraints.maxWidth >= 360 ? 2 : 1;
        final cardWidth = columns == 2
            ? (constraints.maxWidth - gap) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: cards
              .map(
                (card) => SizedBox(
                  width: cardWidth,
                  child: card,
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildUtilityCard(
    _UtilityDef item,
    Color accent,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations l10n, {
    double? progress,
    Widget? detail,
    Widget? topRight,
    String? semanticValue,
  }) {
    final isDark = color.brightness == Brightness.dark;
    const cardAspectRatio = 0.98;
    final topColor = Color.lerp(
      color.surfaceContainerHigh,
      accent,
      isDark ? 0.64 : 0.22,
    )!;
    final midColor = Color.lerp(
      color.surfaceContainerHigh,
      accent,
      isDark ? 0.28 : 0.10,
    )!;
    final bottomColor = Color.lerp(
      color.surface,
      accent,
      isDark ? 0.12 : 0.04,
    )!;

    return Semantics(
      label:
          '${l10n.translate(item.titleKey)}, ${l10n.translate(item.subtitleKey)}',
      value: semanticValue,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: AspectRatio(
          aspectRatio: cardAspectRatio,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [topColor, midColor, bottomColor],
                stops: const [0, 0.52, 1],
              ),
              borderRadius: BorderRadius.circular(spacing.radiusLarge),
              border: Border.all(color: accent.withValues(alpha: 0.24)),
              boxShadow: [
                BoxShadow(
                  color: color.shadow.withValues(alpha: isDark ? 0.22 : 0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(spacing.radiusLarge),
              onTap: () {
                HapticFeedback.mediumImpact();
                ref.read(utilityTrackerProvider).trackUtilityOpen(item.id);
                context.push(item.route);
              },
              child: Padding(
                padding: EdgeInsets.all(spacing.cardInner * 0.75),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Transform.translate(
                          offset: Offset(0, -spacing.elementGap),
                          child: Container(
                            width: spacing.touchTargetSmall + 32,
                            height: spacing.touchTargetSmall + 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: color.onSurface.withValues(
                                alpha: isDark ? 0.10 : 0.14,
                              ),
                              borderRadius:
                                  BorderRadius.circular(spacing.radiusMedium),
                              border: Border.all(
                                color: color.onSurface.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Icon(
                              item.icon,
                              size: spacing.iconMD + 4,
                              color: color.onSurface,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (progress != null)
                          _PlanningProgress(
                            value: progress,
                            color: color.onSurface,
                            textTheme: textTheme,
                            spacing: spacing,
                          )
                        else if (topRight != null)
                          topRight
                        else
                          _UtilityCardArrow(
                            color: color.onSurface,
                            spacing: spacing,
                          ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      l10n.translate(item.titleKey).toUpperCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleLarge?.copyWith(
                        color: color.onSurface,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                        height: 1.05,
                      ),
                    ),
                    if (detail != null) ...[
                      SizedBox(height: spacing.elementGap),
                      detail,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UtilityMetricDetail extends StatelessWidget {
  final Widget value;
  final String label;
  final Color color;
  final TextTheme textTheme;
  final AppSpacing spacing;

  const _UtilityMetricDetail({
    required this.value,
    required this.label,
    required this.color,
    required this.textTheme,
    required this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: value),
        SizedBox(width: spacing.elementGapMin),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelSmall?.copyWith(
              color: color.withValues(alpha: 0.72),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _UtilityCardArrow extends StatelessWidget {
  final Color color;
  final AppSpacing spacing;

  const _UtilityCardArrow({
    required this.color,
    required this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    final size = spacing.touchTargetSmall + 8;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: 0.42),
          width: spacing.strokeThin,
        ),
      ),
      child: Icon(
        LucideIcons.arrowUpRight,
        size: spacing.iconSM,
        color: color.withValues(alpha: 0.86),
      ),
    );
  }
}

class _ProgressDetail extends StatelessWidget {
  final double current;
  final double target;
  final String? currencyCode;

  const _ProgressDetail({
    required this.current,
    required this.target,
    this.currencyCode,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CurrencyText(
          amount: current,
          currencyCode: currencyCode,
          compact: true,
          fixedLength: 0,
          style: textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: color.onSurface,
          ),
        ),
        Text(
          ' of ',
          style: textTheme.labelSmall?.copyWith(color: color.onSurfaceVariant),
        ),
        CurrencyText(
          amount: target,
          currencyCode: currencyCode,
          compact: true,
          fixedLength: 0,
          style: textTheme.labelSmall?.copyWith(color: color.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _PlanningProgress extends StatelessWidget {
  final double value;
  final Color color;
  final TextTheme textTheme;
  final AppSpacing spacing;

  const _PlanningProgress({
    required this.value,
    required this.color,
    required this.textTheme,
    required this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: spacing.touchTargetSmall + 8,
      height: spacing.touchTargetSmall + 8,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: value,
            strokeWidth: spacing.strokeNormal,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation(color),
          ),
          Text(
            '${(value * 100).round()}%',
            style: textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _UtilityDef {
  final String id;
  final String titleKey;
  final String subtitleKey;
  final IconData icon;
  final String route;
  final _Section section;

  const _UtilityDef({
    required this.id,
    required this.titleKey,
    required this.subtitleKey,
    required this.icon,
    required this.route,
    required this.section,
  });
}

enum _Section { active, planning, insights }
