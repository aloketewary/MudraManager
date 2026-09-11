import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/shared/widgets/account_display_card.dart';

void main() {
  testWidgets('renders masked suffix in text and semantics only',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AccountDisplayCard(
            title: 'Primary',
            amount: '₹100',
            accountType: AccountType.bank,
            startColor: Colors.blue,
            endColor: Colors.lightBlue,
            isSelected: false,
            accountNumber: '1234567890',
            callbackAction: () {},
          ),
        ),
      ),
    );

    expect(find.text('•••• 7890'), findsOneWidget);
    expect(find.text('1234567890'), findsNothing);

    final semanticsLabels = tester
        .widgetList<Semantics>(find.byType(Semantics))
        .map((semantics) => semantics.properties.label)
        .whereType<String>();
    expect(semanticsLabels, contains('•••• 7890'));
    expect(semanticsLabels.join(' '), isNot(contains('1234567890')));
  });

  testWidgets('malformed ciphertext becomes safe placeholder', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AccountDisplayCard(
            title: 'Unknown',
            amount: '₹0',
            accountType: AccountType.bank,
            startColor: Colors.blue,
            endColor: Colors.lightBlue,
            isSelected: false,
            accountNumber: 'ENC:bad-payload',
            callbackAction: () {},
          ),
        ),
      ),
    );

    expect(find.text('••••'), findsOneWidget);
    expect(find.textContaining('ENC:'), findsNothing);
  });
}
