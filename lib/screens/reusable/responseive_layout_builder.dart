import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

class ResponsiveLayoutBuilder extends StatelessWidget {
  final Widget columnWidget;
  final Widget rowWidget;
  final double sizedBoxHeight;

  const ResponsiveLayoutBuilder({
    super.key,
    required this.columnWidget,
    required this.rowWidget,
    required this.sizedBoxHeight,
  });

  @override
  Widget build(BuildContext context) {
    final isLargeText = MediaQuery.textScalerOf(context).scale(14) > 18;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final isNarrow = constraints.maxWidth < 350;
        if (isLargeText || isNarrow) {
          return SizedBox(height: sizedBoxHeight, child: columnWidget);
        } else {
          return rowWidget;
        }
      },
    );
  }
}
