import 'package:mudra_manager/core/tone/tone_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UtilityCalculatorButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;

  const UtilityCalculatorButton({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(Tone.current.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (iconColor ?? color.primary).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: iconColor ?? color.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: textTheme.bodySmall?.copyWith(
                  color: color.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
