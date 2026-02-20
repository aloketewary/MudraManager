import 'package:flutter/material.dart';

class ResponsiveLayoutBuilder extends StatelessWidget {
  final Widget columnWidget;
  final Widget rowWidget;

  const ResponsiveLayoutBuilder({
    super.key,
    required this.columnWidget,
    required this.rowWidget,
  });

  @override
  Widget build(BuildContext context) {
    final isLargeText = MediaQuery.textScalerOf(context).scale(14) > 18;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final isNarrow = constraints.maxWidth < 350;
        if (isLargeText || isNarrow) {
          return columnWidget;
        } else {
          return rowWidget;
        }
      },
    );
  }
}
