import 'package:mudra_manager/core/utils/safe_date_format.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:mudra_manager/core/utils/file_utils.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/import_export/data/excel_export_service.dart';
import 'package:mudra_manager/core/state/app_screen_state.dart';
import 'package:mudra_manager/shared/templates/screen_shell.dart';
import 'package:mudra_manager/shared/widgets/ambient_brand_section.dart';
import 'package:mudra_manager/shared/widgets/section_header.dart';
import 'package:mudra_manager/shared/widgets/settings_group_card.dart';
import 'package:mudra_manager/shared/widgets/setting_item.dart';

class ImportExportScreen extends ConsumerStatefulWidget {
  const ImportExportScreen({super.key});

  @override
  ConsumerState<ImportExportScreen> createState() => _ImportExportScreenState();
}

class _ImportExportScreenState extends ConsumerState<ImportExportScreen> {
  DateTime _exportStart = DateTime.now().subtract(const Duration(days: 30));
  DateTime _exportEnd = DateTime.now();
  bool _exporting = false;
  AppLocalizations get ctxt => AppLocalizations.of(context)!;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);

    return ScreenShell(
      config: ScreenShellConfig(
        title: ctxt.importExport_title,
        appBarMode: AppBarMode.standard,
        enableRefresh: false,
      ),
      actions: ScreenActions.empty,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth > 600 ? 600.0 : double.infinity;
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.cardHorizontal,
                  vertical: spacing.cardVertical,
                ),
                children: [
                  _ExportSection(
                    reduceMotion: reduceMotion,
                    exportStart: _exportStart,
                    exportEnd: _exportEnd,
                    exporting: _exporting,
                    onExportStartChanged: (start) => setState(() => _exportStart = start),
                    onExportEndChanged: (end) => setState(() => _exportEnd = end),
                    onExport: () => _doExport,
                  ),
                  SizedBox(height: spacing.sectionGap),
                  _ImportSection(
                    reduceMotion: reduceMotion,
                    onImport: () => _pickAndImport,
                  ),
                  SizedBox(height: spacing.sectionGap),
                  const _InfoCard(),
                  SizedBox(height: spacing.sectionGap),
                  const AmbientBrandSection(showSignature: false, absorbBottomInset: false),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _doExport(AppSpacing spacing) async {
    setState(() => _exporting = true);
    try {
      final bytes = await ExcelExportService.exportTransactions(
        isarService: ref.read(isarServiceProvider),
        startDate: _exportStart,
        endDate: DateTime(
            _exportEnd.year, _exportEnd.month, _exportEnd.day, 23, 59, 59),
      );
      final fileName =
          'Mudra_${safeDateFormat('yyyyMMdd').format(_exportStart)}_${safeDateFormat('yyyyMMdd').format(_exportEnd)}.xlsx';
      await saveExportedFile(bytes, fileName, askUser: true);
      SnackbarService.success(BuddyMessages.exportSuccess, spacing);
    } catch (e) {
      SnackbarService.error(BuddyMessages.exportFailed('$e'), spacing);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _pickAndImport(AppSpacing spacing) async {
    HapticFeedback.mediumImpact();
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;

      final bytes = await file.readAsBytes();

      if (bytes.isEmpty) {
        SnackbarService.error(BuddyMessages.invalidBackupFile, spacing);
        return;
      }

      if (context.mounted) {
        context.push(
          AppRoutes.importPreview,
          extra: bytes,
        );
      }
    } catch (e, _) {
      SnackbarService.error(BuddyMessages.errorWith('$e'), spacing);
    }
  }
}

class _ExportSection extends ConsumerWidget {
  final bool reduceMotion;
  final DateTime exportStart;
  final DateTime exportEnd;
  final bool exporting;
  final void Function(DateTime) onExportStartChanged;
  final void Function(DateTime) onExportEndChanged;
  final VoidCallback onExport;

  const _ExportSection({
    required this.reduceMotion,
    required this.exportStart,
    required this.exportEnd,
    required this.exporting,
    required this.onExportStartChanged,
    required this.onExportEndChanged,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final ctxt = AppLocalizations.of(context)!;
    final dateFmt = safeDateFormat('MMM dd, yyyy', ctxt.localeName);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(ctxt.importExport_export),
        SizedBox(height: spacing.elementGap),
        Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: color.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(spacing.radiusMedium),
            side: BorderSide(
              color: color.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(spacing.cardInner),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ctxt.importExport_exportTitle,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: spacing.elementGap),
                Text(
                  ctxt.importExport_exportDesc,
                  style: textTheme.bodySmall?.copyWith(
                    color: color.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: spacing.sectionGap),
                InkWell(
                  onTap: () async {
                    final range = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      initialDateRange: DateTimeRange(
                        start: exportStart,
                        end: exportEnd,
                      ),
                    );
                    if (range != null) {
                      onExportStartChanged(range.start);
                      onExportEndChanged(range.end);
                    }
                  },
                  borderRadius: BorderRadius.circular(spacing.radiusSmall),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing.cardHorizontal + 4,
                      vertical: spacing.cardVertical + 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(spacing.radiusSmall),
                      border: Border.all(
                        color: color.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.calendarRange,
                            size: 18, color: color.primary),
                        SizedBox(width: spacing.elementGap),
                        Text(
                          '${dateFmt.format(exportStart)} — ${dateFmt.format(exportEnd)}',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          LucideIcons.chevronDown,
                          size: 16,
                          color: color.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: spacing.sectionGap),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: exporting ? null : onExport,
                    icon: exporting
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: color.onPrimary,
                            ),
                          )
                        : const Icon(LucideIcons.fileSpreadsheet, size: 18),
                    label: Text(exporting
                        ? ctxt.importExport_exporting
                        : ctxt.importExport_exportAsExcel),
                    style: FilledButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(vertical: spacing.elementGap * 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(spacing.radiusMedium),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ImportSection extends ConsumerWidget {
  final bool reduceMotion;
  final VoidCallback onImport;

  const _ImportSection({
    required this.reduceMotion,
    required this.onImport,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final ctxt = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(ctxt.importExport_import),
        SizedBox(height: spacing.elementGap),
        Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: color.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(spacing.radiusMedium),
            side: BorderSide(
              color: color.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(spacing.cardInner),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ctxt.importExport_importTitle,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: spacing.elementGap),
                Text(
                  ctxt.importExport_importDesc,
                  style: textTheme.bodySmall?.copyWith(
                    color: color.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: spacing.sectionGap),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildChip(
                      ctxt.importExport_excelFormat,
                      LucideIcons.fileSpreadsheet,
                      color,
                      textTheme,
                      spacing,
                    ),
                    _buildChip(
                      ctxt.importExport_bankStatement,
                      LucideIcons.landmark,
                      color,
                      textTheme,
                      spacing,
                    ),
                    _buildChip(
                      ctxt.importExport_otherApps,
                      LucideIcons.arrowLeftRight,
                      color,
                      textTheme,
                      spacing,
                    ),
                  ],
                ),
                SizedBox(height: spacing.sectionGap),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: onImport,
                    icon: const Icon(LucideIcons.filePlus, size: 18),
                    label: Text(ctxt.importExport_pickFile),
                    style: FilledButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(vertical: spacing.elementGap * 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(spacing.radiusMedium),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChip(
    String label,
    IconData icon,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: spacing.elementGap, vertical: spacing.elementGapMin),
      decoration: BoxDecoration(
        color: color.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(spacing.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color.onSurfaceVariant),
          SizedBox(width: spacing.elementGapMin),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: color.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends ConsumerWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final ctxt = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        color: color.primary.withValues(alpha: 0.06),
        border: Border.all(color: color.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.info, color: color.primary, size: 18),
          SizedBox(width: spacing.elementGap),
          Expanded(
            child: Text(
              ctxt.importExport_infoText,
              style: textTheme.bodySmall?.copyWith(
                color: color.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}