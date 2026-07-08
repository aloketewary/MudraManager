import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_boring_avatars/flutter_boring_avatars.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/trip.dart';
import 'package:mudra_manager/core/extension/case_extention.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/state/app_screen_state.dart';
import 'package:mudra_manager/core/utils/dialog_utils.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/features/trip/data/trip_provider.dart';
import 'package:mudra_manager/features/trip/presentation/widgets/edit_split_sheet.dart';
import 'package:mudra_manager/shared/templates/screen_shell.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';

class ExpenseDetailScreen extends ConsumerStatefulWidget {
  final int expenseId;
  final int tripId;

  const ExpenseDetailScreen({
    super.key,
    required this.expenseId,
    required this.tripId,
  });

  @override
  ConsumerState<ExpenseDetailScreen> createState() =>
      _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends ConsumerState<ExpenseDetailScreen> {
  List<TripParticipant> _selectedParticipants = [];
  SplitType _splitType = SplitType.equal;
  final Map<int, double> _splitAmounts = {};
  bool _isInitialized = false;

  void _initializeData(TripTransaction tripTxn, Trip trip) {
    if (_isInitialized) return;
    _splitType = tripTxn.splitType;
    _selectedParticipants = trip.participants
        .where((p) => tripTxn.participantIds.contains(p.id))
        .toList();
    if (_selectedParticipants.isEmpty) {
      _selectedParticipants = trip.participants.toList();
    }
    for (var i = 0; i < tripTxn.participantIds.length; i++) {
      if (i < tripTxn.splitAmounts.length) {
        _splitAmounts[tripTxn.participantIds[i]] = tripTxn.splitAmounts[i];
      }
    }
    _isInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final tripAsync = ref.watch(tripByIdProvider(widget.tripId));
    final spacing = ref.watch(spacingProvider);
    final isGuestMode = ref.watch(guestModeProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;

    return tripAsync.when(
      data: (trip) {
        if (trip == null) {
          return ScreenShell(
            config: ScreenShellConfig(title: BuddyMessages.genericError),
            body: Center(child: Text(BuddyMessages.genericError)),
          );
        }
        final tripTxn = trip.transactions
            .where((t) => t.id == widget.expenseId)
            .firstOrNull;
        final resolvedAmount = tripTxn?.resolvedAmount;
        if (tripTxn == null || resolvedAmount == null) {
          return ScreenShell(
            config: ScreenShellConfig(title: BuddyMessages.genericError),
            body: Center(child: Text(BuddyMessages.genericError)),
          );
        }

        _initializeData(tripTxn, trip);

        final amount =
            GuestModeUtil.applyGuestMode(resolvedAmount, isGuestMode);
        final paidBy = tripTxn.paidBy.value;
        final category = tripTxn.transaction.value?.category.value?.name ??
            tripTxn.splitExpense.value?.description ??
            'Uncategorized';
        final expenseDate = tripTxn.resolvedDate ?? DateTime.now();
        final expenseDescription = tripTxn.resolvedDescription;
        final perPerson = _selectedParticipants.isNotEmpty
            ? amount / _selectedParticipants.length
            : 0.0;

        return ScreenShell(
          config: ScreenShellConfig(
            title: ctxt.expense_details,
            appBarMode: AppBarMode.standard,
          ),
          actions: ScreenActions.build(
            overflow: [
              ScreenAction(
                id: 'delete_expense',
                label: ctxt.common_delete,
                icon: LucideIcons.trash2,
                onTap: () => _deleteExpense(spacing),
              ),
            ],
          ),
          body: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.cardHorizontal,
              vertical: spacing.cardVertical,
            ),
            children: [
              _buildAmountHero(
                amount,
                category,
                expenseDate,
                spacing,
                color,
                textTheme,
              ),
              SizedBox(height: spacing.sectionGap),
              _buildInfoCard(
                paidBy: paidBy,
                description: expenseDescription,
                trip: trip,
                tripTxn: tripTxn,
                totalAmount: amount,
                spacing: spacing,
                color: color,
                textTheme: textTheme,
              ),
              SizedBox(height: spacing.sectionGap),
              _buildSplitBreakdown(
                tripTxn: tripTxn,
                trip: trip,
                totalAmount: amount,
                perPerson: perPerson,
                spacing: spacing,
                color: color,
                textTheme: textTheme,
              ),
            ],
          ),
        );
      },
      loading: () => ScreenShell(
        config: ScreenShellConfig(title: ctxt.expense_details),
        body: ListView(
          children: List.generate(3, (_) => const DashboardCardSkeleton()),
        ),
      ),
      error: (e, _) => ScreenShell(
        config: ScreenShellConfig(title: BuddyMessages.genericError),
        body: Center(child: Text(BuddyMessages.errorWith('$e'))),
      ),
    );
  }

  Widget _buildAmountHero(
    double amount,
    String category,
    DateTime date,
    AppSpacing spacing,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        color: color.surfaceContainerLow,
        border: Border.all(color: color.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.cardInner),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: spacing.elementGap,
                vertical: spacing.elementGapMin,
              ),
              decoration: BoxDecoration(
                color: color.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(spacing.radiusSmall),
              ),
              child: Text(
                category,
                style: textTheme.labelLarge?.copyWith(
                  color: color.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: spacing.sectionGap),
            CurrencyText(
              amount: amount,
              compact: false,
              style: textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: color.onSurface,
              ),
            ),
            SizedBox(height: spacing.elementGap),
            Text(
              DateFormat('EEEE, d MMMM yyyy').format(date),
              style: textTheme.bodyMedium?.copyWith(
                color: color.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required TripParticipant? paidBy,
    required String? description,
    required Trip trip,
    required TripTransaction tripTxn,
    required double totalAmount,
    required AppSpacing spacing,
    required ColorScheme color,
    required TextTheme textTheme,
  }) {
    final owner = trip.participants.where((p) => p.isOwner).firstOrNull;
    final ownerId = owner?.id;
    double? ownerShare;
    if (ownerId != null) {
      final idx = tripTxn.participantIds.indexOf(ownerId);
      if (idx >= 0 && idx < tripTxn.splitAmounts.length) {
        ownerShare = tripTxn.splitType == SplitType.percentage
            ? totalAmount * tripTxn.splitAmounts[idx] / 100
            : tripTxn.splitType == SplitType.equal
                ? totalAmount / tripTxn.participantIds.length
                : tripTxn.splitAmounts[idx];
      }
    }
    final isPaidByOwner = paidBy?.id == ownerId;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: color.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        side: BorderSide(
          color: color.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.cardInner),
        child: Column(
          children: [
            _infoRow(
              icon: LucideIcons.user,
              label: 'Paid by',
              value: isPaidByOwner ? 'You' : (paidBy?.name ?? 'Unknown'),
              color: color,
              textTheme: textTheme,
              spacing: spacing,
            ),
            if (ownerShare != null && tripTxn.participantIds.length > 1) ...[
              Divider(color: color.outlineVariant.withValues(alpha: 0.3)),
              _infoRow(
                icon: LucideIcons.receiptText,
                label: 'Your share',
                value: formatCurrency(
                  ownerShare,
                  code: trip.currencyCode,
                  decimals: 0,
                ),
                color: color,
                textTheme: textTheme,
                spacing: spacing,
              ),
            ],
            if (description != null && description.isNotEmpty) ...[
              Divider(color: color.outlineVariant.withValues(alpha: 0.3)),
              _infoRow(
                icon: LucideIcons.textQuote,
                label: 'Note',
                value: description,
                color: color,
                textTheme: textTheme,
                spacing: spacing,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    required ColorScheme color,
    required TextTheme textTheme,
    required AppSpacing spacing,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: spacing.cardVertical),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
            ),
            child: Icon(icon, size: 18, color: color.primary),
          ),
          SizedBox(width: spacing.sectionGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.labelSmall?.copyWith(
                    color: color.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: spacing.cardHorizontalMin),
                Text(
                  value,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitBreakdown({
    required TripTransaction tripTxn,
    required Trip trip,
    required double totalAmount,
    required double perPerson,
    required AppSpacing spacing,
    required ColorScheme color,
    required TextTheme textTheme,
  }) {
    final chartColors = [
      color.primary,
      color.tertiary,
      color.secondary,
      color.error,
      color.primaryContainer,
      color.tertiaryContainer,
    ];

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(),
      color: color.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        side: BorderSide(
          color: color.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.cardInner),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.users, color: color.secondary, size: 20),
                SizedBox(width: spacing.sectionGap),
                Expanded(
                  child: Text(
                    'Split \u2022 ${_splitType.name.toTitleCase()}',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (trip.isActive)
                  TextButton.icon(
                    onPressed: () => showEditSplitSheet(
                      context: context,
                      trip: trip,
                      tripTxn: tripTxn,
                      selectedParticipants: _selectedParticipants,
                      splitType: _splitType,
                      splitAmounts: _splitAmounts,
                      onChanged: () => setState(() {}),
                      spacing: spacing,
                    ),
                    icon: const Icon(LucideIcons.pencil, size: 14),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
            SizedBox(height: spacing.sectionGap),
            ..._selectedParticipants.asMap().entries.map((entry) {
              final i = entry.key;
              final p = entry.value;
              final isOwnerRow = p.isOwner;
              final pIdx = tripTxn.participantIds.indexOf(p.id);
              double share;
              if (_splitType == SplitType.equal) {
                share = totalAmount / _selectedParticipants.length;
              } else if (pIdx >= 0 && pIdx < tripTxn.splitAmounts.length) {
                share = _splitType == SplitType.percentage
                    ? totalAmount * tripTxn.splitAmounts[pIdx] / 100
                    : tripTxn.splitAmounts[pIdx];
              } else {
                share = perPerson;
              }
              final pct = totalAmount > 0 ? share / totalAmount : 0.0;
              final barColor = chartColors[i % chartColors.length];

              return Container(
                padding: EdgeInsets.all(spacing.cardInner),
                margin: EdgeInsets.only(bottom: spacing.cardVertical),
                decoration: BoxDecoration(
                  color: isOwnerRow
                      ? color.primaryContainer.withValues(alpha: 0.3)
                      : color.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  border: isOwnerRow
                      ? Border.all(
                          color: color.primary.withValues(alpha: 0.3),
                        )
                      : null,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: ClipOval(
                        child: BoringAvatar(
                          name: p.name,
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
                    SizedBox(width: spacing.elementGap),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isOwnerRow ? 'You' : p.name,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isOwnerRow ? color.primary : null,
                            ),
                          ),
                          SizedBox(height: spacing.cardHorizontalMin),
                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(spacing.radiusSmall),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 4,
                              backgroundColor: color.surface,
                              valueColor: AlwaysStoppedAnimation(barColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: spacing.elementGap),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        CurrencyText(
                          amount: share,
                          compact: false,
                          fixedLength: 0,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: barColor,
                          ),
                        ),
                        Text(
                          '${(pct * 100).toStringAsFixed(0)}%',
                          style: textTheme.labelSmall?.copyWith(
                            color: color.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteExpense(AppSpacing spacing,) async {
    final confirm = await DialogUtils.showConfirmation(
      context, spacing,
      title: 'Delete Expense',
      message: 'This will adjust everyone\'s balance. Continue?',
      confirmText: 'Delete',
      icon: LucideIcons.trash2,
    );
    if (confirm != true) return;
    if (!context.mounted) return;

    final router = GoRouter.of(context);
    await ref.read(tripServiceProvider).removeTripTransaction(
          widget.tripId,
          widget.expenseId,
        );
    ref.invalidate(tripByIdProvider(widget.tripId));

    SnackbarService.success(BuddyMessages.txnDeleted, spacing,);
    router.pop();
  }
}
