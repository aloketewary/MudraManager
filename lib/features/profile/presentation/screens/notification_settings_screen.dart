import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/services/notification_service.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> {
  bool _dailySummaryEnabled = false;
  bool _weeklySummaryEnabled = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);
  int _weeklyDay = DateTime.sunday;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTime = await NotificationService.getSavedReminderTime();
    setState(() {
      _dailySummaryEnabled = prefs.getBool('daily_summary_enabled') ?? false;
      _weeklySummaryEnabled = prefs.getBool('weekly_summary_enabled') ?? true;
      _weeklyDay = prefs.getInt('weekly_summary_day') ?? DateTime.sunday;
      _reminderTime = savedTime ?? const TimeOfDay(hour: 9, minute: 0);
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

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    
    if (time != null) {
      setState(() => _reminderTime = time);
      if (_dailySummaryEnabled) {
        await NotificationService.scheduleDailyReminder(time);
        SnackbarService.success('Reminder time updated');
      }
    }
  }

  Future<void> _selectWeeklyDay() async {
    final day = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Day'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDayOption('Monday', DateTime.monday),
            _buildDayOption('Tuesday', DateTime.tuesday),
            _buildDayOption('Wednesday', DateTime.wednesday),
            _buildDayOption('Thursday', DateTime.thursday),
            _buildDayOption('Friday', DateTime.friday),
            _buildDayOption('Saturday', DateTime.saturday),
            _buildDayOption('Sunday', DateTime.sunday),
          ],
        ),
      ),
    );

    if (day != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('weekly_summary_day', day);
      setState(() => _weeklyDay = day);
      
      if (_weeklySummaryEnabled) {
        await NotificationService.scheduleWeeklySummary(day);
        SnackbarService.success('Weekly day updated');
      }
    }
  }

  Widget _buildDayOption(String label, int day) {
    return RadioListTile<int>(
      title: Text(label),
      value: day,
      groupValue: _weeklyDay,
      onChanged: (value) => Navigator.pop(context, value),
    );
  }

  String _getDayName(int day) {
    switch (day) {
      case DateTime.monday: return 'Monday';
      case DateTime.tuesday: return 'Tuesday';
      case DateTime.wednesday: return 'Wednesday';
      case DateTime.thursday: return 'Thursday';
      case DateTime.friday: return 'Friday';
      case DateTime.saturday: return 'Saturday';
      case DateTime.sunday: return 'Sunday';
      default: return 'Sunday';
    }
  }

  Future<void> _testDailySummary() async {
    HapticFeedback.mediumImpact();
    await NotificationService.showDailySummary();
    SnackbarService.success('Test notification sent');
  }

  Future<void> _testWeeklySummary() async {
    HapticFeedback.mediumImpact();
    await NotificationService.showWeeklySummary();
    SnackbarService.success('Test notification sent');
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Notification Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            color: color.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.today, color: color.primary, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Daily Summary', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: color.onSurface)),
                        const SizedBox(height: 2),
                        Text('Yesterday\'s spending summary', style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  Switch(value: _dailySummaryEnabled, onChanged: _toggleDailySummary),
                ],
              ),
            ),
          ),
          if (_dailySummaryEnabled) ...[
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              color: color.surfaceContainerHighest,
              child: InkWell(
                onTap: _selectTime,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, color: color.primary),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text('Reminder Time', style: textTheme.titleSmall?.copyWith(color: color.onSurface)),
                      ),
                      Text(_reminderTime.format(context), style: textTheme.titleMedium?.copyWith(color: color.primary)),
                      const SizedBox(width: 8),
                      Icon(Icons.chevron_right, color: color.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _testDailySummary,
                icon: const Icon(Icons.send),
                label: const Text('Test Daily Summary'),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            color: color.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.calendar_today, color: color.primary, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Weekly Summary', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: color.onSurface)),
                        const SizedBox(height: 2),
                        Text('Every ${_getDayName(_weeklyDay)} at 9:00 AM', style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  Switch(value: _weeklySummaryEnabled, onChanged: _toggleWeeklySummary),
                ],
              ),
            ),
          ),
          if (_weeklySummaryEnabled) ...[
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              color: color.surfaceContainerHighest,
              child: InkWell(
                onTap: _selectWeeklyDay,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.event, color: color.primary),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text('Summary Day', style: textTheme.titleSmall?.copyWith(color: color.onSurface)),
                      ),
                      Text(_getDayName(_weeklyDay), style: textTheme.titleMedium?.copyWith(color: color.primary)),
                      const SizedBox(width: 8),
                      Icon(Icons.chevron_right, color: color.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _testWeeklySummary,
                icon: const Icon(Icons.send),
                label: const Text('Test Weekly Summary'),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Card(
            elevation: 0,
            color: color.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: color.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Summaries show total spent, income, top category, and current balance from your transactions.',
                      style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
