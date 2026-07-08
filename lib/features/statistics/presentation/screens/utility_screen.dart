import 'package:mudra_manager/core/extension/localization_extenstion.dart';
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
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mudra_manager/features/statistics/data/adaptive_utility_provider.dart';

class UtilityScreen extends ConsumerStatefulWidget {
  final bool isTabActive;
  const UtilityScreen({super.key, this.isTabActive = false});

  @override
  ConsumerState<UtilityScreen> createState() => UtilityScreenState();
}

class UtilityScreenState extends ConsumerState<UtilityScreen>
    with TickerProviderStateMixin {
  List<String> _hiddenUtilities = [];
  List<String> _dismissedAttentionItems = [];
  bool _isLoading = true;
  late final AnimationController _bgIconController;
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
  ];

  List<_UtilityDef> get _allUtilities =>
      [..._activeMoney, ..._planning, ..._insights];

  @override
  void initState() {
    super.initState();
    _bgIconController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );
    if (widget.isTabActive) _bgIconController.repeat(reverse: true);
    _loadPreferences();
  }

  @override
  void dispose() {
    _bgIconController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant UtilityScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isTabActive && !oldWidget.isTabActive) {
      setState(() => _animKey = UniqueKey());
      _bgIconController.repeat(reverse: true);
    } else if (!widget.isTabActive && oldWidget.isTabActive) {
      _bgIconController.stop();
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
        'dismissed_attention_items', _dismissedAttentionItems,);
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
            top: Radius.circular(spacing.radiusSmall * 2),),
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
                          style: textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setModalState(() => _hiddenUtilities = []);
                            setState(() {});
                            _savePreferences();
                            SnackbarService.info(BuddyMessages.settingsSaved, spacing);
                          },
                          child:
                              Text(AppLocalizations.of(context)!.common_reset),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding:
                      EdgeInsets.symmetric(horizontal: spacing.cardHorizontal),
                  children: _allUtilities.map((u) {
                    final visible = _isVisible(u.id);
                    return Card(
                      elevation: 0,
                      margin: EdgeInsets.only(bottom: spacing.elementGap),
                      color: color.surfaceContainerHighest,
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
                          style: textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          l10n.translate(u.subtitleKey),
                          style: textTheme.bodySmall
                              ?.copyWith(color: color.onSurfaceVariant),
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
      return Padding(
        padding: EdgeInsets.all(spacing.cardHorizontalMax),
        child: Column(
          children: List.generate(
            4,
            (_) => Padding(
              padding: EdgeInsets.only(bottom: spacing.elementGap),
              child: SkeletonLoader(
                width: double.infinity,
                height: 80,
                borderRadius: BorderRadius.circular(spacing.radiusMedium),
              ),
            ),
          ),
        ),
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
          // Financial Advisory Layer (Phase 5)
          _buildAdvisoryLayer(color, textTheme, spacing, l10n),

          // Legacy Priority Alerts
          _buildPriorityAlert(color, textTheme, spacing),

          // 1. Active Money
          if (activeVisible.isNotEmpty) ...[
            _sectionHeader(
              l10n.section_activeMoney,
              LucideIcons.zap,
              color.error,
              textTheme,
              spacing,
              staggerIndex: 0,
            ),
            SizedBox(height: spacing.elementGap),
            Wrap(
              spacing: spacing.elementGap,
              runSpacing: spacing.elementGap,
              children: activeVisible
                  .asMap()
                  .entries
                  .map(
                    (e) => SizedBox(
                      width: (MediaQuery.of(context).size.width -
                              spacing.cardHorizontal * 2 -
                              spacing.elementGap) /
                          2,
                      height: 130,
                      child: _buildCard(
                        e.value,
                        color,
                        textTheme,
                        spacing,
                        e.key,
                        l10n,
                      ),
                    ),
                  )
                  .toList(),
            ),
            SizedBox(height: spacing.sectionGap),
          ],

          // 2. Planning
          if (planningVisible.isNotEmpty) ...[
            _sectionHeader(
              l10n.section_planning,
              LucideIcons.compass,
              color.primary,
              textTheme,
              spacing,
              staggerIndex: 2,
            ),
            SizedBox(height: spacing.elementGap),
            SizedBox(
              height: 130,
              child: Row(
                children: planningVisible
                    .asMap()
                    .entries
                    .map(
                      (e) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: e.key != planningVisible.length - 1
                                ? spacing.elementGap
                                : 0,
                          ),
                          child: _buildCard(
                            e.value,
                            color,
                            textTheme,
                            spacing,
                            e.key + 2,
                            l10n,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            SizedBox(height: spacing.sectionGap),
          ],

          // 3. Insights
          if (insightsVisible.isNotEmpty) ...[
            _sectionHeader(
              l10n.section_insights,
              LucideIcons.lightbulb,
              color.secondary,
              textTheme,
              spacing,
              staggerIndex: 4,
            ),
            SizedBox(height: spacing.elementGap),
            ...insightsVisible.asMap().entries.map(
                  (e) => Padding(
                    padding: EdgeInsets.only(bottom: spacing.elementGap),
                    child: _buildListCard(
                      e.value,
                      color,
                      textTheme,
                      spacing,
                      e.key + 4,
                      l10n,
                    ),
                  ),
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

  /// Phase 5: Advisory UI Layer - Non-authoritative attention items
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
                  side: BorderSide(
                    color: color.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    // Advisory Header
                    InkWell(
                      onTap: () {
                        setState(() {
                          _showingAdvisoryExpanded = !_showingAdvisoryExpanded;
                        });
                      },
                      borderRadius: BorderRadius.circular(spacing.radiusMedium),
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
                                    'Financial Advisory (Beta)',
                                    style: textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: color.primary,
                                    ),
                                  ),
                                  Text(
                                    '${attentionItems.length} ${attentionItems.length == 1 ? 'item' : 'items'} may need attention',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: color.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              _showingAdvisoryExpanded
                                  ? LucideIcons.chevronUp
                                  : LucideIcons.chevronDown,
                              size: 16,
                              color: color.onSurfaceVariant,
                            ),
                          ],
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
                                item, color, textTheme, spacing,),
                          ),
                      if (attentionItems.length > 3)
                        Padding(
                          padding: EdgeInsets.all(spacing.cardInner),
                          child: Text(
                            '${attentionItems.length - 3} more items...',
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
                      fontWeight: FontWeight.w600,
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
                onPressed: () => _dismissAttentionItem(item.id),
                icon: Icon(
                  LucideIcons.x,
                  size: 16,
                  color: color.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                padding: EdgeInsets.all(spacing.elementGap * 0.5),
                constraints: const BoxConstraints(
                  minWidth: 24,
                  minHeight: 24,
                ),
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
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: accent),
        SizedBox(width: spacing.elementGap),
        Text(
          title,
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: accent,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 200.ms, delay: (50 * staggerIndex).ms).slideX(
          begin: -0.15,
          end: 0,
          duration: 200.ms,
          delay: (50 * staggerIndex).ms,
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
                          borderRadius:
                              BorderRadius.circular(spacing.radiusMedium),
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
                              color:
                                  color.onSurfaceVariant.withValues(alpha: 0.5),
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

  // Medium card with animated background icon
  Widget _buildCard(
    _UtilityDef item,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    int index,
    AppLocalizations l10n,
  ) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: color.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        side: BorderSide(
          color: color.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          // Track usage for adaptive learning
          ref.read(utilityTrackerProvider).trackUtilityOpen(item.id);
          context.push(item.route);
        },
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        child: Stack(
          children: [
            // Large background icon — slow float
            Positioned(
              right: -8,
              bottom: -14,
              child: AnimatedBuilder(
                animation: _bgIconController,
                builder: (_, __) {
                  final t = _bgIconController.value;
                  return Transform.translate(
                    offset: Offset(t * 6 - 3, -t * 5 + 2.5),
                    child: Transform.rotate(
                      angle: (t - 0.5) * 0.12,
                      child: Icon(
                        item.icon,
                        size: 80,
                        color: color.primary.withValues(alpha: 0.08 + t * 0.04),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Content
            Padding(
              padding: EdgeInsets.all(spacing.cardInner),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(spacing.elementGap),
                    decoration: BoxDecoration(
                      color: color.primary.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(spacing.radiusSmall),
                    ),
                    child: Icon(item.icon, size: 20, color: color.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.translate(item.titleKey),
                    style: textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: spacing.elementGapUltraMin),
                  Text(
                    l10n.translate(item.subtitleKey),
                    style: textTheme.bodySmall
                        ?.copyWith(color: color.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 250.ms, delay: (50 * index).ms).slideY(
          begin: 0.3,
          end: 0,
          duration: 250.ms,
          delay: (50 * index).ms,
          curve: Curves.easeOutCubic,
        );
  }

  // List card with animated background icon
  Widget _buildListCard(
    _UtilityDef item,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    int index,
    AppLocalizations l10n,
  ) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: color.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        side: BorderSide(
          color: color.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          // Track usage for adaptive learning
          ref.read(utilityTrackerProvider).trackUtilityOpen(item.id);
          context.push(item.route);
        },
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        child: Stack(
          children: [
            Positioned(
              right: 30,
              top: -6,
              bottom: -6,
              child: AnimatedBuilder(
                animation: _bgIconController,
                builder: (_, __) {
                  final t = _bgIconController.value;
                  return Transform.translate(
                    offset: Offset(-t * 4 + 2, t * 3 - 1.5),
                    child: Icon(
                      item.icon,
                      size: 56,
                      color: color.secondary.withValues(alpha: 0.07 + t * 0.04),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.all(spacing.cardInner),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(spacing.elementGap),
                    decoration: BoxDecoration(
                      color: color.secondary.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(spacing.radiusSmall),
                    ),
                    child: Icon(item.icon, size: 18, color: color.secondary),
                  ),
                  SizedBox(width: spacing.elementGap * 1.5),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.translate(item.titleKey),
                          style: textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          l10n.translate(item.subtitleKey),
                          style: textTheme.bodySmall
                              ?.copyWith(color: color.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    LucideIcons.chevronRight,
                    size: 16,
                    color: color.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 250.ms, delay: (50 * index).ms).slideY(
          begin: 0.3,
          end: 0,
          duration: 250.ms,
          delay: (50 * index).ms,
          curve: Curves.easeOutCubic,
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
