import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mudra_manager/providers/trip_provider.dart';

class ActiveTripMiniCard extends ConsumerWidget {
  final double globalPadding;

  const ActiveTripMiniCard({super.key, required this.globalPadding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(activeTripsProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return tripsAsync.when(
      data: (trips) {
        if (kDebugMode) {
          print('Total trips: ${trips.length}');
        }

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        final activeTrips =
            trips.where((trip) {
              final start = DateTime(
                trip.startDate.year,
                trip.startDate.month,
                trip.startDate.day,
              );
              final end = DateTime(
                trip.endDate.year,
                trip.endDate.month,
                trip.endDate.day,
              );

              if (kDebugMode) {
                print(
                  'Trip: ${trip.name}, Start: $start, End: $end, Today: $today, Active: ${trip.isActive}',
                );
              }

              return (start.isBefore(today) || start.isAtSameMomentAs(today)) &&
                  (end.isAfter(today) || end.isAtSameMomentAs(today));
            }).toList();

        if (kDebugMode) {
          print('Active trips count: ${activeTrips.length}');
        }

        if (activeTrips.isEmpty) {
          if (kDebugMode) {
            print('No active trips, returning empty');
          }
          return const SizedBox.shrink();
        }

        return Container(
          margin: EdgeInsets.symmetric(horizontal: globalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Active Trips',
                    style: textTheme.titleLarge?.copyWith(color: color.primary),
                  ),
                  TextButton(
                    onPressed: () => context.push('/trips'),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: activeTrips.length,
                  itemBuilder: (context, index) {
                    final trip = activeTrips[index];
                    return GestureDetector(
                      onTap: () => context.push('/trip-detail', extra: trip.id),
                      child: Card(
                        elevation: 0,
                        color: color.surfaceContainerHighest,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap:
                              () =>
                                  context.push('/trip-detail', extra: trip.id),
                          child: Container(
                            width: 200,
                            margin: const EdgeInsets.only(right: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: color.tertiary.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.flight_takeoff,
                                          color: color.tertiary,
                                          size: 20,
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: color.tertiary.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          'ACTIVE',
                                          style: textTheme.labelSmall?.copyWith(
                                            color: color.tertiary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    trip.name,
                                    style: textTheme.titleMedium?.copyWith(
                                      color: color.tertiary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Spacer(),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.people_outline,
                                        size: 16,
                                        color: color.tertiary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${trip.participants.length}',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: color.tertiary,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Icon(
                                        Icons.receipt_outlined,
                                        size: 16,
                                        color: color.tertiary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${trip.transactions.length}',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: color.tertiary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
