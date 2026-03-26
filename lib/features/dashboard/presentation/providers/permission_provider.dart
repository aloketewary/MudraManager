import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

final smsPermissionGrantedProvider =
    FutureProvider.autoDispose<bool>((ref) async {
  if (!Platform.isAndroid) return true; // Don't show on iOS
  final status = await Permission.sms.status;
  return status.isGranted;
});
