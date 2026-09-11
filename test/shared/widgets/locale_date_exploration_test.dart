import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/features/transactions/presentation/widgets/date_range_selector.dart';
import 'package:mudra_manager/features/transactions/presentation/widgets/date_time_picker.dart';
import 'package:mudra_manager/features/transactions/presentation/widgets/transaction_calendar_header.dart';
import 'package:mudra_manager/shared/widgets/transaction_form/date_time_row.dart';

/// Characterization tests for visible date formatting under a selected app
/// locale that differs from Intl's device/default locale.
///
/// These tests intentionally fail on the audited revision. Keep locale pairs,
/// dates, and widget assertions unchanged when validating the fix.
void main() {
  const locales = ['hi', 'bn'];
  final selectedDate = DateTime(2025, 3, 5, 14, 30);
  final startDate = DateTime(2025, 3, 1);
  final endDate = DateTime(2025, 3, 5);

  setUp(() {
    Intl.defaultLocale = 'en_US';
  });

  tearDown(() {
    Intl.defaultLocale = null;
  });

  group('Property 3 — selected locale controls visible dates', () {
    for (final localeName in locales) {
      testWidgets('DateTimeRow uses $localeName date output', (tester) async {
        await tester.pumpWidget(_localizedApp(
          localeName,
          DateTimeRow(selectedDate: selectedDate, onDateChanged: (_) {}),
        ));
        await tester.pumpAndSettle();

        final expected = DateFormat(
          'MMM dd, yyyy',
          localeName,
        ).format(selectedDate);
        expect(find.text(expected), findsOneWidget);
      });

      testWidgets('TransactionCalendarHeader uses $localeName output', (tester) async {
        await tester.pumpWidget(_localizedApp(
          localeName,
          TransactionCalendarHeader(
            useInfiniteScroll: false,
            filterStartDate: startDate,
            filterEndDate: endDate,
            selectedDate: selectedDate,
            showCalendar: false,
            showMonthPicker: false,
            onToggleCalendar: () {},
            onPreviousMonth: () {},
            onNextMonth: () {},
            onResetMonth: () {},
            onToggleMonthPicker: () {},
            onToggleViewMode: () {},
          ),
        ));
        await tester.pumpAndSettle();

        final expected =
            '${DateFormat.MMMd(localeName).format(startDate)} - '
            '${DateFormat.MMMd(localeName).format(endDate)}';
        expect(find.text(expected), findsOneWidget);
      });

      testWidgets('DateRangeSelector uses $localeName output', (tester) async {
        await tester.pumpWidget(_localizedApp(
          localeName,
          DateRangeSelector(
            selectedDate: selectedDate,
            filterStartDate: startDate,
            filterEndDate: endDate,
            showCalendar: false,
            useInfiniteScroll: false,
            onToggleCalendar: () {},
            onPreviousMonth: () {},
            onNextMonth: () {},
            onResetToday: () {},
            onToggleView: () {},
            canGoNext: true,
          ),
        ));
        await tester.pumpAndSettle();

        final expected =
            '${DateFormat.MMMd(localeName).format(startDate)} - '
            '${DateFormat.MMMd(localeName).format(endDate)}';
        expect(find.text(expected), findsOneWidget);
      });

      testWidgets('DateTimePicker uses $localeName output', (tester) async {
        await tester.pumpWidget(_localizedApp(
          localeName,
          DateTimePicker(selectedDate: selectedDate, onDateChanged: (_) {}),
        ));
        await tester.pumpAndSettle();

        final expected = DateFormat.yMMMd(localeName).format(selectedDate);
        expect(find.text(expected), findsOneWidget);
      });

      testWidgets('DateTime selection value remains unchanged for $localeName', (tester) async {
        await tester.pumpWidget(_localizedApp(
          localeName,
          DateTimeRow(selectedDate: selectedDate, onDateChanged: (_) {}),
        ));
        final row = tester.widget<DateTimeRow>(find.byType(DateTimeRow));
        expect(row.selectedDate, selectedDate);
      });
    }

    test('contrasting Intl locale produces different expected output', () {
      final deviceOutput = DateFormat('MMM dd, yyyy').format(selectedDate);
      for (final localeName in locales) {
        final appOutput = DateFormat('MMM dd, yyyy', localeName).format(selectedDate);
        expect(appOutput, isNot(deviceOutput), reason: 'locale=$localeName');
      }
    });
  });

  group('Affected raw formatter characterization', () {
    final affected = <String, List<String>>{
      'lib/shared/widgets/transaction_form/date_time_row.dart': [
        "DateFormat('MMM dd, yyyy').format",
        "DateFormat('hh:mm a').format",
      ],
      'lib/shared/widgets/weekly_calendar.dart': [
        "DateFormat('d').format",
        "DateFormat('MMMM yyyy').format",
      ],
      'lib/features/transactions/presentation/widgets/transaction_calendar_header.dart': [
        'DateFormat.MMMd().format',
        'DateFormat.yMMMM().format',
      ],
      'lib/features/transactions/presentation/widgets/date_range_selector.dart': [
        'DateFormat.MMMd().format',
        'DateFormat.yMMMM().format',
      ],
      'lib/features/transactions/presentation/widgets/date_time_picker.dart': [
        'DateFormat.yMMMd().format',
      ],
      'lib/shared/widgets/transaction_filter_sheet.dart': [
        "DateFormat('dd MMM').format",
      ],
    };

    for (final entry in affected.entries) {
      test('${entry.key} passes selected locale to every visible formatter', () {
        final source = File(entry.key).readAsStringSync();
        for (final formatter in entry.value) {
          expect(
            source,
            isNot(contains(formatter)),
            reason: 'Raw formatter $formatter can use device Intl locale for hi/bn.',
          );
        }
      });
    }
  });
}

Widget _localizedApp(String localeName, Widget child) {
  return ProviderScope(
    overrides: [spacingProvider.overrideWithValue(const AppSpacing())],
    child: MaterialApp(
      locale: Locale(localeName),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}
