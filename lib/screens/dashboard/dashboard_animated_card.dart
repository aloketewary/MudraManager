import 'package:flutter/material.dart';
import 'package:mudra_manager/db/models/account.dart' show AccountType;
import 'package:mudra_manager/util/account_type_extension.dart';

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

    return SizedBox(
      height: 250,
      width: 450,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.primary,
              color.primaryFixed,
              widget.accentColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      widget.accountName,
                      style: textTheme.titleLarge?.copyWith(
                        color: color.onPrimary,
                      ),
                    ),
                    PopupMenuButton<Menu>(
                      enabled: widget.showMenu,
                      popUpAnimationStyle: _animationStyle,
                      icon: Icon(
                        Icons.more_horiz,
                        color:
                            widget.showMenu
                                ? color.onPrimary
                                : Colors.transparent,
                      ),
                      onSelected: (Menu item) {},
                      itemBuilder:
                          (BuildContext context) => <PopupMenuEntry<Menu>>[
                            PopupMenuItem<Menu>(
                              value: Menu.edit,
                              onTap: widget.onEdit,
                              child: const ListTile(
                                leading: Icon(Icons.edit),
                                title: Text('Edit'),
                              ),
                            ),
                            PopupMenuItem<Menu>(
                              value: Menu.archive,
                              onTap: widget.onArchive,
                              child: ListTile(
                                leading: Icon(Icons.archive),
                                title: Text('Archive'),
                              ),
                            ),
                            const PopupMenuDivider(),
                            PopupMenuItem<Menu>(
                              value: Menu.remove,
                              onTap: widget.onRemove,
                              child: const ListTile(
                                leading: Icon(Icons.delete_outline),
                                title: Text('Remove'),
                              ),
                            ),
                          ],
                    ),
                  ],
                ),
                Text(
                  "₹${widget.totalBalance}",
                  style: textTheme.titleLarge?.copyWith(
                    color: color.onPrimary,
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      widget.accountNumber,
                      style: textTheme.titleSmall?.copyWith(
                        color: color.onPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              bottom: -25,
              right: -15,
              child: Icon(
                widget.accountType.icon,
                color: color.primary.withAlpha(50),
                size: 180.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
