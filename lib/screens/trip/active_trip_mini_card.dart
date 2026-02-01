import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mudra_manager/providers/trip_provider.dart';
import 'package:mudra_manager/theme/app_colors.dart';

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
                      child: Container(
                        width: 200,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: AppColors.glassGradient(AppColors.tripActive, isDark),
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.tripActive.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                          boxShadow: AppColors.glassShadow(AppColors.tripActive, isDark),
                        ),
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
                                      color: AppColors.tripActive.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.flight_takeoff,
                                      color: AppColors.tripActive,
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
                                      color: AppColors.tripActive.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'ACTIVE',
                                      style: textTheme.labelSmall?.copyWith(
                                        color: AppColors.tripActive,
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
                                  color: AppColors.tripActive,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.people_outline,
                                    size: 16,
                                    color: AppColors.tripActive,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${trip.participants.length}',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: AppColors.tripActive,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(
                                    Icons.receipt_outlined,
                                    size: 16,
                                    color: AppColors.tripActive,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${trip.transactions.length}',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: AppColors.tripActive,
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
