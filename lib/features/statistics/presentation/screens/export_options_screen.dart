import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/plugins/export_plugin_manager.dart';
import 'package:mudra_manager/core/providers/singleton_providers.dart';
import 'package:mudra_manager/plugins/export_plugin.dart';
import 'package:mudra_manager/core/utils/file_utils.dart';
import 'package:intl/intl.dart';

final exportFormatsProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  return ref.read(exportPluginManagerProvider).getSupportedFormats();
});

final exportTemplatesProvider = FutureProvider.autoDispose.family<List<String>, String>((ref, format) async {
  return ref.read(exportPluginManagerProvider).getTemplatesForFormat(format);
});

class ExportOptionsScreen extends ConsumerWidget {
  final ExportData exportData;

  const ExportOptionsScreen({super.key, required this.exportData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final formatsAsync = ref.watch(exportFormatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.title_exportOptions),
        backgroundColor: color.surfaceContainer,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: () {
              ref.invalidate(exportFormatsProvider);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: formatsAsync.when(
        loading: () => const Padding(padding: EdgeInsets.all(16), child: DashboardCardSkeleton()),
        error: (err, stack) => Center(child: Text(BuddyMessages.errorWith('$err'))),
        data: (formats) {
          if (formats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.fileX, size: 64, color: color.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text(
                    'No export templates enabled',
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enable templates in Settings → Plugins',
                    style: textTheme.bodySmall?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: formats.length,
            itemBuilder: (context, index) {
              final format = formats[index];
              final templatesAsync = ref.watch(exportTemplatesProvider(format));

              return templatesAsync.when(
                loading: () => Card(
                  child: ListTile(
                    leading: const CircularProgressIndicator(),
                    title: Text(AppLocalizations.of(context)!.common_loading),
                  ),
                ),
                error: (err, stack) => Card(
                  child: ListTile(
                    leading: const Icon(LucideIcons.circleAlert),
                    title: Text(BuddyMessages.errorWith('$err')),
                  ),
                ),
                data: (templates) {
                  if (templates.isEmpty) return const SizedBox.shrink();

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ExpansionTile(
                      leading: Icon(_getFormatIcon(format), color: color.primary),
                      title: Text(format, style: textTheme.titleMedium),
                      subtitle: Text('${templates.length} template${templates.length > 1 ? 's' : ''} available'),
                      children: templates
                          .map(
                            (template) => ListTile(
                              title: Text(template),
                              trailing: const Icon(LucideIcons.download),
                              onTap: () => _exportWithTemplate(context, format, template),
                            ),
                          )
                          .toList(),
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
      BuildContext context, String format, String template,) async {
    final plugin = await ExportPluginManager.instance.getPlugin(format, template);
    if (plugin == null) return;

    try {
      final bytes = await plugin.generateExport(exportData);
      final extension = format == 'Excel' ? 'xlsx' : 'pdf';
      final fileName =
          'MudraManager_${template}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.$extension';

      await saveExportedFile(bytes, fileName, askUser: true);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$format export completed')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }
}
