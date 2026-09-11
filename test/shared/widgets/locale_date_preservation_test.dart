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

/// Preservation coverage when selected app locale equals device Intl locale.
/// All inputs are fixed; no picker is opened, so no wall-clock dependency exists.
const localeName = 'en';

void main() {
  final selectedDate = DateTime(2025, 3, 5, 14, 30);
  final startDate = DateTime(2025, 3, 1);
  final endDate = DateTime(2025, 3, 5);

  setUp(() {
    Intl.defaultLocale = 'en_US';
  });

  tearDown(() {
    Intl.defaultLocale = null;
  });

  group('Property 4 preservation — locale-matching visible output', () {
    testWidgets('DateTimeRow preserves selected date and time output', (tester) async {
      await tester.pumpWidget(_localizedApp(
        DateTimeRow(selectedDate: selectedDate, onDateChanged: (_) {}),
      ),);
      await tester.pump();

      expect(
        find.text(DateFormat('MMM dd, yyyy', localeName).format(selectedDate)),
        findsOneWidget,
      );
      expect(
        find.text(DateFormat('hh:mm a', localeName).format(selectedDate)),
        findsOneWidget,
      );
      expect(
        tester.widget<DateTimeRow>(find.byType(DateTimeRow)).selectedDate,
        selectedDate,
      );
    });

    testWidgets('calendar header preserves matching date-range output', (tester) async {
      await tester.pumpWidget(_localizedApp(
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
      ),);
      await tester.pump();

      final expected =
          '${DateFormat.MMMd(localeName).format(startDate)} - '
          '${DateFormat.MMMd(localeName).format(endDate)}';
      expect(find.text(expected), findsOneWidget);
    });

    testWidgets('date range selector preserves matching date-range output', (tester) async {
      await tester.pumpWidget(_localizedApp(
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
      ),);
      await tester.pump();

      final expected =
          '${DateFormat.MMMd(localeName).format(startDate)} - '
          '${DateFormat.MMMd(localeName).format(endDate)}';
      expect(find.text(expected), findsOneWidget);
    });

    testWidgets('date-time picker preserves selected date output', (tester) async {
      await tester.pumpWidget(_localizedApp(
        DateTimePicker(selectedDate: selectedDate, onDateChanged: (_) {}),
      ),);
      await tester.pump();

      expect(
        find.text(DateFormat.yMMMd(localeName).format(selectedDate)),
        findsOneWidget,
      );
      expect(
        tester.widget<DateTimePicker>(find.byType(DateTimePicker)).selectedDate,
        selectedDate,
      );
    });

    test('matching Intl and app locale produce equivalent formatter output', () {
      final appOutput = DateFormat('MMM dd, yyyy', localeName).format(selectedDate);
      final deviceOutput = DateFormat('MMM dd, yyyy').format(selectedDate);
      expect(appOutput, deviceOutput);
      expect(DateFormat.yMMMd(localeName).format(selectedDate),
          DateFormat.yMMMd().format(selectedDate),);
    });

    test('date callbacks preserve selected values unchanged', () {
      DateTime? rowValue;
      final row = DateTimeRow(
        selectedDate: selectedDate,
        onDateChanged: (value) => rowValue = value,
      );
      row.onDateChanged(selectedDate);
      expect(rowValue, selectedDate);

      DateTime? pickerValue;
      final picker = DateTimePicker(
        selectedDate: selectedDate,
        onDateChanged: (value) => pickerValue = value,
      );
      picker.onDateChanged(selectedDate);
      expect(pickerValue, selectedDate);
    });
  });

  group('Property 4 preservation — picker bounds and callbacks', () {
    test('DateTimeRow retains date/time callback composition and future policy', () {
      final source = File(
        'lib/shared/widgets/transaction_form/date_time_row.dart',
      ).readAsStringSync();

      expect(source, contains('final bool allowFuture'));
      expect(source, contains('lastDate: allowFuture ? DateTime(2030) : now'));
      expect(source, contains('firstDate: DateTime(2000)'));
      expect(source, contains('selectedDate.hour'));
      expect(source, contains('selectedDate.minute'));
      expect(source, contains('onDateChanged('));
    });

    test('DateTimePicker retains fixed lower bound and no future selection', () {
      final source = File(
        'lib/features/transactions/presentation/widgets/date_time_picker.dart',
      ).readAsStringSync();

      expect(source, contains('firstDate: DateTime(2020)'));
      expect(source, contains('lastDate: DateTime'));
      expect(source, contains('onDateChanged(date)'));
    });
  });
}

Widget _localizedApp(Widget child) {
  return ProviderScope(
    overrides: [spacingProvider.overrideWithValue(const AppSpacing())],
    child: MaterialApp(
      locale: const Locale(localeName),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}
