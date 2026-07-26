import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/features/analytics/data/personality_archetype.dart';
import 'package:mudra_manager/shared/widgets/type_section_header.dart';

/// Spending personality card showing behavioral archetype and insights.
///
/// Displays:
/// - Persona archetype (e.g., "Mindful Planner", "Spontaneous Spender")
/// - Behavior summary
/// - Key traits as visual indicators
class SpendingPersonalityCard extends ConsumerWidget {
  final PersonalityArchetype archetype;
  final Map<String, double>? spendingBehaviors;

  const SpendingPersonalityCard({
    super.key,
    required this.archetype,
    this.spendingBehaviors,
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
          label: 'Spending Personality',
          icon: LucideIcons.user,
          accentColor: color.secondary,
        ),
        SizedBox(height: spacing.sectionGap),
        // Main card
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.secondary.withValues(alpha: brightness == Brightness.dark ? 0.20 : 0.12),
                color.surface,
              ],
            ),
            borderRadius: BorderRadius.circular(spacing.radiusMedium),
            border: Border.all(color: color.secondary.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: color.secondary.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(spacing.cardInner),
            child: Row(
              children: [
                // Archetype icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        archetype.color.withValues(alpha: 0.2),
                        archetype.color.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  ),
                  child: Icon(
                    archetype.icon,
                    size: spacing.iconXL,
                    color: archetype.color,
                  ),
                ),
                SizedBox(width: spacing.sectionGap),
                // Archetype details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        archetype.name,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: archetype.color,
                        ),
                      ),
                      SizedBox(height: spacing.elementGapMin),
                      Text(
                        archetype.tagline,
                        style: textTheme.bodySmall?.copyWith(
                          color: color.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: spacing.elementGap),
                      // Traits chips
                      Wrap(
                        spacing: spacing.elementGap,
                        runSpacing: spacing.elementGap,
                        children: archetype.traits
                            .map((trait) => _buildTraitChip(trait, color, textTheme, spacing))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: spacing.sectionGap),
        // Behavioral summary
        _buildBehavioralSummary(context, color, textTheme, spacing),
      ],
    );
  }

  Widget _buildTraitChip(String trait, ColorScheme color, TextTheme textTheme, AppSpacing spacing) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.elementGap,
        vertical: spacing.elementGapMin,
      ),
      decoration: BoxDecoration(
        color: color.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(spacing.radiusSmall),
      ),
      child: Text(
        trait,
        style: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: color.secondary,
        ),
      ),
    );
  }

  Widget _buildBehavioralSummary(
    BuildContext context,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(color: color.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          _buildBehaviorRow(
            icon: LucideIcons.chartPie,
            label: 'Style',
            value: archetype.trait,
            color: color,
            textTheme: textTheme,
            spacing: spacing,
          ),
          Divider(height: 1, color: color.outlineVariant.withValues(alpha: 0.3)),
          _buildBehaviorRow(
            icon: LucideIcons.lightbulb,
            label: 'Guidance',
            value: archetype.guidance,
            color: color,
            textTheme: textTheme,
            spacing: spacing,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildBehaviorRow({
    required IconData icon,
    required String label,
    required String value,
    required ColorScheme color,
    required TextTheme textTheme,
    required AppSpacing spacing,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.all(spacing.cardInner),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color.onSurfaceVariant),
          SizedBox(width: spacing.elementGap),
          Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              color: color.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: color.onSurface,
              ),
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}