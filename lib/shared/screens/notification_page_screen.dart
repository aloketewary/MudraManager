import 'package:mudra_manager/core/tone/tone_provider.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/notification_record.dart';
import 'package:mudra_manager/core/providers/notification_record_service.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/shared/widgets/no_data_found.dart';
import 'dart:convert';

final _timeFormat = DateFormat('hh:mm a');
final _dateFormat = DateFormat('MMM dd');

enum _FilterType { all, financial, trip, system }

class NotificationPage extends ConsumerStatefulWidget {
  const NotificationPage({super.key});

  @override
  ConsumerState<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends ConsumerState<NotificationPage> {
  _FilterType _activeFilter = _FilterType.all;

  List<NotificationRecord> _applyFilter(List<NotificationRecord> all) {
    final visible = all.where((n) => !n.isArchived).toList();
    return switch (_activeFilter) {
      _FilterType.all => visible,
      _FilterType.financial => visible
          .where(
            (n) =>
                n.category == NotificationCategory.financial ||
                n.category == NotificationCategory.budget,
          )
          .toList(),
      _FilterType.trip =>
        visible.where((n) => n.category == NotificationCategory.trip).toList(),
      _FilterType.system => visible
          .where((n) => n.category == NotificationCategory.system)
          .toList(),
    };
  }

  // Group by: Today, Yesterday, This Week, Older
  Map<String, List<NotificationRecord>> _groupByTime(
    List<NotificationRecord> items,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo = today.subtract(const Duration(days: 7));

    final groups = <String, List<NotificationRecord>>{};
    for (final n in items) {
      final d = DateTime(n.timestamp.year, n.timestamp.month, n.timestamp.day);
      final String key;
      if (d == today) {
        key = 'Today';
      } else if (d == yesterday) {
        key = 'Yesterday';
      } else if (d.isAfter(weekAgo)) {
        key = 'This Week';
      } else {
        key = 'Older';
      }
      (groups[key] ??= []).add(n);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final notificationService = ref.watch(notificationRecordServiceProvider);

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.checkCheck, size: 20),
            onPressed: () {
              HapticFeedback.mediumImpact();
              notificationService.markAllAsRead();
            },
            tooltip: 'Mark all read',
          ),
          IconButton(
            icon: const Icon(LucideIcons.trash2, size: 20),
            onPressed: () => _confirmClearAll(context, notificationService),
            tooltip: 'Clear all',
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationRecord>>(
        stream: notificationService.watchNotifications(),
        builder: (context, snapshot) {
          final all = snapshot.data ?? [];
          final filtered = _applyFilter(all);
          final grouped = _groupByTime(filtered);
          final hasData = filtered.isNotEmpty;

          // Unread count per filter for chips
          final unreadAll = all.where((n) => !n.isArchived && !n.isRead).length;

          return Column(
            children: [
              // ── Filter chips ──
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.cardHorizontalMax,
                  ),
                  children: _FilterType.values.map((f) {
                    final isActive = _activeFilter == f;
                    final label = switch (f) {
                      _FilterType.all => 'All',
                      _FilterType.financial => 'Financial',
                      _FilterType.trip => 'Trips',
                      _FilterType.system => 'System',
                    };
                    final icon = switch (f) {
                      _FilterType.all => LucideIcons.bell,
                      _FilterType.financial => LucideIcons.wallet,
                      _FilterType.trip => LucideIcons.plane,
                      _FilterType.system => LucideIcons.settings,
                    };
                    return Padding(
                      padding: EdgeInsets.only(right: spacing.elementGap),
                      child: FilterChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(label),
                            if (f == _FilterType.all && unreadAll > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: isActive ? color.onPrimary : color.primary,
                                  borderRadius: BorderRadius.circular(spacing.radiusSmall),
                                ),
                                child: Text(
                                  '$unreadAll',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: isActive ? color.primary : color.onPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        avatar: Icon(icon, size: 16),
                        selected: isActive,
                        onSelected: (_) {
                          HapticFeedback.selectionClick();
                          setState(() => _activeFilter = f);
                        },
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                      ),
                    );
                  }).toList(),
                ),
              ),

              // ── Notification list ──
              Expanded(
                child: !hasData
                    ? NoDataFound(
                        message: _activeFilter == _FilterType.all
                            ? BuddyMessages.noNotifications
                            : BuddyMessages.noFilterResults(_activeFilter.name),
                        iconData: LucideIcons.bellOff,
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: spacing.cardHorizontalMax,
                          vertical: spacing.cardVertical,
                        ),
                        itemCount: _countItems(grouped),
                        itemBuilder: (context, index) {
                          final item = _itemAt(grouped, index);
                          if (item is String) {
                            return _buildSectionHeader(
                              item,
                              color,
                              textTheme,
                              spacing,
                            );
                          }
                          return _buildNotificationCard(
                            item as NotificationRecord,
                            color,
                            textTheme,
                            spacing,
                            notificationService,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Flatten grouped map into a list of headers (String) and items
  int _countItems(Map<String, List<NotificationRecord>> grouped) {
    int count = 0;
    for (final entry in grouped.entries) {
      count += 1 + entry.value.length; // header + items
    }
    return count;
  }

  dynamic _itemAt(Map<String, List<NotificationRecord>> grouped, int index) {
    int i = 0;
    for (final entry in grouped.entries) {
      if (i == index) return entry.key; // section header
      i++;
      if (index < i + entry.value.length) return entry.value[index - i];
      i += entry.value.length;
    }
    return '';
  }

  Widget _buildSectionHeader(
    String title,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Padding(
      padding: EdgeInsets.only(
        top: spacing.sectionGap,
        bottom: spacing.elementGap,
      ),
      child: Text(
        title.toUpperCase(),
        style: textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: color.onSurfaceVariant,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
    NotificationRecord n,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    dynamic notificationService,
  ) {
    final notifColor = _getColorForType(n.type, color);
    final isUrgent = n.priority == NotificationPriority.urgent;

    return Padding(
      padding: EdgeInsets.only(bottom: spacing.elementGap),
      child: Dismissible(
        key: Key(n.id.toString()),
        // Swipe right → archive
        background: Container(
          decoration: BoxDecoration(
            color: color.tertiary,
            borderRadius: BorderRadius.circular(spacing.radiusMedium),
          ),
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.only(left: spacing.cardInner),
          child: Icon(LucideIcons.archive, color: color.onTertiary),
        ),
        // Swipe left → delete
        secondaryBackground: Container(
          decoration: BoxDecoration(
            color: color.error,
            borderRadius: BorderRadius.circular(spacing.radiusMedium),
          ),
          alignment: Alignment.centerRight,
          padding: EdgeInsets.only(right: spacing.cardInner),
          child: Icon(LucideIcons.trash2, color: color.onError),
        ),
        confirmDismiss: (direction) async {
          HapticFeedback.mediumImpact();
          if (direction == DismissDirection.startToEnd) {
            await notificationService.archiveNotification(n);
            return true;
          } else {
            await notificationService.deleteNotification(n);
            return true;
          }
        },
        child: InkWell(
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          onTap: () {
            HapticFeedback.lightImpact();
            _handleNotificationTap(context, n, notificationService);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.all(spacing.cardInner),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  n.isRead
                      ? color.surfaceContainerLow
                      : notifColor.withValues(alpha: 0.06),
                  n.isRead
                      ? color.surfaceContainerLow
                      : notifColor.withValues(alpha: 0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
              border: Border.all(
                color: isUrgent
                    ? color.error.withValues(alpha: 0.4)
                    : n.isRead
                        ? color.outlineVariant.withValues(alpha: 0.15)
                        : notifColor.withValues(alpha: 0.2),
                width: isUrgent ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon
                    Container(
                      padding: EdgeInsets.all(spacing.cardHorizontal),
                      decoration: BoxDecoration(
                        color: notifColor.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(spacing.radiusSmall),
                      ),
                      child: Icon(
                        _getIconForType(n.type),
                        color: notifColor,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: spacing.elementGap + 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  n.title,
                                  style: textTheme.titleSmall?.copyWith(
                                    fontWeight: n.isRead
                                        ? FontWeight.w500
                                        : FontWeight.w700,
                                  ),
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
                          SizedBox(height: spacing.elementGapMin),
                          Text(
                            n.body,
                            style: textTheme.bodySmall?.copyWith(
                              color: color.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: spacing.elementGapMin),
                          Text(
                            _formatTimestamp(n.timestamp),
                            style: textTheme.labelSmall?.copyWith(
                              color:
                                  color.onSurfaceVariant.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Action buttons
                if (n.primaryAction != null || n.secondaryAction != null) ...[
                  SizedBox(height: spacing.elementGap + 4),
                  Row(
                    children: [
                      if (n.primaryAction != null)
                        Expanded(
                          child: FilledButton.tonal(
                            onPressed: () => _handlePrimaryAction(
                              context,
                              n,
                              notificationService,
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor:
                                  notifColor.withValues(alpha: 0.12),
                              foregroundColor: notifColor,
                              padding: EdgeInsets.symmetric(
                                vertical: spacing.cardVertical,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  spacing.radiusSmall,
                                ),
                              ),
                            ),
                            child: Text(
                              n.primaryAction!,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      if (n.primaryAction != null && n.secondaryAction != null)
                        SizedBox(width: spacing.elementGap),
                      if (n.secondaryAction != null)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _handleSecondaryAction(
                              context,
                              n,
                              notificationService,
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                vertical: spacing.cardVertical,
                              ),
                              side: BorderSide(
                                color:
                                    color.outlineVariant.withValues(alpha: 0.3),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  spacing.radiusSmall,
                                ),
                              ),
                            ),
                            child: Text(
                              n.secondaryAction!,
                              style: const TextStyle(fontSize: 13),
                            ),
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
    );
  }

  String _formatTimestamp(DateTime ts) {
    final now = DateTime.now();
    final diff = now.difference(ts);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return _timeFormat.format(ts);
    return '${_dateFormat.format(ts)} · ${_timeFormat.format(ts)}';
  }

  void _confirmClearAll(BuildContext context, dynamic notificationService) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all notifications?'),
        content: Text(BuddyMessages.deleteMessage(null)),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              notificationService.clearAllNotifications();
              ctx.pop();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(
    BuildContext context,
    NotificationRecord n,
    dynamic notificationService,
  ) {
    notificationService.readNotification(record: n);
    if (n.tripId != null) {
      context.push(AppRoutes.tripDetail, extra: n.tripId);
    } else if (n.budgetId != null) {
      context.push(AppRoutes.budgetDashboard);
    }
  }

  void _handlePrimaryAction(
    BuildContext context,
    NotificationRecord n,
    dynamic notificationService,
  ) {
    HapticFeedback.mediumImpact();
    notificationService.readNotification(record: n);

    if (n.actionData != null) {
      try {
        final data = jsonDecode(n.actionData!) as Map<String, dynamic>;
        switch (data['type'] as String?) {
          case 'settle_up':
            if (n.tripId != null) {
              context.push(AppRoutes.tripDetail, extra: n.tripId);
            }
          case 'view_expense':
            if (n.expenseId != null && n.tripId != null) {
              context.push(
                AppRoutes.expenseDetail,
                extra: {'expenseId': n.expenseId, 'tripId': n.tripId},
              );
            }
          case 'view_budget':
            context.push(AppRoutes.budgetDashboard);
          case 'view_bills':
            context.push(AppRoutes.recurringTransactions);
          case 'view_accounts':
            context.push(AppRoutes.manageAccounts);
          case 'view_sms':
            context.push(AppRoutes.smsActivity);
          case 'view_goals':
            context.push(AppRoutes.goalScreen);
        }
      } catch (_) {}
    } else {
      // Fallback: route by notification category
      switch (n.category) {
        case NotificationCategory.budget:
          context.push(AppRoutes.budgetDashboard);
        case NotificationCategory.trip:
          if (n.tripId != null) {
            context.push(AppRoutes.tripDetail, extra: n.tripId);
          }
        case NotificationCategory.financial:
          context.push(AppRoutes.statistics);
        default:
          break;
      }
    }
  }

  void _handleSecondaryAction(
    BuildContext context,
    NotificationRecord n,
    dynamic notificationService,
  ) {
    HapticFeedback.lightImpact();
    notificationService.readNotification(record: n);
    if (n.tripId != null) {
      context.push(AppRoutes.tripDetail, extra: n.tripId);
    }
  }

  Color _getColorForType(String? type, ColorScheme color) {
    return switch (type) {
      'low_balance' => color.tertiary,
      'budget_overspent' => color.error,
      'budget_near_limit' => color.secondary,
      'pending_settlement' => FinanceColors.statusDanger,
      'new_expense' => Colors.blue,
      'reminder' => color.primary,
      'achievement' => Colors.amber,
      'level_up' => Colors.deepPurple,
      'streak' => FinanceColors.statusWarning,
      _ => color.primary,
    };
  }

  IconData _getIconForType(String? type) {
    return switch (type) {
      'low_balance' => LucideIcons.creditCard,
      'budget_overspent' => LucideIcons.circleAlert,
      'budget_near_limit' => LucideIcons.triangleAlert,
      'pending_settlement' => LucideIcons.wallet,
      'new_expense' => LucideIcons.receipt,
      'reminder' => LucideIcons.clock,
      'achievement' => LucideIcons.trophy,
      'level_up' => LucideIcons.zap,
      'streak' => LucideIcons.flame,
      _ => LucideIcons.bell,
    };
  }
}
