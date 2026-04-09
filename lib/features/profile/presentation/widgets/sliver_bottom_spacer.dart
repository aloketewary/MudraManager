import 'package:flutter/material.dart';

class SliverBottomSpacer extends StatelessWidget {
  final double extra;
  const SliverBottomSpacer({super.key, this.extra = 16});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: MediaQuery.of(context).padding.bottom +
            kBottomNavigationBarHeight +
            extra,
      ),
    );
  }
}

class BottomSpacer extends StatelessWidget {
  final double extra;
  const BottomSpacer({super.key, this.extra = 16});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).padding.bottom +
          kBottomNavigationBarHeight +
          extra,
    );
  }
}
