import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/features/statistics/data/financial_attention_layer.dart' as stats_attention;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shared attention banner - reused across app screens for user actions
class AttentionBanner extends ConsumerWidget {
  final stats_attention.AttentionItem item;
  final VoidCallback onDismiss;
  final VoidCallback? onAction;

  const AttentionBanner({
    super.key,
    required this.item,
    required this.onDismiss,
    this.onAction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch<AppSpacing>(spacingProvider);

    final accentColor = _getAttentionColor(item.type, colorScheme);

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontal,
        vertical: spacing.cardVertical,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        color: _getBackgroundColor(item.type, colorScheme),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          onTap: () {
            HapticFeedback.mediumImpact();
            onAction?.call();
          },
          child: Padding(
            padding: EdgeInsets.all(spacing.cardInner),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getAttentionIcon(item.type),
                    color: accentColor,
                    size: 18,
                  ),
                ).animate().fadeIn(duration: 400.ms).scale(),
                SizedBox(width: spacing.elementGap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: spacing.elementGapUltraMin),
                      if (item.message.isNotEmpty)
                        Text(
                          item.message,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        onAction?.call();
                      },
                      child: Text(
                        item.actionLabel,
                        style: textTheme.labelMedium?.copyWith(
                          color: accentColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(height: spacing.elementGapMin),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onDismiss();
                      },
                      child: Icon(
                        LucideIcons.x,
                        size: 16,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.1);
  }

  Color _getAttentionColor(stats_attention.AttentionType type, ColorScheme color) {
    switch (type) {
      case stats_attention.AttentionType.critical:
        return color.error;
      case stats_attention.AttentionType.warning:
        return color.tertiary;
      case stats_attention.AttentionType.info:
        return color.primary;
      case stats_attention.AttentionType.insight:
        return color.secondary;
    }
  }

  Color _getBackgroundColor(stats_attention.AttentionType type, ColorScheme color) {
    switch (type) {
      case stats_attention.AttentionType.critical:
        return color.errorContainer;
      case stats_attention.AttentionType.warning:
        return color.secondaryContainer;
      case stats_attention.AttentionType.info:
        return color.primaryContainer;
      case stats_attention.AttentionType.insight:
        return color.secondaryContainer;
    }
  }

  IconData _getAttentionIcon(stats_attention.AttentionType type) {
    switch (type) {
      case stats_attention.AttentionType.critical:
        return LucideIcons.alertTriangle;
      case stats_attention.AttentionType.warning:
        return LucideIcons.alertCircle;
      case stats_attention.AttentionType.info:
        return LucideIcons.info;
      case stats_attention.AttentionType.insight:
        return LucideIcons.trendingUp;
    }
  }
}
