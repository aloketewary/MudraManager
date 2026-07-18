import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';

/// Section header for settings lists (Core Settings, App Data, Appearance, etc).
/// Uses Material 3 tonal container style for consistent Fintech SaaS appearance.
class SectionHeader extends ConsumerWidget {
  const SectionHeader(this.title, {super.key, this.subtitle = '', this.isPro = false});

  final String title;
  final String subtitle;
  final bool isPro;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);

    return Container(
      margin: EdgeInsets.only(top: spacing.elementGap * 2, bottom: spacing.elementGap),
      padding: EdgeInsets.symmetric(horizontal: spacing.cardHorizontal),
      child: Row(
        children: [
          // Leading accent bar
          Container(
            width: spacing.elementGapMin,
            height: 18,
            decoration: BoxDecoration(
              color: color.primary,
              borderRadius: BorderRadius.circular(spacing.elementGapMin / 2),
            ),
          ),
          SizedBox(width: spacing.elementGapMin),
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: color.onSurface,
              letterSpacing: 0.15,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            SizedBox(width: spacing.elementGap),
            Text(
              subtitle,
              style: textTheme.labelSmall?.copyWith(
                color: color.onSurfaceVariant,
              ),
            ),
          ],
          if (isPro) ...[
            SizedBox(width: spacing.elementGap),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.4)),
              ),
              child: Text(
                'PRO',
                style: textTheme.labelSmall?.copyWith(
                  color: const Color(0xFFD4AF37),
                  fontWeight: FontWeight.w800,
                  fontSize: 9,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}