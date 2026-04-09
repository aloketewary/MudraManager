import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Base interface for all dashboard widgets
abstract class DashboardWidgetPlugin {
  /// Unique widget identifier
  String get id;

  /// Display title
  String get title;

  /// Widget icon
  IconData get icon;

  /// Default order in dashboard (lower = higher)
  int get defaultOrder;

  /// Widget category
  WidgetCategory get category;

  /// Can this widget be resized?
  bool get isResizable => false;

  /// Default size
  WidgetSize get defaultSize => WidgetSize.medium;

  /// Can this widget be disabled by user?
  bool get canBeDisabled => true;

  /// Is this widget visible by default?
  bool get defaultVisible => true;

  /// Is this a premium widget?
  bool get isPremium => false;

  /// Widget description
  String get description => '';

  /// Check if widget should be visible (dynamic visibility)
  bool isVisible(WidgetRef ref) => true;

  /// Build the widget
  Widget build(BuildContext context, WidgetRef ref);

  /// Optional: Widget settings
  Widget? buildSettings(BuildContext context, WidgetRef ref) => null;

  /// Optional: Handle widget tap
  void onTap(BuildContext context, WidgetRef ref) {}

  /// Optional: Refresh widget data
  Future<void> refresh(WidgetRef ref) async {}
}

enum WidgetCategory {
  essential, // Accounts, Cash Flow
  finance, // Budget, Goals
  analytics, // Charts, Predictions
  actions, // Quick Actions
  ai, // AI Insights
  contextual, // Alerts, Warnings
  custom, // User-created
}

enum WidgetSize {
  small, // 1x height
  medium, // 2x height
  large, // 3x height
  full, // Full width + custom height
}
