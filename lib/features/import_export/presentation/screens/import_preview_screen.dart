import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/account/data/account_providers.dart';
import 'package:mudra_manager/features/import_export/data/excel_import_service.dart';
import 'package:mudra_manager/features/import_export/models/column_mapping.dart';
import 'package:mudra_manager/features/import_export/models/import_models.dart';

class ImportPreviewScreen extends ConsumerStatefulWidget {
  final Uint8List fileBytes;
  const ImportPreviewScreen({super.key, required this.fileBytes});

  @override
  ConsumerState<ImportPreviewScreen> createState() =>
      _ImportPreviewScreenState();
}

class _ImportPreviewScreenState extends ConsumerState<ImportPreviewScreen> {
  late List<({String name, int rowCount})> _sheets;
  String? _selectedSheet;
  late List<String> _headers;
  late List<List<String>> _dataRows;
  late ColumnMapping _mapping;
  late List<ImportRow> _parsedRows;
  Account? _selectedAccount;
  String _selectedCurrency = 'INR';
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    debugPrint('[Preview] fileBytes: ${widget.fileBytes.length} bytes');
    _sheets = ExcelImportService.getSheetInfo(widget.fileBytes);
    debugPrint(
      '[Preview] Sheets: ${_sheets.map((s) => '${s.name}(${s.rowCount})').toList()}',
    );
    // Auto-select first sheet with data
    _selectedSheet = _sheets.where((s) => s.rowCount > 1).firstOrNull?.name ??
        _sheets.firstOrNull?.name;
    _loadSheet();
  }

  void _loadSheet() {
    _headers = ExcelImportService.readHeaders(
      widget.fileBytes,
      sheetName: _selectedSheet,
    );
    debugPrint('[Preview] Headers (${_headers.length}): $_headers');
    _dataRows = ExcelImportService.readDataRows(
      widget.fileBytes,
      sheetName: _selectedSheet,
    );
    debugPrint('[Preview] Data rows: ${_dataRows.length}');
    if (_dataRows.isNotEmpty) {
      debugPrint('[Preview] First row: ${_dataRows.first}');
    }
    _mapping = ExcelImportService.autoDetectMapping(_headers);
    debugPrint(
      '[Preview] Mapping: date=${_mapping.dateColumn}, amount=${_mapping.amountColumn}, desc=${_mapping.descriptionColumn}, cat=${_mapping.categoryColumn}, type=${_mapping.typeColumn}, currency=${_mapping.currencyColumn}',
    );
    _parsedRows = ExcelImportService.parseRows(_dataRows, _mapping);
    debugPrint(
      '[Preview] Parsed: ${_parsedRows.length} rows, ${_parsedRows.where((r) => r.isValid).length} valid',
    );
  }

  void _reParse() {
    setState(() {
      _parsedRows = ExcelImportService.parseRows(_dataRows, _mapping);
    });
  }

  int get _validCount => _parsedRows.where((r) => r.isValid).length;
  int get _errorCount => _parsedRows.where((r) => !r.isValid).length;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final accountsAsync = ref.watch(accountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.import_previewImport,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton.icon(
            onPressed:
                _mapping.isValid && _selectedAccount != null && !_importing
                    ? _doImport
                    : null,
            icon: _importing
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color.primary,
                    ),
                  )
                : const Icon(LucideIcons.check, size: 18),
            label: Text(_importing ? 'Importing...' : 'Import'),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.cardHorizontal,
          vertical: spacing.cardVertical,
        ),
        children: [
          // ── SHEET SELECTOR ──
          if (_sheets.length > 1)
            _buildSheetSelector(color, textTheme, spacing),
          if (_sheets.length > 1) SizedBox(height: spacing.sectionGap),

          // ── STATS ──
          _buildStatsRow(color, textTheme, spacing),
          SizedBox(height: spacing.sectionGap),

          // ── COLUMN MAPPING ──
          _buildMappingCard(color, textTheme, spacing),
          SizedBox(height: spacing.sectionGap),

          // ── ACCOUNT SELECTION ──
          _buildAccountSelector(color, textTheme, spacing, accountsAsync),
          SizedBox(height: spacing.sectionGap),

          // ── CURRENCY (only if not mapped from file) ──
          if (_mapping.currencyColumn == null)
            _buildCurrencySelector(color, textTheme, spacing),
          if (_mapping.currencyColumn == null)
            SizedBox(height: spacing.sectionGap),

          // ── DATA PREVIEW ──
          _buildPreviewTable(color, textTheme, spacing),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSheetSelector(
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
        side: BorderSide(color: color.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.cardInner),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.fileSpreadsheet,
                  size: 18,
                  color: color.primary,
                ),
                SizedBox(width: spacing.elementGap),
                Text(
                  'Sheet',
                  style: textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            SizedBox(height: spacing.elementGap + 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _sheets.map((s) {
                final isSelected = _selectedSheet == s.name;
                return ChoiceChip(
                  label: Text('${s.name} (${s.rowCount - 1})'),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      _selectedSheet = s.name;
                      _loadSheet();
                    });
                  },
                  avatar: Icon(
                    isSelected ? LucideIcons.check : LucideIcons.table,
                    size: 16,
                  ),
                  showCheckmark: false,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildStatChip(
            '$_validCount',
            'Valid',
            LucideIcons.circleCheck,
            color.primary,
            color,
            textTheme,
            spacing,
          ),
        ),
        SizedBox(width: spacing.elementGap),
        Expanded(
          child: _buildStatChip(
            '$_errorCount',
            'Errors',
            LucideIcons.circleX,
            color.error,
            color,
            textTheme,
            spacing,
          ),
        ),
        SizedBox(width: spacing.elementGap),
        Expanded(
          child: _buildStatChip(
            '${_dataRows.length}',
            'Total',
            LucideIcons.rows3,
            color.primary,
            color,
            textTheme,
            spacing,
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip(
    String value,
    String label,
    IconData icon,
    Color accent,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Container(
      padding: EdgeInsets.all(spacing.cardHorizontal + 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: accent),
          SizedBox(height: spacing.elementGapMin),
          Text(
            value,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: accent,
            ),
          ),
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

  Widget _buildMappingCard(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    final fields = [
      ('Date', _mapping.dateColumn, LucideIcons.calendar, true),
      ('Amount', _mapping.amountColumn, LucideIcons.coins, true),
      ('Description', _mapping.descriptionColumn, LucideIcons.fileText, false),
      ('Category', _mapping.categoryColumn, LucideIcons.tag, false),
      (
        'Type (Income/Expense)',
        _mapping.typeColumn,
        LucideIcons.arrowLeftRight,
        false
      ),
      ('Currency', _mapping.currencyColumn, LucideIcons.banknote, false),
    ];

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: color.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        side: BorderSide(color: color.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.cardInner),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.columns3, size: 18, color: color.primary),
                SizedBox(width: spacing.elementGap),
                Text(
                  'Column Mapping',
                  style: textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            SizedBox(height: spacing.sectionGap),
            ...fields.map((f) {
              final (label, currentCol, icon, required) = f;
              final mapped = currentCol != null && currentCol < _headers.length;
              return Padding(
                padding: EdgeInsets.only(bottom: spacing.elementGap),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      size: 16,
                      color: mapped
                          ? color.primary
                          : color.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    SizedBox(width: spacing.elementGap),
                    Expanded(
                      child: Text(
                        label,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: required && !mapped
                              ? color.error
                              : color.onSurface,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 160,
                      child: DropdownButtonFormField<int?>(
                        key: ValueKey('${label}_${currentCol}'),
                        value: currentCol,
                        isDense: true,
                        isExpanded: true,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(spacing.radiusSmall),
                          ),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('—')),
                          ..._headers.asMap().entries.map(
                                (e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(
                                    e.value.isEmpty
                                        ? 'Col ${e.key + 1}'
                                        : e.value,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                        ],
                        onChanged: (val) {
                          final v = val ?? ColumnMapping.clearColumn;
                          setState(() {
                            _mapping = switch (label) {
                              'Date' => _mapping.copyWith(dateColumn: v),
                              'Amount' => _mapping.copyWith(amountColumn: v),
                              'Description' =>
                                _mapping.copyWith(descriptionColumn: v),
                              'Category' =>
                                _mapping.copyWith(categoryColumn: v),
                              'Currency' =>
                                _mapping.copyWith(currencyColumn: v),
                              _ => _mapping.copyWith(typeColumn: v),
                            };
                          });
                          _reParse();
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSelector(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AsyncValue<List<Account>> accountsAsync,
  ) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: color.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        side: BorderSide(color: color.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.cardInner),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.landmark, size: 18, color: color.primary),
                SizedBox(width: spacing.elementGap),
                Text(
                  'Default Account',
                  style: textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            SizedBox(height: spacing.elementGap),
            Text(
              'All imported transactions will be added to this account.',
              style:
                  textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
            ),
            SizedBox(height: spacing.elementGap + 4),
            accountsAsync.when(
              data: (accounts) {
                if (_selectedAccount == null && accounts.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted)
                      setState(() => _selectedAccount = accounts.first);
                  });
                }
                return DropdownButtonFormField<int>(
                  key: ValueKey('account_${_selectedAccount?.id}'),
                  value: _selectedAccount?.id,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(spacing.radiusSmall),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  items: accounts
                      .map(
                        (a) =>
                            DropdownMenuItem(value: a.id, child: Text(a.name)),
                      )
                      .toList(),
                  onChanged: (id) {
                    setState(() {
                      _selectedAccount = accounts.firstWhere((a) => a.id == id);
                    });
                  },
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => Text(BuddyMessages.genericError),
            ),
          ],
        ),
      ),
    );
  }

  static const _currencies = [
    ('INR', '₹', 'Indian Rupee'),
    ('USD', '\$', 'US Dollar'),
    ('EUR', '€', 'Euro'),
    ('GBP', '£', 'British Pound'),
    ('JPY', '¥', 'Japanese Yen'),
    ('AUD', 'A\$', 'Australian Dollar'),
    ('CAD', 'C\$', 'Canadian Dollar'),
    ('SGD', 'S\$', 'Singapore Dollar'),
    ('AED', 'AED', 'UAE Dirham'),
    ('SAR', 'SAR', 'Saudi Riyal'),
    ('CHF', 'CHF', 'Swiss Franc'),
    ('CNY', '¥', 'Chinese Yuan'),
    ('HKD', 'HK\$', 'Hong Kong Dollar'),
    ('KRW', '₩', 'Korean Won'),
    ('MYR', 'RM', 'Malaysian Ringgit'),
    ('THB', '฿', 'Thai Baht'),
    ('IDR', 'Rp', 'Indonesian Rupiah'),
    ('PHP', '₱', 'Philippine Peso'),
    ('BDT', '৳', 'Bangladeshi Taka'),
    ('NPR', 'Rs', 'Nepalese Rupee'),
    ('LKR', 'Rs', 'Sri Lankan Rupee'),
    ('PKR', 'Rs', 'Pakistani Rupee'),
    ('ZAR', 'R', 'South African Rand'),
    ('BRL', 'R\$', 'Brazilian Real'),
    ('MXN', 'MX\$', 'Mexican Peso'),
    ('RUB', '₽', 'Russian Ruble'),
    ('TRY', '₺', 'Turkish Lira'),
    ('NZD', 'NZ\$', 'New Zealand Dollar'),
    ('SEK', 'kr', 'Swedish Krona'),
    ('NOK', 'kr', 'Norwegian Krone'),
    ('PLN', 'zł', 'Polish Zloty'),
    ('TWD', 'NT\$', 'Taiwan Dollar'),
    ('VND', '₫', 'Vietnamese Dong'),
    ('NGN', '₦', 'Nigerian Naira'),
    ('KES', 'KSh', 'Kenyan Shilling'),
    ('EGP', 'E£', 'Egyptian Pound'),
  ];

  Widget _buildCurrencySelector(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    final current = _currencies.firstWhere(
      (c) => c.$1 == _selectedCurrency,
      orElse: () => _currencies.first,
    );

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: color.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        side: BorderSide(color: color.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.cardInner),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.banknote, size: 18, color: color.primary),
                SizedBox(width: spacing.elementGap),
                Text(
                  'Currency',
                  style: textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  'No currency column detected',
                  style: textTheme.labelSmall?.copyWith(
                    color: color.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.elementGap),
            Text(
              'Select the currency for all imported transactions.',
              style:
                  textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
            ),
            SizedBox(height: spacing.elementGap + 4),
            InkWell(
              onTap: () => _showCurrencyPicker(color, textTheme, spacing),
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
                    Text(
                      current.$2,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color.primary,
                      ),
                    ),
                    SizedBox(width: spacing.elementGap),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            current.$1,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            current.$3,
                            style: textTheme.bodySmall?.copyWith(
                              color: color.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      LucideIcons.chevronDown,
                      size: 18,
                      color: color.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCurrencyPicker(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    final searchController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final query = searchController.text.toLowerCase();
          final filtered = _currencies.where((c) {
            return c.$1.toLowerCase().contains(query) ||
                c.$3.toLowerCase().contains(query);
          }).toList();

          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            maxChildSize: 0.9,
            minChildSize: 0.4,
            expand: false,
            builder: (context, scrollController) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    controller: searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search currency...',
                      prefixIcon: const Icon(LucideIcons.search, size: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (_) => setModalState(() {}),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final c = filtered[index];
                      final isSelected = c.$1 == _selectedCurrency;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSelected
                              ? color.primary.withValues(alpha: 0.12)
                              : color.surfaceContainerHighest,
                          child: Text(
                            c.$2,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? color.primary
                                  : color.onSurfaceVariant,
                            ),
                          ),
                        ),
                        title: Text(
                          c.$1,
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? color.primary : color.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          c.$3,
                          style: textTheme.bodySmall?.copyWith(
                            color: color.onSurfaceVariant,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(
                                LucideIcons.check,
                                color: color.primary,
                                size: 20,
                              )
                            : null,
                        onTap: () {
                          setState(() => _selectedCurrency = c.$1);
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPreviewTable(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    final previewRows = _parsedRows.take(20).toList();

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: color.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        side: BorderSide(color: color.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.cardInner),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.table, size: 18, color: color.primary),
                SizedBox(width: spacing.elementGap),
                Text(
                  'Preview (first 20 rows)',
                  style: textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            SizedBox(height: spacing.sectionGap),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 16,
                headingRowHeight: 40,
                dataRowMinHeight: 36,
                dataRowMaxHeight: 48,
                columns: const [
                  DataColumn(label: Text('#')),
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Amount'), numeric: true),
                  DataColumn(label: Text('Currency')),
                  DataColumn(label: Text('Type')),
                  DataColumn(label: Text('Description')),
                  DataColumn(label: Text('Status')),
                ],
                rows: previewRows.map((row) {
                  final hasError = !row.isValid;
                  final currency = row.currency ??
                      (_mapping.currencyColumn == null
                          ? _selectedCurrency
                          : null);
                  return DataRow(
                    color: hasError
                        ? WidgetStateProperty.all(
                            color.errorContainer.withValues(alpha: 0.3),
                          )
                        : null,
                    cells: [
                      DataCell(Text('${row.rowIndex}')),
                      DataCell(
                        Text(
                          row.date != null
                              ? '${row.date!.day}/${row.date!.month}/${row.date!.year}'
                              : '—',
                        ),
                      ),
                      DataCell(
                        Text(
                          row.amount != null
                              ? row.amount!.toStringAsFixed(0)
                              : '—',
                        ),
                      ),
                      DataCell(Text(currency ?? '—')),
                      DataCell(Text(row.isExpense ? 'Expense' : 'Income')),
                      DataCell(
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 150),
                          child: Text(
                            row.description ?? '—',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(
                        hasError
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.circleX,
                                    size: 14,
                                    color: color.error,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    row.error ?? 'Error',
                                    style: TextStyle(
                                      color: color.error,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              )
                            : Icon(
                                LucideIcons.circleCheck,
                                size: 14,
                                color: color.primary,
                              ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _doImport() async {
    if (_selectedAccount == null) {
      SnackbarService.error(BuddyMessages.pickAccount);
      return;
    }
    if (_validCount == 0) {
      SnackbarService.error(BuddyMessages.genericError);
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _importing = true);

    // Show blocking overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: Center(
          child: Card(
            margin: const EdgeInsets.all(32),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(
                    AppLocalizations.of(context)!.import_importing(_validCount),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.import_dontClose,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    try {
      final isarService = ref.read(isarServiceProvider);
      final categoryMap =
          await ExcelImportService.buildCategoryMap(isarService);

      final result = await ExcelImportService.importRows(
        rows: _parsedRows,
        defaultAccount: _selectedAccount!,
        categoryMap: categoryMap,
        isarService: isarService,
      );

      if (mounted) {
        Navigator.of(context).pop(); // dismiss loader
        _showResultDialog(result);
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop(); // dismiss loader
      SnackbarService.error(BuddyMessages.errorWith('$e'));
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  void _showResultDialog(ImportResult result) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          result.imported > 0
              ? LucideIcons.circleCheck
              : LucideIcons.circleAlert,
          color: result.imported > 0 ? color.primary : color.error,
          size: 48,
        ),
        title: Text(
          result.imported > 0 ? AppLocalizations.of(context)!.import_complete : AppLocalizations.of(context)!.import_failed,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _resultRow(
              AppLocalizations.of(context)!.import_imported,
              '${result.imported}',
              color.primary,
              textTheme,
            ),
            if (result.categoriesCreated > 0)
              _resultRow(
                AppLocalizations.of(context)!.import_categoriesCreated,
                '${result.categoriesCreated}',
                color.secondary,
                textTheme,
              ),
            if (result.duplicates > 0)
              _resultRow(
                AppLocalizations.of(context)!.import_duplicatesSkipped,
                '${result.duplicates}',
                color.tertiary,
                textTheme,
              ),
            if (result.skipped > 0)
              _resultRow(
                AppLocalizations.of(context)!.import_errorsSkipped,
                '${result.skipped}',
                color.error,
                textTheme,
              ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              ctx.pop();
              if (mounted) context.pop();
            },
            child: Text(AppLocalizations.of(context)!.common_done),
          ),
        ],
      ),
    );
  }

  Widget _resultRow(
    String label,
    String value,
    Color accent,
    TextTheme textTheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: textTheme.bodyMedium),
          Text(
            value,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}
