import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/router/home_screen.dart';
import 'package:mudra_manager/core/providers/user_profile_provider.dart';

void main() {
  testWidgets('HomePage initializes with correct tab', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith((ref) => AsyncValue.data(null)),
        ],
        child: MaterialApp(home: HomePage(initialIndex: 0)),
      ),
    );
    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets('HomePage switches tabs correctly', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith((ref) => AsyncValue.data(null)),
        ],
        child: MaterialApp(home: HomePage(initialIndex: 0)),
      ),
    );
    
    await tester.tap(find.byIcon(Icons.receipt_long_outlined));
    await tester.pumpAndSettle();
    
    expect(find.byIcon(Icons.receipt_long), findsOneWidget);
  });

  testWidgets('HomePage shows FAB on transactions tab', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith((ref) => AsyncValue.data(null)),
        ],
        child: MaterialApp(home: HomePage(initialIndex: 1)),
      ),
    );
    
    await tester.pumpAndSettle();
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('HomePage has 5 navigation destinations', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith((ref) => AsyncValue.data(null)),
        ],
        child: MaterialApp(home: HomePage(initialIndex: 0)),
      ),
    );
    
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(5));
  });
}
