import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

class ProfileTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool isLogout;

  const ProfileTile({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    required this.subtitle,
    this.isLogout = false,
  });

  @override
  Widget build(BuildContext context) {
    var textTheme = Theme.of(context).textTheme;
    var color = Theme.of(context).colorScheme;
    return ListTile(
      title: Text(
        title,
        style: textTheme.titleMedium?.copyWith(
          color: isLogout ? color.error : color.onSurface,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: textTheme.bodySmall?.copyWith(
          color: isLogout ? color.error : color.onSurfaceVariant,
        ),
      ),
      leading: Icon(icon, color: isLogout ? color.error : color.secondary),
      onTap: onTap,
      trailing: Icon(
        Icons.chevron_right,
        color: isLogout ? color.error : color.onSurfaceVariant,
      ),
    );
  }
}
