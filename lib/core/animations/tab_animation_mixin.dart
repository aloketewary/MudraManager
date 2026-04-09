import 'package:flutter/widgets.dart';

/// Mixin for screens inside an IndexedStack that need entrance
/// animations each time their tab becomes visible.
mixin TabAnimationMixin<T extends StatefulWidget> on State<T> {
  Key _tabAnimKey = UniqueKey();

  void handleTabChange(bool isActive, bool wasActive) {
    if (isActive && !wasActive) {
      setState(() => _tabAnimKey = UniqueKey());
    }
  }

  /// Forces full widget rebuild — use for lightweight screens (Utility).
  Widget animatedTabContent(Widget child) {
    return KeyedSubtree(key: _tabAnimKey, child: child);
  }
}
