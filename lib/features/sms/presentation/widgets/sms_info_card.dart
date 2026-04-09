import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';

class SmsInfoCard extends StatelessWidget {
  const SmsInfoCard({super.key});

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(LucideIcons.info, color: color.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How SMS Import Works',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _InfoPoint(emoji: '🏦', text: 'Only scans bank and wallet SMS'),
                  _InfoPoint(emoji: '🔒', text: 'All data stays on your device'),
                  _InfoPoint(emoji: '✨', text: 'Automatically creates transactions'),
                  _InfoPoint(emoji: '🚫', text: 'No personal messages are read'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPoint extends StatelessWidget {
  final String emoji;
  final String text;

  const _InfoPoint({required this.emoji, required this.text});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: textTheme.bodySmall?.copyWith(
                color: color.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
