import 'package:mudra_manager/core/tone/tone_provider.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'dart:io' show Platform;

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
import 'package:mudra_manager/core/services/background_task_manager.dart';
import 'package:mudra_manager/core/services/card_interaction_tracker.dart';
import 'package:mudra_manager/core/services/notification_service.dart';
import 'package:mudra_manager/features/dashboard/data/widget_analytics_provider.dart';
import 'package:mudra_manager/core/utils/refresh_helper.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/account/data/reconciliation_service.dart';
import 'package:mudra_manager/core/widgets/dashboard_widget_plugin.dart';
import 'package:mudra_manager/core/widgets/skeleton_loader.dart';
import 'package:mudra_manager/features/budget/data/budget_alert_provider.dart';
import 'package:mudra_manager/features/budget/data/budget_alert_service.dart';
import 'package:mudra_manager/features/dashboard/data/background_health_provider.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/dashboard_data_provider.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/permission_provider.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/widget_preferences_provider.dart';
import 'package:mudra_manager/features/profile/data/help_guide_provider.dart';
import 'package:mudra_manager/features/sms/presentation/screens/sms_activity_screen.dart';
import 'package:mudra_manager/features/transactions/presentation/widgets/quick_add_transaction_sheet.dart';
import 'package:mudra_manager/shared/widgets/ambient_brand_section.dart';
import 'package:mudra_manager/shared/widgets/budget_alert_banner.dart';
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
    // Deferred — gamification check-in and reconciliation don't affect first frame
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      _performDailyCheckIn();
      ref.read(reconciliationServiceProvider).patchUncategorizedTransactions();
      _checkSmsFirstImportCelebration();
    });
  }

  Future<void> _performDailyCheckIn() async {
    if (!mounted) return;

    // Always cancel streak reminder when user opens the app
    await NotificationService.cancelStreakReminder();

    final prefs = SharedPrefsUtil.instance;
    final lastCheckIn = prefs.getLastDailyCheckIn();
    final now = DateTime.now();

    final isDelayed = lastCheckIn != null &&
        now.difference(lastCheckIn).inHours >= 24;

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
    if (!prefs.getSmsFirstImportReady() || prefs.getSmsFirstImportCelebrated()) {
      return;
    }
    prefs.setSmsFirstImportCelebrated();
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Tone.current.borderRadius * 2)),
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

      if (widget.id == 'hero_moment') return child;

      // Record impression
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
            style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
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

    // Gate: show a single cohesive loading state until core data is ready
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

    // Data is ready — check for zero-state (new user, no transactions)
    final data = dashboardAsync.value;
    final txns = data?.transactions.where((t) => !t.isTransfer).toList() ?? [];
    final hasTransactions = txns.isNotEmpty;
    final nudgeDismissed = SharedPrefsUtil.instance.getFirstTxnNudgeDismissed();
    final onboardedAt = SharedPrefsUtil.instance.getOnboardingCompletedAt();
    final isNewUser = onboardedAt != null &&
        DateTime.now().difference(onboardedAt).inHours < 24;

    // Data is ready — stagger only once
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
        }),
        child: CustomScrollView(
          key: const PageStorageKey('dashboard_scroll'),
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (!hasSeenHelp)
              SliverToBoxAdapter(child: RepaintBoundary(child: _HelpBanner())),
            if (!hasSeenHelp && alerts.isNotEmpty)
              SliverToBoxAdapter(
                child: RepaintBoundary(child: _AlertBanner(alerts: alerts)),
              ),
            SliverToBoxAdapter(
              child: RepaintBoundary(child: _AutoImportBanner()),
            ),
            SliverToBoxAdapter(
              child: RepaintBoundary(child: _BackgroundHealthBanner()),
            ),
            // Zero-state: first-transaction nudge for new users
            if (!hasTransactions && !nudgeDismissed)
              SliverToBoxAdapter(
                child: RepaintBoundary(
                  child: _FirstTransactionNudge(
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
                    // Skip fade-in animation after first launch
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
                          AppLocalizations.of(context)!.dashboard_enableCardsDesc,
                          style: textTheme.bodyMedium
                              ?.copyWith(color: color.onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () =>
                              context.push(AppRoutes.dashboardCustomize),
                          icon: const Icon(LucideIcons.plus),
                          label: Text(AppLocalizations.of(context)!.dashboard_enableCards),
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
                        AppLocalizations.of(context)!.dashboard_customizeDashboard,
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
            context.push(AppRoutes.help);
          },
          child: Padding(
            padding: EdgeInsets.all(spacing.cardInner),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(spacing.elementGap),
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
                SizedBox(width: spacing.elementGap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.dashboard_newToApp,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: color.onSurface,
                        ),
                      ),
                      SizedBox(height: spacing.elementGapUltraMin),
                      Text(
                        AppLocalizations.of(context)!.dashboard_tapToExploreHelp,
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
                SizedBox(width: spacing.elementGap),
                GestureDetector(
                  onTap: () async {
                    await SharedPrefsUtil.instance.setHasSeenHelpGuide(true);
                    ref.read(hasSeenHelpGuideProvider.notifier).set(true);
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

class _AutoImportBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!Platform.isAndroid) return const SizedBox.shrink();

    final granted = ref.watch(smsPermissionGrantedProvider);
    if (granted.isLoading) return const SizedBox.shrink();

    final isGranted = granted.value == true;
    final autoImportOn = SharedPrefsUtil.instance.getSmsImportEnabled();
    final spacing = ref.watch(spacingProvider);

    if (isGranted && autoImportOn) {
      final pending = ref.watch(pendingCountProvider).value ?? 0;
      if (pending > 0) {
        return _buildActiveCard(context, ref, spacing, pending);
      }
      return const SizedBox.shrink();
    }

    if (isGranted && !autoImportOn) {
      return _buildPausedPill(context, ref, spacing);
    }

    final dismissed = SharedPrefsUtil.instance.getSmsbannerDismiss();
    if (dismissed) return const SizedBox.shrink();

    return _buildSetupBanner(context, ref, spacing);
  }

  Widget _buildActiveCard(
    BuildContext context,
    WidgetRef ref,
    AppSpacing spacing,
    int pending,
  ) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = color.tertiary;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontal,
        vertical: spacing.cardVertical,
      ),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          context
              .push(pending > 0 ? AppRoutes.smsActivity : AppRoutes.smsImport);
        },
        child: Container(
          padding: EdgeInsets.all(spacing.cardInner),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(spacing.radiusMedium),
            color:
                color.tertiaryContainer.withValues(alpha: isDark ? 0.4 : 0.3),
            border: Border.all(color: accent.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(spacing.radiusSmall),
                ),
                child: Icon(LucideIcons.bellRing, color: accent, size: 18),
              ),
              SizedBox(width: spacing.elementGap + 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$pending pending review',
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: color.onTertiaryContainer,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context)!.dashboard_tapToReviewTxn,
                      style: textTheme.bodySmall?.copyWith(
                        color: color.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(spacing.radiusSmall),
                ),
                child: Text(
                  '$pending',
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color.onTertiaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPausedPill(
    BuildContext context,
    WidgetRef ref,
    AppSpacing spacing,
  ) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = color.tertiary;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontal,
        vertical: spacing.cardVertical,
      ),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          context.push(AppRoutes.smsImport);
        },
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: spacing.cardInner,
            vertical: spacing.elementGap + 2,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(spacing.radiusMedium),
            color:
                color.tertiaryContainer.withValues(alpha: isDark ? 0.4 : 0.3),
            border: Border.all(color: accent.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: spacing.elementGap + 2),
              Text(
                AppLocalizations.of(context)!.dashboard_autoImportPaused,
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color.onTertiaryContainer,
                ),
              ),
              const Spacer(),
              Text(
                AppLocalizations.of(context)!.dashboard_enable,
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color.onSurfaceVariant,
                ),
              ),
              SizedBox(width: spacing.cardVerticalMin),
              Icon(
                LucideIcons.chevronRight,
                size: 14,
                color: color.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSetupBanner(
    BuildContext context,
    WidgetRef ref,
    AppSpacing spacing,
  ) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = color.tertiary;

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
              color.tertiaryContainer.withValues(alpha: isDark ? 0.5 : 0.4),
              color.tertiaryContainer.withValues(alpha: isDark ? 0.2 : 0.1),
            ],
          ),
          border: Border.all(color: accent.withValues(alpha: 0.3)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          onTap: () {
            HapticFeedback.mediumImpact();
            context.push(AppRoutes.smsImport);
          },
          child: Padding(
            padding: EdgeInsets.all(spacing.cardInner),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(spacing.elementGap + 2),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  ),
                  child: Icon(LucideIcons.bellRing, color: accent, size: 20),
                ),
                SizedBox(width: spacing.cardInner),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.dashboard_enableAutoImport,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: color.onSurface,
                        ),
                      ),
                      SizedBox(height: spacing.cardVerticalMin / 2),
                      Text(
                        AppLocalizations.of(context)!.dashboard_autoTrackDesc,
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
                SizedBox(width: spacing.cardVerticalMin),
                GestureDetector(
                  onTap: () {
                    SharedPrefsUtil.instance.setSmsBannerDismiss();
                    ref.invalidate(smsPermissionGrantedProvider);
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




class _BackgroundHealthBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unhealthy = ref.watch(backgroundTaskUnhealthyProvider).value ?? false;
    if (!unhealthy) return const SizedBox.shrink();

    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontal,
        vertical: spacing.cardVertical,
      ),
      child: Container(
        padding: EdgeInsets.all(spacing.cardInner),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          color: color.errorContainer.withValues(alpha: 0.3),
          border: Border.all(color: color.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.triangleAlert, size: 20, color: color.error),
            SizedBox(width: spacing.elementGap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.dashboard_bgSyncIssueTitle,
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color.onErrorContainer,
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context)!.dashboard_bgSyncIssueDesc,
                    style: textTheme.bodySmall?.copyWith(
                      color: color.onErrorContainer.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () async {
                await BackgroundTaskManager.dismissFailureBanner();
                ref.invalidate(backgroundTaskUnhealthyProvider);
              },
              child: Icon(
                LucideIcons.x,
                size: 18,
                color: color.onErrorContainer.withValues(alpha: 0.6),
              ),
            ),
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

class _FirstTransactionNudge extends ConsumerWidget {
  final bool isNewUser;
  final VoidCallback onDismiss;

  const _FirstTransactionNudge({
    required this.isNewUser,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ctxt = AppLocalizations.of(context)!;
    final accent = color.primary;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontal,
        vertical: spacing.cardVertical,
      ),
      child: Column(
        children: [
          // Main nudge card
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => const QuickAddTransactionSheet(),
              );
            },
            child: Container(
              padding: EdgeInsets.all(spacing.cardInner),
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
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(spacing.elementGap),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(spacing.radiusMedium),
                    ),
                    child: Icon(LucideIcons.plus, color: accent, size: 22),
                  ),
                  SizedBox(width: spacing.elementGap),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ctxt.dashboard_addFirstExpense,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: color.onSurface,
                          ),
                        ),
                        SizedBox(height: spacing.elementGapUltraMin),
                        Text(
                          ctxt.dashboard_addFirstExpenseDesc,
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
                  SizedBox(width: spacing.elementGap),
                  GestureDetector(
                    onTap: onDismiss,
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
          // Quick actions grid for new users
          if (isNewUser) ...[
            SizedBox(height: spacing.elementGap),
            Container(
              padding: EdgeInsets.all(spacing.cardInner),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(spacing.radiusMedium),
                color: color.surfaceContainerLow,
                border: Border.all(
                  color: color.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ctxt.dashboard_meanwhile,
                    style: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: spacing.elementGap),
                  Row(
                    children: [
                      _QuickActionChip(
                        icon: LucideIcons.plus,
                        label: ctxt.dashboard_addExpense,
                        onTap: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => const QuickAddTransactionSheet(),
                        ),
                      ),
                      SizedBox(width: spacing.elementGap),
                      _QuickActionChip(
                        icon: LucideIcons.target,
                        label: ctxt.dashboard_setBudget,
                        onTap: () => context.push(AppRoutes.addBudget),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing.elementGap),
                  Row(
                    children: [
                      _QuickActionChip(
                        icon: LucideIcons.piggyBank,
                        label: ctxt.dashboard_createGoal,
                        onTap: () => context.push(AppRoutes.addGoal),
                      ),
                      SizedBox(width: spacing.elementGap),
                      _QuickActionChip(
                        icon: LucideIcons.landmark,
                        label: ctxt.dashboard_addAccount,
                        onTap: () => context.push(AppRoutes.addAccount),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing.elementGap),
                  Text(
                    ctxt.dashboard_testTip,
                    style: textTheme.bodySmall?.copyWith(
                      color: color.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(Tone.current.borderRadius * 0.625),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Tone.current.borderRadius * 0.625),
            color: color.surfaceContainerHighest.withValues(alpha: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color.primary),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
