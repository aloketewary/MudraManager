import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/features/sms/data/notification_listener_service.dart';

final smsPermissionGrantedProvider =
    FutureProvider.autoDispose<bool>((ref) async {
  if (!Platform.isAndroid) return true;
  return NotificationListenerBridge.isPermissionGranted();
});
