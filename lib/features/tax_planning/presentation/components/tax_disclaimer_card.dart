import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';

/// Tax disclaimer card showing disclaimer text.
class TaxDisclaimerCard extends StatelessWidget {
  final AppLocalizations ctxt;
  final AppSpacing spacing;

  const TaxDisclaimerCard({
    super.key,
    required this.ctxt,
    required this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      label: ctxt.tax_disclaimer,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.all(spacing.cardInner),
        decoration: BoxDecoration(
          color: color.surfaceContainerLow,
          borderRadius: spacing.borderRadiusMedium,
          border: Border.all(color: color.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              LucideIcons.info,
              size: spacing.iconSM,
              color: color.onSurfaceVariant,
            ),
            SizedBox(width: spacing.elementGap),
            Expanded(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: textTheme.bodySmall?.copyWith(
                  color: color.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ) ?? const TextStyle(),
                child: Text(ctxt.tax_disclaimer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}