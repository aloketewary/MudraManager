import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_boring_avatars/flutter_boring_avatars.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/state/app_screen_state.dart';
import 'package:mudra_manager/core/utils/dialog_utils.dart';
import 'package:mudra_manager/features/transactions/data/transaction_provider.dart';
import 'package:mudra_manager/features/trip/data/group_detail_provider.dart';
import 'package:mudra_manager/features/trip/data/trip_provider.dart';
import 'package:mudra_manager/features/trip/domain/group_action.dart';
import 'package:mudra_manager/features/trip/domain/group_detail_state.dart';
import 'package:mudra_manager/features/trip/presentation/widgets/trip_insights_tab.dart';
import 'package:mudra_manager/shared/templates/screen_shell.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:mudra_manager/shared/widgets/widgets.dart';
import 'package:mudra_manager/core/router/app_routes.dart';

class TripDetailScreen extends ConsumerStatefulWidget {
  final int tripId;

  const TripDetailScreen({super.key, required this.tripId});

  @override
  ConsumerState<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends ConsumerState<TripDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _updateTabController(bool isActive) {
    final newLength = isActive ? 2 : 3;
    if (_tabController.length != newLength) {
      _tabController.dispose();
      _tabController = TabController(length: newLength, vsync: this);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(groupDetailProvider(widget.tripId));
    final spacing = ref.watch(spacingProvider);
    final isGuestMode = ref.watch(guestModeProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return stateAsync.when(
      data: (state) {
        if (state == null) {
          return ScreenShell(
            config: ScreenShellConfig(title: BuddyMessages.genericError),
            body: Center(child: Text(BuddyMessages.genericError)),
          );
        }

        final header = state.header;
        _updateTabController(header.isActive);
        final ctxt = AppLocalizations.of(context)!;

        return ScreenShell(
          config: ScreenShellConfig(
            title: header.name,
            appBarMode: AppBarMode.standard,
          ),
          actions: ScreenActions.build(
            overflow: [
              if (state.allowedActions.contains(GroupAction.editGroup))
                ScreenAction(
                  id: 'edit_trip',
                  label: ctxt.trip_editTrip,
                  icon: LucideIcons.pencil,
                  onTap: () => context.push('/edit-trip/${header.id}'),
                ),
              if (state.allowedActions.contains(GroupAction.archiveGroup))
                ScreenAction(
                  id: 'archive_trip',
                  label: ctxt.trip_archiveTrip,
                  icon: LucideIcons.archive,
                  onTap: () => _archiveTrip(header.id),
                ),
            ],
          ),
          body: Column(
            children: [
              _buildSummaryCard(state, isGuestMode, color, textTheme, spacing),
              TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: ctxt.trip_expenses),
                  Tab(text: ctxt.trip_settlements),
                  if (!header.isActive) Tab(text: ctxt.trip_report),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildExpensesTab(
                      state,
                      isGuestMode,
                      spacing,
                      color,
                      textTheme,
                    ),
                    _buildSettlementsTab(
                      state,
                      isGuestMode,
                      spacing,
                      color,
                      textTheme,
                    ),
                    if (!header.isActive)
                      TripInsightsTab(
                        state: state,
                        isGuestMode: isGuestMode,
                        spacing: spacing,
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => ScreenShell(
        config: ScreenShellConfig(
          title: AppLocalizations.of(context)!.common_loading,
        ),
        body: ListView.builder(
          itemCount: 5,
          itemBuilder: (context, index) => const Padding(
            padding: EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    SkeletonLoader(width: 48, height: 48),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonLoader(width: double.infinity, height: 16),
                          SizedBox(height: 8),
                          SkeletonLoader(width: 150, height: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      error: (e, _) => ScreenShell(
        config: ScreenShellConfig(title: BuddyMessages.genericError),
        body: Center(child: Text(BuddyMessages.errorWith('$e'))),
      ),
    );
  }

  Future<void> _archiveTrip(int tripId) async {
    final confirm = await DialogUtils.showConfirmation(
      context,
      title: 'Archive Trip',
      message:
          'This trip will be moved to archive. All data and settlements will be preserved.',
      confirmText: 'Archive',
      icon: LucideIcons.archive,
    );
    if (confirm == true) {
      final router = GoRouter.of(context);
      await ref.read(tripServiceProvider).archiveTrip(widget.tripId);
      ref.invalidate(allTripsProvider);
      ref.invalidate(activeTripsProvider);
      ref.invalidate(groupDetailProvider(widget.tripId));
      router.pop();
    }
  }

  // ─── Summary Card ───────────────────────────────────────────────────────────

  Widget _buildSummaryCard(
    GroupDetailState state,
    bool isGuestMode,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    final header = state.header;
    final timeline = state.timeline;
    final budget = header.budget ??
        (timeline.totalSpent > 0 ? timeline.totalSpent * 1.2 : 10000);
    final budgetUsed = timeline.totalSpent / budget;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontal,
        vertical: spacing.cardVertical,
      ),
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.primaryContainer, color.secondaryContainer],
        ),
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.calendar,
                  size: 14, color: color.onSurfaceVariant),
              SizedBox(width: spacing.elementGapMin),
              Text(
                '${DateFormat.MMMd().format(header.startDate)} - ${DateFormat.MMMd().format(header.endDate)} \u2022 ${header.durationDays} ${header.durationDays == 1 ? 'day' : 'days'}',
                style: textTheme.bodySmall
                    ?.copyWith(color: color.onSurfaceVariant),
              ),
              const Spacer(),
              if (header.isActive)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.elementGap,
                    vertical: spacing.elementGapUltraMin,
                  ),
                  decoration: BoxDecoration(
                    color: color.primary,
                    borderRadius: BorderRadius.circular(spacing.radiusSmall),
                  ),
                  child: Text(
                    'LIVE',
                    style: textTheme.labelSmall?.copyWith(
                      color: color.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: spacing.elementGap),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.trip_totalSpent,
                      style: textTheme.labelMedium
                          ?.copyWith(color: color.onSurfaceVariant),
                    ),
                    SizedBox(height: spacing.elementGapMin),
                    Text(
                      formatCurrency(timeline.totalSpent,
                          code: header.currencyCode, decimals: 0),
                      style: textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.cardInner * 0.75,
                  vertical: spacing.elementGap,
                ),
                decoration: BoxDecoration(
                  color: budgetUsed > 0.9
                      ? color.errorContainer
                      : color.tertiaryContainer,
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${(budgetUsed * 100).toStringAsFixed(0)}%',
                      style: textTheme.titleMedium?.copyWith(
                        color: budgetUsed > 0.9
                            ? color.onErrorContainer
                            : color.onTertiaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'of budget',
                      style: textTheme.labelSmall?.copyWith(
                        color: budgetUsed > 0.9
                            ? color.onErrorContainer
                            : color.onTertiaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Expenses Tab ───────────────────────────────────────────────────────────

  Widget _buildExpensesTab(
    GroupDetailState state,
    bool isGuestMode,
    AppSpacing spacing,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    final timeline = state.timeline;
    final header = state.header;

    if (timeline.totalExpenseCount == 0) {
      final emptyMsg = BuddyMessages.noTripExpenses(true).split('\n');
      return Center(
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
                  color: color.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                emptyMsg.first,
                style:
                    textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              if (emptyMsg.length > 1) ...[
                const SizedBox(height: 8),
                Text(
                  emptyMsg.sublist(1).join('\n'),
                  style: textTheme.bodyMedium
                      ?.copyWith(color: color.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontal,
        vertical: spacing.cardVertical,
      ),
      itemCount: timeline.days.length,
      itemBuilder: (context, dayIndex) {
        final day = timeline.days[dayIndex];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day header
            Padding(
              padding: EdgeInsets.only(
                top: dayIndex == 0 ? 0 : spacing.sectionGap,
                bottom: spacing.elementGap,
              ),
              child: Row(
                children: [
                  Text(
                    DateFormat('EEE, d MMM').format(day.date),
                    style: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${day.expenseCount} expense${day.expenseCount == 1 ? '' : 's'} \u2022 ${formatCurrency(day.totalSpent, code: header.currencyCode, decimals: 0)}',
                    style: textTheme.labelSmall
                        ?.copyWith(color: color.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            // Expense cards
            ...day.expenses.map(
              (expense) => _buildExpenseCard(
                  expense, state, isGuestMode, spacing, color, textTheme),
            ),
          ],
        );
      },
    );
  }

  Widget _buildExpenseCard(
    GroupExpenseView expense,
    GroupDetailState state,
    bool isGuestMode,
    AppSpacing spacing,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    return Dismissible(
      key: Key('expense_${expense.id}'),
      direction: state.allowedActions.contains(GroupAction.addExpense)
          ? DismissDirection.endToStart
          : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: color.error,
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
        ),
        child: Icon(LucideIcons.trash2, color: color.onError),
      ),
      confirmDismiss: (direction) async {
        HapticFeedback.mediumImpact();
        final confirmed = await DialogUtils.showDeleteConfirmation(
          context,
          title: 'Remove Expense',
          message: 'Remove this expense from the trip?',
          deleteText: 'Remove',
        );
        if (confirmed == true) {
          await ref
              .read(tripServiceProvider)
              .removeTripTransaction(widget.tripId, expense.id);
          ref.invalidate(groupDetailProvider(widget.tripId));
        }
        return false;
      },
      child: Card(
        elevation: 0,
        color: color.surfaceContainerLow,
        margin: EdgeInsets.only(bottom: spacing.cardVertical),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          side: BorderSide(color: color.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: ListTile(
          onTap: () {
            HapticFeedback.lightImpact();
            context.push(
              AppRoutes.expenseDetail,
              extra: {'expenseId': expense.id, 'tripId': widget.tripId},
            );
          },
          leading: SizedBox(
            width: 48,
            height: 48,
            child: ClipOval(
              child: BoringAvatar(
                name: expense.paidByName,
                palette: BoringAvatarPalette([
                  color.primary,
                  color.tertiary,
                  color.primaryContainer,
                  color.tertiaryContainer,
                ]),
                type: BoringAvatarType.beam,
              ),
            ),
          ),
          title: Text(
            expense.title,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                'Paid by ${expense.paidByName} \u2022 Split among ${expense.shares.length}',
                style: textTheme.bodySmall
                    ?.copyWith(color: color.onSurfaceVariant),
              ),
              if (expense.description != null &&
                  expense.description!.isNotEmpty)
                Text(
                  expense.description!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: color.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
            ],
          ),
          trailing: CurrencyText(
            currencyCode: state.header.currencyCode,
            amount: GuestModeUtil.applyGuestMode(expense.amount, isGuestMode),
            fixedLength: 0,
            showPositiveSign: false,
            showSign: true,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color.primary,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Settlements Tab ────────────────────────────────────────────────────────

  Widget _buildSettlementsTab(
    GroupDetailState state,
    bool isGuestMode,
    AppSpacing spacing,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    final settlements = state.settlements;
    final header = state.header;
    final canMarkPaid =
        state.allowedActions.contains(GroupAction.markSettlementPaid);

    if (settlements.pending.isEmpty) {
      return ListView(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.cardHorizontal,
          vertical: spacing.cardVertical,
        ),
        children: [
          SizedBox(height: spacing.sectionGap * 2),
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: color.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(LucideIcons.circleCheck,
                      size: 48, color: color.primary),
                ),
                SizedBox(height: spacing.sectionGap),
                Text(
                  AppLocalizations.of(context)!.trip_allSettled,
                  style: textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: spacing.elementGap),
                Text(
                  'No pending settlements for this trip',
                  style: textTheme.bodyMedium
                      ?.copyWith(color: color.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          _buildSettlementHistory(settlements, spacing, color, textTheme),
        ],
      );
    }

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontal,
        vertical: spacing.cardVertical,
      ),
      children: [
        if (header.isActive) ...[
          Container(
            padding: EdgeInsets.all(spacing.cardInner),
            decoration: BoxDecoration(
              color: color.tertiaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.info, size: 16, color: color.tertiary),
                SizedBox(width: spacing.elementGap),
                Expanded(
                  child: Text(
                    'Archive the trip to settle up',
                    style: textTheme.bodySmall
                        ?.copyWith(color: color.onTertiaryContainer),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: spacing.sectionGap),
        ],
        ...settlements.pending.map(
          (s) => Padding(
            padding: EdgeInsets.only(bottom: spacing.cardVertical),
            child: SettlementCard(
              fromPerson: s.fromName,
              toPerson: s.toName,
              amount: s.amount,
              isPaid: false,
              onMarkPaid: canMarkPaid
                  ? () async {
                      HapticFeedback.mediumImpact();
                      await ref.read(tripServiceProvider).recordSettlement(
                            tripId: widget.tripId,
                            fromId: s.fromId,
                            toId: s.toId,
                            amount: s.amount,
                            currencyCode: header.currencyCode,
                          );
                      ref.invalidate(groupDetailProvider(widget.tripId));
                      ref.invalidate(transactionProvider);
                    }
                  : null,
              spacing: spacing,
            ),
          ),
        ),
        _buildSettlementHistory(settlements, spacing, color, textTheme),
      ],
    );
  }

  Widget _buildSettlementHistory(
    SettlementView settlements,
    AppSpacing spacing,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    if (settlements.history.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: spacing.sectionGap),
        Row(
          children: [
            Icon(LucideIcons.history, size: 16, color: color.onSurfaceVariant),
            SizedBox(width: spacing.elementGap),
            Text(
              'Settlement History',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color.onSurfaceVariant,
              ),
            ),
          ],
        ),
        SizedBox(height: spacing.elementGap),
        ...settlements.history.map(
          (record) => Padding(
            padding: EdgeInsets.only(bottom: spacing.elementGap),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: FinanceColors.statusGood,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: spacing.elementGap * 1.5),
                Expanded(
                  child: Text(
                    '${record.fromName} paid ${record.toName}',
                    style:
                        textTheme.bodySmall?.copyWith(color: color.onSurface),
                  ),
                ),
                Text(
                  formatCurrency(record.amount, code: null, decimals: 0),
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: FinanceColors.statusGood,
                  ),
                ),
                SizedBox(width: spacing.elementGap),
                Text(
                  DateFormat('d MMM').format(record.date),
                  style: textTheme.labelSmall
                      ?.copyWith(color: color.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
