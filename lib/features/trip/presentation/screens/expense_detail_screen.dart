import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:mudra_manager/shared/widgets/currency_badge.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_boring_avatars/flutter_boring_avatars.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/trip.dart';
import 'package:mudra_manager/core/extension/case_extention.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/dialog_utils.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/features/trip/data/trip_provider.dart';
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

    return tripAsync.when(
      data: (trip) {
        if (trip == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Trip Not Found')),
            body: const Center(child: Text('Trip not found')),
          );
        }
        final tripTxn = trip.transactions
            .where((t) => t.id == widget.expenseId)
            .firstOrNull;
        final resolvedAmount = tripTxn?.resolvedAmount;
        if (tripTxn == null || resolvedAmount == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Not Found')),
            body: const Center(child: Text('Expense not found')),
          );
        }

        _initializeData(tripTxn, trip);

        final amount =
            GuestModeUtil.applyGuestMode(resolvedAmount, isGuestMode);
        final paidBy = tripTxn.paidBy.value;
        final category = tripTxn.transaction.value?.category.value?.name
            ?? tripTxn.splitExpense.value?.description
            ?? 'Uncategorized';
        final expenseDate = tripTxn.resolvedDate ?? DateTime.now();
        final expenseDescription = tripTxn.resolvedDescription;
        final perPerson = _selectedParticipants.isNotEmpty
            ? amount / _selectedParticipants.length
            : 0.0;

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(LucideIcons.arrowLeft),
              onPressed: () {
                HapticFeedback.mediumImpact();
                context.pop();
              },
            ),
            title: Text(AppLocalizations.of(context)!.expense_details),
            actions: [
              PopupMenuButton(
                icon: const Icon(LucideIcons.ellipsisVertical),
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(LucideIcons.trash2, color: color.error, size: 18),
                        const SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: color.error)),
                      ],
                    ),
                  ),
                ],
                onSelected: (val) {
                  if (val == 'delete') _deleteExpense();
                },
              ),
            ],
          ),
          body: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.cardHorizontal,
              vertical: spacing.cardVertical,
            ),
            children: [
              // Amount hero
              _buildAmountHero(
                amount,
                category,
                expenseDate,
                spacing,
                color,
                textTheme,
              ),
              SizedBox(height: spacing.sectionGap),
              // Info card
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
              const SizedBox(height: 16),
              // Split breakdown
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
      loading: () => Scaffold(
        body: ListView(children: List.generate(3, (_) => const DashboardCardSkeleton())),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(BuddyMessages.genericError)),
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.primaryContainer,
            color.secondaryContainer,
          ],
        ),
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
    // Find owner's share
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
                value: formatCurrency(ownerShare, code: trip.currencyCode, decimals: 0),
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
                    onPressed: () => _editSplit(trip, tripTxn),
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

  // ─── SPLIT EDIT + ACTIONS ───

  void _editSplit(Trip trip, TripTransaction tripTxn) {
    final amount = tripTxn.resolvedAmount ?? 0.0;
    final controllers = <int, TextEditingController>{};
    for (var p in _selectedParticipants) {
      controllers[p.id] = TextEditingController(
        text: (_splitAmounts[p.id] ?? 0).toString(),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final color = Theme.of(context).colorScheme;
          final textTheme = Theme.of(context).textTheme;

          double currentSum = 0;
          for (var id in _selectedParticipants.map((p) => p.id)) {
            currentSum += _splitAmounts[id] ?? 0;
          }
          final isPercentage = _splitType == SplitType.percentage;
          final target = isPercentage ? 100.0 : amount;
          final remaining = target - currentSum;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.expense_editSplit,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Split Type', style: textTheme.titleSmall),
                    if ((_splitType == SplitType.custom ||
                            _splitType == SplitType.percentage) &&
                        amount > 0)
                      Text(
                        isPercentage
                            ? 'Remaining: ${remaining.toStringAsFixed(1)}%'
                            : 'Remaining: ${formatCurrency(remaining, decimals: 2)}',
                        style: textTheme.labelLarge?.copyWith(
                          color: remaining.abs() < 0.1
                              ? color.primary
                              : (remaining < 0 ? color.error : color.tertiary),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                SegmentedButton<SplitType>(
                  segments: const [
                    ButtonSegment(
                      value: SplitType.equal,
                      label: Text('Equal'),
                      icon: Icon(LucideIcons.chartPie, size: 16),
                    ),
                    ButtonSegment(
                      value: SplitType.percentage,
                      label: Text('%'),
                      icon: Icon(LucideIcons.percent, size: 16),
                    ),
                    ButtonSegment(
                      value: SplitType.custom,
                      label: Text('Custom'),
                      icon: Icon(LucideIcons.calculator, size: 16),
                    ),
                  ],
                  selected: {_splitType},
                  onSelectionChanged: (Set<SplitType> selected) {
                    setState(() => _splitType = selected.first);
                    setModalState(() {});
                  },
                ),
                const SizedBox(height: 16),
                Text('Participants', style: textTheme.titleSmall),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: trip.participants.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final p = trip.participants.toList()[index];
                      final isSelected =
                          _selectedParticipants.any((sp) => sp.id == p.id);

                      return InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            if (isSelected) {
                              _selectedParticipants
                                  .removeWhere((sp) => sp.id == p.id);
                              _splitAmounts.remove(p.id);
                            } else {
                              _selectedParticipants.add(p);
                              if (_splitType != SplitType.equal) {
                                _splitAmounts[p.id] = 0.0;
                                controllers[p.id] =
                                    TextEditingController(text: '0');
                              }
                            }
                          });
                          setModalState(() {});
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.primaryContainer.withValues(alpha: 0.2)
                                : color.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? color.primary.withValues(alpha: 0.5)
                                  : color.outlineVariant.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: isSelected
                                    ? color.primary
                                    : color.surfaceContainerHighest,
                                child: Text(
                                  p.name[0].toUpperCase(),
                                  style: TextStyle(
                                    color: isSelected
                                        ? color.onPrimary
                                        : color.onSurfaceVariant,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: (_splitType == SplitType.custom ||
                                            _splitType ==
                                                SplitType.percentage) &&
                                        isSelected
                                    ? Row(
                                        children: [
                                          Text(
                                            p.name,
                                            style:
                                                textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const Spacer(),
                                          if (_splitType ==
                                                  SplitType.percentage &&
                                              amount > 0)
                                            Text(
                                              '${formatCurrency((amount * (_splitAmounts[p.id] ?? 0) / 100), decimals: 0)}  ',
                                              style:
                                                  textTheme.bodySmall?.copyWith(
                                                color: color.primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          SizedBox(
                                            width: 120,
                                            child: TextField(
                                              controller: controllers[p.id],
                                              keyboardType: const TextInputType
                                                  .numberWithOptions(
                                                decimal: true,
                                              ),
                                              decoration: InputDecoration(
                                                prefixText: _splitType ==
                                                        SplitType.percentage
                                                    ? ''
                                                    : null,
                                                prefix: _splitType != SplitType.percentage ? Padding(
                                                  padding: const EdgeInsets.only(right: 4),
                                                  child: CurrencyBadge(code: BaseCurrency.code, size: 12),
                                                ) : null,
                                                suffixText: _splitType ==
                                                        SplitType.percentage
                                                    ? '%'
                                                    : null,
                                                isDense: true,
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 8,
                                                ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                suffixIcon: IconButton(
                                                  icon: Icon(
                                                    LucideIcons.wand,
                                                    size: 18,
                                                    color: color.primary,
                                                  ),
                                                  tooltip:
                                                      'Auto-fill remaining',
                                                  padding: EdgeInsets.zero,
                                                  constraints:
                                                      const BoxConstraints(),
                                                  onPressed: () {
                                                    double othersSum = 0;
                                                    for (var sp
                                                        in _selectedParticipants) {
                                                      if (sp.id == p.id) {
                                                        continue;
                                                      }
                                                      othersSum +=
                                                          _splitAmounts[
                                                                  sp.id] ??
                                                              0;
                                                    }
                                                    final rem =
                                                        target - othersSum;
                                                    setState(
                                                      () =>
                                                          _splitAmounts[p.id] =
                                                              rem,
                                                    );
                                                    controllers[p.id]!.text =
                                                        rem.toStringAsFixed(
                                                      isPercentage ? 1 : 2,
                                                    );
                                                    setModalState(() {});
                                                  },
                                                ),
                                              ),
                                              onChanged: (value) {
                                                setState(() {
                                                  _splitAmounts[p.id] =
                                                      double.tryParse(value) ??
                                                          0.0;
                                                });
                                                setModalState(() {});
                                              },
                                            ),
                                          ),
                                        ],
                                      )
                                    : Text(
                                        p.name,
                                        style: textTheme.titleMedium?.copyWith(
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                              ),
                              if (isSelected && _splitType == SplitType.equal)
                                Icon(
                                  LucideIcons.circleCheck,
                                  color: color.primary,
                                )
                              else if (!isSelected)
                                Icon(
                                  LucideIcons.circle,
                                  color: color.outline,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    for (var c in controllers.values) {
                      c.dispose();
                    }
                    ctx.pop();
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: Text(AppLocalizations.of(context)!.common_done),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteExpense() async {
    final confirm = await DialogUtils.showConfirmation(
      context,
      title: 'Delete Expense',
      message: 'This will adjust everyone\'s balance. Continue?',
      confirmText: 'Delete',
      icon: LucideIcons.trash2,
    );
    if (confirm != true) return;

    await ref.read(tripServiceProvider).removeTripTransaction(
          widget.tripId,
          widget.expenseId,
        );
    ref.invalidate(tripByIdProvider(widget.tripId));

    SnackbarService.success(BuddyMessages.txnDeleted);
    if (mounted) context.pop();
  }
}
