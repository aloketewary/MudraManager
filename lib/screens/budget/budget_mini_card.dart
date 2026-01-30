import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/l10n/app_localizations.dart';
import 'package:mudra_manager/providers/budget_service_provider.dart';
import 'package:mudra_manager/db/models/budget.dart' show Budget;
import 'package:mudra_manager/screens/budget/add_budget_screen.dart'
    show AddBudgetScreen;
import 'package:mudra_manager/screens/budget/budget_dashboard.dart';
import 'package:mudra_manager/screens/reusable/no_data_found.dart';
import 'package:mudra_manager/theme/design_tokens.dart';
import 'package:mudra_manager/util/localization_extension.dart';

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
    var color = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;
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
              Text(
                ctxt.dashboard_mini_budget_text,
                style: textTheme.titleLarge?.copyWith(color: color.primary),
              ),
              Hero(
                tag: 'budgetExpandHero',
                child: IconButton.filled(
                  onPressed:
                      () => {
                        context.push('/budget-dashboard'),
                      },
                  icon: Icon(Icons.open_in_new),
                ),
              ),
            ],
          ),
        ),
        budgetProgressProvider.when(
          data: (budgets) {
            if (budgets.isEmpty) {
              return NoDataFound(
                message: ctxt.dashboard_mini_budget_not_found_text,
                iconData: Icons.pie_chart_outline,
                action: ElevatedButton(
                  onPressed: () {
                    context.push('/add-budget');
                  },
                  child: Text(ctxt.dashboard_mini_budget_add_text),
                ),
              );
            }
            return Column(
              children:
                  budgets.map((entry) {
                    final (
                      Budget budget,
                      double spent,
                      DateTime sDate,
                      DateTime eDate,
                    ) = entry;
                    final percent = (spent / budget.amount).clamp(0.0, 1.0);

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: SizedBox(
                        height: 210,
                        child: GestureDetector(
                          onTap: () {
              HapticFeedback.mediumImpact();
              {};
            },
                          child: Container(
                            // width: 120,
                            padding: const EdgeInsets.all(8.0),
                            margin: EdgeInsets.only(right: 8.0),
                            decoration: BoxDecoration(
                              borderRadius: DesignTokens.borderRadiusMedium,
                              border: Border.all(
                                color:
                                    percent == 1.0
                                        ? color.error
                                        : color.primary,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: <Widget>[
                                    CircleAvatar(
                                      radius: 16,
                                      child: Icon(
                                        percent == 1.0
                                            ? Icons.warning_amber
                                            : Icons.bubble_chart_outlined,
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 8.0),
                                    Expanded(
                                      child: Text(
                                        budget.name.toUpperCase(),
                                        // textAlign: TextAlign.center,
                                        style: textTheme.labelLarge?.copyWith(),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: SizedBox(
                                          height: 140,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                ctxt.budget_dashboardMiniCardBudgetTitleText,
                                                style: textTheme.labelLarge
                                                    ?.copyWith(
                                                      color: color.primaryFixed,
                                                    ),
                                                overflow: TextOverflow.fade,
                                              ),
                                              Text(
                                                ctxt.formatCurrencyWithSign(
                                                  2,
                                                  budget.amount,
                                                ),
                                                style: textTheme.titleLarge
                                                    ?.copyWith(
                                                      color: color.primary,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                overflow: TextOverflow.fade,
                                              ),
                                              Text(
                                                "${ctxt.budget_dashboardMiniCardSpentTitleText} (${ctxt.formatCompactNumber().format((spent / budget.amount) * 100)}%)",
                                                style: textTheme.titleSmall
                                                    ?.copyWith(
                                                      color:
                                                          color.secondaryFixed,
                                                    ),
                                                overflow: TextOverflow.fade,
                                              ),
                                              Text(
                                                ctxt.formatCurrencyWithSign(
                                                  2,
                                                  spent,
                                                ),
                                                style: textTheme.titleLarge
                                                    ?.copyWith(
                                                      color: color.secondary,
                                                      // fontSize: 40,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                overflow: TextOverflow.fade,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Flexible(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: <Widget>[
                                            // Circular progress
                                            Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                SizedBox(
                                                  width: 90,
                                                  height: 90,
                                                  child: CircularProgressIndicator(
                                                    value: percent,
                                                    strokeWidth: 12,
                                                    backgroundColor:
                                                        color.secondary,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                          Color
                                                        >(
                                                          percent >= 1.0
                                                              ? color.error
                                                              : color.primary,
                                                        ),
                                                  ),
                                                ),
                                                Text(
                                                  ctxt.formatPercentNumber(
                                                    percent,
                                                  ),
                                                  style: textTheme.labelLarge
                                                      ?.copyWith(
                                                        color: color.primary,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  "${formatter.format(sDate)} - ${formatter.format(eDate)}",
                                  textAlign: TextAlign.center,
                                  style: textTheme.labelMedium?.copyWith(
                                    color: color.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('Error: $e')),
        ),
      ],
    );
  }
}
