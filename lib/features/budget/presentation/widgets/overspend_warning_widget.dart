import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/features/budget/data/overspend_prediction_provider.dart';
import 'package:mudra_manager/features/budget/domain/overspend_prediction.dart';

class OverspendWarningWidget extends ConsumerWidget {
  const OverspendWarningWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final predictions = ref.watch(overspendPredictionsProvider);

    return predictions.when(
      data: (predictionList) {
        final warnings =
            predictionList.where((p) => p.willOverspend).toList();

        if (warnings.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: warnings.map((prediction) {
              return _WarningCard(prediction: prediction);
            }).toList(),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }
}

class _WarningCard extends StatelessWidget {
  final OverspendPrediction prediction;

  const _WarningCard({required this.prediction});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      color: color.errorContainer,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_rounded, color: color.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    prediction.warningMessage,
                    style: textTheme.bodyMedium?.copyWith(
                      color: color.onErrorContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Spent: ${formatCurrency(prediction.currentSpent, code: BaseCurrency.code)} / ${formatCurrency(prediction.budgetAmount, code: BaseCurrency.code)}',
                  style: textTheme.labelSmall?.copyWith(
                    color: color.onErrorContainer,
                  ),
                ),
                Text(
                  'Projected: ${formatCurrency(prediction.projectedTotal, code: BaseCurrency.code)}',
                  style: textTheme.labelSmall?.copyWith(
                    color: color.onErrorContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (prediction.currentSpent / prediction.budgetAmount)
                    .clamp(0, 1),
                minHeight: 6,
                backgroundColor: color.onErrorContainer.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
