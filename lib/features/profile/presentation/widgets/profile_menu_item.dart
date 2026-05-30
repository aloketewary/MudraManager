import 'package:mudra_manager/core/tone/tone_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Widget? trailing;

  const ProfileMenuItem({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.iconColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? color.primary).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(Tone.current.borderRadius),
          ),
          child: Icon(icon, color: iconColor ?? color.primary),
        ),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        trailing: trailing ?? const Icon(LucideIcons.chevronRight),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
      ),
    );
  }
}
