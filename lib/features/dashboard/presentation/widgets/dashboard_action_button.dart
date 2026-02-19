import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DashboardActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? textColor;
  final String? heroTag;

  const DashboardActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.backgroundColor,
    this.iconColor,
    this.textColor,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final button = Card(
      elevation: 0,
      color: backgroundColor ?? color.primaryContainer,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        child: Container(
          height: 50,
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: (iconColor ?? color.primary).withValues(alpha: 0.15),
                child: Icon(icon, size: 20, color: iconColor ?? color.primary),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: textTheme.labelMedium?.copyWith(
                    color: textColor ?? color.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return heroTag != null ? Hero(tag: heroTag!, child: button) : button;
  }
}
