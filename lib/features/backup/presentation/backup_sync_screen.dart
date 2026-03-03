import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/features/backup/data/enhanced_backup_service.dart';
import 'package:mudra_manager/shared/widgets/common_button.dart';
import 'package:mudra_manager/shared/widgets/app_card.dart';

class BackupSyncScreen extends ConsumerStatefulWidget {
  const BackupSyncScreen({super.key});

  @override
  ConsumerState<BackupSyncScreen> createState() => _BackupSyncScreenState();
}

class _BackupSyncScreenState extends ConsumerState<BackupSyncScreen> {
  final _passwordController = TextEditingController();
  BackupMethod _selectedMethod = BackupMethod.local;
  bool _includeAttachments = true;
  bool _isCreatingBackup = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Share'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildBackupMethodSection(),
            const SizedBox(height: 16),
            _buildBackupOptionsSection(),
            const SizedBox(height: 24),
            _buildCreateBackupButton(),
            const SizedBox(height: 16),
            _buildBackupHistorySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupMethodSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Backup Method',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          ListTile(
            title: const Text('Local Only'),
            subtitle: const Text('Save to device storage'),
            leading: Icon(
              _selectedMethod == BackupMethod.local
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
            ),
            onTap: () => setState(() => _selectedMethod = BackupMethod.local),
          ),
          ListTile(
            title: const Text('Share to Cloud'),
            subtitle: const Text('Save locally + open share dialog'),
            leading: Icon(
              _selectedMethod == BackupMethod.shareToCloud
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
            ),
            onTap: () =>
                setState(() => _selectedMethod = BackupMethod.shareToCloud),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupOptionsSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Options',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SwitchListTile(
            title: const Text('Include Attachments'),
            value: _includeAttachments,
            onChanged: (value) => setState(() => _includeAttachments = value),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Backup Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateBackupButton() {
    return CommonButton(
      text: 'Create Backup',
      onPressed: _isCreatingBackup ? () {} : _createBackup,
    );
  }

  Widget _buildBackupHistorySection() {
    return Expanded(
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Backup History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<BackupInfo>>(
                future: EnhancedBackupService.getAvailableBackups(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final backups = snapshot.data!;
                  return ListView.builder(
                    itemCount: backups.length,
                    itemBuilder: (context, index) {
                      final backup = backups[index];
                      return ListTile(
                        leading: const Icon(Icons.storage),
                        title: Text(backup.name),
                        subtitle: Text(
                          '${_formatFileSize(backup.size)} • ${_formatDate(backup.date)}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.share),
                          onPressed: () => _shareBackup(backup),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createBackup() async {
    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a password')),
      );
      return;
    }

    setState(() => _isCreatingBackup = true);

    try {
      final result = await EnhancedBackupService.createBackupWithShare(
        _passwordController.text,
        method: _selectedMethod,
        includeAttachments: _includeAttachments,
      );

      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup created successfully')),
        );
        setState(() {});
      }
    } finally {
      setState(() => _isCreatingBackup = false);
    }
  }

  Future<void> _shareBackup(BackupInfo backup) async {
    if (backup.path != null) {
      await EnhancedBackupService.shareBackupFile(backup.path!);
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
