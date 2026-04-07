import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/core/db/models/budget.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/features/budget/data/budget_service_provider.dart';
import 'package:mudra_manager/shared/widgets/adaptive_text.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:visibility_detector/visibility_detector.dart';

class BudgetMiniCard extends ConsumerStatefulWidget {
  final double globalPadding;

  const BudgetMiniCard({super.key, this.globalPadding = 16.0});

  @override
  ConsumerState<BudgetMiniCard> createState() => _BudgetMiniCardState();
}

class _BudgetMiniCardState extends ConsumerState<BudgetMiniCard> {
  @override
  Widget build(BuildContext context) {
    final budgetProgressProvider = ref.watch(budgetWithProgressProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;
    final formatter = DateFormat('dd MMM yy', ctxt.localeName);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: widget.globalPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AdaptiveText(
                ctxt.dashboard_mini_budget_text,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color.primary,
                ),
                maxLines: 1,
              ),
              Hero(
                tag: 'budgetExpandHero',
                child: TextButton(
                  onPressed: () => context.push(AppRoutes.budgetDashboard),
                  child: const Text('View All'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        budgetProgressProvider.when(
          data: (budgets) {
            if (budgets.isEmpty) {
              return Container(
                margin: EdgeInsets.symmetric(horizontal: widget.globalPadding),
                child: Card(
                  elevation: 0,
                  color: color.surfaceContainerLow,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      context.push(AppRoutes.addBudget);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.pie_chart_outline,
                            size: 48,
                            color: color.primary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            ctxt.dashboard_mini_budget_not_found_text,
                            style: textTheme.bodyMedium?.copyWith(
                              color: color.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              context.push(AppRoutes.addBudget);
                            },
                            icon: const Icon(Icons.add),
                            label: Text(ctxt.dashboard_mini_budget_add_text),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }
            // Horizontal scrolling budget cards
            return SizedBox(
              height: 220,
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: widget.globalPadding),
                scrollDirection: Axis.horizontal,
                itemCount: budgets.length,
                itemBuilder: (context, index) {
                  final (
                    Budget budget,
                    double spent,
                    DateTime sDate,
                    DateTime eDate,
                  ) = budgets[index];
                  return _BudgetCircularCard(
                    budget: budget,
                    spent: spent,
                    startDate: sDate,
                    endDate: eDate,
                    formatter: formatter,
                  );
                },
              ),
            );
          },
          loading: () => SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              itemBuilder: (_, __) => Padding(
                padding: const EdgeInsets.only(right: 12),
                child: SkeletonLoader(width: 180, height: 200, borderRadius: BorderRadius.all(Radius.circular(20))),
              ),
            ),
          ),
          error: (e, st) => Center(child: Text(BuddyMessages.errorWith('$e'))),
        ),
      ],
    );
  }
}

class _BudgetCircularCard extends StatelessWidget {
  final Budget budget;
  final double spent;
  final DateTime startDate;
  final DateTime endDate;
  final DateFormat formatter;

  const _BudgetCircularCard({
    required this.budget,
    required this.spent,
    required this.startDate,
    required this.endDate,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final percent = (spent / budget.amount).clamp(0.0, 1.0);
    final remaining = budget.amount - spent;
    final isOverBudget = percent >= 1.0;
    final budgetColor = isOverBudget ? color.error : const Color(0xFFF59E0B);

    return Card(
      elevation: 0,
      color: isOverBudget
          ? color.errorContainer
          : color.surfaceContainerHighest,
      child: Container(
        width: 180,
        height: 200,
        margin: const EdgeInsets.only(right: 12),
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            // Navigate to budget details if needed
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Circular Progress
                Center(
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background Circle
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            value: 1.0,
                            strokeWidth: 6,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation(
                              budgetColor.withValues(alpha: 0.15),
                            ),
                          ),
                        ),
                        // Progress Circle
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: _AnimatedCircularProgress(
                            progress: percent,
                            color: budgetColor,
                            strokeWidth: 6,
                          ),
                        ),
                        // Percentage Text
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${(percent * 100).toInt()}%',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: budgetColor,
                                letterSpacing: -0.5,
                              ),
                            ),
                            if (isOverBudget)
                              Icon(
                                Icons.warning_amber,
                                color: budgetColor,
                                size: 12,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Budget Name
                AdaptiveText(
                  budget.name,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color.onSurface,
                  ),
                  maxLines: 1,
                ),

                const SizedBox(height: 4),

                // Spent / Budget
                Row(
                  children: [
                    Flexible(
                      child: CurrencyText(
                        amount: spent,
                        compact: false,
                        fixedLength: 0,
                        style: textTheme.labelSmall?.copyWith(
                          color: color.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                      ),
                    ),
                    Text(
                      ' / ',
                      style: textTheme.labelSmall?.copyWith(
                        color: color.onSurfaceVariant,
                      ),
                    ),
                    Flexible(
                      child: CurrencyText(
                        amount: budget.amount,
                        compact: false,
                        fixedLength: 0,
                        style: textTheme.labelSmall?.copyWith(
                          color: color.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Date Range
                Text(
                  '${formatter.format(startDate)} - ${formatter.format(endDate)}',
                  style: textTheme.labelSmall?.copyWith(
                    color: color.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 4),

                // Remaining/Over Budget
                if (!isOverBudget)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: budgetColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.savings, size: 10, color: budgetColor),
                        const SizedBox(width: 4),
                        Flexible(
                          child: CurrencyText(
                            amount: remaining,
                            compact: false,
                            fixedLength: 0,
                            style: textTheme.labelSmall?.copyWith(
                              color: budgetColor,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                          ),
                        ),
                        Text(
                          ' left',
                          style: textTheme.labelSmall?.copyWith(
                            color: budgetColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: budgetColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_amber, size: 10, color: budgetColor),
                        const SizedBox(width: 4),
                        AdaptiveText(
                          'Over Budget',
                          style: textTheme.labelSmall?.copyWith(
                            color: budgetColor,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedCircularProgress extends StatefulWidget {
  final double progress;
  final Color color;
  final double strokeWidth;

  const _AnimatedCircularProgress({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  State<_AnimatedCircularProgress> createState() =>
      _AnimatedCircularProgressState();
}

class _AnimatedCircularProgressState extends State<_AnimatedCircularProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: ValueKey('budget_circ_${widget.progress}_${widget.color.toARGB32()}'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.3 && !_started) {
          _started = true;
          _ctrl.forward();
        }
      },
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => CircularProgressIndicator(
          value: _anim.value * widget.progress,
          strokeWidth: widget.strokeWidth,
          backgroundColor: Colors.transparent,
          valueColor: AlwaysStoppedAnimation(widget.color),
          strokeCap: StrokeCap.round,
        ),
      ),
    );
  }
}
