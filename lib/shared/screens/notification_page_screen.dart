import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/notification_record.dart';
import 'package:mudra_manager/core/providers/notification_record_service.dart';
import 'package:mudra_manager/shared/widgets/no_data_found.dart';
import 'dart:convert';

final _dateFormatter = DateFormat('MMM dd, yyyy • hh:mm a');

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
            icon: const Icon(LucideIcons.checkCheck),
            onPressed: () async {
              HapticFeedback.mediumImpact();
              await notificationService.markAllAsRead();
            },
            tooltip: 'Mark all as read',
          ),
          IconButton(
            icon: const Icon(LucideIcons.trash2),
            onPressed: () {
              HapticFeedback.mediumImpact();
              notificationService.clearAllNotifications();
            },
            tooltip: 'Delete all',
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationRecord>>(
        stream: notificationService.watchNotifications(),
        builder: (context, snapshot) {
          final allData = snapshot.data ?? [];
          
          final urgent = allData.where((n) => !n.isArchived && n.priority == NotificationPriority.urgent).toList();
          final financial = allData.where((n) => !n.isArchived && n.category == NotificationCategory.financial && n.priority != NotificationPriority.urgent).toList();
          final trip = allData.where((n) => !n.isArchived && n.category == NotificationCategory.trip && n.priority != NotificationPriority.urgent).toList();
          final others = allData.where((n) => !n.isArchived && n.category == NotificationCategory.system).toList();

          final hasData = urgent.isNotEmpty || financial.isNotEmpty || trip.isNotEmpty || others.isNotEmpty;

          return CustomScrollView(
            slivers: [
              if (!hasData)
                const SliverFillRemaining(
                  child: NoDataFound(
                    message: 'No notifications yet.',
                    iconData: Icons.notifications_none_outlined,
                  ),
                )
              else ...[
                if (urgent.isNotEmpty) ..._buildSection(context, 'Urgent', urgent, color, textTheme, notificationService, isUrgent: true),
                if (financial.isNotEmpty) ..._buildSection(context, 'Financial', financial, color, textTheme, notificationService),
                if (trip.isNotEmpty) ..._buildSection(context, 'Trips', trip, color, textTheme, notificationService),
                if (others.isNotEmpty) ..._buildSection(context, 'Other', others, color, textTheme, notificationService),
              ],
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildSection(BuildContext context, String title, List<NotificationRecord> items, ColorScheme color, TextTheme textTheme, dynamic notificationService, {bool isUrgent = false}) {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              if (isUrgent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.circleAlert, size: 14, color: color.error),
                      const SizedBox(width: 4),
                      Text(
                        title.toUpperCase(),
                        style: textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color.error,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  title.toUpperCase(),
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildNotificationCard(context, items[index], color, textTheme, notificationService),
            childCount: items.length,
          ),
        ),
      ),
    ];
  }

  Widget _buildNotificationCard(BuildContext context, NotificationRecord n, ColorScheme color, TextTheme textTheme, dynamic notificationService) {
    final notifColor = _getColorForType(n.type, color);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(n.id.toString()),
        background: Container(
          decoration: BoxDecoration(
            color: color.error,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: Icon(LucideIcons.trash2, color: color.onError),
        ),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => notificationService.deleteNotification(n),
        child: Card(
          elevation: 0,
          color: n.isRead ? color.surfaceContainerLow : color.surfaceContainerHighest,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              HapticFeedback.lightImpact();
              _handleNotificationTap(context, n, notificationService);
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: notifColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_getIconForType(n.type), color: notifColor, size: 24),
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
                              style: textTheme.bodyMedium?.copyWith(color: color.onSurfaceVariant),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _dateFormatter.format(n.timestamp),
                              style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      if (!n.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: notifColor, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  if (n.primaryAction != null || n.secondaryAction != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (n.primaryAction != null)
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => _handlePrimaryAction(context, n, notificationService),
                              icon: Icon(_getActionIcon(n.type), size: 18),
                              label: Text(n.primaryAction!),
                              style: FilledButton.styleFrom(
                                backgroundColor: notifColor,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        if (n.primaryAction != null && n.secondaryAction != null) const SizedBox(width: 8),
                        if (n.secondaryAction != null)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _handleSecondaryAction(context, n, notificationService),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text(n.secondaryAction!),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleNotificationTap(BuildContext context, NotificationRecord n, dynamic notificationService) {
    notificationService.readNotification(record: n);
    if (n.tripId != null) {
      context.push('/trip-detail', extra: n.tripId);
    } else if (n.budgetId != null) {
      context.push('/budget-dashboard');
    }
  }

  void _handlePrimaryAction(BuildContext context, NotificationRecord n, dynamic notificationService) {
    HapticFeedback.mediumImpact();
    notificationService.readNotification(record: n);
    
    if (n.actionData != null) {
      try {
        final data = jsonDecode(n.actionData!) as Map<String, dynamic>;
        final actionType = data['type'] as String?;
        
        if (actionType == 'settle_up' && n.tripId != null) {
          context.push('/trip-detail', extra: n.tripId);
        } else if (actionType == 'view_expense' && n.expenseId != null && n.tripId != null) {
          context.push('/expense-detail', extra: {'expenseId': n.expenseId, 'tripId': n.tripId});
        } else if (actionType == 'view_budget') {
          context.push('/budget-dashboard');
        }
      } catch (_) {}
    }
    
    notificationService.deleteNotification(n);
  }

  void _handleSecondaryAction(BuildContext context, NotificationRecord n, dynamic notificationService) {
    HapticFeedback.lightImpact();
    notificationService.readNotification(record: n);
    
    if (n.tripId != null) {
      context.push('/trip-detail', extra: n.tripId);
    }
  }

  IconData _getActionIcon(String? type) {
    switch (type) {
      case 'pending_settlement': return LucideIcons.circleCheck;
      case 'new_expense': return LucideIcons.eye;
      case 'budget_alert': return LucideIcons.chartPie;
      default: return LucideIcons.arrowRight;
    }
  }

  Color _getColorForType(String? type, ColorScheme color) {
    switch (type) {
      case 'low_balance': return color.tertiary;
      case 'budget_overspent': return color.error;
      case 'budget_near_limit': return color.secondary;
      case 'pending_settlement': return Colors.red;
      case 'new_expense': return Colors.blue;
      case 'reminder': return color.primary;
      default: return color.primary;
    }
  }

  IconData _getIconForType(String? type) {
    switch (type) {
      case 'low_balance': return LucideIcons.creditCard;
      case 'budget_overspent': return LucideIcons.circleAlert;
      case 'budget_near_limit': return LucideIcons.triangleAlert;
      case 'pending_settlement': return LucideIcons.wallet;
      case 'new_expense': return LucideIcons.receipt;
      case 'reminder': return LucideIcons.clock;
      case 'achievement': return LucideIcons.trophy;
      case 'level_up': return LucideIcons.zap;
      case 'streak': return LucideIcons.flame;
      default: return LucideIcons.bell;
    }
  }
}
