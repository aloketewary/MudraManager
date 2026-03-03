import 'package:mudra_manager/core/db/models/transaction.dart';

/// Base class for notification plugins
abstract class NotificationPlugin {
  String get id;
  String get name;
  String get description;
  String get version;
  String get iconPath;

  /// Called when plugin is loaded
  void onLoad() {}

  /// Called when plugin is started
  void onStart() {}

  /// Called when plugin is stopped
  void onStop() {}

  /// Check if this plugin should trigger for the given transaction
  bool shouldTrigger(Transaction transaction);

  /// Get notification title
  String getTitle(Transaction transaction);

  /// Get notification body
  String getBody(Transaction transaction);

  /// Get notification priority (0-5, higher = more important)
  int getPriority() => 3;

  /// Get custom configuration for this plugin
  Map<String, dynamic>? getConfig() => null;
}

/// Context passed to notification plugins
class NotificationContext {
  final Transaction transaction;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  NotificationContext({
    required this.transaction,
    required this.timestamp,
    this.metadata = const {},
  });
}
