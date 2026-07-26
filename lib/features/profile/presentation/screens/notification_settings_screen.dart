import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/state/app_screen_state.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/services/notification_service.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/shared/widgets/ambient_brand_section.dart';
import 'package:mudra_manager/shared/widgets/section_header.dart';
import 'package:mudra_manager/shared/templates/screen_shell.dart';
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

  Future<void> _toggleDailySummary(bool enabled, AppSpacing spacing) async {
    HapticFeedback.mediumImpact();
    final label = AppLocalizations.of(context)!.notifSettings_dailySummary;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('daily_summary_enabled', enabled);
    if (enabled) {
      await NotificationService.scheduleDailyReminder(_reminderTime);
      SnackbarService.success(BuddyMessages.toggledOn('Daily summary'), spacing);
    } else {
      await NotificationService.cancelReminder();
      SnackbarService.success(BuddyMessages.toggledOff(label), spacing);
    }
    if (mounted) setState(() => _dailySummaryEnabled = enabled);
  }

  Future<void> _toggleWeeklySummary(bool enabled, AppSpacing spacing) async {
    HapticFeedback.mediumImpact();
    final label = AppLocalizations.of(context)!.notifSettings_weeklySummary;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('weekly_summary_enabled', enabled);
    if (enabled) {
      await NotificationService.scheduleWeeklySummary(_weeklyDay);
      SnackbarService.success(BuddyMessages.toggledOn(label), spacing);
    } else {
      SnackbarService.success(BuddyMessages.toggledOff(label), spacing);
    }
    if (mounted) setState(() => _weeklySummaryEnabled = enabled);
  }

  Future<void> _toggleStreakReminder(bool enabled, AppSpacing spacing) async {
    HapticFeedback.mediumImpact();
    final label = AppLocalizations.of(context)!.notifSettings_streakReminder;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('streak_reminder_enabled', enabled);
    if (enabled) {
      SnackbarService.success(BuddyMessages.toggledOn(label), spacing);
    } else {
      await NotificationService.cancelStreakReminder();
      SnackbarService.success(BuddyMessages.toggledOff(label), spacing);
    }
    if (mounted) setState(() => _streakReminderEnabled = enabled);
  }

  Future<void> _toggleReEngagement(bool enabled, AppSpacing spacing) async {
    HapticFeedback.mediumImpact();
    final label = AppLocalizations.of(context)!.notifSettings_comeBackNudges;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('re_engagement_enabled', enabled);
    if (enabled) {
      SnackbarService.success(BuddyMessages.toggledOn(label), spacing);
    } else {
      SnackbarService.success(BuddyMessages.toggledOff(label), spacing);
    }
    if (mounted) setState(() => _reEngagementEnabled = enabled);
  }

  Future<void> _toggleSmartAlerts(bool enabled, AppSpacing spacing) async {
    HapticFeedback.mediumImpact();
    final label = AppLocalizations.of(context)!.notifSettings_smartAlerts;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('smart_alerts_enabled', enabled);
    if (enabled) {
      SnackbarService.success(BuddyMessages.toggledOn(label), spacing);
    } else {
      SnackbarService.success(BuddyMessages.toggledOff(label), spacing);
    }
    if (mounted) setState(() => _smartAlertsEnabled = enabled);
  }

  Future<void> _selectTime(AppSpacing spacing) async {
    final time = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (time == null) return;
    setState(() => _reminderTime = time);
    if (_dailySummaryEnabled) {
      await NotificationService.scheduleDailyReminder(time);
      SnackbarService.success(BuddyMessages.reminderUpdated, spacing);
    }
  }

  Future<void> _selectStreakReminderTime(AppSpacing spacing) async {
    final time = await showTimePicker(
      context: context,
      initialTime: _streakReminderTime,
    );
    if (time == null) return;
    setState(() => _streakReminderTime = time);
    await NotificationService.saveStreakReminderTime(time);
    SnackbarService.success(BuddyMessages.reminderUpdated, spacing);
  }

  Future<void> _selectWeeklyDay(AppSpacing spacing) async {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final day = await showModalBottomSheet<int>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(spacing.radiusSmall * 2)),
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
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...List.generate(7, (i) {
              final d = i + 1;
              final selected = d == _weeklyDay;
              return ListTile(
                dense: true,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(spacing.radiusSmall),
                ),
                selected: selected,
                selectedTileColor: color.primaryContainer,
                leading: Icon(
                  selected ? LucideIcons.circleCheck : LucideIcons.circle,
                  size: 20,
                  color: selected ? color.onPrimaryContainer : color.onSurfaceVariant,
                ),
                title: Text(
                  _getDayName(d),
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    color: selected ? color.onPrimaryContainer : color.onSurface,
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
      SnackbarService.success(BuddyMessages.settingsSaved, spacing);
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
      (_streakReminderEnabled ? 1 : 0) +
      (_reEngagementEnabled ? 1 : 0) +
      (_smartAlertsEnabled ? 1 : 0);

  @override
  Widget build(BuildContext context) {
    final ctxt = AppLocalizations.of(context)!;

    return ScreenShell(
      config: ScreenShellConfig(
        title: ctxt.title_notifications,
        appBarMode: AppBarMode.standard,
        enableRefresh: false,
      ),
      actions: ScreenActions.empty,
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final ctxt = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth > 600 ? 600.0 : double.infinity;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: AnimatedSwitcher(
              duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              key: ValueKey(_loaded),
              child: _loaded
                  ? _buildContent(context, color, textTheme, spacing, isDark, ctxt)
                  : _buildLoading(spacing, color),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    bool isDark,
    AppLocalizations ctxt,
  ) {
    return ListView(
      padding: EdgeInsets.only(
        left: spacing.cardHorizontal,
        right: spacing.cardHorizontal,
        top: spacing.cardVertical,
        bottom: 0,
      ),
      children: [
        NotificationHeroCard(
          activeCount: _activeCount,
          isDark: isDark,
          reduceMotion: MediaQuery.of(context).disableAnimations,
        ),
        SizedBox(height: spacing.sectionGap),

        SectionHeader(ctxt.notifSettings_dailySummary),
        SizedBox(height: spacing.elementGap),
        _buildDailySummaryGroup(color, textTheme, spacing, ctxt),
        SizedBox(height: spacing.elementGap * 2),

        SectionHeader(ctxt.notifSettings_streakReminder),
        SizedBox(height: spacing.elementGap),
        _buildStreakReminderGroup(color, textTheme, spacing, ctxt),
        SizedBox(height: spacing.elementGap * 2),

        SectionHeader(ctxt.notifSettings_weeklySummary),
        SizedBox(height: spacing.elementGap),
        _buildWeeklySummaryGroup(color, textTheme, spacing, ctxt),
        SizedBox(height: spacing.elementGap * 2),

        const SectionHeader('Other Settings'),
        SizedBox(height: spacing.elementGap),
        _buildOtherSettingsGroup(color, textTheme, spacing, ctxt),
        SizedBox(height: spacing.sectionGap),

        NotificationInfoCard(color: color, textTheme: textTheme, spacing: spacing, ctxt: ctxt),
        SizedBox(height: spacing.sectionGap),

        const AmbientBrandSection(showSignature: true, absorbBottomInset: false),
        SizedBox(height: spacing.sectionGap),
      ],
    );
  }

  Widget _buildDailySummaryGroup(ColorScheme color, TextTheme textTheme, AppSpacing spacing, AppLocalizations ctxt) {
    return _NotificationGroupCard(
      children: [
        _NotificationToggleRow(
          icon: LucideIcons.calendarDays,
          title: ctxt.notifSettings_dailySummary,
          subtitle: ctxt.notifSettings_dailySummaryDesc,
          value: _dailySummaryEnabled,
          onChanged: (value) => _toggleDailySummary(value, spacing),
          color: color,
        ),
        if (_dailySummaryEnabled) ...[
          _divider(color),
          _NotificationTapRow(
            icon: LucideIcons.clock,
            title: ctxt.notifSettings_reminderTime,
            trailing: _reminderTime.format(context),
            onTap: () => _selectTime(spacing),
            color: color,
          ),
          _divider(color),
          _NotificationTapRow(
            icon: LucideIcons.send,
            title: ctxt.notifSettings_sendTestNotif,
            onTap: () async {
              HapticFeedback.mediumImpact();
              await NotificationService.showLocalNotification(
                id: DateTime.now().microsecondsSinceEpoch % 100000000,
                title: ctxt.notif_heresYesterdayTitle,
                body: ctxt.notifSettings_dailySummaryDesc,
                bypassThrottle: true,
              );
              SnackbarService.success(ctxt.notifSettings_testNotifSent, spacing);
            },
            color: color,
          ),
        ],
      ],
    );
  }

  Widget _buildStreakReminderGroup(ColorScheme color, TextTheme textTheme, AppSpacing spacing, AppLocalizations ctxt) {
    return _NotificationGroupCard(
      children: [
        _NotificationToggleRow(
          icon: LucideIcons.flame,
          title: ctxt.notifSettings_streakReminder,
          subtitle: ctxt.notifSettings_dailyNudgeStreak,
          value: _streakReminderEnabled,
          onChanged: (value) => _toggleStreakReminder(value, spacing),
          color: color,
          iconColor: color.tertiary,
        ),
        if (_streakReminderEnabled) ...[
          _divider(color),
          _NotificationTapRow(
            icon: LucideIcons.clock,
            title: ctxt.notifSettings_reminderTime,
            trailing: _streakReminderTime.format(context),
            onTap: () => _selectStreakReminderTime(spacing),
            color: color,
          ),
        ],
      ],
    );
  }

  Widget _buildWeeklySummaryGroup(ColorScheme color, TextTheme textTheme, AppSpacing spacing, AppLocalizations ctxt) {
    return _NotificationGroupCard(
      children: [
        _NotificationToggleRow(
          icon: LucideIcons.calendarRange,
          title: ctxt.notifSettings_weeklySummary,
          subtitle: ctxt.notifSettings_weeklySchedule(_getDayName(_weeklyDay)),
          value: _weeklySummaryEnabled,
          onChanged: (value) => _toggleWeeklySummary(value, spacing),
          color: color,
        ),
        if (_weeklySummaryEnabled) ...[
          _divider(color),
          _NotificationTapRow(
            icon: LucideIcons.calendarCheck,
            title: ctxt.notifSettings_summaryDay,
            trailing: _getDayName(_weeklyDay),
            onTap: () => _selectWeeklyDay(spacing),
            color: color,
          ),
          _divider(color),
          _NotificationTapRow(
            icon: LucideIcons.send,
            title: ctxt.notifSettings_sendTestNotif,
            onTap: () async {
              HapticFeedback.mediumImpact();
              await NotificationService.showLocalNotification(
                id: DateTime.now().microsecondsSinceEpoch % 100000000,
                title: ctxt.notif_yourWeekInReviewTitle,
                body: ctxt.notifSettings_summaryDesc,
                bypassThrottle: true,
              );
              SnackbarService.success(ctxt.notifSettings_testNotifSent, spacing);
            },
            color: color,
          ),
        ],
      ],
    );
  }

  Widget _buildOtherSettingsGroup(ColorScheme color, TextTheme textTheme, AppSpacing spacing, AppLocalizations ctxt) {
    return _NotificationGroupCard(
      children: [
        _NotificationToggleRow(
          icon: LucideIcons.userCheck,
          title: ctxt.notifSettings_comeBackNudges,
          subtitle: ctxt.notifSettings_gentleReminders,
          value: _reEngagementEnabled,
          onChanged: (value) => _toggleReEngagement(value, spacing),
          color: color,
        ),
        _divider(color),
        _NotificationToggleRow(
          icon: LucideIcons.brain,
          title: ctxt.notifSettings_smartAlerts,
          subtitle: ctxt.notifSettings_budgetWarningsDesc,
          value: _smartAlertsEnabled,
          onChanged: (value) => _toggleSmartAlerts(value, spacing),
          color: color,
        ),
      ],
    );
  }

  Widget _buildLoading(AppSpacing spacing, ColorScheme color) {
    return ListView(
      padding: EdgeInsets.only(
        left: spacing.cardHorizontal,
        right: spacing.cardHorizontal,
        top: spacing.cardVertical,
        bottom: 0,
      ),
      children: [
        _NotificationHeroSkeleton(spacing: spacing, color: color),
        SizedBox(height: spacing.sectionGap),
        _NotificationGroupSkeleton(spacing: spacing, color: color),
        SizedBox(height: spacing.elementGap * 2),
        _NotificationGroupSkeleton(spacing: spacing, color: color),
        SizedBox(height: spacing.elementGap * 2),
        _NotificationGroupSkeleton(spacing: spacing, color: color),
        SizedBox(height: spacing.sectionGap),
        SizedBox(height: spacing.sectionGap),
        const AmbientBrandSection(showSignature: true, absorbBottomInset: false),
      ],
    );
  }

  Widget _divider(ColorScheme color) {
    return Divider(
      height: 1,
      indent: 58,
      color: color.outlineVariant.withValues(alpha: 0.4),
    );
  }
}

class NotificationHeroCard extends ConsumerWidget {
  final int activeCount;
  final bool isDark;
  final bool reduceMotion;

  const NotificationHeroCard({
    super.key,
    required this.activeCount,
    required this.isDark,
    required this.reduceMotion,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final ctxt = AppLocalizations.of(context)!;

    return Semantics(
      label: 'Active notifications: $activeCount',
      child: AnimatedContainer(
        duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 300),
        padding: EdgeInsets.all(spacing.cardInner),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.primary.withValues(alpha: isDark ? 0.2 : 0.12),
              color.primary.withValues(alpha: isDark ? 0.08 : 0.04),
            ],
          ),
          border: Border.all(color: color.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.primary.withValues(alpha: isDark ? 0.15 : 0.1),
                    ),
                  ),
                  ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: const SizedBox(width: 56, height: 56),
                    ),
                  ),
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutBack,
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) => Transform.scale(
                      scale: value,
                      child: child,
                    ),
                    child: Container(
                      padding: EdgeInsets.all(spacing.elementGap * 1.5),
                      decoration: BoxDecoration(
                        color: color.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        activeCount > 0 ? LucideIcons.bellRing : LucideIcons.bellOff,
                        color: color.primary,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: spacing.sectionGap),
            Expanded(
              child: AnimatedDefaultTextStyle(
                duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 200),
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color.primary,
                ) ?? const TextStyle(fontWeight: FontWeight.w700),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ctxt.notifSettings_activeCount(activeCount)),
                    SizedBox(height: spacing.elementGapUltraMin),
                    Text(
                      ctxt.notifSettings_summaryDesc,
                      style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationGroupCard extends ConsumerWidget {
  final List<Widget> children;

  const _NotificationGroupCard({required this.children});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final spacing = ref.watch(spacingProvider);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: color.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        side: BorderSide(color: color.outlineVariant.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _NotificationToggleRow extends ConsumerWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final ColorScheme color;
  final Color? iconColor;

  const _NotificationToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.color,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.read<AppSpacing>(spacingProvider);
    final ic = iconColor ?? color.primary;

    return Semantics(
      label: '$title. ${value ? 'Enabled' : 'Disabled'}. $subtitle',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ic.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(spacing.radiusSmall),
              ),
              child: Icon(icon, color: ic, size: 20),
            ),
            SizedBox(width: spacing.elementGap * 1.5),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(fontWeight: FontWeight.w500, color: color.onSurface),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(color: color.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: spacing.elementGap, top: 2),
                    child: Icon(
                      value ? LucideIcons.check : LucideIcons.x,
                      size: 16,
                      color: value ? color.primary : color.error.withValues(alpha: 0.7),
                    ),
                  ),
                  SizedBox(width: spacing.elementGap),
                  SizedBox(
                    height: 24,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Switch(
                        value: value,
                        onChanged: onChanged,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTapRow extends ConsumerWidget {
  final IconData icon;
  final String title;
  final String? trailing;
  final VoidCallback onTap;
  final ColorScheme color;

  const _NotificationTapRow({
    required this.icon,
    required this.title,
    this.trailing,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.read<AppSpacing>(spacingProvider);
    final textTheme = Theme.of(context).textTheme;

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
                borderRadius: BorderRadius.circular(spacing.radiusSmall),
              ),
              child: Icon(icon, color: color.primary, size: 20),
            ),
            SizedBox(width: spacing.elementGap * 1.5),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontWeight: FontWeight.w500, color: color.onSurface),
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: textTheme.bodyMedium?.copyWith(
                  color: color.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            SizedBox(width: spacing.elementGap),
            Icon(LucideIcons.chevronRight, color: color.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }
}

class NotificationInfoCard extends StatelessWidget {
  final ColorScheme color;
  final TextTheme textTheme;
  final AppSpacing spacing;
  final AppLocalizations ctxt;

  const NotificationInfoCard({
    super.key,
    required this.color,
    required this.textTheme,
    required this.spacing,
    required this.ctxt,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Information about local notifications',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.all(spacing.cardInner),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          gradient: LinearGradient(
            colors: [
              color.primary.withValues(alpha: 0.06),
              color.primary.withValues(alpha: 0.02),
            ],
          ),
          border: Border.all(color: color.primary.withValues(alpha: 0.15)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(spacing.elementGapMin + 2),
              decoration: BoxDecoration(
                color: color.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(spacing.radiusSmall),
              ),
              child: Icon(LucideIcons.info, color: color.primary, size: 16),
            ),
            SizedBox(width: spacing.elementGap),
            Expanded(
              child: Text(
                ctxt.notifSettings_localNotifDisclaimer,
                style: textTheme.bodySmall?.copyWith(
                  color: color.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationHeroSkeleton extends StatelessWidget {
  final AppSpacing spacing;
  final ColorScheme color;

  const _NotificationHeroSkeleton({required this.spacing, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        color: color.surfaceContainerLow,
      ),
      child: Row(
        children: [
          SkeletonLoader(
            width: 56,
            height: 56,
            borderRadius: BorderRadius.circular(28),
          ),
          SizedBox(width: spacing.sectionGap),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(width: 120, height: 18),
                SizedBox(height: 8),
                SkeletonLoader(width: 160, height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationGroupSkeleton extends StatelessWidget {
  final AppSpacing spacing;
  final ColorScheme color;

  const _NotificationGroupSkeleton({required this.spacing, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.surface.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(spacing.radiusMedium + 4),
        border: Border.all(color: color.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: List.generate(3, (index) {
          final isLast = index == 2;
          return Padding(
            padding: EdgeInsets.only(
              left: spacing.cardInner,
              right: spacing.cardInner,
              top: spacing.cardInner,
              bottom: isLast ? spacing.cardInner : spacing.elementGapMin,
            ),
            child: Row(
              children: [
                SkeletonLoader(
                  width: 40,
                  height: 40,
                  borderRadius: BorderRadius.circular(spacing.radiusSmall),
                ),
                SizedBox(width: spacing.cardInner),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonLoader(width: 140, height: 16),
                      SizedBox(height: 6),
                      SkeletonLoader(width: 100, height: 12),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}