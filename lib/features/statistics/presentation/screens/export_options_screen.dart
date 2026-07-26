import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/shared/widgets/no_data_found.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/features/import_export/data/export_plugin_manager.dart';
import 'package:mudra_manager/core/providers/singleton_providers.dart';
import 'package:mudra_manager/features/import_export/data/export_plugin.dart';
import 'package:mudra_manager/core/utils/file_utils.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/core/state/app_screen_state.dart';
import 'package:mudra_manager/shared/templates/screen_shell.dart';

final exportFormatsProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  return ref.read(exportPluginManagerProvider).getSupportedFormats();
});

final exportTemplatesProvider = FutureProvider.autoDispose
    .family<List<String>, String>((ref, format) async {
  return ref.read(exportPluginManagerProvider).getTemplatesForFormat(format);
});

class ExportOptionsScreen extends ConsumerWidget {
  final ExportData exportData;

  const ExportOptionsScreen({super.key, required this.exportData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final ctxt = AppLocalizations.of(context)!;
    final formatsAsync = ref.watch(exportFormatsProvider);

    return ScreenShell(
      config: ScreenShellConfig(
        title: ctxt.title_exportOptions,
        appBarMode: AppBarMode.standard,
        enableRefresh: false,
      ),
      actions: ScreenActions.build(
        appBar: [
          ScreenAction(
            id: 'refresh_exports',
            label: ctxt.common_refresh,
            icon: LucideIcons.refreshCw,
            onTap: () {
              HapticFeedback.mediumImpact();
              ref.invalidate(exportFormatsProvider);
            },
          ),
        ],
      ),
      body: formatsAsync.when(
        loading: () => ListView.builder(
          padding: EdgeInsets.symmetric(
            horizontal: spacing.cardHorizontal,
            vertical: spacing.cardVertical,
          ),
          itemCount: 3,
          itemBuilder: (_, __) => Padding(
            padding: EdgeInsets.only(bottom: spacing.elementGap),
            child: const DashboardCardSkeleton(),
          ),
        ),
        error: (err, stack) =>
            Center(child: Text(BuddyMessages.errorWith('$err'))),
        data: (formats) {
          if (formats.isEmpty) {
            return NoDataFound(
              message: ctxt.export_noTemplatesTitle,
              description: ctxt.export_noTemplatesDesc,
              iconData: LucideIcons.fileX,
            );
          }

          return ListView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.cardHorizontal,
              vertical: spacing.cardVertical,
            ),
            itemCount: formats.length,
            itemBuilder: (context, index) {
              final format = formats[index];
              final templatesAsync = ref.watch(exportTemplatesProvider(format));

              return templatesAsync.when(
                loading: () => Padding(
                  padding: EdgeInsets.only(bottom: spacing.elementGap),
                  child: _FormatGroupSkeleton(spacing: spacing, color: color),
                ),
                error: (err, stack) => Padding(
                  padding: EdgeInsets.only(bottom: spacing.elementGap),
                  child: _FormatGroup(
                    icon: LucideIcons.circleAlert,
                    iconColor: color.error,
                    title: format,
                    subtitle: BuddyMessages.errorWith('$err'),
                    color: color,
                    textTheme: textTheme,
                    spacing: spacing,
                    templates: const [],
                    onTemplateTap: (_) {},
                  ),
                ),
                data: (templates) {
                  if (templates.isEmpty) return const SizedBox.shrink();

                  return Padding(
                    padding: EdgeInsets.only(bottom: spacing.elementGap),
                    child: _FormatGroup(
                      icon: _getFormatIcon(format),
                      iconColor: color.primary,
                      title: format,
                      subtitle:
                          ctxt.export_nTemplatesAvailable(templates.length),
                      color: color,
                      textTheme: textTheme,
                      spacing: spacing,
                      templates: templates,
                      onTemplateTap: (template) =>
                          _exportWithTemplate(context, ref, format, template),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  IconData _getFormatIcon(String format) {
    switch (format) {
      case 'Excel':
        return LucideIcons.fileSpreadsheet;
      case 'PDF':
        return LucideIcons.fileText;
      default:
        return LucideIcons.file;
    }
  }

  Future<void> _exportWithTemplate(
    BuildContext context,
    WidgetRef ref,
    String format,
    String template,
  ) async {
    HapticFeedback.mediumImpact();
    final spacing = ref.read(spacingProvider);
    final ctxt = AppLocalizations.of(context)!;
    final plugin =
        await ExportPluginManager.instance.getPlugin(format, template);
    if (plugin == null) return;

    try {
      final bytes = await plugin.generateExport(exportData);
      final extension = format == 'Excel' ? 'xlsx' : 'pdf';
      final fileName =
          'MudraManager_${template}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.$extension';

      await saveExportedFile(bytes, fileName, askUser: true);

      if (context.mounted) {
        SnackbarService.success(ctxt.export_completed(format), spacing);
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        SnackbarService.error(BuddyMessages.errorWith('$e'), spacing);
      }
    }
  }
}

/// One export format grouped into a single glass container (accent bar +
/// tonal icon header, template rows inside) — matches the grouped-list
/// pattern used across the app's manage screens instead of a bare `Card`.
class _FormatGroup extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final ColorScheme color;
  final TextTheme textTheme;
  final AppSpacing spacing;
  final List<String> templates;
  final ValueChanged<String> onTemplateTap;

  const _FormatGroup({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.textTheme,
    required this.spacing,
    required this.templates,
    required this.onTemplateTap,
  });

  @override
  State<_FormatGroup> createState() => _FormatGroupState();
}

class _FormatGroupState extends State<_FormatGroup> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    final textTheme = widget.textTheme;
    final spacing = widget.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header — accent bar + tonal icon + label + count pill
        Padding(
          padding: EdgeInsets.only(
            left: spacing.cardHorizontal,
            bottom: spacing.elementGap,
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: widget.iconColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: spacing.elementGapMin),
              Container(
                padding: EdgeInsets.all(spacing.elementGap),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.iconColor.withValues(alpha: 0.12),
                      widget.iconColor.withValues(alpha: 0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(spacing.radiusSmall),
                ),
                child: Icon(widget.icon, size: 16, color: widget.iconColor),
              ),
              SizedBox(width: spacing.elementGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      widget.subtitle,
                      style: textTheme.bodySmall
                          ?.copyWith(color: color.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (widget.templates.isNotEmpty)
                InkWell(
                  onTap: () => setState(() => _expanded = !_expanded),
                  borderRadius: BorderRadius.circular(spacing.radiusSmall),
                  child: Padding(
                    padding: EdgeInsets.all(spacing.elementGapMin),
                    child: AnimatedRotation(
                      duration: spacing.animFast,
                      turns: _expanded ? 0.5 : 0,
                      child: Icon(
                        LucideIcons.chevronDown,
                        size: 18,
                        color: color.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Glass container of template rows
        if (widget.templates.isNotEmpty)
          AnimatedSize(
            duration: spacing.animNormal,
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: !_expanded
                ? const SizedBox(width: double.infinity)
                : Container(
                    decoration: BoxDecoration(
                      color: color.surface.withValues(alpha: 0.75),
                      borderRadius:
                          BorderRadius.circular(spacing.radiusMedium + 4),
                      border: Border.all(
                        color: color.outlineVariant.withValues(alpha: 0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.onSurface.withValues(alpha: 0.03),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: widget.templates.asMap().entries.map((entry) {
                        final isLast = entry.key == widget.templates.length - 1;
                        return Column(
                          children: [
                            InkWell(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                widget.onTemplateTap(entry.value);
                              },
                              borderRadius: BorderRadius.vertical(
                                top: entry.key == 0
                                    ? Radius.circular(spacing.radiusMedium + 4)
                                    : Radius.zero,
                                bottom: isLast
                                    ? Radius.circular(spacing.radiusMedium + 4)
                                    : Radius.zero,
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(spacing.cardInner),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        entry.value,
                                        style: textTheme.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      LucideIcons.download,
                                      size: 18,
                                      color: color.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (!isLast)
                              Divider(
                                height: 1,
                                indent: spacing.cardInner,
                                endIndent: spacing.cardInner,
                                color:
                                    color.outlineVariant.withValues(alpha: 0.3),
                              ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
      ],
    );
  }
}

/// Skeleton placeholder for a single format group while its templates load.
class _FormatGroupSkeleton extends StatelessWidget {
  final AppSpacing spacing;
  final ColorScheme color;

  const _FormatGroupSkeleton({required this.spacing, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: color.surface.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(spacing.radiusMedium + 4),
        border: Border.all(color: color.outlineVariant.withValues(alpha: 0.3)),
      ),
    );
  }
}
