import 'package:mudra_manager/core/tone/tone_provider.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';

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
import 'package:mudra_manager/features/dashboard/data/widget_analytics_provider.dart';
import 'package:mudra_manager/core/utils/refresh_helper.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/account/data/reconciliation_service.dart';
import 'package:mudra_manager/core/widgets/dashboard_widget_plugin.dart';
import 'package:mudra_manager/core/widgets/skeleton_loader.dart';
import 'package:mudra_manager/features/budget/data/budget_alert_provider.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/dashboard_data_provider.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/widget_preferences_provider.dart';
import 'package:mudra_manager/features/dashboard/presentation/widgets/dashboard_banners.dart';
import 'package:mudra_manager/features/dashboard/presentation/widgets/first_transaction_nudge.dart';
import 'package:mudra_manager/features/profile/data/help_guide_provider.dart';
import 'package:mudra_manager/features/transactions/presentation/widgets/quick_add_transaction_sheet.dart';
import 'package:mudra_manager/shared/widgets/ambient_brand_section.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/features/dashboard/presentation/widgets/sms_success_celebration_sheet.dart';
import 'package:mudra_manager/features/gamification/presentation/widgets/streak_saved_celebration_sheet.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      _performDailyCheckIn();
      ref.read(reconciliationServiceProvider).patchUncategorizedTransactions();
      _checkSmsFirstImportCelebration();
    });
  }

  Future<void> _performDailyCheckIn() async {
    if (!mounted) return;

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
        final streakCount = int.tryParse(
          RegExp(r'Day (\d+)').firstMatch(result)?.group(1) ?? '',
        );
        if (streakCount != null && streakCount > 1) {
          if (isDelayed && mounted) {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              builder: (_) => StreakSavedCelebrationSheet(
                streakCount: streakCount,
              ),
            );
          } else {
            SnackbarService.success(
              '🔥 ${BuddyMessages.streakMessage(streakCount)}',
            );
          }
        } else {
          SnackbarService.success('🔥 $result');
        }
        log.i('✅ Daily check-in completed');
      }
    }
  }

  void _checkSmsFirstImportCelebration() {
    final prefs = SharedPrefsUtil.instance;
    if (!prefs.getSmsFirstImportReady() ||
        prefs.getSmsFirstImportCelebrated()) {
      return;
    }
    prefs.setSmsFirstImportCelebrated();
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Tone.current.borderRadius * 2),
        ),
      ),
      builder: (_) => const SmsSuccessCelebrationSheet(),
    );
  }

  void _revealNext(int total) {
    if (_allRevealed || !mounted) return;
    Future.delayed(const Duration(milliseconds: 60), () {
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
    try {
      final child = widget.build(context, ref);
      ref.read(widgetAnalyticsServiceProvider).recordImpression(widget.id);

      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          CardInteractionTracker.recordTap(widget.id);
          ref.read(widgetAnalyticsServiceProvider).recordClick(widget.id);
          widget.onTap(context, ref);
        },
        child: AbsorbPointer(
          absorbing: false,
          child: child,
        ),
      );
    } catch (e, stack) {
      log.e('Dashboard widget "${widget.id}" crashed', e, stack);
      return Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Widget failed to load',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardDataProvider);
    final widgets = ref.watch(orderedDashboardWidgetsProvider);
    final alerts = ref.watch(budgetAlertsProvider);
    final hasSeenHelp = ref.watch(hasSeenHelpGuideProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);

    if (!dashboardAsync.hasValue) {
      return Scaffold(
        body: CustomScrollView(
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
        ),
      );
    }

    final data = dashboardAsync.value;
    final txns = data?.transactions.where((t) => !t.isTransfer).toList() ?? [];
    final hasTransactions = txns.isNotEmpty;
    final nudgeDismissed = SharedPrefsUtil.instance.getFirstTxnNudgeDismissed();
    final onboardedAt = SharedPrefsUtil.instance.getOnboardingCompletedAt();
    final isNewUser = onboardedAt != null &&
        DateTime.now().difference(onboardedAt).inHours < 24;

    if (!_allRevealed && _revealedCount == 0 && widgets.isNotEmpty) {
      _revealNext(widgets.length);
    }

    final visibleCount = _allRevealed ? widgets.length : _revealedCount;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => const QuickAddTransactionSheet(compact: true),
          );
        },
        child: const Icon(LucideIcons.plus),
      ),
      body: RefreshIndicator(
        onRefresh: () => RefreshHelper.withMinDuration(() async {
          ref.invalidate(dashboardDataProvider);
          for (final widget in widgets) {
            await widget.refresh(ref);
          }
          if (mounted) {
            SnackbarService.success('✓');
          }
        }),
        child: CustomScrollView(
          key: const PageStorageKey('dashboard_scroll'),
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: RepaintBoundary(
                child: PrioritizedBanner(
                  hasSeenHelp: hasSeenHelp,
                  alerts: alerts,
                ),
              ),
            ),
            if (!hasTransactions && !nudgeDismissed)
              SliverToBoxAdapter(
                child: RepaintBoundary(
                  child: FirstTransactionNudge(
                    isNewUser: isNewUser,
                    onDismiss: () {
                      SharedPrefsUtil.instance.setFirstTxnNudgeDismissed();
                      ref.invalidate(dashboardDataProvider);
                    },
                  ),
                ),
              ),
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
                    final child = _WidgetErrorBoundary(
                      id: widget.id,
                      child: _buildTrackedWidget(context, ref, widget),
                    );
                    if (_hasAnimatedOnce) return child;
                    return child
                        .animate()
                        .fadeIn(duration: 300.ms, curve: Curves.easeOut)
                        .slideY(
                          begin: 0.1,
                          end: 0,
                          duration: 400.ms,
                          curve: Curves.easeOutBack,
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
                          BuddyMessages.noData,
                          style: textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context)!
                              .dashboard_enableCardsDesc,
                          style: textTheme.bodyMedium
                              ?.copyWith(color: color.onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () =>
                              context.push(AppRoutes.dashboardCustomize),
                          icon: const Icon(LucideIcons.plus),
                          label: Text(AppLocalizations.of(context)!
                              .dashboard_enableCards,),
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
                      onPressed: () =>
                          context.push(AppRoutes.dashboardCustomize),
                      icon: Icon(
                        LucideIcons.settings2,
                        size: 16,
                        color: color.onSurfaceVariant,
                      ),
                      label: Text(
                        AppLocalizations.of(context)!
                            .dashboard_customizeDashboard,
                        style: textTheme.labelMedium
                            ?.copyWith(color: color.onSurfaceVariant),
                      ),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: AmbientBrandSection(showSignature: false),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WidgetErrorBoundary extends StatefulWidget {
  final String id;
  final Widget child;

  const _WidgetErrorBoundary({required this.id, required this.child});

  @override
  State<_WidgetErrorBoundary> createState() => _WidgetErrorBoundaryState();
}

class _WidgetErrorBoundaryState extends State<_WidgetErrorBoundary> {
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    if (_hasError) return const SizedBox.shrink();
    return widget.child;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _hasError = false;
  }
}
