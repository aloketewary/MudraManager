import 'package:mudra_manager/core/tone/tone_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/extension/account_type_extenstion.dart';
import 'package:mudra_manager/core/utils/string_util.dart';
import 'package:mudra_manager/shared/widgets/animated_balance.dart';

class _ChipPainter extends CustomPainter {
  final Color color;

  _ChipPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw grid pattern (4x3)
    for (int i = 1; i < 4; i++) {
      // Vertical lines
      canvas.drawLine(
        Offset(size.width * i / 4, 6),
        Offset(size.width * i / 4, size.height - 6),
        paint,
      );
    }

    for (int i = 1; i < 3; i++) {
      // Horizontal lines
      canvas.drawLine(
        Offset(6, size.height * i / 3),
        Offset(size.width - 6, size.height * i / 3),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

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
  AnimationStyle? _animationStyle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;

    final accentLuminance = widget.accentColor.computeLuminance();
    final textColor = accentLuminance > 0.5 ? Colors.black : Colors.white;
    final textColorWithAlpha = textColor.withValues(alpha: 0.85);

    return Container(
      height: 220,
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.accentColor,
            widget.accentColor.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(Tone.current.borderRadius),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: textColor.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: textColor.withValues(alpha: 0.06),
              ),
            ),
          ),

          // Card content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with chip and menu
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Chip icon
                    Container(
                      width: 50,
                      height: 40,
                      decoration: BoxDecoration(
                        color: textColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: textColor.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: CustomPaint(painter: _ChipPainter(textColor)),
                    ),
                    if (widget.showMenu)
                      Container(
                        decoration: BoxDecoration(
                          color: textColor.withValues(alpha: 0.15),
                          borderRadius:
                              BorderRadius.circular(Tone.current.borderRadius),
                        ),
                        child: PopupMenuButton<Menu>(
                          popUpAnimationStyle: _animationStyle,
                          icon: Icon(
                            LucideIcons.ellipsisVertical,
                            color: textColor,
                            size: 20,
                          ),
                          onSelected: (Menu item) {},
                          itemBuilder: (BuildContext context) =>
                              <PopupMenuEntry<Menu>>[
                            PopupMenuItem<Menu>(
                              value: Menu.edit,
                              onTap: widget.onEdit,
                              child: const ListTile(
                                leading: Icon(LucideIcons.pencil),
                                title: Text('Edit'),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                              ),
                            ),
                            PopupMenuItem<Menu>(
                              value: Menu.archive,
                              onTap: widget.onArchive,
                              child: const ListTile(
                                leading: Icon(LucideIcons.archive),
                                title: Text('Archive'),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                              ),
                            ),
                            const PopupMenuDivider(),
                            PopupMenuItem<Menu>(
                              value: Menu.remove,
                              onTap: widget.onRemove,
                              child: ListTile(
                                leading: Icon(
                                  LucideIcons.trash2,
                                  color: color.error,
                                ),
                                title: Text(
                                  'Remove',
                                  style: TextStyle(color: color.error),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                const Spacer(),

                // Balance
                AnimatedBalance(
                  value: widget.totalBalance.toDouble(),
                  style: textTheme.headlineLarge?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 32,
                    letterSpacing: -0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 2),

                Text(
                  'Current Balance',
                  style: textTheme.labelSmall?.copyWith(
                    color: textColorWithAlpha,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 16),

                // Footer with card number and type
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.accountNumber,
                            style: textTheme.bodyMedium?.copyWith(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2.0,
                              fontFamily: AppTheme.monoFontFamily,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.accountName,
                            style: textTheme.labelMedium?.copyWith(
                              color: textColorWithAlpha,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      widget.accountType.icon,
                      color: textColor.withValues(alpha: 0.9),
                      size: 28,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
