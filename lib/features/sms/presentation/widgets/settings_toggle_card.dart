import 'package:mudra_manager/core/tone/tone_provider.dart';
import 'package:flutter/material.dart';

class SettingsToggleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final Function(bool) onChanged;
  final bool enabled;

  const SettingsToggleCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: color.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(Tone.current.borderRadius),
              ),
              child: Icon(icon, color: color.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value && enabled,
              onChanged: enabled ? onChanged : null,
            ),
          ],
        ),
      ),
    );
  }
}
