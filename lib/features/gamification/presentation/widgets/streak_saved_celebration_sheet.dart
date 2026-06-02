import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';

class StreakSavedCelebrationSheet extends ConsumerStatefulWidget {
  final int streakCount;

  const StreakSavedCelebrationSheet({
    super.key,
    required this.streakCount,
  });

  @override
  ConsumerState<StreakSavedCelebrationSheet> createState() =>
      _StreakSavedCelebrationSheetState();
}

class _StreakSavedCelebrationSheetState
    extends ConsumerState<StreakSavedCelebrationSheet> {
  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
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
              Container(
                padding: EdgeInsets.all(spacing.sectionGap),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.primary.withValues(alpha: isDark ? 0.25 : 0.18),
                      color.primary.withValues(alpha: isDark ? 0.1 : 0.06),
                    ],
                  ),
                ),
                child: Icon(
                  LucideIcons.flame,
                  size: 64,
                  color: color.primary,
                ),
              ),
              SizedBox(height: spacing.sectionGap),
              Text(
                AppLocalizations.of(context)!.streak_savedTitle,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: color.onSurface,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: spacing.elementGap),
              Text(
                AppLocalizations.of(context)!.streak_savedBody(widget.streakCount),
                style: textTheme.bodyLarge?.copyWith(
                  color: color.onSurfaceVariant,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: spacing.sectionGap),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: color.primary,
                    foregroundColor: color.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(spacing.radiusMedium),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.streak_keepGoing,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      letterSpacing: 0.2,
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
              numberOfParticles: 40,
              maxBlastForce: 25,
              minBlastForce: 10,
              emissionFrequency: 0.06,
              gravity: 0.25,
              colors: [
                color.primary,
                color.tertiary,
                Colors.orange,
                Colors.amber,
              ],
            ),
          ),
        ),
      ],
    );
  }
}
