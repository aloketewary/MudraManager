import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/features/trip/data/trip_provider.dart';
import 'package:mudra_manager/shared/widgets/no_data_found.dart';
import 'package:mudra_manager/core/widgets/skeleton_loader.dart';

final _dateFormatter = DateFormat.MMMd();

class TripsScreen extends ConsumerWidget {
  const TripsScreen({super.key});

  String _getTripStatus(DateTime startDate, DateTime endDate, bool isActive) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    if (!isActive) return 'Completed';
    if (today.isBefore(start)) return 'Upcoming';
    if (today.isAfter(end)) return 'Past';
    return 'Active';
  }

  Color _getStatusColor(String status, ColorScheme color) {
    switch (status) {
      case 'Active':
        return color.primary;
      case 'Upcoming':
        return Colors.blue;
      case 'Past':
        return Colors.orange;
      case 'Completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(allTripsProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trips & Split Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              HapticFeedback.mediumImpact();
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (ctx) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: color.onSurfaceVariant.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Icon(Icons.card_travel, size: 64, color: color.primary),
                      const SizedBox(height: 16),
                      Text(
                        'How it works',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Create trips, add participants, link transactions, and split expenses automatically. Only one trip can be active at a time.',
                        style: textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: () => ctx.pop(),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Got it'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: tripsAsync.when(
        data: (trips) {
          if (trips.isEmpty) {
            return NoDataFound(
              message: 'No trips yet\nCreate your first trip to split expenses',
              iconData: Icons.card_travel,
              action: FilledButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  context.push('/create-trip');
                },
                icon: const Icon(Icons.add),
                label: const Text('Create Trip'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            );
          }

          // Separate active and archived trips
          final activeTrip = trips.where((t) => t.isActive).firstOrNull;
          final archivedTrips = trips.where((t) => !t.isActive).toList();

          return ListView(
            padding: const EdgeInsets.all(16).copyWith(bottom: 80),
            children: [
              // Active Trip Section
              if (activeTrip != null) ...[
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ACTIVE TRIP',
                      style: textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTripCard(context, ref, activeTrip, color, textTheme, isActive: true),
                const SizedBox(height: 32),
              ],

              // Archived Trips Section
              if (archivedTrips.isNotEmpty) ...[
                Text(
                  'TRIP ARCHIVE',
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                ...archivedTrips.map((trip) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildTripCard(context, ref, trip, color, textTheme),
                    )),
              ],
            ],
          );
        },
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(16).copyWith(bottom: 80),
          itemCount: 4,
          itemBuilder: (context, index) => const SkeletonCard(),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading trips', style: textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                '$e',
                style: textTheme.bodySmall?.copyWith(
                  color: color.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.mediumImpact();
          context.push('/create-trip');
        },
        icon: const Icon(Icons.add),
        label: const Text('New Trip'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildTripCard(
    BuildContext context,
    WidgetRef ref,
    trip,
    ColorScheme color,
    TextTheme textTheme, {
    bool isActive = false,
  }) {
    final duration = trip.endDate.difference(trip.startDate).inDays + 1;
    final status = _getTripStatus(trip.startDate, trip.endDate, trip.isActive);
    final statusColor = _getStatusColor(status, color);

    return Card(
      margin: EdgeInsets.zero,
      elevation: isActive ? 4 : 0,
      color: isActive ? color.primaryContainer : color.surfaceContainerHighest,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          context.push('/trip-detail', extra: trip.id);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  trip.isActive ? Icons.flight_takeoff : Icons.check_circle,
                  color: statusColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.name,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_dateFormatter.format(trip.startDate)} - ${_dateFormatter.format(trip.endDate)} • $duration days',
                      style: textTheme.bodySmall?.copyWith(
                        color: color.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  status,
                  style: textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: color.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
