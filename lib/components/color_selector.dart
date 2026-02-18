import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ColorSelector extends StatelessWidget {
  final Color selectedColor;
  final Function(Color) onColorSelected;
  final List<Color> colors;

  const ColorSelector({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
    this.colors = Colors.primaries,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: colors.map((c) {
          return GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              onColorSelected(c);
            },
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c,
                border: Border.all(
                  color: selectedColor == c ? Colors.white : Colors.transparent,
                  width: 3,
                ),
                boxShadow: selectedColor == c
                    ? [
                        BoxShadow(
                          color: c.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
