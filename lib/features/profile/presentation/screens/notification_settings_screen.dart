// lib/features/profile/presentation/screens/notification_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/services/notification_service.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  bool _dailySummaryEnabled = false;
  bool _weeklySummaryEnabled = true;
  bool _streakReminderEnabled = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _streakReminderTime = const TimeOfDay(hour: 20, minute: 0);
  int _weeklyDay = DateTime.sunday;
  bool _loaded = false;
  bool _reEngagementEnabled = true;
  bool _smartAlertsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final results = await Future.wait([
      SharedPreferences.getInstance(),
      NotificationService.getSavedReminderTime(),
      NotificationService.getSavedStreakReminderTime(),
    ]);
    if (!mounted) return;
    final prefs = results[0] as SharedPreferences;
    _reEngagementEnabled = prefs.getBool('re_engagement_enabled') ?? true;
    setState(() {
      _dailySummaryEnabled = prefs.getBool('daily_summary_enabled') ?? false;
      _weeklySummaryEnabled = prefs.getBool('weekly_summary_enabled') ?? true;
      _streakReminderEnabled = prefs.getBool('streak_reminder_enabled') ?? true;
      _weeklyDay = prefs.getInt('weekly_summary_day') ?? DateTime.sunday;
      _reminderTime =
          (results[1] as TimeOfDay?) ?? const TimeOfDay(hour: 9, minute: 0);
      _streakReminderTime =
          (results[2] as TimeOfDay?) ?? const TimeOfDay(hour: 20, minute: 0);
      _loaded = true;
    });
  }

  Future<void> _toggleDailySummary(bool enabled) async {
    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('daily_summary_enabled', enabled);
    if (enabled) {
      await NotificationService.scheduleDailyReminder(_reminderTime);
      SnackbarService.success('Daily summary enabled');
    } else {
      await NotificationService.cancelReminder();
      SnackbarService.success('Daily summary disabled');
    }
    setState(() => _dailySummaryEnabled = enabled);
  }

  Future<void> _toggleWeeklySummary(bool enabled) async {
    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('weekly_summary_enabled', enabled);
    if (enabled) {
      await NotificationService.scheduleWeeklySummary(_weeklyDay);
      SnackbarService.success('Weekly summary enabled');
    } else {
      SnackbarService.success('Weekly summary disabled');
    }
    setState(() => _weeklySummaryEnabled = enabled);
  }

  Future<void> _toggleStreakReminder(bool enabled) async {
    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('streak_reminder_enabled', enabled);
    if (enabled) {
      SnackbarService.success('Come-back Nudges enabled');
    } else {
      SnackbarService.success('Come-back Nudges disabled');
    }
    setState(() => _reEngagementEnabled = enabled);
  }

  Future<void> _toggleReEngagement(bool enabled) async {
    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('re_engagement_enabled', enabled);
    if (enabled) {
      SnackbarService.success('Streak reminder enabled');
    } else {
      await NotificationService.cancelStreakReminder();
      SnackbarService.success('Streak reminder disabled');
    }
    setState(() => _streakReminderEnabled = enabled);
  }

  Future<void> _toggleSmartAlerts(bool enabled) async {
    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('smart_alerts_enabled', enabled);
    if (enabled) {
      SnackbarService.success('Smart alerts enabled');
    } else {
      SnackbarService.success('Smart alerts disabled');
    }
    setState(() => _smartAlertsEnabled = enabled);
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (time == null) return;
    setState(() => _reminderTime = time);
    if (_dailySummaryEnabled) {
      await NotificationService.scheduleDailyReminder(time);
      SnackbarService.success('Reminder time updated');
    }
  }

  Future<void> _selectStreakReminderTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _streakReminderTime,
    );
    if (time == null) return;
    setState(() => _streakReminderTime = time);
    await NotificationService.saveStreakReminderTime(time);
    SnackbarService.success('Streak reminder time updated');
  }

  Future<void> _selectWeeklyDay() async {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final day = await showModalBottomSheet<int>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: color.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Select Day',
              style:
                  textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...List.generate(7, (i) {
              final d = i + 1; // Monday=1 .. Sunday=7
              final selected = d == _weeklyDay;
              return ListTile(
                dense: true,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                selected: selected,
                selectedTileColor: color.primaryContainer,
                leading: Icon(
                  selected ? LucideIcons.circleCheck : LucideIcons.circle,
                  size: 20,
                  color: selected
                      ? color.onPrimaryContainer
                      : color.onSurfaceVariant,
                ),
                title: Text(
                  _getDayName(d),
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    color:
                        selected ? color.onPrimaryContainer : color.onSurface,
                  ),
                ),
                onTap: () => Navigator.pop(ctx, d),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (day == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('weekly_summary_day', day);
    setState(() => _weeklyDay = day);
    if (_weeklySummaryEnabled) {
      await NotificationService.scheduleWeeklySummary(day);
      SnackbarService.success('Weekly day updated');
    }
  }

  String _getDayName(int day) {
    const names = {
      DateTime.monday: 'Monday',
      DateTime.tuesday: 'Tuesday',
      DateTime.wednesday: 'Wednesday',
      DateTime.thursday: 'Thursday',
      DateTime.friday: 'Friday',
      DateTime.saturday: 'Saturday',
      DateTime.sunday: 'Sunday',
    };
    return names[day] ?? 'Sunday';
  }

  int get _activeCount =>
      (_dailySummaryEnabled ? 1 : 0) +
      (_weeklySummaryEnabled ? 1 : 0) +
      (_streakReminderEnabled ? 1 : 0);

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.symmetric(
                horizontal: spacing.cardHorizontal,
                vertical: spacing.cardVertical,
              ),
              children: [
                // ── HERO STATUS ──
                Container(
                  padding: EdgeInsets.all(spacing.cardInner),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(spacing.radiusMedium),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.primary.withValues(
                          alpha: isDark ? 0.2 : 0.12,
                        ),
                        color.primaryContainer.withValues(alpha: 0.4),
                      ],
                    ),
                    border: Border.all(
                      color: color.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutBack,
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, value, child) =>
                            Transform.scale(scale: value, child: child),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: color.primary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _activeCount > 0
                                ? LucideIcons.bellRing
                                : LucideIcons.bellOff,
                            color: color.primary,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$_activeCount of 3 active',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: color.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Summaries show spending, income, top category & balance',
                              style: textTheme.bodySmall?.copyWith(
                                color: color.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── DAILY SUMMARY ──
                _buildSectionHeader('Daily Summary', color, textTheme),
                const SizedBox(height: 10),
                _buildGroupedCard(
                  color: color,
                  textTheme: textTheme,
                  spacing: spacing,
                  children: [
                    _buildToggleRow(
                      icon: LucideIcons.calendarDays,
                      title: 'Daily Summary',
                      subtitle: "Yesterday's spending overview",
                      value: _dailySummaryEnabled,
                      onChanged: _toggleDailySummary,
                      color: color,
                      textTheme: textTheme,
                    ),
                    if (_dailySummaryEnabled) ...[
                      _divider(color),
                      _buildTapRow(
                        icon: LucideIcons.clock,
                        title: 'Reminder Time',
                        trailing: _reminderTime.format(context),
                        onTap: _selectTime,
                        color: color,
                        textTheme: textTheme,
                      ),
                      _divider(color),
                      _buildTapRow(
                        icon: LucideIcons.send,
                        title: 'Send Test Notification',
                        onTap: () async {
                          HapticFeedback.mediumImpact();
                          await NotificationService.showDailySummary();
                          SnackbarService.success(
                            'Test notification sent',
                          );
                        },
                        color: color,
                        textTheme: textTheme,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),

                // ── STREAK REMINDER ──
                _buildSectionHeader(
                  'Streak Reminder',
                  color,
                  textTheme,
                ),
                const SizedBox(height: 10),
                _buildGroupedCard(
                  color: color,
                  textTheme: textTheme,
                  spacing: spacing,
                  children: [
                    _buildToggleRow(
                      icon: LucideIcons.flame,
                      title: 'Streak Reminder',
                      subtitle: 'Daily nudge to keep your streak',
                      value: _streakReminderEnabled,
                      onChanged: _toggleStreakReminder,
                      color: color,
                      textTheme: textTheme,
                      iconColor: const Color(0xFFFF9800),
                    ),
                    if (_streakReminderEnabled) ...[
                      _divider(color),
                      _buildTapRow(
                        icon: LucideIcons.clock,
                        title: 'Reminder Time',
                        trailing: _streakReminderTime.format(context),
                        onTap: _selectStreakReminderTime,
                        color: color,
                        textTheme: textTheme,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),

                // ── WEEKLY SUMMARY ──
                _buildSectionHeader(
                  'Weekly Summary',
                  color,
                  textTheme,
                ),
                const SizedBox(height: 10),
                _buildGroupedCard(
                  color: color,
                  textTheme: textTheme,
                  spacing: spacing,
                  children: [
                    _buildToggleRow(
                      icon: LucideIcons.calendarRange,
                      title: 'Weekly Summary',
                      subtitle: 'Every ${_getDayName(_weeklyDay)} at 9:00 AM',
                      value: _weeklySummaryEnabled,
                      onChanged: _toggleWeeklySummary,
                      color: color,
                      textTheme: textTheme,
                    ),
                    if (_weeklySummaryEnabled) ...[
                      _divider(color),
                      _buildTapRow(
                        icon: LucideIcons.calendarCheck,
                        title: 'Summary Day',
                        trailing: _getDayName(_weeklyDay),
                        onTap: _selectWeeklyDay,
                        color: color,
                        textTheme: textTheme,
                      ),
                      _divider(color),
                      _buildTapRow(
                        icon: LucideIcons.send,
                        title: 'Send Test Notification',
                        onTap: () async {
                          HapticFeedback.mediumImpact();
                          await NotificationService.showWeeklySummary();
                          SnackbarService.success(
                            'Test notification sent',
                          );
                        },
                        color: color,
                        textTheme: textTheme,
                      ),
                    ],
                  ],
                ),
                const SizedBox(
                  height: 16,
                ),
                _buildGroupedCard(
                  color: color,
                  textTheme: textTheme,
                  spacing: spacing,
                  children: [
                    _buildToggleRow(
                      icon: LucideIcons.userCheck,
                      title: 'Come-back Nudges',
                      subtitle:
                          'Gentle reminders if you haven\'t opened the app',
                      value: _reEngagementEnabled,
                      onChanged: _toggleReEngagement,
                      color: color,
                      textTheme: textTheme,
                    ),
                  ],
                ),
                const SizedBox(
                  height: 16,
                ),
                _buildGroupedCard(
                  color: color,
                  textTheme: textTheme,
                  spacing: spacing,
                  children: [
                    _buildToggleRow(
                      icon: LucideIcons.brain,
                      title: 'Smart Alerts',
                      subtitle:
                          'Budget warnings, spending spikes, bill reminders',
                      value: _smartAlertsEnabled,
                      onChanged: _toggleSmartAlerts,
                      color: color,
                      textTheme: textTheme,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── INFO ──
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(spacing.radiusMedium),
                    color: color.primary.withValues(alpha: 0.06),
                    border: Border.all(
                      color: color.primary.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        LucideIcons.info,
                        color: color.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Notifications are delivered locally on your device. No data is sent to any server.',
                          style: textTheme.bodySmall?.copyWith(
                            color: color.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
              ],
            ),
    );
  }

  // ── SHARED BUILDERS ──

  Widget _buildSectionHeader(
    String title,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: color.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildGroupedCard({
    required ColorScheme color,
    required TextTheme textTheme,
    required AppSpacing spacing,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: color.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        side: BorderSide(
          color: color.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _divider(ColorScheme color) {
    return Divider(
      height: 1,
      indent: 58,
      color: color.outlineVariant.withValues(alpha: 0.4),
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required ColorScheme color,
    required TextTheme textTheme,
    Color? iconColor,
  }) {
    final ic = iconColor ?? color.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ic.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: ic, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
                Text(
                  subtitle,
                  style: textTheme.bodySmall
                      ?.copyWith(color: color.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildTapRow({
    required IconData icon,
    required String title,
    String? trailing,
    required VoidCallback onTap,
    required ColorScheme color,
    required TextTheme textTheme,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style:
                    textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
            if (trailing != null)
              Text(
                trailing,
                style: textTheme.bodyMedium?.copyWith(
                  color: color.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: color.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
