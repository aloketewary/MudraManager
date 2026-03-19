import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/services/card_interaction_tracker.dart';
import 'package:mudra_manager/core/services/notification_service.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/core/widgets/dashboard_widget_plugin.dart';
import 'package:mudra_manager/features/budget/data/budget_alert_provider.dart';
import 'package:mudra_manager/features/budget/data/budget_alert_service.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/dashboard_data_provider.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/widget_preferences_provider.dart';
import 'package:mudra_manager/features/profile/data/help_guide_provider.dart';
import 'package:mudra_manager/shared/widgets/budget_alert_banner.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';

class DashboardHome extends ConsumerStatefulWidget {
  const DashboardHome({super.key});

  @override
  ConsumerState<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends ConsumerState<DashboardHome> {
  final AppLog log = AppLog(getLogger(), 'DashBoardHome');
  static bool _hasAnimatedOnce = false;
  int _revealedCount = 0;
  bool _allRevealed = _hasAnimatedOnce;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), _performDailyCheckIn);
  }

  Future<void> _performDailyCheckIn() async {
    if (!mounted) return;

    // Always cancel streak reminder when user opens the app
    await NotificationService.cancelStreakReminder();

    final prefs = SharedPrefsUtil.instance;
    final lastCheckIn = prefs.getLastDailyCheckIn();
    final now = DateTime.now();

    if (lastCheckIn == null ||
        !(lastCheckIn.year == now.year &&
            lastCheckIn.month == now.month &&
            lastCheckIn.day == now.day)) {
      final service = await ref.read(gamificationServiceInitProvider.future);
      final result = await service.updateDailyCheckIn();
      if (result != null && mounted) {
        await prefs.setLastDailyCheckIn(now);
        SnackbarService.success('🔥 $result');
        log.i('✅ Daily check-in completed');
      }
    }
  }

  void _revealNext(int total) {
    if (_allRevealed || !mounted) return;
    Future.delayed(const Duration(milliseconds: 80), () {
      if (!mounted) return;
      setState(() {
        _revealedCount++;
        if (_revealedCount >= total) {
          _allRevealed = true;
          _hasAnimatedOnce = true;
        }
      });
    });
  }

  Widget _buildTrackedWidget(
    BuildContext context,
    WidgetRef ref,
    DashboardWidgetPlugin widget,
  ) {
    // Hero moment is auto-dismiss, not tappable for navigation
    if (widget.id == 'hero_moment') return widget.build(context, ref);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        CardInteractionTracker.recordTap(widget.id);
        widget.onTap(context, ref);
      },
      child: AbsorbPointer(
        // Let the card's own InkWell handle visual feedback
        absorbing: false,
        child: widget.build(context, ref),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardDataProvider);
    final widgets = ref.watch(orderedDashboardWidgetsProvider);
    final alerts = ref.watch(budgetAlertsProvider);
    final hasSeenHelp = ref.watch(hasSeenHelpGuideProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Gate: show a single cohesive loading state until core data is ready
    if (!dashboardAsync.hasValue) {
      return const Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  SizedBox(height: 8),
                  AccountCardSkeleton(),
                  SizedBox(height: 8),
                  BudgetCardSkeleton(),
                  SizedBox(height: 8),
                  DashboardCardSkeleton(),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Data is ready — stagger only once
    if (!_allRevealed && _revealedCount == 0 && widgets.isNotEmpty) {
      _revealNext(widgets.length);
    }

    final visibleCount = _allRevealed ? widgets.length : _revealedCount;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardDataProvider);
          for (final widget in widgets) {
            await widget.refresh(ref);
          }
        },
        child: CustomScrollView(
          key: const PageStorageKey('dashboard_scroll'),
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (!hasSeenHelp) SliverToBoxAdapter(child: _HelpBanner()),
            if (!hasSeenHelp && alerts.isNotEmpty)
              SliverToBoxAdapter(child: _AlertBanner(alerts: alerts)),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final widget = widgets[index];
                  if (index < visibleCount) {
                    if (index == visibleCount - 1 && !_allRevealed) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _revealNext(widgets.length);
                      });
                    }
                    return _StaggeredEntry(
                      key: ValueKey(widget.id),
                      child: _buildTrackedWidget(context, ref, widget),
                    );
                  }
                  return const SizedBox.shrink();
                },
                childCount: widgets.length,
              ),
            ),
            if (widgets.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.layoutDashboard,
                          size: 64,
                          color: color.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No cards enabled',
                          style: textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Enable dashboard cards to see your financial overview',
                          style: textTheme.bodyMedium
                              ?.copyWith(color: color.onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () => context.push('/dashboard-customize'),
                          icon: const Icon(LucideIcons.plus),
                          label: const Text('Enable Cards'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (widgets.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TextButton.icon(
                      onPressed: () => context.push('/dashboard-customize'),
                      icon: Icon(
                        LucideIcons.settings2,
                        size: 16,
                        color: color.onSurfaceVariant,
                      ),
                      label: Text(
                        'Customize Dashboard',
                        style: textTheme.labelMedium
                            ?.copyWith(color: color.onSurfaceVariant),
                      ),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Fade-in entry for each staggered widget
class _StaggeredEntry extends StatefulWidget {
  final Widget child;
  const _StaggeredEntry({super.key, required this.child});

  @override
  State<_StaggeredEntry> createState() => _StaggeredEntryState();
}

class _StaggeredEntryState extends State<_StaggeredEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

class _AlertBanner extends ConsumerWidget {
  final List<BudgetAlert> alerts;

  const _AlertBanner({required this.alerts});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        BudgetAlertBanner(
          alerts: alerts,
          onDismiss: () {
            ref.read(budgetAlertsProvider.notifier).dismissAlert(alerts.first);
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _HelpBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = color.primary;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontal,
        vertical: spacing.cardVertical,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent.withValues(alpha: isDark ? 0.2 : 0.12),
              accent.withValues(alpha: isDark ? 0.08 : 0.04),
            ],
          ),
          border: Border.all(color: accent.withValues(alpha: 0.3)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          onTap: () {
            HapticFeedback.mediumImpact();
            context.push('/help');
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  ),
                  child: Icon(
                    LucideIcons.badgeQuestionMark,
                    color: accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'New to Mudra Manager?',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: color.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tap to explore the help guide',
                        style: textTheme.bodySmall?.copyWith(
                          color: color.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: color.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () async {
                    await SharedPrefsUtil.instance.setHasSeenHelpGuide(true);
                    ref.read(hasSeenHelpGuideProvider.notifier).state = true;
                  },
                  child: Icon(
                    LucideIcons.x,
                    size: 18,
                    color: color.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
