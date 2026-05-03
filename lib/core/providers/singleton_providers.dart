import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/features/notifications/data/smart_notification_service.dart';
import 'package:mudra_manager/features/sms/data/recurring_detector_service.dart';
import 'package:mudra_manager/features/sms/data/sms_activity_service.dart';
import 'package:mudra_manager/features/sms/data/sms_processor_service.dart';
import 'package:mudra_manager/plugins/sms_parser_manager.dart';
import 'package:mudra_manager/plugins/export_plugin_manager.dart';
import 'package:mudra_manager/core/services/plugin_service.dart';

/// Wraps SmartNotificationService singleton for UI code.
/// Background tasks continue using SmartNotificationService.instance directly.
final smartNotificationServiceProvider = Provider<SmartNotificationService>(
  (ref) => SmartNotificationService.instance,
);

/// Wraps SmsActivityService singleton for UI code.
final smsActivityServiceProvider = Provider<SmsActivityService>(
  (ref) => SmsActivityService.instance,
);

/// Wraps SmsProcessorService singleton for UI code.
final smsProcessorServiceProvider = Provider<SmsProcessorService>(
  (ref) => SmsProcessorService.instance,
);

/// Wraps SmsParserManager singleton for UI code.
final smsParserManagerProvider = Provider<SmsParserManager>(
  (ref) => SmsParserManager.instance,
);

/// Wraps ExportPluginManager singleton for UI code.
final exportPluginManagerProvider = Provider<ExportPluginManager>(
  (ref) => ExportPluginManager.instance,
);

/// Wraps PluginService singleton for UI code.
final pluginServiceProvider = Provider<PluginService>(
  (ref) => PluginService(),
);

/// RecurringDetectorService with proper IsarService injection.
final recurringDetectorServiceProvider =
    Provider.autoDispose<RecurringDetectorService>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  return RecurringDetectorService(isarService);
});
