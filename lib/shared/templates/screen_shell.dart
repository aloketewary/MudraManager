import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/state/app_screen_state.dart';

/// AppBar mode determines chrome style only.
enum AppBarMode {
  /// Standard title + action icons.
  standard,

  /// Search field active in AppBar.
  search,

  /// Minimal — no title, only leading + actions.
  minimal,

  /// Hidden — no AppBar (e.g., dashboard with custom SliverAppBar).
  none,
}

/// Chrome-only configuration. Rendering hints. No logic. No actions.
class ScreenShellConfig {
  final String? title;
  final AppBarMode appBarMode;
  final bool enableRefresh;

  const ScreenShellConfig({
    this.title,
    this.appBarMode = AppBarMode.standard,
    this.enableRefresh = true,
  });
}

/// ScreenShell — dumb chrome renderer.
///
/// Reads pre-grouped action slots from [actions]. No filtering. No selection.
/// Renders:
///   - actions.appBar → AppBar icon buttons
///   - actions.overflow → PopupMenuButton
///   - actions.fab → FloatingActionButton
///   - actions.contextual → NOT rendered here (template's job)
///
/// If this widget ever needs a `.where` or `.firstOrNull`, the architecture
/// is violated. Fix the state provider, not the shell.
class ScreenShell extends ConsumerWidget {
  final ScreenShellConfig config;
  final Widget body;
  final ScreenActions actions;
  final Future<void> Function()? onRefresh;
  final Widget? leading;
  final ValueChanged<String>? onSearch;
  final String? searchHint;

  const ScreenShell({
    super.key,
    required this.config,
    required this.body,
    this.actions = ScreenActions.empty,
    this.onRefresh,
    this.leading,
    this.onSearch,
    this.searchHint,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: color.surface,
      appBar: _buildAppBar(context, color, textTheme),
      floatingActionButton: actions.fab != null
          ? FloatingActionButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                actions.fab!.onTap();
              },
              child: Icon(actions.fab!.icon),
            )
          : null,
      body: _buildBody(),
    );
  }

  PreferredSizeWidget? _buildAppBar(
    BuildContext context,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    final actionWidgets = <Widget>[
      ...actions.appBar.map(
        (a) => IconButton(
          icon: Icon(a.icon, size: 20),
          tooltip: a.label,
          onPressed: () {
            HapticFeedback.mediumImpact();
            a.onTap();
          },
        ),
      ),
      if (actions.overflow.isNotEmpty)
        PopupMenuButton<String>(
          onSelected: (id) {
            final action = actions.overflow.firstWhere((a) => a.id == id);
            HapticFeedback.mediumImpact();
            action.onTap();
          },
          itemBuilder: (_) => actions.overflow
              .map(
                (a) => PopupMenuItem<String>(
                  value: a.id,
                  child: Row(
                    children: [
                      Icon(a.icon, size: 18, color: color.onSurface),
                      const SizedBox(width: 12),
                      Text(a.label),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
    ];

    return switch (config.appBarMode) {
      AppBarMode.none => null,
      AppBarMode.minimal => AppBar(
          leading: leading,
          actions: actionWidgets,
        ),
      AppBarMode.search => AppBar(
          leading: leading,
          title: TextField(
            autofocus: true,
            onChanged: onSearch,
            decoration: InputDecoration(
              hintText: searchHint ?? 'Search...',
              border: InputBorder.none,
              hintStyle: textTheme.bodyLarge?.copyWith(
                color: color.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
            style: textTheme.bodyLarge,
          ),
          actions: actionWidgets,
        ),
      AppBarMode.standard => AppBar(
          leading: leading,
          title: config.title != null
              ? Text(
                  config.title!,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
          actions: actionWidgets,
        ),
    };
  }

  Widget _buildBody() {
    if (!config.enableRefresh || onRefresh == null) {
      return body;
    }
    return RefreshIndicator(
      onRefresh: onRefresh!,
      child: body,
    );
  }
}
