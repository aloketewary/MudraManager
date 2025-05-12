import 'package:flutter/material.dart';

class CategoryCard extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final bool isSelected;
  final bool isNewCard;
  final bool isUnderWrap;
  final Function callbackAction;

  const CategoryCard({
    super.key,
    required this.label,
    required this.color,
    required this.icon,
    required this.isSelected,
    required this.callbackAction,
    this.isNewCard = false,
    this.isUnderWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    var colorTheme = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;
    var size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () => callbackAction(),
      child: Container(
        width: isUnderWrap ? size.width / 2.5 : isNewCard ? 150 : 150,
        padding: const EdgeInsets.all(8.0),
        margin: isUnderWrap ? null : const EdgeInsets.only(right: 8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          // color: isSelected ? colorTheme.primary : Colors.transparent,
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
          ), // Subtle border
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: textTheme.labelLarge?.copyWith(
                  color: isSelected ? colorTheme.onPrimary : colorTheme.primary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8.0),
            CircleAvatar(radius: 16, child: Icon(icon, size: 16)),
          ],
        ),
      ),
    );
  }
}
