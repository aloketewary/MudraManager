import 'package:mudra_manager/shared/widgets/no_data_found.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:mudra_manager/features/dashboard/data/priority_alert_provider.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UtilityScreen extends ConsumerStatefulWidget {
  const UtilityScreen({super.key});

  @override
  ConsumerState<UtilityScreen> createState() => UtilityScreenState();
}

class UtilityScreenState extends ConsumerState<UtilityScreen> {
  List<String> _hiddenUtilities = [];
  bool _isLoading = true;

  // Grouped utility definitions
  static const _activeMoney = [
    _UtilityDef(
      id: 'recurring',
      title: 'Bills',
      subtitle: 'Upcoming & recurring',
      icon: LucideIcons.repeat,
      route: AppRoutes.recurringTransactions,
      section: _Section.active,
    ),
    _UtilityDef(
      id: 'trips',
      title: 'Groups',
      subtitle: 'Trips & splits',
      icon: LucideIcons.users,
      route: AppRoutes.trips,
      section: _Section.active,
    ),
  ];

  static const _planning = [
    _UtilityDef(
      id: 'budgets',
      title: 'Budgets',
      subtitle: 'Spending limits',
      icon: LucideIcons.chartPie,
      route: AppRoutes.budgetDashboard,
      section: _Section.planning,
    ),
    _UtilityDef(
      id: 'goals',
      title: 'Goals',
      subtitle: 'Savings progress',
      icon: LucideIcons.target,
      route: AppRoutes.goalScreen,
      section: _Section.planning,
    ),
  ];

  static const _insights = [
    _UtilityDef(
      id: 'monthly_comparison',
      title: 'Monthly Comparison',
      subtitle: 'Current vs last month',
      icon: LucideIcons.arrowLeftRight,
      route: AppRoutes.monthlyComparison,
      section: _Section.insights,
    ),
  ];

  List<_UtilityDef> get _allUtilities =>
      [..._activeMoney, ..._planning, ..._insights];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final hidden = prefs.getStringList('hidden_utilities') ?? [];
    if (mounted) {
      setState(() {
        _hiddenUtilities = hidden;
        _isLoading = false;
      });
    }
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('hidden_utilities', _hiddenUtilities);
  }

  bool _isVisible(String id) => !_hiddenUtilities.contains(id);

  void showCustomizeSheet() => _showCustomizeSheet();

  void _showCustomizeSheet() {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.read(spacingProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: color.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                        Icon(LucideIcons.settings2,
                            color: color.primary, size: 22),
                        SizedBox(width: spacing.elementGap),
                        Text(
                          'Customize Utilities',
                          style: textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setModalState(() => _hiddenUtilities = []);
                            setState(() {});
                            _savePreferences();
                            SnackbarService.info(BuddyMessages.settingsSaved);
                          },
                          child: const Text('Reset'),
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
                          u.title,
                          style: textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          u.subtitle,
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

    final activeVisible =
        _activeMoney.where((u) => _isVisible(u.id)).toList();
    final planningVisible =
        _planning.where((u) => _isVisible(u.id)).toList();
    final insightsVisible =
        _insights.where((u) => _isVisible(u.id)).toList();

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
          label: const Text('Add Utilities'),
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontal,
        vertical: spacing.cardVertical,
      ),
      children: [
        // Priority alert
        _buildPriorityAlert(color, textTheme, spacing),

        // 1. Active Money
        if (activeVisible.isNotEmpty) ...[
          _sectionHeader(
            'Active Money',
            LucideIcons.zap,
            color.error,
            textTheme,
            spacing,
          ),
          SizedBox(height: spacing.elementGap),
          Row(
            children: activeVisible
                .map(
                  (u) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: u != activeVisible.last
                            ? spacing.elementGap
                            : 0,
                      ),
                      child: _buildCard(u, color, textTheme, spacing),
                    ),
                  ),
                )
                .toList(),
          ),
          SizedBox(height: spacing.sectionGap * 1.5),
        ],

        // 2. Planning
        if (planningVisible.isNotEmpty) ...[
          _sectionHeader(
            'Planning',
            LucideIcons.compass,
            color.primary,
            textTheme,
            spacing,
          ),
          SizedBox(height: spacing.elementGap),
          Row(
            children: planningVisible
                .map(
                  (u) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: u != planningVisible.last
                            ? spacing.elementGap
                            : 0,
                      ),
                      child: _buildCard(u, color, textTheme, spacing),
                    ),
                  ),
                )
                .toList(),
          ),
          SizedBox(height: spacing.sectionGap * 1.5),
        ],

        // 3. Insights
        if (insightsVisible.isNotEmpty) ...[
          _sectionHeader(
            'Insights',
            LucideIcons.lightbulb,
            color.secondary,
            textTheme,
            spacing,
          ),
          SizedBox(height: spacing.elementGap),
          ...insightsVisible.map(
            (u) => Padding(
              padding: EdgeInsets.only(bottom: spacing.elementGap),
              child: _buildListCard(u, color, textTheme, spacing),
            ),
          ),
        ],

        SizedBox(
          height: MediaQuery.of(context).padding.bottom +
              kBottomNavigationBarHeight +
              16,
        ),
      ],
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color accent,
      TextTheme textTheme, AppSpacing spacing) {
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
    );
  }

  Widget _buildPriorityAlert(
      ColorScheme color, TextTheme textTheme, AppSpacing spacing) {
    return Consumer(
      builder: (context, ref, _) {
        final alertAsync = ref.watch(priorityAlertProvider);
        return alertAsync.maybeWhen(
          data: (alert) {
            if (alert == null) return const SizedBox.shrink();

            final alertColor = alert.type == AlertType.urgent
                ? color.error
                : alert.type == AlertType.warning
                    ? color.tertiary
                    : color.primary;

            return Padding(
              padding: EdgeInsets.only(bottom: spacing.sectionGap),
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
                        color: color.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          orElse: () => const SizedBox.shrink(),
        );
      },
    );
  }

  // Medium card — used for Active Money and Planning sections
  Widget _buildCard(_UtilityDef item, ColorScheme color, TextTheme textTheme,
      AppSpacing spacing) {
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
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          context.push(item.route);
        },
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        child: Padding(
          padding: EdgeInsets.all(spacing.cardInner),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(item.icon, size: 24, color: color.primary),
              SizedBox(height: spacing.elementGap * 1.5),
              Text(
                item.title,
                style: textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: spacing.elementGapMin),
              Text(
                item.subtitle,
                style: textTheme.bodySmall
                    ?.copyWith(color: color.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // List card — used for Insights section (smaller, horizontal)
  Widget _buildListCard(_UtilityDef item, ColorScheme color,
      TextTheme textTheme, AppSpacing spacing) {
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
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          context.push(item.route);
        },
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        child: Padding(
          padding: EdgeInsets.all(spacing.cardInner),
          child: Row(
            children: [
              Icon(item.icon, size: 22, color: color.secondary),
              SizedBox(width: spacing.elementGap * 1.5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      item.subtitle,
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
      ),
    );
  }
}

class _UtilityDef {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final _Section section;

  const _UtilityDef({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    required this.section,
  });
}

enum _Section { active, planning, insights }
