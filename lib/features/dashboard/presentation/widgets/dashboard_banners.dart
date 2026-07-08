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
import 'package:mudra_manager/features/budget/data/budget_alert_provider.dart';
import 'package:mudra_manager/features/budget/data/budget_alert_service.dart';
import 'package:mudra_manager/features/dashboard/data/background_health_provider.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/permission_provider.dart';
import 'package:mudra_manager/features/profile/data/help_guide_provider.dart';
import 'package:mudra_manager/features/sms/presentation/screens/sms_activity_screen.dart';
import 'package:mudra_manager/shared/widgets/budget_alert_banner.dart';

/// Shows only the highest-priority banner. One slot, one message.
/// Priority: BackgroundHealth > BudgetAlert > AutoImport > Help
class PrioritizedBanner extends ConsumerWidget {
  final bool hasSeenHelp;
  final List<BudgetAlert> alerts;

  const PrioritizedBanner({
    super.key,
    required this.hasSeenHelp,
    required this.alerts,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unhealthy = ref.watch(backgroundTaskUnhealthyProvider).value ?? false;
    if (unhealthy) return const BackgroundHealthBanner();

    if (alerts.isNotEmpty) {
      return Column(
        children: [
          BudgetAlertBanner(
            alerts: alerts,
            onDismiss: () {
              ref
                  .read(budgetAlertsProvider.notifier)
                  .dismissAlert(alerts.first);
            },
          ),
          const SizedBox(height: 16),
        ],
      );
    }

    if (Platform.isAndroid) {
      final granted = ref.watch(smsPermissionGrantedProvider);
      if (!granted.isLoading) {
        final isGranted = granted.value == true;
        final autoImportOn = SharedPrefsUtil.instance.getSmsImportEnabled();
        if (isGranted && autoImportOn) {
          final pending = ref.watch(pendingCountProvider).value ?? 0;
          if (pending > 0) return const AutoImportBanner();
        } else if (isGranted && !autoImportOn) {
          return const AutoImportBanner();
        } else if (!SharedPrefsUtil.instance.getSmsbannerDismiss()) {
          return const AutoImportBanner();
        }
      }
    }

    if (!hasSeenHelp) return const HelpBanner();

    return const SizedBox.shrink();
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
