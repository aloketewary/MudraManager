import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/features/insights/domain/ai_summary.dart';
import 'package:mudra_manager/shared/widgets/type_section_header.dart';

/// AI-powered conversational financial summary card.
///
/// Displays a friendly coach message with:
/// - Personalized greeting
/// - Positive highlight
/// - Concern (if any)
/// - Financial prediction
class AiSummaryCard extends ConsumerWidget {
  final AiSummary aiSummary;

  const AiSummaryCard({
    super.key,
    required this.aiSummary,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TypeSectionHeader(
          label: 'AI Summary',
          icon: LucideIcons.sparkles,
          accentColor: color.primary,
        ),
        SizedBox(height: spacing.sectionGap),
        // Coach message card
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.primary.withValues(alpha: brightness == Brightness.dark ? 0.20 : 0.12),
                color.surface,
              ],
            ),
            borderRadius: BorderRadius.circular(spacing.radiusMedium),
            border: Border.all(color: color.primary.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: color.primary.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(spacing.cardInner),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting with avatar
                Row(
                  children: [
                    Container(
                      width: spacing.iconXL,
                      height: spacing.iconXL,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.primary.withValues(alpha: 0.2),
                            color.secondary.withValues(alpha: 0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(spacing.radiusMedium),
                      ),
                      child: Icon(
                        LucideIcons.bot,
                        size: spacing.iconMD,
                        color: color.primary,
                      ),
                    ),
                    SizedBox(width: spacing.elementGap),
                    Expanded(
                      child: Text(
                        aiSummary.greeting,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing.sectionGap),
                // Positive highlight
                _buildHighlightRow(
                  icon: LucideIcons.thumbsUp,
                  iconColor: FinanceColors.incomeColor(brightness),
                  label: 'Going Well',
                  text: aiSummary.positiveHighlight,
                  color: color,
                  textTheme: textTheme,
                  spacing: spacing,
                ),
                if (aiSummary.hasConcerns) ...[
                  SizedBox(height: spacing.elementGap),
                  _buildHighlightRow(
                    icon: LucideIcons.alertCircle,
                    iconColor: FinanceColors.statusWarning,
                    label: 'Needs Attention',
                    text: aiSummary.concernHighlight,
                    color: color,
                    textTheme: textTheme,
                    spacing: spacing,
                  ),
                ],
                SizedBox(height: spacing.sectionGap),
                // Prediction
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.elementGap,
                    vertical: spacing.elementGap,
                  ),
                  decoration: BoxDecoration(
                    color: color.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(spacing.radiusSmall),
                    border: Border.all(color: color.primary.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.trendingUp,
                        size: 14,
                        color: color.primary,
                      ),
                      SizedBox(width: spacing.elementGapMin),
                      Expanded(
                        child: Text(
                          aiSummary.prediction,
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: color.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHighlightRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String text,
    required ColorScheme color,
    required TextTheme textTheme,
    required AppSpacing spacing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: iconColor),
        SizedBox(width: spacing.elementGap),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: iconColor,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: spacing.elementGapMin),
              Text(
                text,
                style: textTheme.bodyMedium?.copyWith(
                  color: color.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}