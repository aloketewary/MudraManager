import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/domain/financial_states.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/state/app_screen_state.dart';

/// Template A — Core Overview
///
/// Used for: dashboard, accounts home, net worth.
/// Structure:
///   - Primary number (balance, net worth)
///   - 1 derived metric row
///   - Constraint strip (budget/bill state)
///   - Action row (static CTAs)
///   - Optional content below
///
/// This template ONLY renders. It does NOT compute state.
class CoreOverviewTemplate extends ConsumerWidget {
  /// The primary number to display prominently.
  final Widget primaryMetric;

  /// Optional derived metric row (income/expense, etc).
  final Widget? derivedMetrics;

  /// Optional constraint strip (budget + bill badges).
  final Widget? constraintStrip;

  /// Optional alert banner (highest priority only).
  final ScreenAlert? alert;

  /// Contextual action buttons (rendered inline in body).
  /// Pass ScreenActions.contextual here directly.
  final List<ScreenAction> actions;

  /// Additional content below the core structure.
  final List<Widget> content;

  /// Data gate — controls what renders.
  final DataValidityLevel gate;

  /// Widget to show when gate is insufficient.
  final Widget? setupWidget;

  const CoreOverviewTemplate({
    super.key,
    required this.primaryMetric,
    this.derivedMetrics,
    this.constraintStrip,
    this.alert,
    this.actions = const [],
    this.content = const [],
    this.gate = DataValidityLevel.valid,
    this.setupWidget,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);

    // Gate: insufficient → show setup only
    if (gate == DataValidityLevel.insufficient) {
      return setupWidget ?? const SizedBox.shrink();
    }

    return CustomScrollView(
      slivers: [
        // Alert (if any)
        if (alert != null)
          SliverToBoxAdapter(
            child: _AlertBanner(alert: alert!, spacing: spacing),
          ),

        // Primary metric
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.cardHorizontal,
              vertical: spacing.cardVertical,
            ),
            child: primaryMetric,
          ),
        ),

        // Derived metrics row
        if (derivedMetrics != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: spacing.cardHorizontal),
              child: derivedMetrics,
            ),
          ),

        // Constraint strip
        if (constraintStrip != null && gate == DataValidityLevel.valid)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: spacing.cardHorizontal,
                vertical: spacing.elementGap,
              ),
              child: constraintStrip,
            ),
          ),

        // Actions
        if (actions.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: spacing.cardHorizontal,
                vertical: spacing.elementGap,
              ),
              child: Row(
                children: actions
                    .map((a) => Expanded(
                          child: _ActionButton(action: a),
                        ),)
                    .toList(),
              ),
            ),
          ),

        // Additional content
        SliverList(
          delegate: SliverChildListDelegate(content),
        ),
      ],
    );
  }
}

class _AlertBanner extends StatelessWidget {
  final ScreenAlert alert;
  final AppSpacing spacing;

  const _AlertBanner({required this.alert, required this.spacing});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final alertColor = switch (alert.level) {
      ScreenAlertLevel.urgent => color.error,
      ScreenAlertLevel.warning => color.tertiary,
      ScreenAlertLevel.info => color.primary,
    };

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontal,
        vertical: spacing.cardVertical,
      ),
      child: Container(
        padding: EdgeInsets.all(spacing.cardInner),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          color: alertColor.withValues(alpha: 0.1),
          border: Border.all(color: alertColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.title,
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: alertColor,
                    ),
                  ),
                  Text(
                    alert.message,
                    style: textTheme.bodySmall?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final ScreenAction action;

  const _ActionButton({required this.action});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          children: [
            Icon(action.icon, color: color.primary, size: 20),
            const SizedBox(height: 4),
            Text(
              action.label,
              style: textTheme.labelSmall?.copyWith(
                color: color.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
