import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/core/services/background_task_manager.dart';
import 'package:mudra_manager/features/insights/data/attention_mapper.dart';
import 'package:mudra_manager/features/budget/data/budget_alert_service.dart';
import 'package:mudra_manager/features/dashboard/data/background_health_provider.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/permission_provider.dart';
import 'package:mudra_manager/features/profile/data/help_guide_provider.dart';
import 'package:mudra_manager/features/sms/presentation/screens/sms_activity_screen.dart';
import 'package:mudra_manager/features/statistics/data/adaptive_utility_provider.dart';
import 'package:mudra_manager/features/statistics/data/financial_attention_layer.dart'
    as stats_attention;
import 'package:shared_preferences/shared_preferences.dart';

/// Shows only the highest-priority banner. One slot, one message.
/// Priority: BackgroundHealth > BudgetAlert > AutoImport > Advisory > Help
class PrioritizedBanner extends ConsumerStatefulWidget {
  final bool hasSeenHelp;
  final List<BudgetAlert> alerts;
  final int? pendingSmsCount;

  const PrioritizedBanner({
    super.key,
    required this.hasSeenHelp,
    required this.alerts,
    this.pendingSmsCount,
  });

  @override
  ConsumerState<PrioritizedBanner> createState() => _PrioritizedBannerState();
}

class _PrioritizedBannerState extends ConsumerState<PrioritizedBanner> {
  List<String> _dismissedAttentionItems = [];

  @override
  void initState() {
    super.initState();
    _loadDismissedItems();
  }

  Future<void> _loadDismissedItems() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getStringList('dashboard_advisory_dismissed');
    if (dismissed != null && mounted) {
      setState(() {
        _dismissedAttentionItems = dismissed;
      });
    }
  }

  Future<void> _saveDismissedItems() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'dashboard_advisory_dismissed',
      _dismissedAttentionItems,
    );
  }

  @override
  Widget build(BuildContext context) {
    final spacing = ref.watch(spacingProvider);

    // Background health blocks everything (critical)
    final unhealthy = ref.watch(backgroundTaskUnhealthyProvider).value ?? false;
    if (unhealthy) return const BackgroundHealthBanner();

    // Collect all attention items
    final allItems = <stats_attention.AttentionItem>[];

    // Budget alerts
    for (final alert in widget.alerts) {
      allItems.addAll(AttentionMapper.mapBudgetAlerts([alert]));
    }

    // SMS pending
    if (widget.pendingSmsCount != null && widget.pendingSmsCount! > 0) {
      allItems
          .addAll(AttentionMapper.mapSmsPendingAlerts(widget.pendingSmsCount!));
    }

    // Android auto-import setup reminder
    if (Platform.isAndroid) {
      final granted = ref.watch(smsPermissionGrantedProvider);
      if (!granted.isLoading) {
        final isGranted = granted.value == true;
        final autoImportOn = SharedPrefsUtil.instance.getSmsImportEnabled();
        final dismissed = SharedPrefsUtil.instance.getSmsbannerDismiss();
        if (!dismissed) {
          if (isGranted && !autoImportOn) {
            allItems.add(
              const stats_attention.AttentionItem(
                id: 'sms_import_off',
                type: stats_attention.AttentionType.info,
                title: 'Enable Auto-Import',
                message: 'Import transactions from SMS automatically',
                priority: 0.5,
                actionLabel: 'Enable',
                actionRoute: AppRoutes.smsActivity,
              ),
            );
          } else if (!isGranted && !dismissed) {
            allItems.add(
              const stats_attention.AttentionItem(
                id: 'sms_permission',
                type: stats_attention.AttentionType.info,
                title: 'Enable SMS Permission',
                message: 'Allow SMS access for transaction import',
                priority: 0.5,
                actionLabel: 'Enable',
                actionRoute: AppRoutes.smsActivity,
              ),
            );
          }
        }
      }
    }

    // Adaptive utility advisory items
    final advisoryAsync = ref.watch(adaptiveUtilityProvider);
    if (advisoryAsync is AsyncData && advisoryAsync.value != null) {
      allItems.addAll(advisoryAsync.value!.attentionItems);
    }

    // Filter dismissed
    final visibleItems = allItems
        .where((item) => !_dismissedAttentionItems.contains(item.id))
        .toList();

    // Help banner (always below advisory)
    final helpBanner =
        widget.hasSeenHelp ? const SizedBox.shrink() : const HelpBanner();

    // No items
    if (visibleItems.isEmpty) return helpBanner;

    return Column(
      children: [
        FinancialAdvisoryBanner(
          attentionItems: visibleItems,
          onDismissItem: (id) {
            setState(() {
              _dismissedAttentionItems.add(id);
            });
            _saveDismissedItems();
          },
        ),
        helpBanner,
      ],
    );
  }
}

class HelpBanner extends ConsumerWidget {
  const HelpBanner({super.key});

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
                        AppLocalizations.of(context)!
                            .dashboard_tapToExploreHelp,
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

class AutoImportBanner extends ConsumerWidget {
  const AutoImportBanner({super.key});

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
                padding: EdgeInsets.all(spacing.elementGap + 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(spacing.radiusSmall),
                ),
                child: Icon(LucideIcons.bellRing, color: accent, size: 18),
              ),
              SizedBox(width: spacing.elementGap),
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
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.elementGap,
                  vertical: spacing.elementGapMin,
                ),
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
                width: spacing.elementGap * 2,
                height: spacing.elementGap * 2,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: spacing.elementGap),
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
                        AppLocalizations.of(context)!
                            .dashboard_enableAutoImport,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: color.onSurface,
                        ),
                      ),
                      SizedBox(height: spacing.elementGap),
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

class BackgroundHealthBanner extends ConsumerWidget {
  const BackgroundHealthBanner({super.key});

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

/// Expandable multi-item advisory banner for dashboard
/// Features smooth animations, micro-interactions, and accessibility support
class FinancialAdvisoryBanner extends ConsumerStatefulWidget {
  final List<AttentionItem> attentionItems;
  final void Function(String id) onDismissItem;

  const FinancialAdvisoryBanner({
    super.key,
    required this.attentionItems,
    required this.onDismissItem,
  });

  @override
  ConsumerState<FinancialAdvisoryBanner> createState() =>
      _FinancialAdvisoryBannerState();
}

class _FinancialAdvisoryBannerState
    extends ConsumerState<FinancialAdvisoryBanner> {
  bool _expanded = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.read(spacingProvider);

    return Semantics(
      label:
          'Financial Advisory Banner. ${widget.attentionItems.length} items. '
          'Tap to ${_expanded ? 'collapse' : 'expand'}',
      child: InkWell(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          HapticFeedback.selectionClick();
          setState(() => _expanded = !_expanded);
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          margin: EdgeInsets.symmetric(
            horizontal: spacing.cardHorizontal,
            vertical: spacing.cardVertical,
          ),
          transform: Matrix4.identity()..scale(_isPressed ? 0.98 : 1.0),
          decoration: BoxDecoration(
            color: color.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(spacing.radiusMedium),
            border: Border.all(color: color.primary.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              // Header row
              Padding(
                padding: EdgeInsets.all(spacing.cardInner),
                child: Row(
                  children: [
                    // Icon with pulse effect when expanded
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.all(spacing.elementGap),
                      decoration: BoxDecoration(
                        color: color.primary.withValues(
                          alpha: _expanded ? 0.2 : 0.1,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.lightbulb,
                        color: color.primary,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: spacing.elementGap * 1.5),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Financial Advisory',
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: color.primary,
                            ),
                          ),
                          Text(
                            '${widget.attentionItems.length} '
                            '${widget.attentionItems.length == 1 ? 'item' : 'items'} '
                            'may need attention',
                            style: textTheme.bodySmall?.copyWith(
                              color: color.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, animation) =>
                          RotationTransition(
                        turns: animation,
                        child: ScaleTransition(
                          scale: animation,
                          child: child,
                        ),
                      ),
                      child: Icon(
                        _expanded
                            ? LucideIcons.chevronUp
                            : LucideIcons.chevronDown,
                        key: ValueKey(_expanded),
                        size: 20,
                        color: color.primary,
                      ),
                    ),
                  ],
                ),
              ),
              // Expandable items with smooth reveal
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 250),
                firstChild: const SizedBox.shrink(),
                secondChild: _buildExpandedContent(color, textTheme, spacing),
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedContent(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    final displayItems = _expanded
        ? widget.attentionItems
        : widget.attentionItems.take(3).toList();

    return Column(
      children: [
        // Divider with fade
        Divider(
          height: 1,
          color: color.outlineVariant.withValues(alpha: 0.5),
        ),
        // Animated list of items
        ...displayItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return _buildAnimatedAdvisoryItem(
            item,
            color,
            textTheme,
            spacing,
            index,
          );
        }),
        // "More items" indicator
        if (widget.attentionItems.length > 3)
          Padding(
            padding: EdgeInsets.all(spacing.cardInner),
            child: Text(
              '${widget.attentionItems.length - 3} more item${widget.attentionItems.length - 3 == 1 ? '' : 's'}...',
              style: textTheme.bodySmall?.copyWith(
                color: color.onSurfaceVariant.withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAnimatedAdvisoryItem(
    AttentionItem item,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    int index,
  ) {
    final itemColor = _getAttentionColor(item.type, color);

    return AnimatedContainer(
      duration: Duration(milliseconds: 150 + (index * 50)),
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            context.push(item.actionRoute);
          },
          borderRadius: BorderRadius.circular(spacing.radiusSmall),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.cardInner,
              vertical: spacing.elementGap * 1.25,
            ).copyWith(right: spacing.cardInner * 0.5),
            child: Row(
              children: [
                // Urgency indicator bar
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: itemColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(width: spacing.elementGap),
                // Icon with colored background
                Container(
                  padding: EdgeInsets.all(spacing.elementGap * 0.75),
                  decoration: BoxDecoration(
                    color: itemColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getAttentionIcon(item.type),
                    color: itemColor,
                    size: 16,
                  ),
                ),
                SizedBox(width: spacing.elementGap * 1.25),
                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: color.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.message.isNotEmpty) ...[
                        SizedBox(height: spacing.elementGapUltraMin),
                        Text(
                          item.message,
                          style: textTheme.bodySmall?.copyWith(
                            color: color.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                // Dismiss button (not for critical)
                if (item.type != AttentionType.critical)
                  Padding(
                    padding: EdgeInsets.only(left: spacing.elementGap),
                    child: IconButton(
                      onPressed: () => widget.onDismissItem(item.id),
                      icon: Icon(
                        LucideIcons.x,
                        size: 18,
                        color: color.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      splashRadius: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getAttentionColor(AttentionType type, ColorScheme color) {
    return switch (type) {
      AttentionType.critical => color.error,
      AttentionType.warning => color.tertiary,
      AttentionType.info => color.primary,
      AttentionType.insight => color.primaryContainer,
    };
  }

  IconData _getAttentionIcon(AttentionType type) {
    return switch (type) {
      AttentionType.critical => LucideIcons.alertCircle,
      AttentionType.warning => LucideIcons.alertTriangle,
      AttentionType.info => LucideIcons.info,
      AttentionType.insight => LucideIcons.checkCircle2,
    };
  }
}
