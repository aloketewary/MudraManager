import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';

class SmsSuccessCelebrationSheet extends ConsumerStatefulWidget {
  const SmsSuccessCelebrationSheet({super.key});

  @override
  ConsumerState<SmsSuccessCelebrationSheet> createState() =>
      _SmsSuccessCelebrationSheetState();
}

class _SmsSuccessCelebrationSheetState
    extends ConsumerState<SmsSuccessCelebrationSheet> {
  final _confetti = ConfettiController(duration: const Duration(seconds: 2));

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    _confetti.play();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final ctxt = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            spacing.cardHorizontalMax,
            spacing.cardVertical,
            spacing.cardHorizontalMax,
            spacing.cardVerticalMax + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: color.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: spacing.sectionGap),
              Semantics(
                label: 'Celebration',
                excludeSemantics: true,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.primary.withValues(alpha: isDark ? 0.2 : 0.14),
                        color.primary.withValues(alpha: isDark ? 0.08 : 0.05),
                      ],
                    ),
                  ),
                  child: Icon(
                    LucideIcons.sparkles,
                    size: 48,
                    color: color.primary,
                  ),
                ),
              ),
              SizedBox(height: spacing.sectionGap),
              Text(
                ctxt.sms_celebrationTitle,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: spacing.elementGap),
              Text(
                ctxt.sms_celebrationBody,
                style: textTheme.bodyLarge?.copyWith(
                  color: color.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: spacing.sectionGap),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(spacing.radiusMedium),
                    ),
                  ),
                  child: Text(
                    ctxt.sms_celebrationCta,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              SizedBox(height: spacing.cardVertical),
            ],
          ),
        ),
        Positioned.fill(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 30,
              maxBlastForce: 20,
              minBlastForce: 8,
              emissionFrequency: 0.05,
              gravity: 0.2,
              colors: [
                color.primary,
                color.tertiary,
                color.secondary,
              ],
            ),
          ),
        ),
      ],
    );
  }
}
