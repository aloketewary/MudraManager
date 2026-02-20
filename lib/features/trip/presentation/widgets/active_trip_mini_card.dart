import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/features/trip/data/trip_provider.dart';

class ActiveTripMiniCard extends ConsumerWidget {
  final double globalPadding;

  const ActiveTripMiniCard({super.key, required this.globalPadding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(activeTripsProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return tripsAsync.when(
      data: (trips) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        final activeTrips = trips.where((trip) {
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
          return (start.isBefore(today) || start.isAtSameMomentAs(today)) &&
              (end.isAfter(today) || end.isAtSameMomentAs(today));
        }).toList();

        if (activeTrips.isEmpty) return const SizedBox.shrink();

        final trip = activeTrips.first;
        final duration = trip.endDate.difference(trip.startDate).inDays + 1;
        final daysLeft = trip.endDate.difference(today).inDays + 1;

        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              context.push('/trip-detail', extra: trip.id);
            },
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: globalPadding),
              child: Card(
                elevation: 0,
                color: color.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: color.tertiaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.flight_takeoff,
                              color: color.onTertiaryContainer,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Active Trip',
                                  style: textTheme.labelMedium?.copyWith(
                                    color: color.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  trip.name,
                                  style: textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: color.onSurfaceVariant,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricItem(
                              icon: Icons.calendar_today,
                              label: 'Duration',
                              value: '$duration days',
                              color: color,
                              textTheme: textTheme,
                            ),
                          ),
                          Expanded(
                            child: _MetricItem(
                              icon: Icons.hourglass_bottom,
                              label: 'Days Left',
                              value: '$daysLeft days',
                              color: color,
                              textTheme: textTheme,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricItem(
                              icon: Icons.people,
                              label: 'Participants',
                              value: '${trip.participants.length}',
                              color: color,
                              textTheme: textTheme,
                            ),
                          ),
                          Expanded(
                            child: _MetricItem(
                              icon: Icons.receipt_long,
                              label: 'Expenses',
                              value: '${trip.transactions.length}',
                              color: color,
                              textTheme: textTheme,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.tertiaryContainer.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: color.onTertiaryContainer,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${DateFormat.MMMd().format(trip.startDate)} - ${DateFormat.MMMd().format(trip.endDate)}',
                                style: textTheme.bodySmall?.copyWith(
                                  color: color.onTertiaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme color;
  final TextTheme textTheme;

  const _MetricItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color.onSurfaceVariant),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: textTheme.labelSmall?.copyWith(
                color: color.onSurfaceVariant,
              ),
            ),
            Text(
              value,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
