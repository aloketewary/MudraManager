import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';

/// Color picker for category selection.
///
/// Usage:
/// ```dart
/// CategoryColorPicker(
///   selectedColor: _selectedColor,
///   onColorChanged: (c) => setState(() => _selectedColor = c),
///   onCustomPick: () => _pickColor(),
/// )
/// ```
class CategoryColorPicker extends ConsumerWidget {
  final Color selectedColor;
  final ValueChanged<Color> onColorChanged;
  final VoidCallback? onCustomPick;
  final List<Color>? quickColors;

  const CategoryColorPicker({
    super.key,
    required this.selectedColor,
    required this.onColorChanged,
    this.onCustomPick,
    this.quickColors,
  });

  static const defaultColors = [
    Color(0xFFE53935), // Red
    Color(0xFFE91E63), // Pink
    Color(0xFF9C27B0), // Purple
    Color(0xFF3F51B5), // Indigo
    Color(0xFF2196F3), // Blue
    Color(0xFF00BCD4), // Cyan
    Color(0xFF009688), // Teal
    Color(0xFF4CAF50), // Green
    Color(0xFFFF9800), // Orange
    Color(0xFF795548), // Brown
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final spacing = ref.watch(spacingProvider);
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final colors = quickColors ?? defaultColors;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.cardInner),
        child: Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: spacing.elementGap,
                runSpacing: spacing.elementGap,
                children: colors.map((c) {
                  final isSelected = selectedColor.toARGB32() == c.toARGB32();
                  return _buildColorSwatch(
                        c: c,
                        isSelected: isSelected,
                        color: color,
                        reduceMotion: reduceMotion,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          onColorChanged(c);
                        },
                      );
                }).toList(),
              ),
            ),
            SizedBox(width: spacing.elementGap * 1.5),
            _buildCustomPicker(context, color, spacing),
          ],
        ),
      ),
    );
  }

  Widget _buildColorSwatch({
    required Color c,
    required bool isSelected,
    required ColorScheme color,
    required bool reduceMotion,
    required VoidCallback onTap,
  }) {
    return Semantics(
      label: 'Color ${c.value.toRadixString(16)}',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 200),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: c,
            shape: BoxShape.circle,
            border: isSelected
                ? Border.all(
                    color: color.onSurface,
                    width: 2.5,
                  )
                : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: c.withValues(alpha: 0.4),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
          child: isSelected
              ? Icon(
                  LucideIcons.check,
                  color: Colors.white,
                  size: 18,
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildCustomPicker(BuildContext context, ColorScheme color, AppSpacing spacing) {
    return Tooltip(
      message: 'Custom color',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          onCustomPick?.call();
        },
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: color.outlineVariant,
              width: 1.5,
            ),
          ),
          child: Icon(
            LucideIcons.ellipsis,
            size: 18,
            color: color.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}