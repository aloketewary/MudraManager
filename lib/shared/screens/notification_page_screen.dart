import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/core/db/models/notification_record.dart';
import 'package:mudra_manager/core/providers/notification_record_service.dart';
import 'package:mudra_manager/shared/widgets/no_data_found.dart';


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

          return CustomScrollView(
            slivers: [
              if (data.isEmpty)
                const SliverFillRemaining(
                  child: NoDataFound(
                    message: 'No notifications yet.',
                    iconData: Icons.notifications_none_outlined,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final n = data[index];
                      final notifColor = _getColorForType(n.type, color);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
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
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
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
                                  const SizedBox(width: 16),
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
                                        const SizedBox(height: 4),
                                        Text(
                                          n.body,
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: color.onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
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
        return Icons.credit_card_off_rounded;
      case 'budget_overspent':
        return Icons.error_outline_rounded;
      case 'budget_near_limit':
        return Icons.warning_amber_rounded;
      case 'reminder':
        return Icons.access_time_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }
}
