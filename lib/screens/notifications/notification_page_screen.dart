import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notificationService = ref.watch(notificationRecordServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications', style: textTheme.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () {
              HapticFeedback.mediumImpact();
              notificationService.clearAllNotifications();
            },
            tooltip: 'Clear all',
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationRecord>>(
        stream: notificationService.watchNotifications(),
        builder: (context, snapshot) {
          final data = snapshot.data ?? [];
          final unreadCount = data.where((n) => !n.isRead).length;

          return CustomScrollView(
            slivers: [
              if (data.isEmpty)
                SliverFillRemaining(
                  child: NoDataFound(
                    message: 'No notifications yet.',
                    iconData: Icons.notifications_none_outlined,
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final n = data[index];
                      final notifColor = _getColorForType(n.type, color);
                      return Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Card(
                          elevation: 0,
                          color: color.surfaceContainerHighest,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              HapticFeedback.lightImpact();
                              notificationService.readNotification(record: n);
                            },
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: notifColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      _getIconForType(n.type),
                                      color: notifColor,
                                      size: 24,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          n.title,
                                          style: textTheme.titleMedium?.copyWith(
                                            fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          n.body,
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: color.onSurfaceVariant,
                                          ),
                                        ),
                                        SizedBox(height: 6),
                                        Text(
                                          DateFormat('MMM dd, yyyy • hh:mm a').format(n.timestamp),
                                          style: textTheme.bodySmall?.copyWith(
                                            color: color.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!n.isRead)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: notifColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }, childCount: data.length),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Color _getColorForType(String? type, ColorScheme color) {
    switch (type) {
      case 'low_balance':
        return color.tertiary;
      case 'budget_overspent':
        return color.error;
      case 'budget_near_limit':
        return color.secondary;
      case 'reminder':
        return color.primary;
      default:
        return color.primary;
    }
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
