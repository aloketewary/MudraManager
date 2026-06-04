import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/widgets.dart';

enum GoalType {
  house,
  vehicle,
  travel,
  education,
  wedding,
  custom;

  IconData get icon => switch (this) {
        GoalType.house => LucideIcons.house,
        GoalType.vehicle => LucideIcons.car,
        GoalType.travel => LucideIcons.plane,
        GoalType.education => LucideIcons.graduationCap,
        GoalType.wedding => LucideIcons.heart,
        GoalType.custom => LucideIcons.target,
      };
}

enum GoalPriority {
  essential,
  important,
  optional,
}
