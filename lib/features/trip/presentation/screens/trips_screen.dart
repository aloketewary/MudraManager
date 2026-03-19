import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/features/trip/data/trip_provider.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:mudra_manager/core/db/models/trip.dart';
import 'package:mudra_manager/core/router/app_routes.dart';

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
        return color.tertiary;
      case 'Past':
        return color.secondary;
      case 'Completed':
        return color.primaryContainer;
      default:
        return color.onSurfaceVariant;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Active':
        return LucideIcons.plane;
      case 'Upcoming':
        return LucideIcons.calendar;
      case 'Past':
        return LucideIcons.clock;
      case 'Completed':
        return LucideIcons.circleCheck;
      default:
        return LucideIcons.circle;
    }
  }

  Map<String, dynamic> _getHeaderInsight(List<Trip> trips, ColorScheme color) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Check for active trip
    final activeTrip = trips.where((t) => t.isActive).firstOrNull;
    if (activeTrip != null) {
      final daysLeft = activeTrip.endDate.difference(today).inDays;
      if (daysLeft >= 0) {
        return {
          'icon': LucideIcons.plane,
          'title': 'Trip in Progress',
          'message':
              '${activeTrip.name} • ${daysLeft == 0 ? 'Last day' : '$daysLeft ${daysLeft == 1 ? 'day' : 'days'} left'}',
          'color': color.primary,
        };
      }
    }

    // Check for upcoming trips
    final upcomingTrips = trips.where((t) {
      final start =
          DateTime(t.startDate.year, t.startDate.month, t.startDate.day);
      return t.isActive && start.isAfter(today);
    }).toList();

    if (upcomingTrips.isNotEmpty) {
      upcomingTrips.sort((a, b) => a.startDate.compareTo(b.startDate));
      final nextTrip = upcomingTrips.first;
      final daysUntil = nextTrip.startDate.difference(today).inDays;

      if (daysUntil <= 7) {
        return {
          'icon': LucideIcons.calendar,
          'title': 'Upcoming Trip',
          'message':
              '${nextTrip.name} starts in ${daysUntil == 0 ? 'today' : daysUntil == 1 ? 'tomorrow' : '$daysUntil days'}',
          'color': color.tertiary,
        };
      }
    }

    // Check for trips from last year same time
    final lastYearTrips = trips.where((t) {
      final tripMonth = t.startDate.month;
      final tripDay = t.startDate.day;
      final currentMonth = now.month;
      final currentDay = now.day;
      final yearDiff = now.year - t.startDate.year;

      return yearDiff == 1 &&
          (tripMonth == currentMonth && (tripDay - currentDay).abs() <= 7);
    }).toList();

    if (lastYearTrips.isNotEmpty) {
      final trip = lastYearTrips.first;
      return {
        'icon': LucideIcons.sparkles,
        'title': 'Memory Lane',
        'message': 'Last year you went to ${trip.name} around this time',
        'color': color.secondary,
      };
    }

    // Check for completed trips
    final completedTrips = trips.where((t) => !t.isActive).length;
    if (completedTrips > 0) {
      return {
        'icon': LucideIcons.mapPin,
        'title': 'Travel History',
        'message':
            'You\'ve completed $completedTrips ${completedTrips == 1 ? 'trip' : 'trips'}',
        'color': color.secondary,
      };
    }

    // Default: encourage planning
    return {
      'icon': LucideIcons.compass,
      'title': 'Plan Your Next Trip',
      'message': 'Ready to explore? Create a trip to track expenses',
      'color': color.primary,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(allTripsProvider);
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: tripsAsync.when(
        data: (trips) {
          final activeTrip = trips.where((t) => t.isActive).firstOrNull;
          final archivedTrips = trips.where((t) => !t.isActive).toList();
          final insight = _getHeaderInsight(trips, color);
          final hasInsight = trips.isNotEmpty;

          if (trips.isEmpty) {
            return CustomScrollView(
              slivers: [
                _buildAppBar(
                  context,
                  textTheme,
                  color,
                  null,
                  showInfo: true,
                ),
                SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(spacing.cardHorizontalMax),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: color.surfaceContainerHighest,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              LucideIcons.plane,
                              size: 64,
                              color:
                                  color.onSurfaceVariant.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No trips yet',
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create your first trip to split expenses',
                            style: textTheme.bodyMedium?.copyWith(
                              color: color.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              context.push(AppRoutes.createTrip);
                            },
                            icon: const Icon(LucideIcons.plus),
                            label: const Text('Create Trip'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          return CustomScrollView(
            slivers: [
              _buildAppBar(
                context,
                textTheme,
                color,
                hasInsight ? insight : null,
                showInfo: true,
              ),
              if (activeTrip != null) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      spacing.cardHorizontal,
                      spacing.sectionGap,
                      spacing.cardHorizontal,
                      spacing.elementGap,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ACTIVE TRIP',
                          style: textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: color.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing.cardHorizontal,
                      vertical: spacing.cardVertical,
                    ),
                    child: _buildTripCard(
                      context,
                      ref,
                      activeTrip,
                      color,
                      textTheme,
                      spacing,
                      isActive: true,
                    ),
                  ),
                ),
              ],
              if (archivedTrips.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing.cardHorizontal,
                      vertical: spacing.cardVertical,
                    ),
                    child: Text(
                      'TRIP ARCHIVE',
                      style: textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color.onSurfaceVariant,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.cardHorizontal,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: EdgeInsets.only(bottom: spacing.cardVertical,),
                        child: _buildTripCard(
                          context,
                          ref,
                          archivedTrips[index],
                          color,
                          textTheme,
                          spacing,
                        ),
                      ),
                      childCount: archivedTrips.length,
                    ),
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
        loading: () => CustomScrollView(
          slivers: [
            _buildLoadingAppBar(context, textTheme, color, spacing),
            SliverPadding(
              padding: EdgeInsets.all(spacing.cardHorizontalMax),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: EdgeInsets.only(bottom: spacing.cardVertical),
                    child: Card(
                      color: color.surfaceContainerHighest,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            SkeletonLoader(
                              width: 48,
                              height: 48,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SkeletonLoader(
                                      width: double.infinity, height: 16),
                                  SizedBox(height: 8),
                                  SkeletonLoader(width: 150, height: 12),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            const SkeletonLoader(width: 70, height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                  childCount: 4,
                ),
              ),
            ),
          ],
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: color.errorContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.circleAlert,
                  size: 64,
                  color: color.error,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Error loading trips',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$e',
                style: textTheme.bodySmall?.copyWith(
                  color: color.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(
    BuildContext context,
    TextTheme textTheme,
    ColorScheme color,
    Map<String, dynamic>? insight, {
    bool showInfo = false,
  }) {
    final hasInsight = insight != null;
    final expandedHeight = hasInsight ? 200.0 : 120.0;

    return SliverAppBar(
      expandedHeight: expandedHeight,
      pinned: true,
      backgroundColor: color.surface,
      actions: [
        IconButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            context.push(AppRoutes.createTrip);
          },
          icon: const Icon(LucideIcons.plus),
          tooltip: 'New Trip',
        ),
        if (showInfo)
          IconButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              _showInfoSheet(context, color, textTheme);
            },
            icon: const Icon(LucideIcons.info),
            tooltip: 'Info',
          ),
      ],
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final expandRatio = (constraints.maxHeight - kToolbarHeight) /
              (expandedHeight - kToolbarHeight);
          return FlexibleSpaceBar(
            titlePadding: EdgeInsets.zero,
            centerTitle: false,
            title: Opacity(
              opacity: 1 - expandRatio.clamp(0.0, 1.0),
              child: Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 16, bottom: 16),
                child: Text(
                  'Trips & Split',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            background: hasInsight
                ? Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          (insight['color'] as Color).withValues(alpha: 0.15),
                          (insight['color'] as Color).withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Opacity(
                        opacity: expandRatio.clamp(0.0, 1.0),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: (insight['color'] as Color)
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      insight['icon'] as IconData,
                                      color: insight['color'] as Color,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          insight['title'] as String,
                                          style:
                                              textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: insight['color'] as Color,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          insight['message'] as String,
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: color.onSurfaceVariant,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                : Container(
                    color: color.surface,
                  ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingAppBar(
    BuildContext context,
    TextTheme textTheme,
    ColorScheme color,
    AppSpacing spacing,
  ) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: color.surface,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final expandRatio =
              (constraints.maxHeight - kToolbarHeight) / (200 - kToolbarHeight);
          return FlexibleSpaceBar(
            titlePadding: EdgeInsets.zero,
            centerTitle: false,
            title: Opacity(
              opacity: 1 - expandRatio.clamp(0.0, 1.0),
              child: Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 16, bottom: 16),
                child: Text(
                  'Trips & Split',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.primaryContainer,
                    color.secondaryContainer,
                  ],
                ),
              ),
              child: SafeArea(
                child: Opacity(
                  opacity: expandRatio.clamp(0.0, 1.0),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            SkeletonLoader(
                              width: 48,
                              height: 48,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SkeletonLoader(width: 150, height: 18),
                                  SizedBox(height: 6),
                                  SkeletonLoader(width: 200, height: 14),
                                ],
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
    );
  }

  Widget _buildTripCard(
    BuildContext context,
    WidgetRef ref,
    Trip trip,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing, {
    bool isActive = false,
  }) {
    final duration = trip.endDate.difference(trip.startDate).inDays + 1;
    final status = _getTripStatus(trip.startDate, trip.endDate, trip.isActive);
    final statusColor = _getStatusColor(status, color);
    final statusIcon = _getStatusIcon(status);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(),
      color: isActive
          ? color.primaryContainer.withValues(alpha: 0.3)
          : color.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        side: BorderSide(
          color: isActive
              ? color.primary.withValues(alpha: 0.3)
              : color.outlineVariant.withValues(alpha: 0.5),
          width: isActive ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          context.push(AppRoutes.tripDetail, extra: trip.id);
        },
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        child: Padding(
          padding: EdgeInsets.all(spacing.cardInner),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                ),
                child: Icon(
                  statusIcon,
                  color: color.onSurfaceVariant,
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
                    Row(
                      children: [
                        Icon(
                          LucideIcons.calendar,
                          size: 14,
                          color: color.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${_dateFormatter.format(trip.startDate)} - ${_dateFormatter.format(trip.endDate)}',
                            style: textTheme.bodySmall?.copyWith(
                              color: color.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            color: color.onSurfaceVariant,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$duration ${duration == 1 ? 'day' : 'days'}',
                          style: textTheme.bodySmall?.copyWith(
                            color: color.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(spacing.radiusSmall),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  status,
                  style: textTheme.labelSmall?.copyWith(
                    color: color.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                LucideIcons.chevronRight,
                color: color.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInfoSheet(
      BuildContext context, ColorScheme color, TextTheme textTheme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: color.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.plane,
                size: 48,
                color: color.primary,
              ),
            ),
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
              style: textTheme.bodyMedium?.copyWith(
                color: color.onSurfaceVariant,
              ),
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
  }
}
