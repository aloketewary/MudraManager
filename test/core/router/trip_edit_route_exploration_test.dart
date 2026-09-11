import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Characterization tests for trip-edit deep-link identifiers.
///
/// The route currently calls int.parse directly. These tests record malformed
/// path classes and intentionally fail on that implementation; no production
/// route behavior is changed here.
void main() {
  final routerSource = File('lib/core/router/app_router.dart').readAsStringSync();
  final routeStart = routerSource.indexOf("path: '\${AppRoutes.editTrip}/:id'");
  final routeBody = routerSource.substring(
    routeStart,
    routerSource.indexOf('GoRoute(', routeStart + 1),
  );

  const malformed = [
    'not-a-number',
    '',
    '   ',
    '%E0%A4%A',
    '%2F',
  ];

  group('Property 5 — invalid trip-edit identifiers fail safely', () {
    test('all malformed path classes are rejected before route construction', () {
      for (final raw in malformed) {
        expect(_parseCanonicalId(raw), isNull, reason: 'raw=$raw');
      }
      expect(_parseCanonicalId(null), isNull, reason: 'missing id');
    });

    test('route uses guarded parsing instead of int.parse', () {
      expect(
        routeBody,
        contains('int.tryParse'),
        reason: 'Counterexample: /edit-trip/not-a-number reaches int.parse and throws FormatException.',
      );
      expect(
        routeBody,
        isNot(contains('int.parse(')),
        reason: 'Malformed input must not reach uncaught numeric parsing.',
      );
    });

    test('malformed route cannot fall through to create-trip mode', () {
      expect(routeBody, isNot(contains('ManageTripScreen(isTrip:')));
      expect(
        routeBody,
        contains('ManageTripScreen(tripId:'),
        reason: 'Only canonical numeric IDs may enter edit mode.',
      );
    });

    test('numeric nonexistent ID remains numeric not-found case', () {
      expect(_parseCanonicalId('999999'), 999999);
      expect(_parseCanonicalId('0'), 0);
      expect(_parseCanonicalId('-1'), -1);
    });
  });
}

int? _parseCanonicalId(String? raw) {
  final value = raw?.trim();
  if (value == null || value.isEmpty) return null;
  return int.tryParse(value);
}
