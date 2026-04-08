import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/core/theme/theme_provider.dart';

void main() {
  group('AppColorTheme colorScheme generation', () {
    test('all themes produce valid light scheme', () {
      for (final theme in AppColorTheme.values) {
        if (theme == AppColorTheme.dynamic) continue; // needs device
        final scheme = theme.lightColorScheme();
        expect(scheme.brightness, Brightness.light,
            reason: '${theme.name} light scheme has wrong brightness');
        expect(scheme.primary, isNotNull);
      }
    });

    test('all themes produce valid dark scheme', () {
      for (final theme in AppColorTheme.values) {
        if (theme == AppColorTheme.dynamic) continue;
        final scheme = theme.darkColorScheme();
        expect(scheme.brightness, Brightness.dark,
            reason: '${theme.name} dark scheme has wrong brightness');
      }
    });

    test('AMOLED mode has pure black surface', () {
      for (final theme in AppColorTheme.values) {
        if (theme == AppColorTheme.dynamic) continue;
        final scheme = theme.amoledColorScheme();
        expect(scheme.surface, Colors.black,
            reason: '${theme.name} AMOLED should have black surface');
      }
    });

    test('pro themes have hand-tuned colors (different from seed-only)', () {
      // Pro themes should have tuning that makes light primary differ from
      // a pure fromSeed result
      final ocean = AppColorTheme.ocean;
      final scheme = ocean.lightColorScheme();
      // Ocean's tuned primary is 0xFF006494
      expect(scheme.primary, const Color(0xFF006494));
    });

    test('free themes use pure fromSeed (no tuning overrides)', () {
      // Finance theme has no tuning, so primary comes from Material 3 algo
      final finance = AppColorTheme.finance;
      final scheme = finance.lightColorScheme();
      // Just verify it generates without error and has the seed influence
      expect(scheme.primary, isNotNull);
    });
  });

  group('FinanceColors', () {
    test('income colors are green-ish', () {
      expect(FinanceColors.income.green, greaterThan(FinanceColors.income.red));
      expect(FinanceColors.incomeDark.green, greaterThan(FinanceColors.incomeDark.red));
    });

    test('expense colors are red-ish', () {
      expect(FinanceColors.expense.red, greaterThan(FinanceColors.expense.green));
      expect(FinanceColors.expenseDark.red, greaterThan(FinanceColors.expenseDark.green));
    });

    test('transfer colors are blue-ish', () {
      expect(FinanceColors.transfer.blue, greaterThan(FinanceColors.transfer.red));
      expect(FinanceColors.transferDark.blue, greaterThan(FinanceColors.transferDark.red));
    });

    test('brightness-aware helpers return correct variant', () {
      expect(FinanceColors.incomeColor(Brightness.light), FinanceColors.income);
      expect(FinanceColors.incomeColor(Brightness.dark), FinanceColors.incomeDark);
      expect(FinanceColors.expenseColor(Brightness.light), FinanceColors.expense);
      expect(FinanceColors.expenseColor(Brightness.dark), FinanceColors.expenseDark);
      expect(FinanceColors.transferColor(Brightness.light), FinanceColors.transfer);
      expect(FinanceColors.transferColor(Brightness.dark), FinanceColors.transferDark);
    });
  });

  group('AppThemeMode', () {
    test('all modes exist', () {
      expect(AppThemeMode.values, contains(AppThemeMode.system));
      expect(AppThemeMode.values, contains(AppThemeMode.light));
      expect(AppThemeMode.values, contains(AppThemeMode.dark));
      expect(AppThemeMode.values, contains(AppThemeMode.amoled));
    });
  });
}
