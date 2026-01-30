import 'package:flutter/material.dart';

class DialogUtils {
  static Future<bool?> showDeleteConfirmation(
    BuildContext context, {
    required String title,
    required String message,
    String? cancelText,
    String? deleteText,
  }) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: color.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: color.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Icon(Icons.delete_forever_rounded, size: 48, color: color.error),
              SizedBox(height: 16),
              Text(
                title,
                style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                message,
                style: textTheme.bodyMedium?.copyWith(color: color.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: color.outline),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        (cancelText ?? 'CANCEL').toUpperCase(),
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: color.error,
                        foregroundColor: color.onError,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        (deleteText ?? 'DELETE').toUpperCase(),
                        style: TextStyle(fontWeight: FontWeight.bold),
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
}
