import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/entitlement/entitlement_feature.dart';
import 'package:mudra_manager/core/entitlement/entitlement_provider.dart';
import 'package:mudra_manager/core/router/app_routes.dart';

/// Wraps a child widget — shows the actual content behind a blur
/// overlay with an upgrade prompt if the user lacks access.
class ProGate extends ConsumerWidget {
  final ProFeature feature;
  final Widget child;

  const ProGate({super.key, required this.feature, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessAsync = ref.watch(canAccessProvider(feature));

    return accessAsync.when(
      data: (canAccess) => canAccess
          ? child
          : Stack(
              children: [
                // Real screen content rendered underneath
                IgnorePointer(child: child),
                // Blur + upgrade overlay
                _BlurUpgradeOverlay(feature: feature),
              ],
            ),
      loading: () => child,
      error: (_, __) => child,
    );
  }
}

class _BlurUpgradeOverlay extends StatelessWidget {
  final ProFeature feature;

  const _BlurUpgradeOverlay({required this.feature});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned.fill(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            color: color.surface.withValues(alpha: isDark ? 0.7 : 0.6),
            child: SafeArea(
              child: Column(
                children: [
                  // Back button row
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4, top: 4),
                      child: IconButton(
                        icon: const Icon(LucideIcons.arrowLeft),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Lock icon with glow
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.primary.withValues(alpha: 0.25),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.primary.withValues(
                            alpha: isDark ? 0.15 : 0.1,
                          ),
                          blurRadius: 40,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            color.primary
                                .withValues(alpha: isDark ? 0.2 : 0.14),
                            color.tertiary
                                .withValues(alpha: isDark ? 0.08 : 0.05),
                          ],
                        ),
                      ),
                      child: Icon(
                        LucideIcons.lock,
                        size: 36,
                        color: color.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Unlock with Pro',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      _descriptionFor(feature),
                      style: textTheme.bodyMedium?.copyWith(
                        color: color.onSurfaceVariant,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Upgrade button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          context.push(AppRoutes.upgrade);
                        },
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.sparkles, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Upgrade to Pro',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Maybe later',
                      style: textTheme.bodyMedium?.copyWith(
                        color: color.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _descriptionFor(ProFeature feature) {
    return switch (feature) {
      ProFeature.advancedAnalytics =>
        'Get deep insights into your spending patterns with advanced charts and reports.',
      ProFeature.spendingPersonality =>
        'Discover your unique spending personality and get personalized tips.',
      ProFeature.netWorth =>
        'Track your complete net worth across all accounts and investments.',
      ProFeature.monthlyRecap =>
        'Get a beautiful monthly recap of your finances.',
      ProFeature.dashboardCustomize =>
        'Customize your dashboard with the widgets that matter most to you.',
      ProFeature.businessExports =>
        'Export professional business reports in Excel and PDF.',
      ProFeature.cloudBackup =>
        'Backup your data to Google Drive for safekeeping.',
      ProFeature.premiumPlugins =>
        'Access all category packs and premium plugins.',
      ProFeature.allThemes =>
        'Unlock all color themes and personalization options.',
      _ => 'This feature is available with Mudra Pro.',
    };
  }
}

/// Small "PRO" badge to show next to menu items.
class ProBadge extends ConsumerWidget {
  const ProBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPro = ref.watch(isProProvider);

    return isPro.when(
      data: (pro) => pro
          ? const SizedBox.shrink()
          : Container(
              margin: const EdgeInsets.only(left: 6),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.tertiary,
                  ],
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'PRO',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 9,
                      letterSpacing: 0.5,
                    ),
              ),
            ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Card-level Pro gate — shows content behind a blur overlay
/// with a lock + upgrade prompt when the user lacks access.
class ProCardGate extends ConsumerWidget {
  final ProFeature feature;
  final Widget child;
  final double borderRadius;

  const ProCardGate({
    super.key,
    required this.feature,
    required this.child,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessAsync = ref.watch(canAccessProvider(feature));

    return accessAsync.when(
      data: (canAccess) => canAccess
          ? child
          : Stack(
              children: [
                IgnorePointer(child: child),
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(borderRadius),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surface
                              .withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(borderRadius),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              context.push(AppRoutes.upgrade);
                            },
                            borderRadius: BorderRadius.circular(borderRadius),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.lock,
                                    size: 16,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Unlock with Pro',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
      loading: () => child,
      error: (_, __) => child,
    );
  }
}
