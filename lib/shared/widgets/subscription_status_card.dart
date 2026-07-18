import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/entitlement/entitlement_provider.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/router/app_routes.dart';

/// Subscription status card: Pro/Free/Trial badge with action to upgrade.
class SubscriptionStatusCard extends ConsumerWidget {
  const SubscriptionStatusCard({
    super.key,
    this.onTap,
  });

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);

    final planAsync = ref.watch(proPlanInfoProvider);

    return planAsync.when(
      data: (info) {
        final accent = info.isPro
            ? color.tertiary
            : info.isTrial
                ? color.primary
                : color.primary;

        return GestureDetector(
          onTap: onTap ??
              () {
                HapticFeedback.mediumImpact();
                context.push(AppRoutes.upgrade);
              },
          child: Container(
            padding: EdgeInsets.all(spacing.cardInner),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: color.brightness == Brightness.dark ? 0.2 : 0.12),
                  accent.withValues(alpha: color.brightness == Brightness.dark ? 0.08 : 0.04),
                ],
              ),
              border: Border.all(
                color: accent.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(spacing.radiusSmall),
                  ),
                  child: Icon(
                    info.isPro
                        ? LucideIcons.crown
                        : info.isTrial
                            ? LucideIcons.gift
                            : LucideIcons.sparkles,
                    color: accent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            info.isPro
                                ? info.label
                                : info.isTrial
                                    ? 'Full Access'
                                    : 'Upgrade to Pro',
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (info.isTrial) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: color.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(
                                    spacing.radiusSmall * 0.5),
                              ),
                              child: Text(
                                '${info.trialDaysRemaining}d LEFT',
                                style: textTheme.labelSmall?.copyWith(
                                  color: color.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 9,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                          if (info.isPro) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(
                                    spacing.radiusSmall * 0.5),
                              ),
                              child: Text(
                                'ACTIVE',
                                style: textTheme.labelSmall?.copyWith(
                                  color: accent,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 9,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _subscriptionSubtitle(info),
                        style: textTheme.bodySmall?.copyWith(
                          color: color.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  LucideIcons.chevronRight,
                  color: accent,
                  size: 20,
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  String _subscriptionSubtitle(ProPlanInfo info) {
    if (info.isTrial) {
      final days = info.trialDaysRemaining ?? 0;
      if (days > 30) return 'Enjoy full access';
      if (days > 7) return '$days days remaining';
      if (days > 0) return 'Ends in $days days';
      return 'Trial ended';
    }
    if (!info.isPro) return 'Unlock all features';

    if (info.expiresAt != null) {
      final days = info.expiresAt!.difference(DateTime.now()).inDays;
      if (days < 0) return 'Expired, renew now';
      if (days == 0) return 'Expires today';
      if (days == 1) return 'Renews tomorrow';
      return 'Renews in $days days';
    }
    return 'Active subscription';
  }
}
