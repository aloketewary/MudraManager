import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/notification_record.dart';
import 'package:mudra_manager/core/providers/notification_record_service.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/core/state/app_screen_state.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:mudra_manager/shared/templates/screen_shell.dart';
import 'package:mudra_manager/shared/widgets/no_data_found.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';

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

  Map<String, List<NotificationRecord>> _groupByTime(
    List<NotificationRecord> items,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo = today.subtract(const Duration(days: 7));

    final groups = <String, List<NotificationRecord>>{};
    for (final notification in items) {
      final date = DateTime(
        notification.timestamp.year,
        notification.timestamp.month,
        notification.timestamp.day,
      );
      final String key;
      if (date == today) {
        key = 'Today';
      } else if (date == yesterday) {
        key = 'Yesterday';
      } else if (date.isAfter(weekAgo)) {
        key = 'This Week';
      } else {
        key = 'Older';
      }
      (groups[key] ??= []).add(notification);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final notificationService = ref.watch(notificationRecordServiceProvider);

    return ScreenShell(
      config: const ScreenShellConfig(
        title: 'Notifications',
        appBarMode: AppBarMode.standard,
        enableRefresh: false,
      ),
      actions: ScreenActions.build(
        appBar: [
          ScreenAction(
            id: 'mark_all_read',
            label: 'Mark all read',
            icon: LucideIcons.checkCheck,
            onTap: () => notificationService.markAllAsRead(),
          ),
          ScreenAction(
            id: 'clear_all',
            label: 'Clear all',
            icon: LucideIcons.trash2,
            onTap: () => _confirmClearAll(context, notificationService),
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationRecord>>(
        stream: notificationService.watchNotifications(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(BuddyMessages.errorWith('${snapshot.error}')),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return _buildLoadingState(spacing);
          }

          return _buildNotificationList(
            snapshot.data ?? [],
            color,
            textTheme,
            spacing,
            notificationService,
          );
        },
      ),
    );
  }

  Widget _buildLoadingState(AppSpacing spacing) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontal,
        vertical: spacing.cardVertical,
      ),
      children: List.generate(
        4,
        (index) => const DashboardCardSkeleton(),
      ),
    );
  }

  Widget _buildNotificationList(
    List<NotificationRecord> all,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    dynamic notificationService,
  ) {
    final filtered = _applyFilter(all);
    final grouped = _groupByTime(filtered);
    final unreadAll = all.where((n) => !n.isArchived && !n.isRead).length;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        spacing.cardHorizontal,
        spacing.cardVertical,
        spacing.cardHorizontal,
        spacing.cardVertical + MediaQuery.of(context).padding.bottom,
      ),
      children: [
        _buildFilterBar(unreadAll, color, textTheme, spacing),
        SizedBox(height: spacing.sectionGap),
        if (filtered.isEmpty)
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.42,
            child: NoDataFound(
              message: _activeFilter == _FilterType.all
                  ? BuddyMessages.noNotifications
                  : BuddyMessages.noFilterResults(_activeFilter.name),
              iconData: LucideIcons.bellOff,
            ),
          )
        else
          ...grouped.entries.map(
            (entry) => _buildNotificationGroup(
              entry.key,
              entry.value,
              color,
              textTheme,
              spacing,
              notificationService,
            ),
          ),
      ],
    );
  }

  Widget _buildFilterBar(
    int unreadAll,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _FilterType.values.map((filter) {
          final isActive = _activeFilter == filter;
          final label = switch (filter) {
            _FilterType.all => 'All',
            _FilterType.financial => 'Financial',
            _FilterType.trip => 'Trips',
            _FilterType.system => 'System',
          };
          final icon = switch (filter) {
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
                  if (filter == _FilterType.all && unreadAll > 0) ...[
                    SizedBox(width: spacing.elementGapMin),
                    Text(
                      '$unreadAll',
                      style: textTheme.labelSmall?.copyWith(
                        color:
                            isActive ? color.primary : color.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ],
              ),
              avatar: Icon(icon, size: spacing.iconSM),
              selected: isActive,
              onSelected: (_) {
                HapticFeedback.selectionClick();
                setState(() => _activeFilter = filter);
              },
              showCheckmark: false,
              visualDensity: VisualDensity.compact,
              side: BorderSide(
                color: isActive
                    ? color.primary.withValues(alpha: 0.35)
                    : color.outlineVariant.withValues(alpha: 0.22),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNotificationGroup(
    String title,
    List<NotificationRecord> notifications,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    dynamic notificationService,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: spacing.sectionGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title,
            notifications.length,
            color,
            textTheme,
            spacing,
          ),
          SizedBox(height: spacing.elementGap),
          ...notifications.map(
            (notification) => Padding(
              padding: EdgeInsets.only(bottom: spacing.elementGap),
              child: _buildNotificationCard(
                notification,
                color,
                textTheme,
                spacing,
                notificationService,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    int count,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: spacing.elementGap,
            vertical: spacing.elementGapMin,
          ),
          decoration: BoxDecoration(
            color: color.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: color.primary.withValues(alpha: 0.16),
            ),
          ),
          child: Text(
            '$count',
            style: textTheme.labelSmall?.copyWith(
              color: color.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationCard(
    NotificationRecord notification,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    dynamic notificationService,
  ) {
    final notifColor = _getColorForType(notification.type, color);
    final isUrgent = notification.priority == NotificationPriority.urgent;
    final borderRadius = spacing.borderRadiusLarge;

    return Dismissible(
      key: Key(notification.id.toString()),
      background: Container(
        decoration: BoxDecoration(
          color: color.tertiary,
          borderRadius: borderRadius,
        ),
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(left: spacing.cardInner),
        child: Icon(LucideIcons.archive, color: color.onTertiary),
      ),
      secondaryBackground: Container(
        decoration: BoxDecoration(
          color: color.error,
          borderRadius: borderRadius,
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: spacing.cardInner),
        child: Icon(LucideIcons.trash2, color: color.onError),
      ),
      confirmDismiss: (direction) async {
        HapticFeedback.mediumImpact();
        if (direction == DismissDirection.startToEnd) {
          await notificationService.archiveNotification(notification);
        } else {
          await notificationService.deleteNotification(notification);
        }
        return true;
      },
      child: _AnimatedNotificationTile(
        semanticLabel: notification.title,
        borderRadius: borderRadius,
        onTap: () {
          HapticFeedback.lightImpact();
          _handleNotificationTap(context, notification, notificationService);
        },
        child: Container(
          padding: EdgeInsets.all(spacing.cardInner),
          decoration: BoxDecoration(
            color: color.surfaceContainerHigh,
            borderRadius: borderRadius,
            border: Border.all(
              color: isUrgent
                  ? color.error.withValues(alpha: 0.45)
                  : notification.isRead
                      ? color.outlineVariant.withValues(alpha: 0.22)
                      : notifColor.withValues(alpha: 0.35),
              width: isUrgent ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: spacing.touchTargetSmall,
                    height: spacing.touchTargetSmall,
                    decoration: BoxDecoration(
                      color: notifColor.withValues(alpha: 0.12),
                      borderRadius: spacing.borderRadiusMedium,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      _getIconForType(notification.type),
                      color: notifColor,
                      size: spacing.iconSM,
                    ),
                  ),
                  SizedBox(width: spacing.elementGap),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: textTheme.titleSmall?.copyWith(
                                  fontWeight: notification.isRead
                                      ? FontWeight.w500
                                      : FontWeight.w700,
                                ),
                              ),
                            ),
                            if (!notification.isRead)
                              Container(
                                width: spacing.elementGapMin,
                                height: spacing.elementGapMin,
                                decoration: BoxDecoration(
                                  color: notifColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: spacing.elementGapMin),
                        Text(
                          notification.body,
                          style: textTheme.bodySmall?.copyWith(
                            color: color.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: spacing.elementGapMin),
                        Text(
                          _formatTimestamp(notification.timestamp),
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
              if (notification.primaryAction != null ||
                  notification.secondaryAction != null) ...[
                SizedBox(height: spacing.elementGap + 4),
                Row(
                  children: [
                    if (notification.primaryAction != null)
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed: () => _handlePrimaryAction(
                            context,
                            notification,
                            notificationService,
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: notifColor.withValues(alpha: 0.12),
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
                            notification.primaryAction!,
                            style: textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    if (notification.primaryAction != null &&
                        notification.secondaryAction != null)
                      SizedBox(width: spacing.elementGap),
                    if (notification.secondaryAction != null)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _handleSecondaryAction(
                            context,
                            notification,
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
                            notification.secondaryAction!,
                            style: textTheme.labelLarge,
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
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return _timeFormat.format(timestamp);
    return '${_dateFormat.format(timestamp)} · ${_timeFormat.format(timestamp)}';
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
    NotificationRecord notification,
    dynamic notificationService,
  ) {
    notificationService.readNotification(record: notification);
    if (notification.tripId != null) {
      context.push(AppRoutes.tripDetail, extra: notification.tripId);
    } else if (notification.budgetId != null) {
      context.push(AppRoutes.budgetDashboard);
    }
  }

  void _handlePrimaryAction(
    BuildContext context,
    NotificationRecord notification,
    dynamic notificationService,
  ) {
    HapticFeedback.mediumImpact();
    notificationService.readNotification(record: notification);

    if (notification.actionData != null) {
      try {
        final data =
            jsonDecode(notification.actionData!) as Map<String, dynamic>;
        switch (data['type'] as String?) {
          case 'settle_up':
            if (notification.tripId != null) {
              context.push(AppRoutes.tripDetail, extra: notification.tripId);
            }
          case 'view_expense':
            if (notification.expenseId != null && notification.tripId != null) {
              context.push(
                AppRoutes.expenseDetail,
                extra: {
                  'expenseId': notification.expenseId,
                  'tripId': notification.tripId,
                },
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
      switch (notification.category) {
        case NotificationCategory.budget:
          context.push(AppRoutes.budgetDashboard);
        case NotificationCategory.trip:
          if (notification.tripId != null) {
            context.push(
              AppRoutes.tripDetail,
              extra: notification.tripId,
            );
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
    NotificationRecord notification,
    dynamic notificationService,
  ) {
    HapticFeedback.lightImpact();
    notificationService.readNotification(record: notification);
    if (notification.tripId != null) {
      context.push(AppRoutes.tripDetail, extra: notification.tripId);
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

class _AnimatedNotificationTile extends StatefulWidget {
  final String semanticLabel;
  final BorderRadius borderRadius;
  final VoidCallback onTap;
  final Widget child;

  const _AnimatedNotificationTile({
    required this.semanticLabel,
    required this.borderRadius,
    required this.onTap,
    required this.child,
  });

  @override
  State<_AnimatedNotificationTile> createState() =>
      _AnimatedNotificationTileState();
}

class _AnimatedNotificationTileState extends State<_AnimatedNotificationTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final child = Semantics(
      container: true,
      button: true,
      label: widget.semanticLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: widget.borderRadius,
          onTap: widget.onTap,
          onTapDown: reduceMotion ? null : (_) => _controller.forward(),
          onTapUp: reduceMotion ? null : (_) => _controller.reverse(),
          onTapCancel: reduceMotion ? null : _controller.reverse,
          child: widget.child,
        ),
      ),
    );

    if (reduceMotion) return child;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, animatedChild) => Transform.scale(
        scale: _scaleAnimation.value,
        alignment: Alignment.center,
        child: animatedChild,
      ),
      child: child,
    );
  }
}
