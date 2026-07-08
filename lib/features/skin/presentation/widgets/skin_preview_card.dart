import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/skin/model/skin.dart';
import 'package:mudra_manager/core/skin/converter/skin_to_theme.dart';
import 'package:mudra_manager/core/theme/theme_provider.dart';

class SkinPreviewCard extends ConsumerWidget {
  final Skin skin;
  
  final bool isSelected;
  final VoidCallback onTap;

  const SkinPreviewCard({
    super.key,
    required this.skin,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final mode = brightness == Brightness.light
        ? AppThemeMode.light
        : AppThemeMode.dark;
    final colorScheme = SkinToTheme.colorScheme(skin, mode);
    final isHairline = skin.style.dividerStyle == 'hairline';
    final radius = skin.style.cardRadius;
    final spacing = ref.watch(spacingProvider);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(spacing.radiusSmall),
          border: Border.all(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(spacing.radiusSmall),
          child: Stack(
            children: [
              _buildPreview(colorScheme, isHairline, radius, spacing),
              if (isSelected)
                Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    radius: 10,
                    backgroundColor: colorScheme.primary,
                    child: const Icon(
                      LucideIcons.check,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview(
    ColorScheme colorScheme,
    bool isHairline,
    double radius,
    AppSpacing spacing,
  ) {
    final borderColor = colorScheme.outline.withValues(
      alpha: skin.style.borderOpacity,
    );

    return Column(
      children: [
        // Mini AppBar
        Container(
          height: 32,
          color: colorScheme.surface,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Icon(LucideIcons.menu, size: 14, color: colorScheme.onSurface),
              const SizedBox(width: 8),
              Container(
                height: 6,
                width: 40,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface,
                  borderRadius: BorderRadius.circular(spacing.radiusSmall * 0.5),
                ),
              ),
            ],
          ),
        ),
        // Mini Body
        Expanded(
          child: Container(
            color: colorScheme.surface,
            padding: const EdgeInsets.all(10),
            child: isHairline
                ? _buildHairlinePreview(colorScheme, borderColor, radius)
                : _buildStandardPreview(colorScheme, radius, spacing),
          ),
        ),
      ],
    );
  }

  /// Standard card-based preview (rounded cards with fill).
  Widget _buildStandardPreview(ColorScheme colorScheme, double radius, AppSpacing spacing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(radius.clamp(4, 12)),
          ),
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: colorScheme.primary,
                child: Icon(
                  LucideIcons.indianRupee,
                  size: 12,
                  color: colorScheme.onPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 6,
                width: 40,
                decoration: BoxDecoration(
                  color: colorScheme.onPrimaryContainer,
                  borderRadius: BorderRadius.circular(spacing.radiusSmall * 0.5),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Align(
          alignment: Alignment.bottomRight,
          child: CircleAvatar(
            radius: 16,
            backgroundColor: colorScheme.tertiary,
            child: Icon(
              LucideIcons.plus,
              size: 14,
              color: colorScheme.onTertiary,
            ),
          ),
        ),
      ],
    );
  }

  /// Hairline cross-grid preview (transparent cards, faint dividers).
  Widget _buildHairlinePreview(
    ColorScheme colorScheme,
    Color borderColor,
    double radius,
  ) {
    return Column(
      children: [
        // Top metric row with vertical divider
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _metricBlock(
                  colorScheme,
                  '₹24.5K',
                  'Spent',
                  radius,
                ),
              ),
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: borderColor,
              ),
              Expanded(
                child: _metricBlock(
                  colorScheme,
                  '₹8.2K',
                  'Saved',
                  radius,
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, thickness: 1, color: borderColor),
        // Bottom row
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _metricBlock(
                  colorScheme,
                  '91%',
                  'Budget',
                  radius,
                ),
              ),
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: borderColor,
              ),
              Expanded(
                child: Center(
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _metricBlock(
    ColorScheme colorScheme,
    String value,
    String label,
    double radius,
  ) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              color: colorScheme.onSurfaceVariant,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
