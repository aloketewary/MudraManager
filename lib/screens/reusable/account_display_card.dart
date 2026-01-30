import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:mudra_manager/db/models/account.dart' show AccountType;
import 'package:mudra_manager/util/account_type_extension.dart';

class AccountDisplayCard extends StatelessWidget {
  final String title;
  final String amount;
  final AccountType accountType;
  final Color startColor;
  final Color endColor;
  final Function callbackAction;
  final bool isSelected;
  final String? accountNumber;

  const AccountDisplayCard({
    super.key,
    required this.title,
    required this.amount,
    required this.accountType,
    required this.startColor,
    required this.endColor,
    required this.callbackAction,
    required this.isSelected,
    required this.accountNumber,
  });

  @override
  Widget build(BuildContext context) {
    var color = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: () => callbackAction(),
      child: Container(
        width: 210,
        // Adjust width as needed
        margin: const EdgeInsets.only(right: 20),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          gradient: LinearGradient(
            colors:
                isSelected
                    ? [color.primary, color.primaryFixed, endColor]
                    : [color.surface, color.surfaceDim, endColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: color.primary, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    color: isSelected ? color.onPrimary : color.primary,
                  ),
                ),
              ],
            ),
            Text(
              amount,
              style: textTheme.titleLarge?.copyWith(
                color: isSelected ? color.onPrimary : color.primary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Icon(
                  accountType.icon,
                  color: isSelected ? color.onPrimary : color.primary,
                  size: 24,
                ),
                const SizedBox(width: 8.0),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      accountType.label.toUpperCase(),
                      style: textTheme.labelSmall?.copyWith(
                        color: isSelected ? color.onPrimary : color.primary,
                      ),
                    ),
                    Text(
                      '**** **** **** ${accountNumber?.substring(0, 4) ?? '****'}',
                      style: TextStyle(
                        color: isSelected ? color.onPrimary : color.primary,
                        fontSize: 14.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
