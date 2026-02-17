import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mudra_manager/components/currency_text.dart';
import 'package:mudra_manager/providers/analytics_provider.dart';
import 'package:mudra_manager/util/localization_extension.dart';

class SpendingPredictionCard extends ConsumerWidget {
  final double globalPadding;

  const SpendingPredictionCard({super.key, required this.globalPadding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final predictionAsync = ref.watch(predictedSpendingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return predictionAsync.when(
      data: (predicted) {
        if (predicted <= 0) return SizedBox.shrink();
        
        return Container(
          margin: EdgeInsets.symmetric(horizontal: globalPadding),
          child: Card(
            elevation: 0,
            color: color.surfaceContainerLow,
            child: InkWell(
              onTap: () {
                HapticFeedback.mediumImpact();
                context.push('/statistics');
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.trending_up, color: color.primary),
                        SizedBox(width: 8),
                        Text(
                          'Spending Prediction',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                        Icon(Icons.chevron_right, color: color.onSurfaceVariant),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Next Month',
                              style: textTheme.bodySmall?.copyWith(
                                color: color.onSurfaceVariant,
                              ),
                            ),
                            SizedBox(height: 4),
                            TweenAnimationBuilder<double>(
                              duration: Duration(milliseconds: 1500),
                              curve: Curves.easeOutCubic,
                              tween: Tween(begin: 0.0, end: predicted),
                              builder: (context, value, child) {
                                return CurrencyText(
                                  amount: value,
                                  compact: false,
                                  style: textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: color.primary,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: color.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.auto_graph,
                            color: color.onPrimaryContainer,
                            size: 32,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Based on last 3 months average',
                      style: textTheme.bodySmall?.copyWith(
                        color: color.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () => SizedBox.shrink(),
      error: (_, __) => SizedBox.shrink(),
    );
  }
}
