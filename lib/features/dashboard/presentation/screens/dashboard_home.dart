import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mudra_manager/core/constants/dashboard_constants.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/core/services/card_interaction_tracker.dart';
import 'package:mudra_manager/core/services/notification_service.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:mudra_manager/core/utils/refresh_helper.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/core/widgets/dashboard_widget_plugin.dart';
import 'package:mudra_manager/core/widgets/skeleton_loader.dart';
import 'package:mudra_manager/features/account/data/reconciliation_service.dart';
import 'package:mudra_manager/features/budget/data/budget_alert_provider.dart';
import 'package:mudra_manager/features/budget/data/budget_alert_service.dart';
import 'package:mudra_manager/features/dashboard/data/today_card_analytics.dart';
import 'package:mudra_manager/features/dashboard/data/widget_analytics_provider.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/dashboard_data_provider.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/widget_preferences_provider.dart';
import 'package:mudra_manager/features/dashboard/presentation/widgets/dashboard_banners.dart';
import 'package:mudra_manager/features/dashboard/presentation/widgets/first_transaction_nudge.dart';
import 'package:mudra_manager/features/dashboard/presentation/widgets/sms_success_celebration_sheet.dart';
import 'package:mudra_manager/features/gamification/presentation/widgets/streak_saved_celebration_sheet.dart';
import 'package:mudra_manager/features/profile/data/help_guide_provider.dart';
import 'package:mudra_manager/features/transactions/presentation/widgets/quick_add_transaction_sheet.dart';
import 'package:mudra_manager/shared/widgets/ambient_brand_section.dart';

// ─────────────────────────────────────────────────────────────
// ENTERPRISE STATE MANAGEMENT — Animation State (StateNotifier)
// ─────────────────────────────────────────────────────────────

class DashboardAnimationState {
  final int revealedCount;
  final bool allRevealed;
  final bool hasAnimatedOnce;

  const DashboardAnimationState({
    this.revealedCount = 0,
    this.allRevealed = false, 
    this.hasAnimatedOnce = false,
  });

  DashboardAnimationState copyWith({
    int? revealedCount,
    bool? allRevealed,
    bool? hasAnimatedOnce,
  }) {
    return DashboardAnimationState(
      revealedCount: revealedCount ?? this.revealedCount,
      allRevealed: allRevealed ?? this.allRevealed,
      hasAnimatedOnce: hasAnimatedOnce ?? this.hasAnimatedOnce,
    );
  }

  DashboardAnimationState revealNext(int total) {
    final newCount = revealedCount + 1;
    return copyWith(
      revealedCount: newCount,
      allRevealed: newCount >= total,
      hasAnimatedOnce: newCount >= total,
    );
  }
}

final dashboardAnimationProvider =
    NotifierProvider<DashboardAnimationNotifier, DashboardAnimationState>(
  DashboardAnimationNotifier.new,
);

class DashboardAnimationNotifier extends Notifier<DashboardAnimationState> {
  @override
  DashboardAnimationState build() => const DashboardAnimationState();

  void revealNext(int total) {
    if (state.allRevealed) return;
    state = state.revealNext(total);
  }

  void reset() {
    state = const DashboardAnimationState();
  }
}

// ─────────────────────────────────────────────────────────────
// MAIN WIDGET — ConsumerWidget Pattern
// ─────────────────────────────────────────────────────────────

class DashboardHome extends ConsumerWidget {
  const DashboardHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const _DashboardHomeBody();
  }
}

class _DashboardHomeBody extends ConsumerStatefulWidget {
  const _DashboardHomeBody();

  @override
  ConsumerState<_DashboardHomeBody> createState() => _DashboardHomeBodyState();
}

class _DashboardHomeBodyState extends ConsumerState<_DashboardHomeBody> {
  final AppLog log = AppLog(getLogger(), 'DashboardHome');

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
  }

  Future<void> _initializeDashboard() async {
    TodayCardAnalytics.recordSessionStart();

    Future.delayed(DashboardConstants.initDelayDuration, () async {
      if (!mounted) return;

      // Check budget alerts on init
      try {
        final alertService = ref.read(budgetAlertServiceProvider);
        final budgetAlerts = await alertService.checkBudgetsOnDashboardLoad();
        if (budgetAlerts.isNotEmpty && mounted) {
          ref.read(budgetAlertsNotifierProvider.notifier).addAlerts(budgetAlerts);
        }
      } catch (e) {
        // Ignore budget check errors
      }

      await _performDailyCheckIn();
      if (!mounted) return;

      ref.read(reconciliationServiceProvider).patchUncategorizedTransactions();
      if (!mounted) return;

      _checkSmsFirstImportCelebration();
    });
  }

  Future<void> _performDailyCheckIn() async {
    try {
      final spacing = ref.read(spacingProvider);
      await NotificationService.cancelStreakReminder();

      final prefs = SharedPrefsUtil.instance;
      final lastCheckIn = prefs.getLastDailyCheckIn();
      final now = DateTime.now();

      final isDelayed =
          lastCheckIn != null && now.difference(lastCheckIn).inHours >= 24;

      if (lastCheckIn == null ||
          !(lastCheckIn.year == now.year &&
              lastCheckIn.month == now.month &&
              lastCheckIn.day == now.day)) {
        final service = await ref.read(gamificationServiceInitProvider.future);
        final result = await service.updateDailyCheckIn();

        if (result != null && mounted) {
          await prefs.setLastDailyCheckIn(now);
          final streakCount = result.streakCount;

          if (streakCount > 1) {
            if (isDelayed && mounted) {
              _showStreakCelebration(streakCount);
            } else {
              SnackbarService.success(
                '🔥 ${BuddyMessages.streakMessage(streakCount)}', spacing,
              );
            }
          } else {
            SnackbarService.success('🔥 Day $streakCount streak! +${result.xpEarned} XP', spacing);
          }
          log.i('Daily check-in completed successfully');
        }
      }
    } catch (e, stack) {
      log.e('Daily check-in failed', e, stack);
    }
  }

  void _showStreakCelebration(int streakCount) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StreakSavedCelebrationSheet(streakCount: streakCount),
    );
  }

  void _checkSmsFirstImportCelebration() {
    try {
      final spacing = ref.read(spacingProvider);
      final prefs = SharedPrefsUtil.instance;

      if (!prefs.getSmsFirstImportReady() || prefs.getSmsFirstImportCelebrated()) {
        return;
      }
      prefs.setSmsFirstImportCelebrated();

      showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(spacing.radiusSmall * 2),
        ),
        builder: (_) => const SmsSuccessCelebrationSheet(),
      );
    } catch (e, stack) {
      log.e('Sms celebration check failed', e, stack);
    }
  }

  bool _isNewUser() {
    final onboardedAt = SharedPrefsUtil.instance.getOnboardingCompletedAt();
    return onboardedAt != null &&
        DateTime.now().difference(onboardedAt).inHours < DashboardConstants.newUserHoursThreshold;
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final dashboardAsync = ref.watch(dashboardDataProvider);
    final widgets = ref.watch(orderedDashboardWidgetsProvider);
    final alerts = ref.watch(budgetAlertsNotifierProvider);
    final hasSeenHelp = ref.watch(hasSeenHelpGuideProvider);
    final animationState = ref.watch(dashboardAnimationProvider);
    final ctxt = AppLocalizations.of(context)!;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showQuickAddSheet,
        tooltip: ctxt.quickAdd_title,
        child: const Icon(LucideIcons.plus),
      ),
      body: dashboardAsync.when(
        loading: () => const _DashboardLoading(),
        error: (e, _) => _buildErrorState(e, ctxt),
        data: (data) {
          // Pre-compute expensive operations once
          final txns = data.transactions.where((t) => !t.isTransfer).toList();
          final hasTransactions = txns.isNotEmpty;

          return LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth =
                  constraints.maxWidth > DashboardConstants.maxWidth
                      ? DashboardConstants.maxWidth
                      : double.infinity;
              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: _DashboardContent(
                    reduceMotion: reduceMotion,
                    data: data,
                    widgets: widgets,
                    alerts: alerts,
                    hasSeenHelp: hasSeenHelp,
                    animationState: animationState,
                    pendingSmsCount: data.pendingSmsCount,
                    hasTransactions: hasTransactions,
                    nudgeDismissed: SharedPrefsUtil.instance.getFirstTxnNudgeDismissed(),
                    isNewUser: _isNewUser(),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showQuickAddSheet() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const QuickAddTransactionSheet(compact: true),
    );
  }

  Widget _buildErrorState(Object error, AppLocalizations ctxt) {
    final spacing = ref.read(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(spacing.cardInner),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.alertCircle, size: 48, color: color.error),
            SizedBox(height: spacing.sectionGap),
            Text(ctxt.common_error, style: textTheme.titleMedium),
            SizedBox(height: spacing.elementGap),
            FilledButton.icon(
              onPressed: () => ref.invalidate(dashboardDataProvider),
              icon: const Icon(LucideIcons.rotateCcw),
              label: Text(ctxt.common_retry),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CONTENT WIDGET — Stateless, Receives All State as Parameters
// ─────────────────────────────────────────────────────────────

class _DashboardContent extends ConsumerWidget {
  final bool reduceMotion;
  final DashboardData data;
  final List<DashboardWidgetPlugin> widgets;
  final List<BudgetAlert> alerts;
  final bool hasSeenHelp;
  final DashboardAnimationState animationState;
  final int pendingSmsCount;

  // Pre-computed values passed as constructor params
  final bool hasTransactions;
  final bool nudgeDismissed;
  final bool isNewUser;

  const _DashboardContent({
    required this.reduceMotion,
    required this.data,
    required this.widgets,
    required this.alerts,
    required this.hasSeenHelp,
    required this.animationState,
    required this.pendingSmsCount,
    required this.hasTransactions,
    required this.nudgeDismissed,
    required this.isNewUser,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final ctxt = AppLocalizations.of(context)!;
    final animationNotifier = ref.read(dashboardAnimationProvider.notifier);

    if (!animationState.allRevealed &&
        animationState.revealedCount == 0 &&
        widgets.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        animationNotifier.revealNext(widgets.length);
      });
    }

    final visibleCount =
        animationState.allRevealed ? widgets.length : animationState.revealedCount;
    final duration = reduceMotion ? Duration.zero : DashboardConstants.animationDuration;
    final hasAnimatedOnce = animationState.hasAnimatedOnce;

    return RefreshIndicator(
      onRefresh: () => RefreshHelper.withMinDuration(() async {
        ref.invalidate(dashboardDataProvider);
        for (final widget in widgets) {
          await widget.refresh(ref);
        }
      }),
      child: CustomScrollView(
        key: const PageStorageKey('dashboard_scroll'),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: PrioritizedBanner(
              hasSeenHelp: hasSeenHelp,
              alerts: alerts,
              pendingSmsCount: pendingSmsCount,
            ),
          ),
          if (!hasTransactions && !nudgeDismissed)
            SliverToBoxAdapter(
              child: FirstTransactionNudge(
                isNewUser: isNewUser,
                onDismiss: () {
                  SharedPrefsUtil.instance.setFirstTxnNudgeDismissed();
                  ref.invalidate(dashboardDataProvider);
                },
              ),
            ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final widget = widgets[index];
                if (index < visibleCount) {
                  if (index == visibleCount - 1 && !animationState.allRevealed) {
                    Future.delayed(DashboardConstants.revealDelay, () {
                      animationNotifier.revealNext(widgets.length);
                    });
                  }

                  final child = _buildTrackedWidget(context, ref, widget);

                  if (hasAnimatedOnce) return child;

                  return child
                      .animate()
                      .fadeIn(duration: duration, curve: Curves.easeOut)
                      .slideY(
                        begin: 0.1,
                        end: 0,
                        duration: DashboardConstants.slideDuration,
                        curve: Curves.easeOutBack,
                      );
                }
                return const SizedBox.shrink();
              },
              childCount: widgets.length,
            ),
          ),
          if (widgets.isEmpty) _buildEmptyState(context, color, textTheme, spacing, ctxt),
          if (widgets.isNotEmpty) _buildFooter(context, color, textTheme, spacing, ctxt),
        ],
      ),
    );
  }

  Widget _buildTrackedWidget(
    BuildContext context,
    WidgetRef ref,
    DashboardWidgetPlugin widget,
  ) {
    final child = widget.build(context, ref);
    ref.read(widgetAnalyticsServiceProvider).recordImpression(widget.id);

    return Semantics(
      button: true,
      label: '${widget.title} card',
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          CardInteractionTracker.recordTap(widget.id);
          ref.read(widgetAnalyticsServiceProvider).recordClick(widget.id);
          widget.onTap(context, ref);
        },
        child: RepaintBoundary(
          child: child,
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(spacing.cardInner),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.layoutDashboard,
                size: 64,
                color: color.onSurfaceVariant,
              ),
              SizedBox(height: spacing.sectionGap),
              Text(
                BuddyMessages.noData,
                style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: spacing.elementGap),
              Text(
                ctxt.dashboard_enableCardsDesc,
                style: textTheme.bodyMedium?.copyWith(color: color.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: spacing.sectionGap),
              FilledButton.icon(
                onPressed: () => context.push(AppRoutes.dashboardCustomize),
                icon: const Icon(LucideIcons.plus),
                label: Text(ctxt.dashboard_enableCards),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(
    BuildContext context,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          Center(
            child: Padding(
              padding: EdgeInsets.only(top: spacing.elementGap),
              child: TextButton.icon(
                onPressed: () => context.push(AppRoutes.dashboardCustomize),
                icon: Icon(
                  LucideIcons.settings2,
                  size: 16,
                  color: color.onSurfaceVariant,
                ),
                label: Text(
                  ctxt.dashboard_customizeDashboard,
                  style: textTheme.labelMedium?.copyWith(color: color.onSurfaceVariant),
                ),
              ),
            ),
          ),
          const AmbientBrandSection(showSignature: false),
          const SizedBox(height: 120),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// LOADING STATE — Pure Stateless Widget
// ─────────────────────────────────────────────────────────────

class _DashboardLoading extends ConsumerWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              SizedBox(height: spacing.elementGap),
              const AccountCardSkeleton(),
              const QuickActionsSkeleton(),
              const CashFlowSkeleton(),
              const BudgetCardSkeleton(),
              const DashboardCardSkeleton(),
            ],
          ),
        ),
      ],
    );
  }
}
