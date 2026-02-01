import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:mudra_manager/db/models/backup_metadata.dart';
import 'package:mudra_manager/service/backup_restore_service.dart';
import 'package:mudra_manager/util/dialog_utils.dart';
import 'package:mudra_manager/util/snackbar_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _isLoading = false;
  List<BackupMetadata> _backupHistory = [];
  BackupMetadata? _lastBackup;
  String _reminderFrequency = 'weekly';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final history = await BackupService.getBackupHistory();
    final last = await BackupService.getLastBackup();
    final prefs = await SharedPreferences.getInstance();
    final frequency = prefs.getString('backup_reminder_frequency') ?? 'weekly';

    setState(() {
      _backupHistory = history;
      _lastBackup = last;
      _reminderFrequency = frequency;
    });
  }

  Future<void> _createBackup() async {
    final password = await _showPasswordDialog(isRestore: false);
    if (password == null) return;

    final includeAttachments = await _showAttachmentDialog();
    if (includeAttachments == null) return;

    setState(() => _isLoading = true);

    final filePath = await BackupService.createEncryptedBackup(
      password,
      includeAttachments: includeAttachments,
    );

    setState(() => _isLoading = false);

    if (filePath != null) {
      SnackbarService.success('Backup created successfully');
      _showBackupLocationDialog(filePath);
      _loadData();
    } else {
      SnackbarService.error('Failed to create backup');
    }
  }

  Future<void> _restoreBackup() async {
    final password = await _showPasswordDialog(isRestore: true);
    if (password == null) return;

    final confirmed = await DialogUtils.showConfirmation(
      context,
      title: 'Restore Backup',
      message: 'This will replace all current data. Continue?',
    );
    if (confirmed != true) return;

    setState(() => _isLoading = true);

    final isar = Isar.getInstance()!;
    final result = await BackupService.restoreEncryptedBackup(
      context,
      isar,
      password,
    );

    setState(() => _isLoading = false);

    if (result == 'success') {
      SnackbarService.success('Backup restored successfully');
    }
  }

  Future<String?> _showPasswordDialog({required bool isRestore}) async {
    final controller = TextEditingController();
    final confirmController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(isRestore ? 'Enter Password' : 'Set Backup Password'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (!isRestore) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: confirmController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm Password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (!isRestore && controller.text != confirmController.text) {
                    SnackbarService.error('Passwords do not match');
                    return;
                  }
                  if (controller.text.length < 6) {
                    SnackbarService.error(
                      'Password must be at least 6 characters',
                    );
                    return;
                  }
                  Navigator.pop(context, controller.text);
                },
                child: const Text('Continue'),
              ),
            ],
          ),
    );
  }

  Future<bool?> _showAttachmentDialog() async {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Include Attachments?'),
            content: const Text(
              'Include receipt images in backup? This will increase file size.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Yes'),
              ),
            ],
          ),
    );
  }

  void _showBackupLocationDialog(String path) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Backup Created'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Backup saved at:'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    path,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Upload this file to Google Drive, Dropbox, or any cloud storage for safekeeping.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  Future<void> _updateReminderFrequency(String frequency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('backup_reminder_frequency', frequency);
    setState(() => _reminderFrequency = frequency);
    SnackbarService.success('Reminder frequency updated');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildLastBackupCard(),
                  const SizedBox(height: 16),
                  _buildActionsCard(),
                  const SizedBox(height: 16),
                  _buildReminderCard(),
                  const SizedBox(height: 16),
                  _buildHistoryCard(),
                ],
              ),
    );
  }

  Widget _buildLastBackupCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Last Backup',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_lastBackup != null) ...[
              _buildInfoRow(
                'Date',
                DateFormat(
                  'MMM dd, yyyy hh:mm a',
                ).format(_lastBackup!.backupDate),
              ),
              _buildInfoRow(
                'Size',
                '${(_lastBackup!.fileSize / 1024).toStringAsFixed(2)} KB',
              ),
              _buildInfoRow('Records', '${_lastBackup!.recordCount}'),
              _buildInfoRow(
                'Attachments',
                _lastBackup!.includesAttachments ? 'Included' : 'Excluded',
              ),
            ] else
              const Text(
                'No backups yet',
                style: TextStyle(color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _createBackup,
                icon: const Icon(Icons.backup),
                label: const Text('Create Backup'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _restoreBackup,
                icon: const Icon(Icons.restore),
                label: const Text('Restore Backup'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Backup Reminders',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _reminderFrequency,
              decoration: const InputDecoration(
                labelText: 'Frequency',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'daily', child: Text('Daily')),
                DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                DropdownMenuItem(value: 'never', child: Text('Never')),
              ],
              onChanged: (value) {
                if (value != null) _updateReminderFrequency(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Backup History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_backupHistory.isEmpty)
              const Text(
                'No backup history',
                style: TextStyle(color: Colors.grey),
              )
            else
              ..._backupHistory
                  .take(5)
                  .map(
                    (backup) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.folder_zip),
                      title: Text(backup.fileName),
                      subtitle: Text(
                        DateFormat(
                          'MMM dd, yyyy hh:mm a',
                        ).format(backup.backupDate),
                      ),
                      trailing: Text(
                        '${(backup.fileSize / 1024).toStringAsFixed(1)} KB',
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
