import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';

class SmsInfoCard extends ConsumerWidget {
  const SmsInfoCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final ctxt = AppLocalizations.of(context)!;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: color.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        side: BorderSide(color: color.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.cardInner),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(spacing.elementGap + 4),
              decoration: BoxDecoration(
                color: color.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(spacing.radiusMedium),
              ),
              child: Icon(LucideIcons.info, color: color.primary, size: 24),
            ),
            SizedBox(width: spacing.cardInner),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ctxt.sms_infoTitle,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color.onSurface,
                    ),
                  ),
                  SizedBox(height: spacing.elementGap),
                  _InfoPoint(emoji: '🏦', text: ctxt.sms_infoOnlyScans, spacing: spacing),
                  _InfoPoint(emoji: '🔒', text: ctxt.sms_infoStaysOnDevice, spacing: spacing),
                  _InfoPoint(emoji: '✨', text: ctxt.sms_infoAutoCreates, spacing: spacing),
                  _InfoPoint(emoji: '🚫', text: ctxt.sms_infoNoPersonal, spacing: spacing),
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
  final AppSpacing spacing;

  const _InfoPoint({required this.emoji, required this.text, required this.spacing});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: spacing.elementGapMin + 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          SizedBox(width: spacing.elementGap),
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
