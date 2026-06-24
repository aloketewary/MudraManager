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

class SplitDetailScreen extends ConsumerStatefulWidget {
  final int tripId;

  const SplitDetailScreen({super.key, required this.tripId});

  @override
  ConsumerState<SplitDetailScreen> createState() => _SplitDetailScreenState();
}

class _SplitDetailScreenState extends ConsumerState<SplitDetailScreen>
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
            fab: state.allowedActions.contains(GroupAction.addExpense) &&
                    !header.isTrip
                ? ScreenAction(
                    id: 'add_split_expense',
                    label: ctxt.trip_splitExpense,
                    icon: LucideIcons.plus,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      context.push(
                        AppRoutes.addTripTransaction,
                        extra: widget.tripId,
                      );
                    },
                  )
                : null,
            overflow: [
              if (state.allowedActions.contains(GroupAction.editGroup))
                ScreenAction(
                  id: 'edit_group',
                  label: ctxt.trip_editTrip,
                  icon: LucideIcons.pencil,
                  onTap: () => context.push('/edit-trip/${header.id}'),
                ),
              if (state.allowedActions.contains(GroupAction.archiveGroup))
                ScreenAction(
                  id: 'archive_group',
                  label: ctxt.trip_archiveTrip,
                  icon: LucideIcons.archive,
                  onTap: () => _archiveGroup(header.id),
                ),
            ],
          ),
          body: Column(
            children: [
              _buildSummaryCard(state, isGuestMode, color, textTheme, spacing),
              TabBar(
                controller: _tabController,
                tabs: [
                  Tab(
                    text:
                        header.isTrip ? ctxt.trip_expenses : ctxt.trip_balances,
                  ),
                  Tab(
                    text: header.isTrip
                        ? ctxt.trip_settlements
                        : ctxt.trip_expenses,
                  ),
                  if (!header.isActive) Tab(text: ctxt.trip_report),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: header.isTrip
                      ? [
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
                        ]
                      : [
                          _buildSettlementsTab(
                            state,
                            isGuestMode,
                            spacing,
                            color,
                            textTheme,
                          ),
                          _buildExpensesTab(
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

  Future<void> _archiveGroup(int groupId) async {
    final confirm = await DialogUtils.showConfirmation(
      context,
      title: AppLocalizations.of(context)!.trip_archiveGroupTitle,
      message: AppLocalizations.of(context)!.trip_archiveGroupMsg,
      confirmText: AppLocalizations.of(context)!.trip_archive,
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
          if (header.isTrip)
            Row(
              children: [
                Icon(LucideIcons.calendar,
                    size: 14, color: color.onSurfaceVariant,),
                SizedBox(width: spacing.elementGapMin),
                Text(
                  '${DateFormat.MMMd().format(header.startDate)} - ${DateFormat.MMMd().format(header.endDate)} \u2022 ${header.durationDays} ${AppLocalizations.of(context)!.trip_nDays(header.durationDays)}',
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
                      AppLocalizations.of(context)!.trip_live,
                      style: textTheme.labelSmall?.copyWith(
                        color: color.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          if (!header.isTrip && header.isActive)
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.elementGap,
                  vertical: spacing.elementGapUltraMin,
                ),
                decoration: BoxDecoration(
                  color: color.primary,
                  borderRadius: BorderRadius.circular(spacing.radiusSmall),
                ),
                child: Text(
                  AppLocalizations.of(context)!.section_active.toUpperCase(),
                  style: textTheme.labelSmall?.copyWith(
                    color: color.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          SizedBox(height: spacing.elementGap),
          if (header.isTrip)
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
                            code: header.currencyCode, decimals: 0,),
                        style: textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                if (header.budget != null)
                  Builder(builder: (_) {
                    final budgetUsed = timeline.totalSpent / header.budget!;
                    return Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: spacing.cardInner * 0.75,
                        vertical: spacing.elementGap,
                      ),
                      decoration: BoxDecoration(
                        color: budgetUsed > 0.9
                            ? color.errorContainer
                            : color.tertiaryContainer,
                        borderRadius:
                            BorderRadius.circular(spacing.radiusMedium),
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
                            AppLocalizations.of(context)!.trip_ofBudget,
                            style: textTheme.labelSmall?.copyWith(
                              color: budgetUsed > 0.9
                                  ? color.onErrorContainer
                                  : color.onTertiaryContainer,
                            ),
                          ),
                        ],
                      ),
                    );
                  },),
              ],
            )
          else
            Row(
              children: [
                Icon(LucideIcons.users,
                    size: 14, color: color.onSurfaceVariant,),
                SizedBox(width: spacing.elementGapMin),
                Text(
                  '${header.memberCount} ${AppLocalizations.of(context)!.trip_nPeople(header.memberCount)}',
                  style: textTheme.bodySmall
                      ?.copyWith(color: color.onSurfaceVariant),
                ),
                if (timeline.totalSpent > 0) ...[
                  Text(' \u2022 ',
                      style: textTheme.bodySmall
                          ?.copyWith(color: color.onSurfaceVariant),),
                  Text(
                    '${formatCurrency(timeline.totalSpent, code: header.currencyCode, decimals: 0)} total',
                    style: textTheme.bodySmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
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
      final emptyMsg = BuddyMessages.noTripExpenses(header.isTrip).split('\n');
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
                  header.isTrip ? LucideIcons.plane : LucideIcons.split,
                  size: 64,
                  color: color.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
              SizedBox(height: spacing.sectionGap),
              Text(
                emptyMsg.first,
                style:
                    textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              if (emptyMsg.length > 1) ...[
                SizedBox(height: spacing.elementGap),
                Text(
                  emptyMsg.sublist(1).join('\n'),
                  style: textTheme.bodyMedium
                      ?.copyWith(color: color.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
              if (!header.isTrip &&
                  state.allowedActions.contains(GroupAction.addExpense)) ...[
                SizedBox(height: spacing.sectionGap),
                FilledButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    context.push(AppRoutes.addTripTransaction,
                        extra: widget.tripId,);
                  },
                  icon: const Icon(LucideIcons.plus, size: 18),
                  label: Text(AppLocalizations.of(context)!.trip_splitExpense),
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
            if (header.isTrip) ...[
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
                      '${day.expenseCount} ${AppLocalizations.of(context)!.trip_nExpenses(day.expenseCount)} \u2022 ${formatCurrency(day.totalSpent, code: header.currencyCode, decimals: 0)}',
                      style: textTheme.labelSmall?.copyWith(
                        color: color.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Expense cards for this day
            ...day.expenses.map(
              (expense) => _buildExpenseCard(
                expense,
                state,
                isGuestMode,
                spacing,
                color,
                textTheme,
              ),
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
    final header = state.header;

    return Dismissible(
      key: Key('expense_${expense.id}'),
      direction: state.allowedActions.contains(GroupAction.addExpense)
          ? DismissDirection.endToStart
          : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: spacing.cardInner),
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
          title: AppLocalizations.of(context)!.trip_removeExpense,
          message: header.isTrip
              ? AppLocalizations.of(context)!.trip_removeExpenseMsg
              : AppLocalizations.of(context)!.trip_removeGroupExpenseMsg,
          deleteText: AppLocalizations.of(context)!.trip_remove,
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
              if (header.isTrip)
                Text(
                  AppLocalizations.of(context)!.trip_paidBySplitAmong(expense.paidByName, expense.shares.length),
                  style: textTheme.bodySmall
                      ?.copyWith(color: color.onSurfaceVariant),
                )
              else
                Text(
                  _buildSplitContextLabel(expense),
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
            currencyCode: header.currencyCode,
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

  String _buildSplitContextLabel(GroupExpenseView expense) {
    if (expense.paidByOwner) return 'You paid';
    if (expense.ownerShareAmount != null) {
      return '${expense.paidByName} paid \u2022 You owe ${formatCurrency(expense.ownerShareAmount!, code: expense.currencyCode, decimals: 0)}';
    }
    return '${expense.paidByName} paid';
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
                  padding: EdgeInsets.all(spacing.sectionGap),
                  decoration: BoxDecoration(
                    color: color.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(LucideIcons.circleCheck,
                      size: 48, color: color.primary,),
                ),
                SizedBox(height: spacing.sectionGap),
                Text(
                  AppLocalizations.of(context)!.trip_allSettled,
                  style: textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: spacing.elementGap),
                Text(
                  AppLocalizations.of(context)!.trip_everyoneSquare,
                  style: textTheme.bodyMedium
                      ?.copyWith(color: color.onSurfaceVariant),
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
        // Trip active hint
        if (header.isTrip && header.isActive) ...[
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
                    AppLocalizations.of(context)!.trip_archiveToSettle,
                    style: textTheme.bodySmall
                        ?.copyWith(color: color.onTertiaryContainer),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: spacing.sectionGap),
        ],
        // Pending count summary for splits
        if (!header.isTrip) ...[
          Container(
            padding: EdgeInsets.all(spacing.cardInner),
            decoration: BoxDecoration(
              color: color.surfaceContainerLow,
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
              border: Border.all(
                  color: color.outlineVariant.withValues(alpha: 0.5),),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.clock, size: 20, color: color.tertiary),
                SizedBox(width: spacing.elementGap * 1.5),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.trip_nPendingSettlements(settlements.pendingCount),
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: spacing.sectionGap),
        ],
        // Settlement cards
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
              AppLocalizations.of(context)!.trip_settlementHistory,
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
