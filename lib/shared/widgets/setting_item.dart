import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';

/// Single setting row with icon, title, subtitle, and optional trailing widget.
/// Used in settings lists (profile, security, budget, etc).
class SettingItem extends ConsumerWidget {
  const SettingItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
    this.disabled = false,
    this.selected,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool disabled;
  final bool? selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final spacing = ref.watch(spacingProvider);
    final textTheme = Theme.of(context).textTheme;
    final alpha = disabled ? 0.4 : 1.0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: spacing.cardHorizontal, vertical: spacing.elementGapUltraMin),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  onTap();
                },
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          splashColor: color.primary.withValues(alpha: 0.12),
          highlightColor: color.primary.withValues(alpha: 0.08),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.cardHorizontalMax,
              vertical: spacing.elementGap * 1.5,
            ),
            child: Row(
              children: [
                // Tonal gradient icon container
                Container(
                  padding: EdgeInsets.all(spacing.elementGap),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.primary.withValues(alpha: 0.12 * alpha),
                        color.surfaceContainerHighest.withValues(alpha: alpha),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(spacing.radiusSmall),
                  ),
                  child: Icon(
                    icon,
                    color: color.primary.withValues(alpha: alpha),
                    size: 20,
                  ),
                ),
                SizedBox(width: spacing.elementGap * 1.5),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: color.onSurface.withValues(alpha: alpha),
                              ),
                            ),
                          ),
                          if (trailing != null) trailing!,
                          if (selected == true)
                            Padding(
                              padding: EdgeInsets.only(left: spacing.elementGap),
                              child: Icon(
                                LucideIcons.check,
                                size: 16,
                                color: color.primary,
                              ),
                            ),
                        ],
                      ),
                      Text(
                        subtitle,
                        style: textTheme.bodySmall?.copyWith(
                          color: color.onSurfaceVariant.withValues(alpha: alpha),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  LucideIcons.chevronRight,
                  color: color.onSurfaceVariant.withValues(alpha: 0.5 * alpha),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
