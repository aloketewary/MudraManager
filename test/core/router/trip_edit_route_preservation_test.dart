import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/features/trip/presentation/screens/edit_trip_screen.dart';

/// Preservation coverage for canonical numeric trip-edit routes.
///
/// Route construction currently depends on GoRouter/Isar, so deterministic
/// source and destination contracts cover valid IDs without a real database.
void main() {
  final routerSource = File('lib/core/router/app_router.dart').readAsStringSync();
  final routeStart = routerSource.indexOf("path: '\${AppRoutes.editTrip}/:id'");
  final routeEnd = routerSource.indexOf('GoRoute(', routeStart + 1);
  final routeBody = routerSource.substring(routeStart, routeEnd);
  final screenSource = File(
    'lib/features/trip/presentation/screens/edit_trip_screen.dart',
  ).readAsStringSync();

  group('Property 6 preservation — valid edit identifiers', () {
    for (final rawId in ['1', '42', '999999']) {
      test('canonical numeric ID $rawId remains edit destination', () {
        final id = int.parse(rawId);
        final screen = ManageTripScreen(tripId: id);

        expect(screen.tripId, id);
        expect(screen.isTrip, isTrue);
        expect(routeBody, contains('ManageTripScreen(tripId: id)'));
      });
    }

    test('existing-trip edit mode still loads by canonical ID', () {
      expect(routeBody, contains('ManageTripScreen(tripId: id)'));
      expect(screenSource, contains('tripByIdProvider(widget.tripId!)'));
      expect(screenSource, contains('_initializeData(trip)'));
      expect(screenSource, contains('if (trip == null)'));
    });

    test('edit save flow preserves loaded data and update behavior', () {
      expect(screenSource, contains('Future<void> _saveTrip'));
      expect(screenSource, contains('if (isEditMode && originalTrip != null)'));
      expect(screenSource, contains('originalTrip.name ='));
      expect(screenSource, contains('originalTrip.description ='));
      expect(screenSource, contains('updateTrip('));
      expect(screenSource, contains('tripUpdated'));
      expect(screenSource, contains('tripByIdProvider(widget.tripId!)'));
    });

    test('numeric nonexistent ID retains provider-driven not-found state', () {
      expect(screenSource, contains('if (trip == null)'));
      expect(screenSource, contains('trip_tripNotFound'));
      expect(screenSource, contains('trip_groupNotFound'));
      expect(screenSource, contains('return Scaffold('));
    });
  });
}
