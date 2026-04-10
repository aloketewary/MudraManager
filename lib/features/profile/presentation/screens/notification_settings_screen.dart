import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
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
    final label = AppLocalizations.of(context)!.notifSettings_dailySummary;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('daily_summary_enabled', enabled);
    if (enabled) {
      await NotificationService.scheduleDailyReminder(_reminderTime);
      SnackbarService.success(BuddyMessages.toggledOn('Daily summary'));
    } else {
      await NotificationService.cancelReminder();
      SnackbarService.success(BuddyMessages.toggledOff(label));
    }
    if (mounted) setState(() => _dailySummaryEnabled = enabled);
  }

  Future<void> _toggleWeeklySummary(bool enabled) async {
    HapticFeedback.mediumImpact();
    final label = AppLocalizations.of(context)!.notifSettings_weeklySummary;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('weekly_summary_enabled', enabled);
    if (enabled) {
      await NotificationService.scheduleWeeklySummary(_weeklyDay);
      SnackbarService.success(BuddyMessages.toggledOn(label));
    } else {
      SnackbarService.success(BuddyMessages.toggledOff(label));
    }
    if (mounted) setState(() => _weeklySummaryEnabled = enabled);
  }

  Future<void> _toggleStreakReminder(bool enabled) async {
    HapticFeedback.mediumImpact();
    final label = AppLocalizations.of(context)!.notifSettings_comeBackNudges;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('streak_reminder_enabled', enabled);
    if (enabled) {
      SnackbarService.success(BuddyMessages.toggledOn(label));
    } else {
      SnackbarService.success(BuddyMessages.toggledOff(label));
    }
    if (mounted) setState(() => _reEngagementEnabled = enabled);
  }

  Future<void> _toggleReEngagement(bool enabled) async {
    HapticFeedback.mediumImpact();
    final label = AppLocalizations.of(context)!.notifSettings_streakReminder;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('re_engagement_enabled', enabled);
    if (enabled) {
      SnackbarService.success(BuddyMessages.toggledOn(label));
    } else {
      await NotificationService.cancelStreakReminder();
      SnackbarService.success(BuddyMessages.toggledOff(label));
    }
    if (mounted) setState(() => _streakReminderEnabled = enabled);
  }

  Future<void> _toggleSmartAlerts(bool enabled) async {
    HapticFeedback.mediumImpact();
    final label = AppLocalizations.of(context)!.notifSettings_smartAlerts;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('smart_alerts_enabled', enabled);
    if (enabled) {
      SnackbarService.success(BuddyMessages.toggledOn(label));
    } else {
      SnackbarService.success(BuddyMessages.toggledOff(label));
    }
    if (mounted) setState(() => _smartAlertsEnabled = enabled);
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
      SnackbarService.success(BuddyMessages.reminderUpdated);
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
    SnackbarService.success(BuddyMessages.reminderUpdated);
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
              AppLocalizations.of(context)!.notifSettings_selectDay,
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
      SnackbarService.success(BuddyMessages.settingsSaved);
    }
  }

  String _getDayName(int day) {
    final ctxt = AppLocalizations.of(context)!;
    final names = {
      DateTime.monday: ctxt.day_monday,
      DateTime.tuesday: ctxt.day_tuesday,
      DateTime.wednesday: ctxt.day_wednesday,
      DateTime.thursday: ctxt.day_thursday,
      DateTime.friday: ctxt.day_friday,
      DateTime.saturday: ctxt.day_saturday,
      DateTime.sunday: ctxt.day_sunday,
    };
    return names[day] ?? ctxt.day_sunday;
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
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.title_notifications)),
      body: !_loaded
          ? Padding(padding: EdgeInsets.all(spacing.cardHorizontal), child: Column(children: [const DashboardCardSkeleton(), SizedBox(height: spacing.elementGap), const DashboardCardSkeleton()]))
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
                        color.primary.withValues(alpha: isDark ? 0.08 : 0.04),
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
                      SizedBox(width: spacing.sectionGap),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.notifSettings_activeCount(_activeCount),
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: color.primary,
                              ),
                            ),
                            SizedBox(height: spacing.elementGapMin),
                            Text(
                              AppLocalizations.of(context)!.notifSettings_summaryDesc,
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
                _buildSectionHeader(AppLocalizations.of(context)!.notifSettings_dailySummary, color, textTheme),
                const SizedBox(height: 10),
                _buildGroupedCard(
                  color: color,
                  textTheme: textTheme,
                  spacing: spacing,
                  children: [
                    _buildToggleRow(
                      icon: LucideIcons.calendarDays,
                      title: AppLocalizations.of(context)!.notifSettings_dailySummary,
                      subtitle: AppLocalizations.of(context)!.notifSettings_dailySummaryDesc,
                      value: _dailySummaryEnabled,
                      onChanged: _toggleDailySummary,
                      color: color,
                      textTheme: textTheme,
                    ),
                    if (_dailySummaryEnabled) ...[
                      _divider(color),
                      _buildTapRow(
                        icon: LucideIcons.clock,
                        title: AppLocalizations.of(context)!.notifSettings_reminderTime,
                        trailing: _reminderTime.format(context),
                        onTap: _selectTime,
                        color: color,
                        textTheme: textTheme,
                      ),
                      _divider(color),
                      _buildTapRow(
                        icon: LucideIcons.send,
                        title: AppLocalizations.of(context)!.notifSettings_sendTestNotif,
                        onTap: () async {
                          final msg = AppLocalizations.of(context)!.notifSettings_testNotifSent;
                          HapticFeedback.mediumImpact();
                          await NotificationService.showDailySummary();
                          SnackbarService.success(msg);
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
                  AppLocalizations.of(context)!.notifSettings_streakReminder,
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
                      title: AppLocalizations.of(context)!.notifSettings_streakReminder,
                      subtitle: AppLocalizations.of(context)!.notifSettings_dailyNudgeStreak,
                      value: _streakReminderEnabled,
                      onChanged: _toggleStreakReminder,
                      color: color,
                      textTheme: textTheme,
                      iconColor: color.tertiary,
                    ),
                    if (_streakReminderEnabled) ...[
                      _divider(color),
                      _buildTapRow(
                        icon: LucideIcons.clock,
                        title: AppLocalizations.of(context)!.notifSettings_reminderTime,
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
                  AppLocalizations.of(context)!.notifSettings_weeklySummary,
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
                      title: AppLocalizations.of(context)!.notifSettings_weeklySummary,
                      subtitle: AppLocalizations.of(context)!.notifSettings_weeklySchedule(_getDayName(_weeklyDay)),
                      value: _weeklySummaryEnabled,
                      onChanged: _toggleWeeklySummary,
                      color: color,
                      textTheme: textTheme,
                    ),
                    if (_weeklySummaryEnabled) ...[
                      _divider(color),
                      _buildTapRow(
                        icon: LucideIcons.calendarCheck,
                        title: AppLocalizations.of(context)!.notifSettings_summaryDay,
                        trailing: _getDayName(_weeklyDay),
                        onTap: _selectWeeklyDay,
                        color: color,
                        textTheme: textTheme,
                      ),
                      _divider(color),
                      _buildTapRow(
                        icon: LucideIcons.send,
                        title: AppLocalizations.of(context)!.notifSettings_sendTestNotif,
                        onTap: () async {
                          final msg = AppLocalizations.of(context)!.notifSettings_testNotifSent;
                          HapticFeedback.mediumImpact();
                          await NotificationService.showWeeklySummary();
                          SnackbarService.success(msg);
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
                      title: AppLocalizations.of(context)!.notifSettings_comeBackNudges,
                      subtitle:
                          AppLocalizations.of(context)!.notifSettings_gentleReminders,
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
                      title: AppLocalizations.of(context)!.notifSettings_smartAlerts,
                      subtitle:
                          AppLocalizations.of(context)!.notifSettings_budgetWarningsDesc,
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
                          AppLocalizations.of(context)!.notifSettings_localNotifDisclaimer,
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
              LucideIcons.chevronRight,
              color: color.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
