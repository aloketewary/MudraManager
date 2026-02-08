import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:mudra_manager/db/models/account.dart' show AccountType;
import 'package:mudra_manager/screens/reusable/animated_balance.dart'
    show AnimatedBalance;
import 'package:mudra_manager/theme/design_tokens.dart';
import 'package:mudra_manager/util/account_type_extension.dart';
import 'package:mudra_manager/util/string_util.dart';

enum AnimationStyles { defaultStyle, custom, none }

const List<(AnimationStyles, String)> animationStyleSegments =
    <(AnimationStyles, String)>[
      (AnimationStyles.defaultStyle, 'Default'),
      (AnimationStyles.custom, 'Custom'),
      (AnimationStyles.none, 'None'),
    ];

enum Menu { edit, archive, remove }

class AnimatedAccountCard extends StatefulWidget {
  final String totalBalance;
  final String accountNumber;
  final Color backgroundColor;
  final Color accentColor;
  final String accountName;
  final AccountType accountType;
  final VoidCallback? onArchive;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;
  final bool showMenu;
  final bool isBehind;

  const AnimatedAccountCard({
    super.key,
    required this.totalBalance,
    required this.accountNumber,
    required this.backgroundColor,
    required this.accentColor,
    required this.accountName,
    required this.accountType,
    required this.onArchive,
    required this.onEdit,
    required this.onRemove,
    required this.showMenu,
    this.isBehind = false,
  });

  @override
  State<AnimatedAccountCard> createState() => _AnimatedAccountCard();
}

class _AnimatedAccountCard extends State<AnimatedAccountCard> {
  final Set<AnimationStyles> _animationStyleSelection = <AnimationStyles>{
    AnimationStyles.defaultStyle,
  };
  AnimationStyle? _animationStyle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    
    // Calculate proper text color based on accent color brightness
    final accentLuminance = widget.accentColor.computeLuminance();
    final textColor = accentLuminance > 0.5 ? Colors.black : Colors.white;
    final textColorWithAlpha = textColor.withValues(alpha: 0.9);
    final surfaceOverlay = textColor.withValues(alpha: 0.2);

    return Container(
      height: 220,
      margin: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacing12, 
        vertical: DesignTokens.spacing8,
      ),
      padding: EdgeInsets.all(DesignTokens.spacing24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.accentColor,
            widget.accentColor.withValues(alpha: 0.9),
            widget.accentColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: widget.accentColor.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        widget.accountName,
                        style: textTheme.titleLarge?.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.showMenu)
                      Container(
                        decoration: BoxDecoration(
                          color: surfaceOverlay,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: PopupMenuButton<Menu>(
                          popUpAnimationStyle: _animationStyle,
                          icon: Icon(
                            Icons.more_vert,
                            color: textColor,
                            size: 20,
                          ),
                          onSelected: (Menu item) {},
                          itemBuilder: (BuildContext context) => <PopupMenuEntry<Menu>>[
                            PopupMenuItem<Menu>(
                              value: Menu.edit,
                              onTap: widget.onEdit,
                              child: ListTile(
                                leading: Icon(Icons.edit_outlined),
                                title: Text('Edit'),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12),
                              ),
                            ),
                            PopupMenuItem<Menu>(
                              value: Menu.archive,
                              onTap: widget.onArchive,
                              child: ListTile(
                                leading: Icon(Icons.archive_outlined),
                                title: Text('Archive'),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12),
                              ),
                            ),
                            PopupMenuDivider(),
                            PopupMenuItem<Menu>(
                              value: Menu.remove,
                              onTap: widget.onRemove,
                              child: ListTile(
                                leading: Icon(Icons.delete_outline, color: color.error),
                                title: Text('Remove', style: TextStyle(color: color.error)),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                
                Spacer(),
                
                AnimatedBalance(
                  value: widget.totalBalance.toDouble(),
                  style: textTheme.headlineLarge?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                
                SizedBox(height: 16),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        widget.accountNumber,
                        style: textTheme.bodyLarge?.copyWith(
                          color: textColorWithAlpha,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.0,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: surfaceOverlay,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.accountType.name.toUpperCase(),
                        style: textTheme.labelSmall?.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              bottom: -20,
              right: -10,
              child: Icon(
                widget.accountType.icon,
                color: textColor.withValues(alpha: 0.1),
                size: 120.0,
              ),
            ),
          ],
        ),
    );
  }
}