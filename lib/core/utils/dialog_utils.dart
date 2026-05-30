import 'package:mudra_manager/core/tone/tone_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';

class DialogUtils {
  static Future<bool?> showDeleteConfirmation(
    BuildContext context, {
    String? title,
    String? message,
    String? cancelText,
    String? deleteText,
  }) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: color.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Tone.current.borderRadius * 2)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: color.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Icon(LucideIcons.trash2, size: 48, color: color.error),
              const SizedBox(height: 16),
              Text(
                title ?? BuddyMessages.deleteTitle,
                style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message ?? BuddyMessages.deleteMessage(null),
                style: textTheme.bodyMedium?.copyWith(color: color.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: color.outline),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tone.current.borderRadius)),
                      ),
                      child: Text(
                        (cancelText ?? BuddyMessages.deleteCancel).toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: color.error,
                        foregroundColor: color.onError,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tone.current.borderRadius)),
                      ),
                      child: Text(
                        (deleteText ?? BuddyMessages.deleteConfirm).toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<bool?> showConfirmation(
    BuildContext context, {
    required String title,
    required String message,
    String? cancelText,
    String? confirmText,
    IconData? icon,
  }) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: color.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Tone.current.borderRadius * 2)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: color.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              if (icon != null) ...[
                Icon(icon, size: 48, color: color.primary),
                const SizedBox(height: 16),
              ],
              Text(
                title,
                style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: textTheme.bodyMedium?.copyWith(color: color.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: color.outline),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tone.current.borderRadius)),
                      ),
                      child: Text(
                        (cancelText ?? 'CANCEL').toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tone.current.borderRadius)),
                      ),
                      child: Text(
                        (confirmText ?? 'CONFIRM').toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<String?> showPasswordDialog(
    BuildContext context, {
    required bool isRestore,
  }) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: color.surface,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Tone.current.borderRadius * 2)),
      ),
      builder: (context) => _PasswordDialogContent(isRestore: isRestore, color: color, textTheme: textTheme),
    );
  }

  static Future<String?> showListItems({
    required BuildContext context,
    required String title,
    required List<String> items,
    IconData? icon,
    required void Function(String item) onItemSelected,
    required String selectedValue,
  }) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: color.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Tone.current.borderRadius * 2)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: color.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              if (icon != null) ...[
                Icon(icon, size: 48, color: color.primary),
                const SizedBox(height: 16),
              ],
              Text(
                title,
                style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ...items.map((item) => ListTile(
                    title: Text(item),
                    onTap: () {
                      Navigator.pop(context, item);
                      onItemSelected(item);
                    },
                    selected: item == selectedValue,
                    trailing: item == selectedValue ? Icon(LucideIcons.check, color: color.primary) : null,
                  ),),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasswordDialogContent extends StatefulWidget {
  final bool isRestore;
  final ColorScheme color;
  final TextTheme textTheme;

  const _PasswordDialogContent({
    required this.isRestore,
    required this.color,
    required this.textTheme,
  });

  @override
  State<_PasswordDialogContent> createState() => _PasswordDialogContentState();
}

class _PasswordDialogContentState extends State<_PasswordDialogContent> {
  late final TextEditingController _controller;
  late final TextEditingController _confirmController;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _confirmController = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: widget.color.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Icon(LucideIcons.lock, size: 48, color: widget.color.primary),
          const SizedBox(height: 16),
          Text(
            widget.isRestore ? 'Enter Password' : 'Set Backup Password',
            style: widget.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _controller,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(Tone.current.borderRadius)),
              prefixIcon: const Icon(LucideIcons.keyRound),
            ),
          ),
          if (!widget.isRestore) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _confirmController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(Tone.current.borderRadius)),
                prefixIcon: const Icon(LucideIcons.keyRound),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tone.current.borderRadius)),
                  ),
                  child: const Text('CANCEL', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    if (!widget.isRestore && _controller.text != _confirmController.text) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Passwords do not match')),
                      );
                      return;
                    }
                    if (_controller.text.length < 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Password must be at least 6 characters')),
                      );
                      return;
                    }
                    Navigator.pop(context, _controller.text);
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tone.current.borderRadius)),
                  ),
                  child: const Text('CONTINUE', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
