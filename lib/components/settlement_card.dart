import 'package:flutter/material.dart';

class SettlementCard extends StatelessWidget {
  final String fromPerson;
  final String toPerson;
  final double amount;
  final bool isPaid;
  final VoidCallback? onMarkPaid;

  const SettlementCard({
    super.key,
    required this.fromPerson,
    required this.toPerson,
    required this.amount,
    this.isPaid = false,
    this.onMarkPaid,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
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
                        backgroundColor: color.errorContainer,
                        child: Text(
                          fromPerson[0].toUpperCase(),
                          style: TextStyle(
                            color: color.error,
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
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Owes',
                          style: textTheme.labelSmall?.copyWith(
                            color: color.error,
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
                        color: isPaid ? color.primary : color.error,
                        size: 32,
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isPaid ? color.primaryContainer : color.errorContainer,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isPaid ? color.primary : color.error,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          '₹${amount.toStringAsFixed(2)}',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isPaid ? color.primary : color.error,
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
                        backgroundColor: color.primaryContainer,
                        child: Text(
                          toPerson[0].toUpperCase(),
                          style: TextStyle(
                            color: color.primary,
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
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Gets',
                          style: textTheme.labelSmall?.copyWith(
                            color: color.primary,
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
            
            if (isPaid)
              Container(
                margin: EdgeInsets.only(top: 12),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: color.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: color.primary, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Settled',
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
    );
  }
}
