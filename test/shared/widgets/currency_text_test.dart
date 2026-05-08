import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';

void main() {
  setUp(() {
    BaseCurrency.sync('INR');
  });

  Widget buildTestWidget(CurrencyText child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: child),
    );
  }

  group('CurrencyText Semantics', () {
    testWidgets('renders Tooltip', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const CurrencyText(amount: 12500),
      ),);
      await tester.pumpAndSettle();
      expect(find.byType(Tooltip), findsOneWidget);
    });

    testWidgets('contains Semantics with excludeSemantics', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const CurrencyText(amount: 500),
      ),);
      await tester.pumpAndSettle();

      // Find Semantics that is a descendant of Tooltip (our custom one)
      final allSemantics = tester.widgetList<Semantics>(find.byType(Semantics));
      final ours = allSemantics.where((s) => s.excludeSemantics == true && s.properties.label != null && s.properties.label!.isNotEmpty);
      expect(ours, isNotEmpty, reason: 'Should have a Semantics with excludeSemantics and a label');
    });

    testWidgets('semantic label contains currency name for INR', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const CurrencyText(amount: 500),
      ),);
      await tester.pumpAndSettle();

      final allSemantics = tester.widgetList<Semantics>(find.byType(Semantics));
      final ours = allSemantics.where((s) => s.properties.label?.contains('Indian Rupee') ?? false);
      expect(ours, isNotEmpty);
    });

    testWidgets('semantic label contains amount', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const CurrencyText(amount: 1234),
      ),);
      await tester.pumpAndSettle();

      final allSemantics = tester.widgetList<Semantics>(find.byType(Semantics));
      final ours = allSemantics.where((s) => s.properties.label?.contains('1234') ?? false);
      expect(ours, isNotEmpty);
    });

    testWidgets('negative amount has minus in label', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const CurrencyText(amount: -500, showSign: true, isExpense: true),
      ),);
      await tester.pumpAndSettle();

      final allSemantics = tester.widgetList<Semantics>(find.byType(Semantics));
      final ours = allSemantics.where((s) => s.properties.label?.contains('minus') ?? false);
      expect(ours, isNotEmpty);
    });

    testWidgets('USD shows US Dollar', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const CurrencyText(amount: 100, currencyCode: 'USD'),
      ),);
      await tester.pumpAndSettle();

      final allSemantics = tester.widgetList<Semantics>(find.byType(Semantics));
      final ours = allSemantics.where((s) => s.properties.label?.contains('US Dollar') ?? false);
      expect(ours, isNotEmpty);
    });
  });
}
