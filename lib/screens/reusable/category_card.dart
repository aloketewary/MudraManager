import 'package:flutter/material.dart';

class CategoryCard extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final bool isSelected;
  final bool isNewCard;
  final Function callbackAction;

  const CategoryCard({
    super.key,
    required this.label,
    required this.color,
    required this.icon,
    required this.isSelected,
    required this.callbackAction,
    this.isNewCard = false,
  });

  @override
  Widget build(BuildContext context) {
    var colorTheme = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: () => callbackAction(),
      child: Container(
        width: isNewCard ? 150 : 150,
        padding: const EdgeInsets.all(8.0),
        margin: const EdgeInsets.only(right: 8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          color: isSelected ? colorTheme.primary : Colors.transparent,
          border: Border.all(
            color: colorTheme.primary,
            width: 2,
          ), // Subtle border
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            CircleAvatar(radius: 16, child: Icon(icon, size: 16)),
            const SizedBox(width: 8.0),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: isSelected ? colorTheme.onPrimary : colorTheme.primary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
