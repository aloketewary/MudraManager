import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/utils/category_resolver.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:mudra_manager/features/import_export/models/column_mapping.dart';
import 'package:mudra_manager/features/import_export/models/import_models.dart';

class ExcelImportService {
  static final _log = AppLog(getLogger(), 'ExcelImport');

  /// Get all sheet names with row counts.
  static List<({String name, int rowCount})> getSheetInfo(Uint8List bytes) {
    final excel = Excel.decodeBytes(bytes);
    return excel.tables.entries.map((e) {
      return (name: e.key, rowCount: e.value.rows.length);
    }).toList();
  }

  /// Read headers from a specific sheet (or first with data).
  static List<String> readHeaders(Uint8List bytes, {String? sheetName}) {
    _log.i('Decoding ${bytes.length} bytes');
    final excel = Excel.decodeBytes(bytes);
    final sheetNames = excel.tables.keys.toList();
    _log.i('Sheets: $sheetNames');
    if (sheetNames.isEmpty) return [];

    // If a specific sheet is requested, use it
    if (sheetName != null && excel.tables.containsKey(sheetName)) {
      final sheet = excel.tables[sheetName]!;
      final allRows = sheet.rows;
      _log.i('Sheet "$sheetName": ${allRows.length} rows');
      if (allRows.isEmpty) return [];
      final headerRow = allRows.first;
      _log.i('Header raw: ${headerRow.map((c) => c?.value).toList()}');
      return List.generate(
        headerRow.length,
        (i) => headerRow[i]?.value?.toString().trim() ?? 'Column ${i + 1}',
      );
    }

    // Otherwise find first sheet with rows
    for (final name in sheetNames) {
      final sheet = excel.tables[name]!;
      final allRows = sheet.rows;
      _log.i('Sheet "$name": ${allRows.length} rows (maxRows=${sheet.maxRows}, maxCols=${sheet.maxCols})');
      if (allRows.isEmpty) continue;

      final headerRow = allRows.first;
      _log.i('Header raw: ${headerRow.map((c) => c?.value).toList()}');
      return List.generate(
        headerRow.length,
        (i) => headerRow[i]?.value?.toString().trim() ?? 'Column ${i + 1}',
      );
    }
    return [];
  }

  /// Read all data rows (skip header).
  static List<List<String>> readDataRows(Uint8List bytes, {String? sheetName, int maxRows = 500}) {
    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) return [];

    // If a specific sheet is requested, use it
    if (sheetName != null && excel.tables.containsKey(sheetName)) {
      return _extractDataRows(excel.tables[sheetName]!, maxRows);
    }

    // Otherwise find first sheet with data
    for (final name in excel.tables.keys) {
      final sheet = excel.tables[name]!;
      final allRows = sheet.rows;
      _log.i('readDataRows "$name": ${allRows.length} rows');
      if (allRows.length > 1) {
        return _extractDataRows(sheet, maxRows);
      }
    }
    return [];
  }

  static List<List<String>> _extractDataRows(Sheet sheet, int maxRows) {
    final allRows = sheet.rows;
    if (allRows.isEmpty) return [];
    final colCount = allRows.first.length;
    final rows = <List<String>>[];

    for (int i = 1; i < allRows.length && i <= maxRows; i++) {
      final sheetRow = allRows[i];
      final hasData = sheetRow.any((cell) =>
          cell != null && cell.value != null && cell.value.toString().trim().isNotEmpty);
      if (!hasData) continue;

      rows.add(
        List.generate(
          colCount,
          (j) => j < sheetRow.length
              ? (sheetRow[j]?.value?.toString().trim() ?? '')
              : '',
        ),
      );
    }
    return rows;
  }

  /// Auto-detect column mapping from headers.
  static ColumnMapping autoDetectMapping(List<String> headers) {
    int? dateCol, amountCol, descCol, catCol, accountCol, typeCol, currencyCol;

    for (int i = 0; i < headers.length; i++) {
      final h = headers[i].toLowerCase().trim();
      if (h.isEmpty) continue;

      // Exact matches first (highest priority)
      if (dateCol == null && (h == 'date' || h == 'txn date' || h == 'transaction date')) {
        dateCol = i;
      } else if (amountCol == null && (h == 'amount' || h == 'sum' || h == 'total' || h == 'value' || h == 'debit amount' || h == 'credit amount')) {
        amountCol = i;
      } else if (descCol == null && (h == 'description' || h == 'narration' || h == 'particulars' || h == 'remarks' || h == 'note' || h == 'memo' || h == 'detail' || h == 'details')) {
        descCol = i;
      } else if (typeCol == null && (h == 'type' || h == 'transaction type' || h == 'cr/dr' || h == 'dr/cr' || h == 'income/expense')) {
        typeCol = i;
      } else if (catCol == null && (h == 'category' || h == 'tag' || h == 'head' || h == 'expense category')) {
        catCol = i;
      } else if (accountCol == null && (h == 'account' || h == 'bank' || h == 'source' || h == 'a/c' || h == 'account name')) {
        accountCol = i;
      } else if (currencyCol == null && (h == 'currency' || h == 'ccy' || h == 'currency code')) {
        currencyCol = i;
      }
    }

    // Fuzzy fallback for unmatched columns
    for (int i = 0; i < headers.length; i++) {
      final h = headers[i].toLowerCase().trim();
      if (h.isEmpty) continue;
      if (i == dateCol || i == amountCol || i == descCol || i == typeCol || i == catCol || i == accountCol || i == currencyCol) continue;

      if (dateCol == null && h.contains('date')) dateCol = i;
      else if (amountCol == null && (h.contains('amount') || h.contains('debit') || h.contains('credit'))) amountCol = i;
      else if (descCol == null && (h.contains('desc') || h.contains('narr') || h.contains('particular') || h.contains('remark'))) descCol = i;
      else if (currencyCol == null && (h.contains('curr') || h.contains('ccy'))) currencyCol = i;
    }

    String dateFormat = 'dd/MM/yyyy';
    // Will be refined during preview

    return ColumnMapping(
      dateColumn: dateCol,
      amountColumn: amountCol,
      descriptionColumn: descCol,
      categoryColumn: catCol,
      accountColumn: accountCol,
      typeColumn: typeCol,
      currencyColumn: currencyCol,
      dateFormat: dateFormat,
    );
  }

  /// Parse rows using the given mapping.
  static List<ImportRow> parseRows(
    List<List<String>> dataRows,
    ColumnMapping mapping,
  ) {
    final parsed = <ImportRow>[];

    for (int i = 0; i < dataRows.length; i++) {
      final row = dataRows[i];
      try {
        final date = _parseDate(
          _cellAt(row, mapping.dateColumn),
          mapping.dateFormat,
        );
        final rawAmount = _cellAt(row, mapping.amountColumn);
        final amount = _parseAmount(rawAmount);
        final description = _cellAt(row, mapping.descriptionColumn);
        final category = _cellAt(row, mapping.categoryColumn);
        final account = _cellAt(row, mapping.accountColumn);
        final currency = _cellAt(row, mapping.currencyColumn) ?? _detectCurrency(rawAmount);
        final typeStr = _cellAt(row, mapping.typeColumn)?.toLowerCase() ?? '';

        bool isExpense = true;
        if (typeStr.isNotEmpty) {
          isExpense = !_matchesAny(typeStr, ['credit', 'cr', 'income', 'received', 'deposit']);
        } else if (amount != null && rawAmount != null) {
          if (rawAmount.startsWith('-') || rawAmount.startsWith('(')) {
            isExpense = true;
          }
        }

        String? error;
        if (date == null) error = 'Invalid date';
        if (amount == null || amount <= 0) error = error ?? 'Invalid amount';

        parsed.add(ImportRow(
          rowIndex: i + 2,
          date: date,
          amount: amount?.abs(),
          description: description,
          category: category,
          account: account,
          currency: currency,
          isExpense: isExpense,
          error: error,
        ));
      } catch (e) {
        parsed.add(ImportRow(
          rowIndex: i + 2,
          error: 'Parse error: $e',
        ));
      }
    }
    return parsed;
  }

  /// Import valid rows into the database.
  /// Auto-creates missing categories with relevant icons/colors/keywords.
  static Future<ImportResult> importRows({
    required List<ImportRow> rows,
    required Account defaultAccount,
    required Map<String, Category> categoryMap,
    required IsarService isarService,
    bool autoCreateCategories = true,
  }) async {
    final isar = await isarService.getInstance();
    int imported = 0;
    int skipped = 0;
    int duplicates = 0;
    int categoriesCreated = 0;
    final errors = <String>[];

    final validRows = rows.where((r) => r.isValid).toList();

    for (final row in validRows) {
      // Duplicate check: same date + amount + description
      final isDuplicate = await _checkDuplicate(
        isar, row.date!, row.amount!, row.description,
      );
      if (isDuplicate) {
        duplicates++;
        continue;
      }

      try {
        final txn = Transaction.create(
          date: row.date!,
          amount: row.amount!,
          isExpense: row.isExpense,
          description: row.description,
        );

        txn.account.value = defaultAccount;

        // Match or auto-create category
        if (row.category != null && row.category!.isNotEmpty) {
          final catKey = row.category!.toLowerCase().trim();
          var matched = categoryMap[catKey];

          if (matched == null && autoCreateCategories) {
            // Auto-create with relevant icon/color/keywords
            matched = CategoryResolver.createCategory(row.category!);
            await isar.writeTxn(() async {
              await isar.categorys.put(matched!);
            });
            // Add to map so subsequent rows reuse it
            categoryMap[catKey] = matched;
            categoriesCreated++;
            _log.i('Auto-created category: ${row.category}');
          }

          txn.category.value = matched;
        }

        txn.isFromSms = false;

        await isar.writeTxn(() async {
          await isar.transactions.put(txn);
          await txn.account.save();
          await txn.category.save();
        });

        imported++;
      } catch (e) {
        errors.add('Row ${row.rowIndex}: $e');
        skipped++;
      }
    }

    skipped += rows.where((r) => !r.isValid).length;

    _log.i('Import done: $imported imported, $skipped skipped, $duplicates duplicates, $categoriesCreated categories created');

    return ImportResult(
      imported: imported,
      skipped: skipped,
      duplicates: duplicates,
      errors: errors,
      categoriesCreated: categoriesCreated,
    );
  }

  /// Build a lowercase category name → Category map for matching.
  static Future<Map<String, Category>> buildCategoryMap(IsarService isarService) async {
    final isar = await isarService.getInstance();
    final categories = await isar.categorys.where().findAll();
    final map = <String, Category>{};
    for (final cat in categories) {
      map[cat.name.toLowerCase().trim()] = cat;
      // Also add keywords
      for (final kw in cat.keywords ?? []) {
        map[kw.toLowerCase().trim()] = cat;
      }
    }
    return map;
  }

  // ── Helpers ──

  static bool _matchesAny(String value, List<String> patterns) {
    return patterns.any((p) => value.contains(p));
  }

  static String? _detectCurrency(String? value) {
    if (value == null || value.isEmpty) return null;
    final v = value.trim();
    const symbolMap = {
      '\u20b9': 'INR', '\u0024': 'USD', '\u20ac': 'EUR', '\u00a3': 'GBP',
      '\u00a5': 'JPY', '\u20a9': 'KRW', '\u20bd': 'RUB', '\u20ba': 'TRY',
      '\u0e3f': 'THB', '\u20b4': 'UAH', '\u20a6': 'NGN', '\u20b5': 'GHS',
    };
    for (final entry in symbolMap.entries) {
      if (v.contains(entry.key)) return entry.value;
    }
    final codeMatch = RegExp(
      r'^(INR|USD|EUR|GBP|JPY|AUD|CAD|SGD|AED|SAR|BDT|NPR|LKR|PKR|MYR|THB|IDR|PHP|VND|KRW|CNY|HKD|TWD|NZD|ZAR|BRL|MXN|RUB|TRY|CHF|SEK|NOK|DKK|PLN|CZK|HUF)\s',
      caseSensitive: false,
    ).firstMatch(v);
    if (codeMatch != null) return codeMatch.group(1)!.toUpperCase();
    return null;
  }

  static String? _cellAt(List<String> row, int? index) {
    if (index == null || index >= row.length) return null;
    final val = row[index].trim();
    return val.isEmpty ? null : val;
  }

  static DateTime? _parseDate(String? value, String format) {
    if (value == null || value.isEmpty) return null;
    // Try the specified format first
    try {
      return DateFormat(format).parseStrict(value);
    } catch (_) {}
    // Try common formats
    for (final fmt in [
      'dd/MM/yyyy', 'MM/dd/yyyy', 'yyyy-MM-dd', 'dd-MM-yyyy',
      'dd/MM/yyyy HH:mm', 'yyyy-MM-dd HH:mm:ss',
      'd/M/yyyy', 'd-M-yyyy', 'dd MMM yyyy', 'd MMM yyyy',
    ]) {
      try {
        return DateFormat(fmt).parseStrict(value);
      } catch (_) {}
    }
    // Try DateTime.parse as last resort
    return DateTime.tryParse(value);
  }

  static double? _parseAmount(String? value) {
    if (value == null || value.isEmpty) return null;
    // Strip all known currency symbols, codes, spaces, commas, parentheses
    final cleaned = value
        .replaceAll(RegExp(r'[₹$€£¥₩₽₺฿₴₦₵₸₼₾₿\s,]'), '')
        .replaceAll(RegExp(r'^(INR|USD|EUR|GBP|JPY|AUD|CAD|SGD|AED|SAR|BDT|NPR|LKR|PKR|MYR|THB|IDR|PHP|VND|KRW|CNY|HKD|TWD|NZD|ZAR|BRL|MXN|RUB|TRY|CHF|SEK|NOK|DKK|PLN|CZK|HUF|RON|BGN|HRK|ISK|ILS|EGP|KES|GHS|TZS|UGX|NGN|XOF|XAF)\s*', caseSensitive: false), '')
        .replaceAll('(', '-')
        .replaceAll(')', '')
        .trim();
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  static Future<bool> _checkDuplicate(
    Isar isar, DateTime date, double amount, String? description,
  ) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    var query = isar.transactions
        .filter()
        .dateBetween(startOfDay, endOfDay)
        .and()
        .amountEqualTo(amount);

    if (description != null && description.isNotEmpty) {
      query = query.and().descriptionEqualTo(description);
    }

    return await query.count() > 0;
  }
}
