import 'dart:convert';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/sms_activity.dart';
import 'package:mudra_manager/core/tone/tone_provider.dart';
import 'package:mudra_manager/features/notifications/data/smart_check.dart';

class PendingSmsCheck extends SmartCheck {
  @override
  String get type => 'pending_sms';

  @override
  Future<void> run() async {
    final isar = await IsarService().getInstance();
    final pendingCount = await isar.smsActivitys
        .filter()
        .statusEqualTo(ActivityStatus.pending)
        .or()
        .statusEqualTo(ActivityStatus.needsReview)
        .or()
        .statusEqualTo(ActivityStatus.duplicate)
        .count();

    if (pendingCount > 0) {
      await SmartNotificationEmitter.emit(
        isar,
        type: type,
        title: Tone.appL10n?.notif_smsFoundTitle(pendingCount) ??
            '📱 $pendingCount SMS transactions found',
        body: Tone.current.pendingSmsNotif(pendingCount),
        channel: 'pending_transactions',
        channelName: 'Pending Transactions',
        primaryAction: 'Review',
        actionData: jsonEncode({'type': 'view_sms'}),
      );
    }
  }
}
