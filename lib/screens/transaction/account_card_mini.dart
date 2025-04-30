import 'package:flutter/material.dart';
import 'package:mudra_manager/db/models/account.dart' show Account;
import 'package:mudra_manager/util/account_type_extension.dart';

class AccountCardMini extends StatelessWidget {
  final Account account;
  final bool selected;
  final Future<double> balance;

  const AccountCardMini({
    super.key,
    required this.account,
    this.selected = false,
    required this.balance,
  });

  @override
  Widget build(BuildContext ctx) {
    final color = Theme.of(ctx).colorScheme;
    final textTheme = Theme.of(ctx).textTheme;
    return Container(
      width: 120,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.primary,
            color.primaryFixed,
            Color(account.colorValue ?? 0x00FFFF),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border:
            selected
                ? Border.all(color: color.tertiary, width: 2)
                : Border.all(color: color.primary, width: 2),
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: 0,
            right: 0,
            child: Icon(
              account.accountType.icon,
              color: color.onPrimary.withAlpha(25),
              size: 50,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                account.name,
                style: textTheme.labelLarge?.copyWith(color: color.onPrimary),
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              FutureBuilder(
                future: balance,
                builder: (context, AsyncSnapshot<double> data) {
                  if (data.connectionState == ConnectionState.waiting) {
                    return Text("...");
                  }
                  return Text(
                    '₹${data.data?.toStringAsFixed(2)}',
                    style: textTheme.labelLarge?.copyWith(
                      color: color.onPrimary,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
