import 'package:mudra_manager/core/tone/tone_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/features/trip/data/trip_provider.dart';
import 'package:mudra_manager/core/router/app_routes.dart';

class ActiveTripMiniCard extends ConsumerWidget {
  final double globalPadding;

  const ActiveTripMiniCard({super.key, required this.globalPadding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(allTripsProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return tripsAsync.when(
      data: (trips) {
        final activeTrip = trips.where((t) => t.isActive).firstOrNull;
        if (activeTrip == null) return const SizedBox.shrink();

        final trip = activeTrip;
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final daysLeft = trip.endDate.difference(today).inDays + 1;

        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: SizedBox(
            width: double.infinity,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: globalPadding),
              child: Card(
                elevation: 0,
                color: color.errorContainer,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(Tone.current.borderRadius),
                  side: BorderSide(color: color.error, width: 2),
                ),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    context.push(AppRoutes.tripDetail, extra: trip.id);
                  },
                  borderRadius:
                      BorderRadius.circular(Tone.current.borderRadius),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: color.error,
                            shape: BoxShape.circle,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                LucideIcons.plane,
                                color: color.onError,
                                size: 28,
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: color.error,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'TRIP MODE',
                                    style: textTheme.labelSmall?.copyWith(
                                      color: color.error,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: color.error,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'LIVE',
                                      style: textTheme.labelSmall?.copyWith(
                                        color: color.onError,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                trip.name,
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: color.onErrorContainer,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildMetricItem(
                                      '$daysLeft days left',
                                      '${trip.transactions.length} expenses',
                                      LucideIcons.clock,
                                      color.primary,
                                      color,
                                      textTheme,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildMetricItem(
                                      '${trip.participants.length} people',
                                      DateFormat.MMMd().format(trip.endDate),
                                      LucideIcons.users,
                                      color.tertiary,
                                      color,
                                      textTheme,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          LucideIcons.chevronRight,
                          color: color.onErrorContainer,
                          size: 20,
                        ),
                      ],
                    ),
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

  Widget _buildMetricItem(
    String label,
    String value,
    IconData icon,
    Color itemColor,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    return Row(
      children: [
        Icon(icon, color: itemColor, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.bodySmall?.copyWith(
                  color: color.onSurfaceVariant,
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                value,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
