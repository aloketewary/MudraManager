import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/db/models/notification_record.dart'
    show NotificationRecord;
import 'package:mudra_manager/providers/notification_record_service.dart';
import 'package:mudra_manager/screens/reusable/no_data_found.dart';
import 'package:mudra_manager/theme/app_colors.dart';

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
                      final notifColor = _getColorForType(n.type);
                      return Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: AppColors.glassGradient(
                                notifColor,
                                isDark,
                              ),
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: notifColor.withValues(
                                alpha: n.isRead ? 0.2 : 0.3,
                              ),
                              width: 1.5,
                            ),
                            boxShadow: AppColors.glassShadow(
                              notifColor,
                              isDark,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            leading: Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: color.surface,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: notifColor.withValues(alpha: 0.15),
                                    blurRadius: 12,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                _getIconForType(n.type),
                                color: notifColor,
                                size: 24,
                              ),
                            ),
                            title: Text(
                              n.title,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight:
                                    n.isRead
                                        ? FontWeight.w500
                                        : FontWeight.w600,
                                color: notifColor.withValues(
                                  alpha: n.isRead ? 0.7 : 1,
                                ),
                                letterSpacing: -0.2,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 4),
                                Text(
                                  n.body,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: notifColor.withValues(
                                      alpha: n.isRead ? 0.6 : 0.75,
                                    ),
                                    fontSize: 13,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  DateFormat(
                                    'MMM dd, yyyy • hh:mm a',
                                  ).format(n.timestamp),
                                  style: textTheme.bodySmall?.copyWith(
                                    color: notifColor.withValues(alpha: 0.5),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            trailing:
                                !n.isRead
                                    ? Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: notifColor,
                                        shape: BoxShape.circle,
                                      ),
                                    )
                                    : null,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              notificationService.readNotification(record: n);
                            },
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

  Color _getColorForType(String? type) {
    switch (type) {
      case 'low_balance':
        return Color(0xFFF59E0B);
      case 'budget_overspent':
        return AppColors.expense;
      case 'budget_near_limit':
        return Color(0xFFF59E0B);
      case 'reminder':
        return Color(0xFF6366F1);
      default:
        return Color(0xFF06B6D4);
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
