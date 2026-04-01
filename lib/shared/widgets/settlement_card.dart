import 'package:flutter/material.dart';
import 'package:flutter_boring_avatars/flutter_boring_avatars.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/shared/widgets/widgets.dart';

class SettlementCard extends StatelessWidget {
  final String fromPerson;
  final String toPerson;
  final double amount;
  final bool isPaid;
  final VoidCallback? onMarkPaid;
  final DateTime? settledDate;
  final AppSpacing spacing;

  const SettlementCard({
    super.key,
    required this.fromPerson,
    required this.toPerson,
    required this.amount,
    this.isPaid = false,
    this.onMarkPaid,
    this.settledDate,
    required this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Opacity(
      opacity: isPaid ? 0.6 : 1.0,
      child: CustomPaint(
        painter: isPaid
            ? DashedBorderPainter(color: color.outline.withValues(alpha: 0.5))
            : null,
        child: Card(
          margin: const EdgeInsets.only(),
          elevation: 0,
          color: isPaid
              ? color.surfaceContainerLow
              : color.surfaceContainerHighest,
          child: Padding(
            padding: EdgeInsets.all(spacing.cardInner),
            child: Column(
              children: [
                Row(
                  children: [
                    // From Person
                    Expanded(
                      child: Column(
                        children: [
                          SizedBox(
                            width: 48,
                            height: 48,
                            child: ClipOval(
                              child: BoringAvatar(
                                name: fromPerson,
                                palette: BoringAvatarPalette([
                                  color.primary,
                                  color.tertiary,
                                  color.primaryContainer,
                                  color.tertiaryContainer,
                                ]),
                                type: BoringAvatarType.beam,
                              ),
                            ),
                          ),
                          SizedBox(height: spacing.elementGap),
                          Text(
                            fromPerson,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isPaid ? color.onSurfaceVariant : null,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: spacing.elementGap),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: spacing.cardHorizontalMin,
                              vertical: spacing.cardVerticalMin,
                            ),
                            decoration: BoxDecoration(
                              color: isPaid
                                  ? color.surfaceContainerHigh
                                  : color.errorContainer,
                              borderRadius:
                                  BorderRadius.circular(spacing.radiusMedium),
                            ),
                            child: Text(
                              'Owes',
                              style: textTheme.labelSmall?.copyWith(
                                color: isPaid
                                    ? color.onSurfaceVariant
                                    : color.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Arrow and Amount
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: spacing.cardHorizontal,
                        vertical: spacing.cardVertical,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.arrow_forward_rounded,
                            color:
                                isPaid ? color.onSurfaceVariant : color.error,
                            size: 32,
                          ),
                          SizedBox(height: spacing.elementGap),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: spacing.cardHorizontal,
                              vertical: spacing.cardVertical,
                            ),
                            decoration: BoxDecoration(
                              color: isPaid
                                  ? color.surfaceContainerHigh
                                  : color.errorContainer,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isPaid
                                    ? color.onSurfaceVariant
                                    : color.error,
                                width: 2,
                              ),
                            ),
                            child: CurrencyText(
                              amount: amount,
                              fixedLength: 2,
                              compact: false,
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isPaid
                                    ? color.onSurfaceVariant
                                    : color.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // To Person
                    Expanded(
                      child: Column(
                        children: [
                          SizedBox(
                            width: 48,
                            height: 48,
                            child: ClipOval(
                              child: BoringAvatar(
                                name: toPerson,
                                palette: BoringAvatarPalette([
                                  color.primary,
                                  color.tertiary,
                                  color.primaryContainer,
                                  color.tertiaryContainer,
                                ]),
                                type: BoringAvatarType.beam,
                              ),
                            ),
                          ),
                          SizedBox(height: spacing.elementGap),
                          Text(
                            toPerson,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isPaid ? color.onSurfaceVariant : null,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: spacing.elementGap),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: spacing.cardHorizontalMin,
                              vertical: spacing.cardVerticalMin,
                            ),
                            decoration: BoxDecoration(
                              color: isPaid
                                  ? color.surfaceContainerHigh
                                  : color.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Gets',
                              style: textTheme.labelSmall?.copyWith(
                                color: isPaid
                                    ? color.onSurfaceVariant
                                    : color.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (!isPaid && onMarkPaid != null) ...[
                  SizedBox(height: spacing.cardHorizontalMax),
                  FilledButton.icon(
                    onPressed: onMarkPaid,
                    icon: const Icon(Icons.check_circle_outline, size: 20),
                    label: const Text('Mark as Paid'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 44),
                      backgroundColor: color.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
                if (isPaid && settledDate != null)
                  Container(
                    margin: EdgeInsets.only(top: spacing.cardHorizontal),
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing.cardHorizontal,
                      vertical: spacing.cardVertical,
                    ),
                    decoration: BoxDecoration(
                      color: color.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: color.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Settled on ${DateFormat.MMMd().format(settledDate!)}',
                          style: textTheme.labelLarge?.copyWith(
                            color: color.primary,
                            fontWeight: FontWeight.bold,
                          ),
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

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double dashLength;
  final double gapLength;

  DashedBorderPainter({
    required this.color,
    this.dashLength = 4,
    this.gapLength = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(12),
        ),
      );

    final dashPath = _createDashedPath(path, dashLength, gapLength);
    canvas.drawPath(dashPath, paint);
  }

  Path _createDashedPath(Path source, double dashLength, double gapLength) {
    final path = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final nextDash = distance + dashLength;
        final nextGap = nextDash + gapLength;
        path.addPath(
          metric.extractPath(distance, math.min(nextDash, metric.length)),
          Offset.zero,
        );
        distance = nextGap;
      }
    }
    return path;
  }

  @override
  bool shouldRepaint(DashedBorderPainter oldDelegate) => false;
}
