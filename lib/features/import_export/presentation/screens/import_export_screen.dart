import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:mudra_manager/core/utils/file_utils.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/import_export/data/excel_export_service.dart';

class ImportExportScreen extends ConsumerStatefulWidget {
  const ImportExportScreen({super.key});

  @override
  ConsumerState<ImportExportScreen> createState() => _ImportExportScreenState();
}

class _ImportExportScreenState extends ConsumerState<ImportExportScreen> {
  DateTime _exportStart = DateTime.now().subtract(const Duration(days: 30));
  DateTime _exportEnd = DateTime.now();
  bool _exporting = false;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Import & Export',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.cardHorizontal,
          vertical: spacing.cardVertical,
        ),
        children: [
          // ── EXPORT SECTION ──
          _buildSectionHeader('Export', LucideIcons.upload, color, textTheme),
          SizedBox(height: spacing.elementGap),
          _buildExportCard(color, textTheme, spacing),
          SizedBox(height: spacing.sectionGap),

          // ── IMPORT SECTION ──
          _buildSectionHeader('Import', LucideIcons.download, color, textTheme),
          SizedBox(height: spacing.elementGap),
          _buildImportCard(color, textTheme, spacing),
          SizedBox(height: spacing.sectionGap),

          // ── INFO ──
          Container(
            padding: EdgeInsets.all(spacing.cardInner),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
              color: color.primary.withValues(alpha: 0.06),
              border: Border.all(
                color: color.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.info, color: color.primary, size: 18),
                SizedBox(width: spacing.elementGap + 4),
                Expanded(
                  child: Text(
                    'Export creates an Excel file with all transaction details. '
                    'Import supports .xlsx files from other finance apps or manual spreadsheets.',
                    style: textTheme.bodySmall?.copyWith(
                      color: color.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: color.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildExportCard(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    final dateFmt = DateFormat('MMM dd, yyyy');

    return Card(
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
              'Export Transactions',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: spacing.elementGap),
            Text(
              'Download your transactions as an Excel file.',
              style: textTheme.bodySmall?.copyWith(
                color: color.onSurfaceVariant,
              ),
            ),
            SizedBox(height: spacing.sectionGap),

            // Date range
            InkWell(
              onTap: () async {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  initialDateRange: DateTimeRange(
                    start: _exportStart,
                    end: _exportEnd,
                  ),
                );
                if (range != null) {
                  setState(() {
                    _exportStart = range.start;
                    _exportEnd = range.end;
                  });
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
                    Icon(LucideIcons.calendarRange, size: 18, color: color.primary),
                    SizedBox(width: spacing.elementGap),
                    Text(
                      '${dateFmt.format(_exportStart)} — ${dateFmt.format(_exportEnd)}',
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

            // Export button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _exporting ? null : _doExport,
                icon: _exporting
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: color.onPrimary,
                        ),
                      )
                    : const Icon(LucideIcons.fileSpreadsheet, size: 18),
                label: Text(_exporting ? 'Exporting...' : 'Export as Excel'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportCard(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Card(
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
              'Import from Excel',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: spacing.elementGap),
            Text(
              'Import transactions from an .xlsx file. '
              'You\'ll be able to preview and map columns before importing.',
              style: textTheme.bodySmall?.copyWith(
                color: color.onSurfaceVariant,
              ),
            ),
            SizedBox(height: spacing.sectionGap),

            // Supported formats
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildChip('Excel (.xlsx)', LucideIcons.fileSpreadsheet, color, textTheme),
                _buildChip('Bank Statement', LucideIcons.landmark, color, textTheme),
                _buildChip('Other Apps', LucideIcons.arrowLeftRight, color, textTheme),
              ],
            ),
            SizedBox(height: spacing.sectionGap),

            // Import button
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: _pickAndImport,
                icon: const Icon(LucideIcons.filePlus, size: 18),
                label: const Text('Pick Excel File'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(
    String label,
    IconData icon,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color.onSurfaceVariant),
          const SizedBox(width: 6),
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

  Future<void> _doExport() async {
    setState(() => _exporting = true);
    try {
      final bytes = await ExcelExportService.exportTransactions(
        isarService: ref.read(isarServiceProvider),
        startDate: _exportStart,
        endDate: DateTime(_exportEnd.year, _exportEnd.month, _exportEnd.day, 23, 59, 59),
      );
      final fileName =
          'Mudra_${DateFormat('yyyyMMdd').format(_exportStart)}_${DateFormat('yyyyMMdd').format(_exportEnd)}.xlsx';
      await saveExportedFile(bytes, fileName, askUser: true);
      SnackbarService.success(BuddyMessages.exportSuccess);
    } catch (e) {
      SnackbarService.error(BuddyMessages.exportFailed('$e'));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _pickAndImport() async {
    HapticFeedback.mediumImpact();
    try {
      debugPrint('[Import] Picking file...');
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        debugPrint('[Import] No file selected');
        return;
      }
      final file = result.files.first;
      debugPrint('[Import] File: name=${file.name}, size=${file.size}, path=${file.path}, hasBytes=${file.bytes != null}');

      Uint8List? bytes = file.bytes;

      if (bytes == null && file.path != null) {
        debugPrint('[Import] bytes is null, reading from path: ${file.path}');
        final f = File(file.path!);
        if (await f.exists()) {
          bytes = await f.readAsBytes();
          debugPrint('[Import] Read ${bytes.length} bytes from file path');
        } else {
          debugPrint('[Import] File does not exist at path: ${file.path}');
        }
      }

      if (bytes == null || bytes.isEmpty) {
        debugPrint('[Import] FAILED: bytes is null or empty');
        SnackbarService.error(BuddyMessages.invalidBackupFile);
        return;
      }

      debugPrint('[Import] SUCCESS: ${bytes.length} bytes, navigating to preview');

      if (mounted) {
        context.push(
          AppRoutes.importPreview,
          extra: bytes,
        );
      }
    } catch (e, stack) {
      debugPrint('[Import] ERROR: $e');
      debugPrint('[Import] Stack: $stack');
      SnackbarService.error(BuddyMessages.errorWith('$e'));
    }
  }
}
