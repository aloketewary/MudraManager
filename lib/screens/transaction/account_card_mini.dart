import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:mudra_manager/db/models/account.dart' show Account;
import 'package:mudra_manager/util/account_type_extension.dart';
import 'package:mudra_manager/l10n/app_localizations.dart';
import 'package:mudra_manager/util/localization_extension.dart';

class AccountCardMini extends StatelessWidget {
  final Account? account;
  final bool selected;
  final Future<double>? balance;
  final bool isSkeleton;

  const AccountCardMini({
    super.key,
    required this.account,
    this.selected = false,
    required this.balance,
    this.isSkeleton = false,
  });

  /// Skeleton constructor
  const AccountCardMini.skeleton({super.key})
    : account = null,
      selected = false,
      balance = null,
      isSkeleton = true;

  @override
  Widget build(BuildContext ctx) {
    final color = Theme.of(ctx).colorScheme;
    final textTheme = Theme.of(ctx).textTheme;
    
    // Calculate proper text color based on account color
    final accountColor = Color(account?.colorValue ?? 0xFFBDBDBD);
    final accountLuminance = accountColor.computeLuminance();
    final textColor = accountLuminance > 0.5 ? Colors.black : Colors.white;

    return Container(
      width: 120,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              isSkeleton
                  ? [Colors.grey, Colors.grey.shade900]
                  : [
                    color.primary,
                    color.primaryFixed,
                    accountColor,
                  ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? color.tertiary : color.primary,
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          if (!isSkeleton)
            Positioned(
              bottom: 0,
              right: 0,
              child: Icon(
                account!.accountType.icon,
                color: textColor.withValues(alpha: 0.1),
                size: 50,
              ),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              isSkeleton
                  ? Container(width: 60, height: 12, color: Colors.white54)
                  : Text(
                    account!.name,
                    style: textTheme.labelLarge?.copyWith(
                      color: textColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              const Spacer(),
              isSkeleton
                  ? Container(width: 50, height: 14, color: Colors.white54)
                  : FutureBuilder<double>(
                    future: balance,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Text("...");
                      }
                      return Text(
                        AppLocalizations.of(context)!.formatCurrencyWithSign(2, snapshot.data ?? 0),
                        style: textTheme.labelLarge?.copyWith(
                          color: textColor,
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
