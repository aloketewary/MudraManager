import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/engine/dashboard_state_provider.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/logic/attention/dashboard_attention_provider.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/core/services/card_interaction_tracker.dart';
import 'package:mudra_manager/core/services/notification_service.dart';
import 'package:mudra_manager/core/state/app_screen_state.dart';
import 'package:mudra_manager/core/state/dashboard_state.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:mudra_manager/core/utils/refresh_helper.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/core/widgets/dashboard_widget_plugin.dart';
import 'package:mudra_manager/core/widgets/skeleton_loader.dart';
import 'package:mudra_manager/features/account/data/reconciliation_service.dart';
import 'package:mudra_manager/features/dashboard/data/widget_analytics_provider.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/widget_preferences_provider.dart';
import 'package:mudra_manager/features/dashboard/presentation/widgets/sms_success_celebration_sheet.dart';
import 'package:mudra_manager/features/dashboard/presentation/widgets/staggered_widget_list.dart';
import 'package:mudra_manager/features/gamification/presentation/widgets/streak_saved_celebration_sheet.dart';
import 'package:mudra_manager/features/transactions/presentation/widgets/quick_add_transaction_sheet.dart';
import 'package:mudra_manager/shared/templates/templates.dart';
import 'package:mudra_manager/shared/widgets/ambient_brand_section.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';

class DashboardHome extends ConsumerStatefulWidget {
  const DashboardHome({super.key});

  @override
  ConsumerState<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends ConsumerState<DashboardHome> {
  static bool _hasAnimatedOnce = false;

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
              builder: (_) =>
                  StreakSavedCelebrationSheet(streakCount: streakCount),
            );
          } else {
            SnackbarService.success(
              '🔥 ${BuddyMessages.streakMessage(streakCount)}',
            );
          }
        } else {
          SnackbarService.success('🔥 $result');
        }
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const SmsSuccessCelebrationSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardStateV2Provider);
    final widgets = ref.watch(orderedDashboardWidgetsProvider);
    final attention = ref.watch(dashboardAttentionProvider);
    ref.watch(spacingProvider);
    final l10n = AppLocalizations.of(context)!;

    if (dashboardState == null) {
      return const _DashboardSkeleton();
    }

    final screenState = AppScreenState<DashboardState>(
      gate: dashboardState.gate,
      data: dashboardState,
      alert: attention,
      actions: ScreenActions.build(
        appBar: [
          ScreenAction(
            id: 'customize',
            label: l10n.dashboard_customizeDashboard,
            icon: LucideIcons.settings2,
            onTap: () => context.push(AppRoutes.dashboardCustomize),
          ),
          ScreenAction(
            id: 'refresh',
            label: 'Refresh',
            icon: LucideIcons.refreshCw,
            onTap: () => _handleRefresh(ref, widgets),
          ),
        ],
        fab: ScreenAction(
          id: 'quick_add',
          label: l10n.common_addLabel,
          icon: LucideIcons.plus,
          onTap: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => const QuickAddTransactionSheet(compact: true),
          ),
        ),
      ),
    );

    // Build content sections
    final List<Widget> content = [];

    // Zero-state check for transactions
    final hasTransactions = dashboardState.balance != 0 ||
        dashboardState.cashflow.incomeTotal != 0 ||
        dashboardState.cashflow.expenseTotal != 0;
    // We can use a more precise check if needed, but balance/cashflow is a good proxy.
    // Re-check original logic: dashboardAsync.value?.transactions.where((t) => !t.isTransfer).toList() ?? [];

    final nudgeDismissed = SharedPrefsUtil.instance.getFirstTxnNudgeDismissed();
    final onboardedAt = SharedPrefsUtil.instance.getOnboardingCompletedAt();
    final isNewUser = onboardedAt != null &&
        DateTime.now().difference(onboardedAt).inHours < 24;

    if (!hasTransactions && !nudgeDismissed) {
      content.add(
        _FirstTransactionNudge(
          isNewUser: isNewUser,
          onDismiss: () {
            SharedPrefsUtil.instance.setFirstTxnNudgeDismissed();
            ref.invalidate(dashboardStateV2Provider);
          },
        ),
      );
    }

    if (widgets.isEmpty) {
      content.add(_EmptyWidgetsState(l10n: l10n));
    } else {
      final List<Widget> widgetList =
          widgets.map((w) => _TrackedWidget(widget: w)).toList();
      widgetList.add(const AmbientBrandSection(showSignature: false));

      content.add(
        StaggeredWidgetList(
          animate: !_hasAnimatedOnce,
          onComplete: () => _hasAnimatedOnce = true,
          children: widgetList,
        ),
      );
    }

    return ScreenShell(
      config: ScreenShellConfig(
        title: 'Mudra',
        appBarMode: AppBarMode.standard,
        enableRefresh: true,
      ),
      onRefresh: () => _handleRefresh(ref, widgets),
      actions: screenState.actions,
      body: CoreOverviewTemplate(
        gate: screenState.gate,
        alert: screenState.alert,
        primaryMetric: _PrimaryMetric(
          balance: dashboardState.balance,
          label: l10n.accounts_totalBalance,
        ),
        content: content,
      ),
    );
  }

  Future<void> _handleRefresh(
    WidgetRef ref,
    List<DashboardWidgetPlugin> widgets,
  ) async {
    await RefreshHelper.withMinDuration(() async {
      ref.invalidate(dashboardStateV2Provider);
      for (final widget in widgets) {
        await widget.refresh(ref);
      }
      if (mounted) {
        SnackbarService.success('✓');
        _hasAnimatedOnce = true;
      }
    });
  }
}

class _PrimaryMetric extends StatelessWidget {
  final double balance;
  final String label;

  const _PrimaryMetric({required this.balance, required this.label});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelLarge?.copyWith(color: color.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        CurrencyText(
          amount: balance,
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
      ],
    );
  }
}

class _TrackedWidget extends ConsumerWidget {
  final DashboardWidgetPlugin widget;

  const _TrackedWidget({required this.widget});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    try {
      ref.read(widgetAnalyticsServiceProvider).recordImpression(widget.id);
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          CardInteractionTracker.recordTap(widget.id);
          ref.read(widgetAnalyticsServiceProvider).recordClick(widget.id);
          widget.onTap(context, ref);
        },
        child: widget.build(context, ref),
      );
    } catch (e) {
      return _WidgetErrorCard(id: widget.id);
    }
  }
}

class _WidgetErrorCard extends StatelessWidget {
  final String id;
  const _WidgetErrorCard({required this.id});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Card(
      color: color.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Widget "$id" failed to load',
          style: TextStyle(color: color.onErrorContainer),
        ),
      ),
    );
  }
}

class _EmptyWidgetsState extends StatelessWidget {
  final AppLocalizations l10n;
  const _EmptyWidgetsState({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
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
              style:
                  textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.dashboard_enableCardsDesc,
              style:
                  textTheme.bodyMedium?.copyWith(color: color.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push(AppRoutes.dashboardCustomize),
              icon: const Icon(LucideIcons.plus),
              label: Text(l10n.dashboard_enableCards),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardSkeleton extends ConsumerWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
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
    final l10n = AppLocalizations.of(context)!;
    final accent = color.primary;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontal,
        vertical: spacing.cardVertical,
      ),
      child: Column(
        children: [
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
                          l10n.dashboard_addFirstExpense,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: color.onSurface,
                          ),
                        ),
                        SizedBox(height: spacing.elementGapUltraMin),
                        Text(
                          l10n.dashboard_addFirstExpenseDesc,
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
                    l10n.dashboard_meanwhile,
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
                        label: l10n.dashboard_addExpense,
                        onTap: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => const QuickAddTransactionSheet(),
                        ),
                      ),
                      SizedBox(width: spacing.elementGap),
                      _QuickActionChip(
                        icon: LucideIcons.target,
                        label: l10n.dashboard_setBudget,
                        onTap: () => context.push(AppRoutes.addBudget),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing.elementGap),
                  Row(
                    children: [
                      _QuickActionChip(
                        icon: LucideIcons.piggyBank,
                        label: l10n.dashboard_createGoal,
                        onTap: () => context.push(AppRoutes.addGoal),
                      ),
                      SizedBox(width: spacing.elementGap),
                      _QuickActionChip(
                        icon: LucideIcons.landmark,
                        label: l10n.dashboard_addAccount,
                        onTap: () => context.push(AppRoutes.addAccount),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing.elementGap),
                  Text(
                    l10n.dashboard_testTip,
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
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
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
