import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/trip.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/core/state/app_screen_state.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/core/tone/tone_provider.dart';
import 'package:mudra_manager/core/utils/refresh_helper.dart';
import 'package:mudra_manager/features/trip/data/trip_provider.dart';
import 'package:mudra_manager/features/trip/data/trip_service.dart';
import 'package:mudra_manager/shared/templates/templates.dart';
import 'package:mudra_manager/shared/widgets/ambient_brand_section.dart';

class TripsScreen extends ConsumerStatefulWidget {
  const TripsScreen({super.key});

  @override
  ConsumerState<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends ConsumerState<TripsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tripsAsync = ref.watch(allTripsProvider);
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final tabBar = PreferredSize(
      preferredSize: const Size.fromHeight(kTextTabBarHeight),
      child: Consumer(
        builder: (context, ref, _) {
          final tripsAsync = ref.watch(allTripsProvider);
          final l10n = AppLocalizations.of(context)!;

          return TabBar(
            controller: _tabController,
            tabs: tripsAsync.maybeWhen(
              data: (all) => [
                Tab(
                    text:
                        '${l10n.title_trips} (${all.where((t) => t.isTrip).length})',),
                Tab(
                    text:
                        '${l10n.title_shared} (${all.where((t) => !t.isTrip).length})',),
              ],
              orElse: () =>
                  [Tab(text: l10n.title_trips), Tab(text: l10n.title_shared)],
            ),
          );
        },
      ),
    );

    return ScreenShell(
      config: ScreenShellConfig(
        title: AppLocalizations.of(context)!.title_groups,
        bottom: tabBar,
      ),
      actions: ScreenActions.build(
        appBar: [
          ScreenAction(
            id: 'create',
            label: AppLocalizations.of(context)!.common_new,
            icon: LucideIcons.plus,
            onTap: () {
              HapticFeedback.mediumImpact();
              _showCreateSheet(context, color, textTheme, spacing);
            },
          ),
        ],
      ),
      body: tripsAsync.when(
        data: (allItems) {
          final trips = allItems.where((t) => t.isTrip).toList();
          final splits = allItems.where((t) => !t.isTrip).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildListView(context, ref, trips, spacing, color, textTheme,
                  isTrip: true,),
              _buildListView(context, ref, splits, spacing, color, textTheme,
                  isTrip: false,),
            ],
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator.adaptive()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(spacing.sectionGap * 2),
                decoration: BoxDecoration(
                  color: color.errorContainer,
                  shape: BoxShape.circle,
                ),
                child:
                    Icon(LucideIcons.circleAlert, size: 64, color: color.error),
              ),
              SizedBox(height: spacing.sectionGap),
              Text(
                AppLocalizations.of(context)!.trip_errorLoading,
                style:
                    textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: spacing.elementGap),
              Text(
                '$e',
                style: textTheme.bodySmall
                    ?.copyWith(color: color.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListView(
    BuildContext context,
    WidgetRef ref,
    List<Trip> items,
    AppSpacing spacing,
    ColorScheme color,
    TextTheme textTheme, {
    required bool isTrip,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(spacing.cardHorizontalMax),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(spacing.sectionGap * 2),
                decoration: BoxDecoration(
                  color: color.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isTrip ? LucideIcons.plane : LucideIcons.split,
                  size: 64,
                  color: color.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
              SizedBox(height: spacing.sectionGap),
              Text(
                isTrip ? AppLocalizations.of(context)!.trip_noTripsYet : AppLocalizations.of(context)!.trip_noSplitsYet,
                style:
                    textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: spacing.elementGap),
              Text(
                isTrip
                    ? AppLocalizations.of(context)!.trip_createTripDesc
                    : AppLocalizations.of(context)!.trip_createSplitDesc,
                style: textTheme.bodyMedium
                    ?.copyWith(color: color.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final active = items.where((t) => t.isActive).toList();
    final archived = items.where((t) => !t.isActive).toList();

    return RefreshIndicator(
      onRefresh: () => RefreshHelper.withMinDuration(() async {
        ref.invalidate(allTripsProvider);
      }),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: spacing.cardHorizontal,
          vertical: spacing.cardVertical,
        ),
        children: [
          if (active.isNotEmpty) ...[
            _buildTypeHeader(
              isTrip
                  ? AppLocalizations.of(context)!.section_active.toUpperCase()
                  : AppLocalizations.of(context)!.section_ongoing.toUpperCase(),
              isTrip ? LucideIcons.plane : LucideIcons.split,
              color.primary,
              textTheme,
            ),
            SizedBox(height: spacing.elementGap),
            ...active.map(
              (t) => Padding(
                padding: EdgeInsets.only(bottom: spacing.cardVertical),
                child: _buildTripCard(
                    context, ref, t, color, textTheme, spacing,
                    isActive: true,),
              ),
            ),
            SizedBox(height: spacing.sectionGap),
          ],
          if (archived.isNotEmpty) ...[
            _buildTypeHeader(
              AppLocalizations.of(context)!.section_archive.toUpperCase(),
              LucideIcons.archive,
              color.onSurfaceVariant,
              textTheme,
            ),
            SizedBox(height: spacing.elementGap),
            ...archived.map(
              (t) => Padding(
                padding: EdgeInsets.only(bottom: spacing.cardVertical),
                child:
                    _buildTripCard(context, ref, t, color, textTheme, spacing),
              ),
            ),
          ],
          const SizedBox(height: 24),
          const AmbientBrandSection(),
        ],
      ),
    );
  }

  Widget _buildTypeHeader(
    String label,
    IconData icon,
    Color iconColor,
    TextTheme textTheme,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Text(
          label,
          style: textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: iconColor,
            letterSpacing: 1.2,
          ),
        ),
      ],
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
    final isSplit = !trip.isTrip;
    final duration = trip.endDate.difference(trip.startDate).inDays + 1;
    final summaryAsync = ref.watch(tripSummaryProvider(trip.id));

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: isActive
          ? color.primaryContainer.withValues(alpha: 0.3)
          : color.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        side: BorderSide(
          color: isActive
              ? color.primary.withValues(alpha: 0.3)
              : color.outlineVariant.withValues(alpha: 0.5),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(spacing.elementGap * 1.5),
                    decoration: BoxDecoration(
                      color: color.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(spacing.radiusMedium),
                    ),
                    child: Icon(
                      isSplit ? LucideIcons.users : LucideIcons.plane,
                      color: color.primary,
                      size: 22,
                    ),
                  ),
                  SizedBox(width: spacing.elementGap * 1.5),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.name,
                          style: textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: spacing.elementGapUltraMin),
                        if (!isSplit)
                          Text(
                            '${DateFormat.MMMd().format(trip.startDate)} - ${DateFormat.MMMd().format(trip.endDate)} \u2022 $duration days',
                            style: textTheme.bodySmall
                                ?.copyWith(color: color.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),
                  if (trip.isActive)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: spacing.elementGap,
                        vertical: spacing.elementGapMin,
                      ),
                      decoration: BoxDecoration(
                        color: color.primary.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(spacing.radiusSmall),
                      ),
                      child: Text(
                        isSplit
                            ? AppLocalizations.of(context)!.section_active
                            : AppLocalizations.of(context)!.trip_live,
                        style: textTheme.labelSmall?.copyWith(
                          color: color.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (!trip.isActive)
                    Icon(
                      LucideIcons.circleCheck,
                      size: 16,
                      color: color.onSurfaceVariant.withValues(alpha: 0.4),
                    ),
                  SizedBox(width: spacing.elementGapMin),
                  Icon(
                    LucideIcons.chevronRight,
                    size: 16,
                    color: color.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                ],
              ),
              summaryAsync.maybeWhen(
                data: (s) {
                  if (s.totalSpent == 0 && s.participantCount <= 1) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: EdgeInsets.only(top: spacing.elementGap),
                    child: isSplit
                        ? _buildSplitSummary(context, s, trip.currencyCode,
                            color, textTheme, spacing,)
                        : _buildTripSummary(
                            s, trip.currencyCode, color, textTheme, spacing,),
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTripSummary(
    TripSummary s,
    String? currencyCode,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Text(
                formatCurrency(s.totalSpent, code: currencyCode, decimals: 0),
                style:
                    textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                ' ${AppLocalizations.of(context)!.trip_spent}',
                style: textTheme.bodySmall
                    ?.copyWith(color: color.onSurfaceVariant),
              ),
              if (s.ownerShare > 0) ...[
                Text(
                  ' \u2022 ',
                  style: textTheme.bodySmall
                      ?.copyWith(color: color.onSurfaceVariant),
                ),
                Text(
                  formatCurrency(s.ownerShare, code: currencyCode, decimals: 0),
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color.primary,
                  ),
                ),
                Text(
                  ' ${AppLocalizations.of(context)!.trip_yourShare}',
                  style: textTheme.bodySmall
                      ?.copyWith(color: color.onSurfaceVariant),
                ),
              ],
            ],
          ),
        ),
        Text(
          AppLocalizations.of(context)!.trip_nPeople(s.participantCount),
          style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildSplitSummary(
    BuildContext context,
    TripSummary s,
    String? currencyCode,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    final Color balanceColor;
    final String balanceText;

    if (s.youGet) {
      balanceColor = FinanceColors.statusGood;
      balanceText =
          'You\'ll get ${formatCurrency(s.netBalance, code: currencyCode, decimals: 0)}';
    } else if (s.youOwe) {
      balanceColor = FinanceColors.statusDanger;
      balanceText =
          'You owe ${formatCurrency(s.netBalance.abs(), code: currencyCode, decimals: 0)}';
    } else if (s.settled) {
      balanceColor = FinanceColors.statusGood;
      balanceText = AppLocalizations.of(context)!.trip_allSettled;
    } else {
      balanceColor = color.onSurfaceVariant;
      balanceText = 'No expenses yet';
    }

    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration:
              BoxDecoration(color: balanceColor, shape: BoxShape.circle),
        ),
        SizedBox(width: spacing.elementGap),
        Expanded(
          child: Text(
            balanceText,
            style: textTheme.bodySmall?.copyWith(
              color: balanceColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          '${s.participantCount} people',
          style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
        ),
      ],
    );
  }

  void _showCreateSheet(
    BuildContext context,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      backgroundColor: color.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(Tone.current.borderRadius * 2),),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(spacing.cardInner + spacing.elementGap),
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
              SizedBox(height: spacing.sectionGap),
              Text(
                'Create Group',
                style:
                    textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: spacing.sectionGap),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(spacing.elementGap),
                  decoration: BoxDecoration(
                    color: color.primaryContainer,
                    borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  ),
                  child:
                      Icon(LucideIcons.plane, color: color.primary, size: 24),
                ),
                title: Text(
                  l10n.trip_createTrip,
                  style: textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  l10n.trip_trackTravel,
                  style: textTheme.bodySmall
                      ?.copyWith(color: color.onSurfaceVariant),
                ),
                trailing: Icon(LucideIcons.chevronRight,
                    size: 18, color: color.onSurfaceVariant,),
                onTap: () {
                  HapticFeedback.mediumImpact();
                  ctx.pop();
                  context.push(AppRoutes.createTrip, extra: {'isTrip': true});
                },
              ),
              SizedBox(height: spacing.elementGap),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(spacing.elementGap),
                  decoration: BoxDecoration(
                    color: color.secondaryContainer,
                    borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  ),
                  child:
                      Icon(LucideIcons.users, color: color.secondary, size: 24),
                ),
                title: Text(
                  l10n.trip_createGroup,
                  style: textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  l10n.trip_splitBills,
                  style: textTheme.bodySmall
                      ?.copyWith(color: color.onSurfaceVariant),
                ),
                trailing: Icon(LucideIcons.chevronRight,
                    size: 18, color: color.onSurfaceVariant,),
                onTap: () {
                  HapticFeedback.mediumImpact();
                  ctx.pop();
                  context.push(AppRoutes.createTrip, extra: {'isTrip': false});
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
