import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

class SettlementCard extends StatelessWidget {
  final String fromPerson;
  final String toPerson;
  final double amount;
  final bool isPaid;
  final VoidCallback? onMarkPaid;
  final DateTime? settledDate;

  const SettlementCard({
    super.key,
    required this.fromPerson,
    required this.toPerson,
    required this.amount,
    this.isPaid = false,
    this.onMarkPaid,
    this.settledDate,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Opacity(
      opacity: isPaid ? 0.6 : 1.0,
      child: CustomPaint(
        painter: isPaid ? DashedBorderPainter(color: color.outline.withValues(alpha: 0.5)) : null,
        child: Card(
          margin: EdgeInsets.only(bottom: 12),
          elevation: 0,
          color: isPaid ? color.surfaceContainerLow : color.surfaceContainerHighest,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // From Person
                    Expanded(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: isPaid ? color.surfaceContainerHigh : color.errorContainer,
                            child: Text(
                              fromPerson[0].toUpperCase(),
                              style: TextStyle(
                                color: isPaid ? color.onSurfaceVariant : color.error,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
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
                          SizedBox(height: 4),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isPaid ? color.surfaceContainerHigh : color.errorContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Owes',
                              style: textTheme.labelSmall?.copyWith(
                                color: isPaid ? color.onSurfaceVariant : color.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Arrow and Amount
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: isPaid ? color.onSurfaceVariant : color.error,
                            size: 32,
                          ),
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isPaid ? color.surfaceContainerHigh : color.errorContainer,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isPaid ? color.onSurfaceVariant : color.error,
                                width: 2,
                              ),
                            ),
                            child: Text(
                              '₹${amount.toStringAsFixed(2)}',
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isPaid ? color.onSurfaceVariant : color.error,
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
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: isPaid ? color.surfaceContainerHigh : color.primaryContainer,
                            child: Text(
                              toPerson[0].toUpperCase(),
                              style: TextStyle(
                                color: isPaid ? color.onSurfaceVariant : color.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
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
                          SizedBox(height: 4),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isPaid ? color.surfaceContainerHigh : color.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Gets',
                              style: textTheme.labelSmall?.copyWith(
                                color: isPaid ? color.onSurfaceVariant : color.primary,
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
                  SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: onMarkPaid,
                    icon: Icon(Icons.check_circle_outline, size: 20),
                    label: Text('Mark as Paid'),
                    style: FilledButton.styleFrom(
                      minimumSize: Size(double.infinity, 44),
                      backgroundColor: color.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
                
                if (isPaid && settledDate != null)
                  Container(
                    margin: EdgeInsets.only(top: 12),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Settled on ${DateFormat.MMMd().format(settledDate!)}',
                          style: textTheme.labelLarge?.copyWith(
                            color: Colors.green,
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
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(12),
      ));

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
