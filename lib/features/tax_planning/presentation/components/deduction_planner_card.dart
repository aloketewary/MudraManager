import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';

/// Interactive deduction planner with animated sliders.
class DeductionPlannerCard extends StatefulWidget {
  final Map<String, double> plannedDeductions;
  final void Function(String key, double amount) onUpdateDeduction;
  final AppLocalizations ctxt;
  final AppSpacing spacing;

  const DeductionPlannerCard({
    super.key,
    required this.plannedDeductions,
    required this.onUpdateDeduction,
    required this.ctxt,
    required this.spacing,
  });

  @override
  State<DeductionPlannerCard> createState() => _DeductionPlannerCardState();
}

class _DeductionPlannerCardState extends State<DeductionPlannerCard> {
  late final MediaQueryData _mediaQuery;

  bool get _isReducedMotion => _mediaQuery.disableAnimations;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _mediaQuery = MediaQuery.of(context);
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final deductionOptions = [
      (_PlannerOption.nps, widget.ctxt.tax_nps80CCD1B, 50000.0),
      (_PlannerOption.section80C, widget.ctxt.tax_section80C, 150000.0),
      (_PlannerOption.section80D, widget.ctxt.tax_section80D, 50000.0),
      (_PlannerOption.hra, widget.ctxt.tax_hraExemption, 60000.0),
      (_PlannerOption.homeLoan, widget.ctxt.tax_homeLoanInterest, 200000.0),
    ];

    return Semantics(
      label: widget.ctxt.tax_plannerDeductions,
      child: AnimatedContainer(
        duration: _isReducedMotion ? Duration.zero : const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(horizontal: widget.spacing.cardHorizontal, vertical: widget.spacing.cardVertical),
        decoration: BoxDecoration(
          color: color.surfaceContainerLow,
          borderRadius: BorderRadius.circular(widget.spacing.radiusMedium),
          border:
              Border.all(color: color.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...deductionOptions.mapIndexed((index, option) {
              final (key, label, maxAmount) = option;
              final currentValue = widget.plannedDeductions[key.name] ?? 0;

              return AnimatedSize(
                duration: _isReducedMotion ? Duration.zero : const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                child: Column(
                  key: ValueKey(key.name),
                  children: [
                    _DeductionSlider(
                      label: label,
                      currentValue: currentValue,
                      maxValue: maxAmount,
                      color: color,
                      textTheme: textTheme,
                      spacing: widget.spacing,
                      ctxt: widget.ctxt,
                      isReducedMotion: _isReducedMotion,
                      onUpdateMax: () => widget.onUpdateDeduction(key.name, maxAmount),
                      onUpdateDeduction: (value) => widget.onUpdateDeduction(key.name, value),
                    ),
                    if (index < deductionOptions.length - 1)
                      SizedBox(height: widget.spacing.elementGap),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _DeductionSlider extends StatefulWidget {
  final String label;
  final double currentValue;
  final double maxValue;
  final ColorScheme color;
  final TextTheme textTheme;
  final ValueChanged<double> onUpdateDeduction;
  final VoidCallback onUpdateMax;
  final AppSpacing spacing;
  final AppLocalizations ctxt;
  final bool isReducedMotion;

  const _DeductionSlider({
    required this.label,
    required this.currentValue,
    required this.maxValue,
    required this.color,
    required this.textTheme,
    required this.onUpdateDeduction,
    required this.onUpdateMax,
    required this.spacing,
    required this.ctxt,
    required this.isReducedMotion,
  });

  @override
  State<_DeductionSlider> createState() => __DeductionSliderState();
}

class __DeductionSliderState extends State<_DeductionSlider> {
  void _handleChanged(double value) {
    HapticFeedback.lightImpact();
    widget.onUpdateDeduction(value);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      final currentValue = widget.currentValue;
      final step = widget.maxValue / 10;

      if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
          event.logicalKey == LogicalKeyboardKey.arrowUp) {
        HapticFeedback.lightImpact();
        widget.onUpdateDeduction((currentValue + step).clamp(0, widget.maxValue));
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
          event.logicalKey == LogicalKeyboardKey.arrowDown) {
        HapticFeedback.lightImpact();
        widget.onUpdateDeduction((currentValue - step).clamp(0, widget.maxValue));
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.home) {
        HapticFeedback.lightImpact();
        widget.onUpdateDeduction(0);
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.end) {
        HapticFeedback.lightImpact();
        widget.onUpdateMax();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final remainingAmount = widget.maxValue - widget.currentValue;
    final remainingPercent = (remainingAmount / widget.maxValue * 100).round();

    return Semantics(
      label: widget.label,
      hint: widget.ctxt.tax_upTo(widget.maxValue.toInt()),
      child: Focus(
        onKeyEvent: _handleKeyEvent,
        child: Builder(
          builder: (context) {
            final focused = Focus.of(context).hasFocus;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.label,
                        style: widget.textTheme.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.onUpdateMax,
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 150),
                        style: widget.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: widget.color.primary,
                          decoration: TextDecoration.underline,
                          decorationColor: widget.color.primary.withValues(alpha: 0.5),
                        ) ?? const TextStyle(),
                        child: CurrencyText(
                          amount: widget.currentValue,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: widget.spacing.elementGapMin),
                AnimatedContainer(
                  duration: widget.isReducedMotion ? Duration.zero : const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.spacing.radiusSmall),
                    border: focused
                        ? Border.all(color: widget.color.primary, width: 2)
                        : null,
                  ),
                  child: Slider(
                      value: widget.currentValue,
                      min: 0,
                      max: widget.maxValue,
                      onChanged: _handleChanged,
                      onChangeStart: (_) => HapticFeedback.lightImpact(),
                      onChangeEnd: (_) => HapticFeedback.mediumImpact(),
                      activeColor: widget.color.primary,
                      inactiveColor: widget.color.surfaceContainerHighest,
                      thumbColor: widget.color.primary,
                      overlayColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.pressed)
                            ? widget.color.primary.withValues(alpha: 0.2)
                            : Colors.transparent,
                      ),
                    ),
                ),
                AnimatedContainer(
                  duration: widget.isReducedMotion ? Duration.zero : const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.spacing.elementGapMin,
                    vertical: widget.spacing.elementGapUltraMin,
                  ),
                  decoration: BoxDecoration(
                    color: remainingAmount > 0
                        ? widget.color.onSurfaceVariant.withValues(alpha: 0.08)
                        : widget.color.primary.withValues(alpha: 0.1),
                    borderRadius: widget.spacing.borderRadiusSmall,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '0',
                        style: widget.textTheme.labelSmall?.copyWith(
                          color: widget.color.onSurfaceVariant,
                        ),
                      ),
                      if (remainingAmount > 0)
                        Text(
                          '$remainingPercent% ${widget.ctxt.tax_remaining(remainingAmount.round())}',
                          style: widget.textTheme.labelSmall?.copyWith(
                            color: widget.color.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      else
                        Icon(
                          LucideIcons.checkCircle2,
                          size: 14,
                          color: widget.color.primary,
                        ),
                      Text(
                        widget.ctxt.tax_upTo(widget.maxValue.toInt()),
                        style: widget.textTheme.labelSmall?.copyWith(
                          color: widget.color.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

extension _ListExtension<E> on List<E> {
  Iterable<T> mapIndexed<T>(T Function(int index, E element) f) {
    return [for (var i = 0; i < length; i++) f(i, this[i])];
  }
}

enum _PlannerOption {
  nps,
  section80C,
  section80D,
  hra,
  homeLoan,
}
