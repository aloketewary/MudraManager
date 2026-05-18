import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';

class CategoryCard extends ConsumerWidget {
  final String label;
  final Color color;
  final IconData icon;
  final bool isSelected;
  final bool isNewCard;
  final bool isUnderWrap;
  final Function callbackAction;
  final Function? onLongPress;

  const CategoryCard({
    super.key,
    required this.label,
    required this.color,
    required this.icon,
    required this.isSelected,
    required this.callbackAction,
    this.isNewCard = false,
    this.isUnderWrap = false,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorTheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final size = MediaQuery.of(context).size;
    final spacing = ref.watch(spacingProvider);
    
    // Calculate proper text color for category color background
    final categoryLuminance = color.computeLuminance();
    final categoryTextColor = categoryLuminance > 0.5 ? Colors.black : Colors.white;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        callbackAction();
      },
      onLongPress: onLongPress != null ? () {
        HapticFeedback.mediumImpact();
        onLongPress!();
      } : null,
      child: Container(
        width: isUnderWrap ? size.width / 2.5 : isNewCard ? 150 : 150,
        padding: const EdgeInsets.all(8.0),
        margin: isUnderWrap ? null : const EdgeInsets.only(right: 8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                isSelected
                    ? [colorTheme.primary, colorTheme.primaryFixed, color]
                    : [Colors.transparent, Colors.transparent, color],
          ),
          border: Border.all(
            color: colorTheme.primary,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: textTheme.labelLarge?.copyWith(
                  color: isSelected ? categoryTextColor : colorTheme.primary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8.0),
            CircleAvatar(
              radius: 16,
              backgroundColor: color,
              child: Icon(
                icon,
                size: 16,
                color: categoryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
