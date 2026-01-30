import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/db/models/notification_record.dart'
    show NotificationRecord;
import 'package:mudra_manager/providers/notification_record_service.dart';
import 'package:mudra_manager/screens/reusable/no_data_found.dart';

class NotificationPage extends ConsumerWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    final notificationService = ref.watch(notificationRecordServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications', style: textTheme.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () {
              notificationService.clearAllNotifications();
            },
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationRecord>>(
        stream: notificationService.watchNotifications(),
        builder: (context, snapshot) {
          final data = snapshot.data ?? [];
          if (data.isEmpty) {
            return NoDataFound(
              message: 'No notifications yet.',
              iconData: Icons.notifications_none_outlined,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final n = data[index];
              return ListTile(
                leading: Icon(
                  _getIconForType(n.type),
                  color: n.isRead ? color.secondary : color.primary,
                ),
                title: Text(
                  n.title,
                  style: textTheme.titleMedium?.copyWith(
                    color: n.isRead ? color.secondary : color.primary,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      n.body,
                      style: textTheme.labelLarge?.copyWith(
                        color: n.isRead ? color.secondary : color.primary,
                      ),
                    ),
                    Text(
                      DateFormat('dd-MM-yyyy hh:mm:ss a').format(n.timestamp),
                      style: textTheme.labelSmall?.copyWith(
                        color: n.isRead ? color.secondary : color.primary,
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  notificationService.readNotification(record: n);
                },
              );
            },
          );
        },
      ),
    );
  }

  IconData _getIconForType(String? type) {
    switch (type) {
      case 'low_balance':
        return Icons.account_balance_wallet_outlined;
      case 'budget_overspent':
        return Icons.warning_amber_outlined;
      case 'budget_near_limit':
        return Icons.track_changes_outlined;
      case 'reminder':
        return Icons.notifications_active_outlined;
      default:
        return Icons.notifications_none_outlined;
    }
  }
}
