import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:isar_community/isar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/sms_activity.dart';
import 'package:mudra_manager/core/extension/localization_extenstion.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/refresh_helper.dart';
import 'package:mudra_manager/features/account/data/account_providers.dart';
import 'package:mudra_manager/features/sms/data/sms_activity_service.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:mudra_manager/core/router/app_routes.dart';

final smsActivityProvider =
    FutureProvider.autoDispose<List<SmsActivity>>((ref) async {
  ref.watch(smsRefreshProvider);
  return await SmsActivityService.instance.getAllActivities();
});

final pendingCountProvider = FutureProvider.autoDispose<int>((ref) async {
  ref.watch(smsRefreshProvider);
  return await SmsActivityService.instance.getPendingCount();
});

final smsRefreshProvider = StateProvider<int>((ref) => 0);

class SmsActivityScreen extends ConsumerStatefulWidget {
  const SmsActivityScreen({super.key});

  @override
  ConsumerState<SmsActivityScreen> createState() => _SmsActivityScreenState();
}

class _SmsActivityScreenState extends ConsumerState<SmsActivityScreen>
    with WidgetsBindingObserver {
  ActivityStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(smsRefreshProvider.notifier).state++;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activitiesAsync = ref.watch(smsActivityProvider);
    final pendingCount = ref.watch(pendingCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Activity'),
        actions: [
          IconButton(
            icon: Icon(
              _filterStatus != null
                  ? LucideIcons.listTodo
                  : LucideIcons.listFilter,
              size: 20,
            ),
            onPressed: () => _showFilterSheet(color, textTheme),
          ),
        ],
      ),
      body: activitiesAsync.when(
        data: (activities) {
          final filtered = _filterStatus == null
              ? activities
              : activities.where((a) => a.status == _filterStatus).toList();

          return RefreshIndicator(
            onRefresh: () => RefreshHelper.withMinDuration(() async {
              ref.invalidate(smsActivityProvider);
              ref.invalidate(pendingCountProvider);
            }),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── HERO SUMMARY ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      spacing.cardHorizontal,
                      spacing.cardVertical,
                      spacing.cardHorizontal,
                      0,
                    ),
                    child: _buildHeroCard(
                      activities,
                      pendingCount.valueOrNull ?? 0,
                      color,
                      textTheme,
                      spacing,
                      isDark,
                    ),
                  ),
                ),

                // ── FILTER CHIP (when active) ──
                if (_filterStatus != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        spacing.cardHorizontal,
                        12,
                        spacing.cardHorizontal,
                        0,
                      ),
                      child: Row(
                        children: [
                          Chip(
                            label: Text(
                              _statusLabel(_filterStatus!),
                              style: textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            avatar: Icon(
                              _statusIcon(_filterStatus!),
                              size: 14,
                            ),
                            deleteIcon: const Icon(LucideIcons.x, size: 14),
                            onDeleted: () =>
                                setState(() => _filterStatus = null),
                            visualDensity: VisualDensity.compact,
                          ),
                          const Spacer(),
                          Text(
                            '${filtered.length} result${filtered.length == 1 ? '' : 's'}',
                            style: textTheme.bodySmall?.copyWith(
                              color: color.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ── EMPTY STATE ──
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.inbox,
                            size: 48,
                            color:
                                color.onSurfaceVariant.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _filterStatus != null
                                ? 'No ${_statusLabel(_filterStatus!).toLowerCase()} activities'
                                : BuddyMessages.noTransactions,
                            style: textTheme.bodyLarge?.copyWith(
                              color: color.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ── ACTIVITY LIST ──
                if (filtered.isNotEmpty)
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing.cardHorizontal,
                      vertical: spacing.cardVertical,
                    ),
                    sliver: SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) =>
                          _ActivityCard(activity: filtered[index]),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.of(context).padding.bottom +
                        kBottomNavigationBarHeight +
                        16,
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => ListView.builder(
          padding: EdgeInsets.all(spacing.cardHorizontalMax),
          itemCount: 5,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SkeletonLoader(
              width: double.infinity,
              height: 80,
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
            ),
          ),
        ),
        error: (e, _) => Center(child: Text(BuddyMessages.errorWith('$e'))),
      ),
    );
  }

  // ── HERO CARD ──

  Widget _buildHeroCard(
    List<SmsActivity> all,
    int pendingCount,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    bool isDark,
  ) {
    final approved =
        all.where((a) => a.status == ActivityStatus.approved).length;
    final rejected =
        all.where((a) => a.status == ActivityStatus.rejected).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(spacing.radiusLarge),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.primary.withValues(alpha: isDark ? 0.2 : 0.12),
            color.primaryContainer.withValues(alpha: 0.4),
          ],
        ),
        border: Border.all(
          color: color.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutBack,
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) =>
                    Transform.scale(scale: value, child: child),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.bellRing,
                    color: color.primary,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${all.length} Transactions',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: color.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pendingCount > 0
                          ? '$pendingCount need${pendingCount == 1 ? 's' : ''} attention'
                          : BuddyMessages.noNotifications,
                      style: textTheme.bodySmall?.copyWith(
                        color: color.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Stat pills
          Row(
            children: [
              _statPill(
                '$approved',
                'Approved',
                color.primary,
                color,
                textTheme,
              ),
              const SizedBox(width: 8),
              _statPill(
                '$pendingCount',
                'Pending',
                color.tertiary,
                color,
                textTheme,
              ),
              const SizedBox(width: 8),
              _statPill(
                '$rejected',
                'Rejected',
                color.error,
                color,
                textTheme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statPill(
    String value,
    String label,
    Color accent,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: accent,
              ),
            ),
            Text(
              label,
              style: textTheme.labelSmall?.copyWith(
                color: color.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── FILTER SHEET ──

  void _showFilterSheet(ColorScheme color, TextTheme textTheme) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 16),
            Text(
              'Filter by Status',
              style:
                  textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...[
              null,
              ActivityStatus.pending,
              ActivityStatus.needsReview,
              ActivityStatus.duplicate,
              ActivityStatus.approved,
              ActivityStatus.rejected,
            ].map((status) {
              final selected = _filterStatus == status;
              final label = status == null ? 'All' : _statusLabel(status);
              return ListTile(
                dense: true,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                selected: selected,
                selectedTileColor: color.primaryContainer,
                leading: Icon(
                  status == null ? LucideIcons.list : _statusIcon(status),
                  size: 20,
                  color: selected
                      ? color.onPrimaryContainer
                      : _statusColor(status, color),
                ),
                title: Text(
                  label,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    color:
                        selected ? color.onPrimaryContainer : color.onSurface,
                  ),
                ),
                trailing: selected
                    ? Icon(
                        LucideIcons.check,
                        size: 18,
                        color: color.onPrimaryContainer,
                      )
                    : null,
                onTap: () {
                  setState(() => _filterStatus = status);
                  Navigator.pop(ctx);
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── HELPERS ──

  String _statusLabel(ActivityStatus status) {
    switch (status) {
      case ActivityStatus.pending:
        return 'Pending';
      case ActivityStatus.needsReview:
        return 'Needs Review';
      case ActivityStatus.duplicate:
        return 'Duplicates';
      case ActivityStatus.approved:
        return 'Approved';
      case ActivityStatus.rejected:
        return 'Rejected';
    }
  }

  IconData _statusIcon(ActivityStatus status) {
    switch (status) {
      case ActivityStatus.pending:
        return LucideIcons.clock;
      case ActivityStatus.approved:
        return LucideIcons.circleCheck;
      case ActivityStatus.duplicate:
        return LucideIcons.copy;
      case ActivityStatus.rejected:
        return LucideIcons.circleX;
      case ActivityStatus.needsReview:
        return LucideIcons.circleAlert;
    }
  }

  Color _statusColor(ActivityStatus? status, ColorScheme color) {
    if (status == null) return color.primary;
    switch (status) {
      case ActivityStatus.pending:
        return color.tertiary;
      case ActivityStatus.approved:
        return color.primary;
      case ActivityStatus.duplicate:
        return color.error;
      case ActivityStatus.rejected:
        return color.onSurfaceVariant;
      case ActivityStatus.needsReview:
        return color.tertiary;
    }
  }
}

// ── ACTIVITY CARD ──

class _ActivityCard extends ConsumerWidget {
  final SmsActivity activity;

  const _ActivityCard({required this.activity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final isIncome = activity.isIncome == true;
    final statusColor = _getStatusColor(color);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: color.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        side: BorderSide(
          color: color.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          _showActivityDetails(context);
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Status icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getStatusIcon(),
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.sender,
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          DateFormat('dd MMM, hh:mm a').format(activity.date),
                          style: textTheme.bodySmall?.copyWith(
                            color: color.onSurfaceVariant,
                          ),
                        ),
                        if (activity.confidence != null) ...[
                          _dot(color),
                          _ConfidenceBadge(
                            confidence: activity.confidence!,
                            color: color,
                            textTheme: textTheme,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Chips row
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _StatusChip(
                          label: _getStatusLabel(),
                          color: statusColor,
                        ),
                        if (activity.isPotentialDuplicate == true)
                          _StatusChip(
                            label: 'DUPLICATE',
                            color: color.error,
                          ),
                        if (activity.transactionType != null)
                          _StatusChip(
                            label: activity.transactionType!,
                            color: color.tertiary,
                          ),
                        if (activity.isLikelyTransfer == true)
                          _StatusChip(
                            label: 'TRANSFER',
                            color: color.secondary,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Amount
              if (activity.amount != null)
                CurrencyText(
                  amount: activity.amount!,
                  showSign: true,
                  isExpense: !isIncome,
                  compact: true,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isIncome ? color.primary : color.error,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dot(ColorScheme color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      width: 3,
      height: 3,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.onSurfaceVariant.withValues(alpha: 0.5),
      ),
    );
  }

  Color _getStatusColor(ColorScheme color) {
    switch (activity.status) {
      case ActivityStatus.pending:
        return color.tertiary;
      case ActivityStatus.approved:
        return color.primary;
      case ActivityStatus.duplicate:
        return color.error;
      case ActivityStatus.rejected:
        return color.onSurfaceVariant;
      case ActivityStatus.needsReview:
        return color.tertiary;
    }
  }

  String _getStatusLabel() {
    switch (activity.status) {
      case ActivityStatus.pending:
        return 'PENDING';
      case ActivityStatus.approved:
        return 'APPROVED';
      case ActivityStatus.duplicate:
        return 'DUPLICATE';
      case ActivityStatus.rejected:
        return 'REJECTED';
      case ActivityStatus.needsReview:
        return 'REVIEW';
    }
  }

  IconData _getStatusIcon() {
    switch (activity.status) {
      case ActivityStatus.pending:
        return LucideIcons.clock;
      case ActivityStatus.approved:
        return LucideIcons.circleCheck;
      case ActivityStatus.duplicate:
        return LucideIcons.copy;
      case ActivityStatus.rejected:
        return LucideIcons.circleX;
      case ActivityStatus.needsReview:
        return LucideIcons.circleAlert;
    }
  }

  void _showActivityDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ActivityDetailsSheet(activity: activity),
    );
  }
}

// ── CONFIDENCE BADGE ──

class _ConfidenceBadge extends StatelessWidget {
  final int confidence;
  final ColorScheme color;
  final TextTheme textTheme;

  const _ConfidenceBadge({
    required this.confidence,
    required this.color,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final c = confidence >= 80
        ? color.primary
        : confidence >= 60
            ? color.tertiary
            : color.error;

    return Text(
      '$confidence%',
      style: textTheme.labelSmall?.copyWith(
        color: c,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

// ── STATUS CHIP ──

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

// ── DETAILS SHEET ──
class _ActivityDetailsSheet extends ConsumerStatefulWidget {
  final SmsActivity activity;
  const _ActivityDetailsSheet({required this.activity});
  @override
  ConsumerState<_ActivityDetailsSheet> createState() =>
      _ActivityDetailsSheetState();
}

class _ActivityDetailsSheetState extends ConsumerState<_ActivityDetailsSheet> {
  bool _hasMatchingAccount = true;
  @override
  void initState() {
    super.initState();
    _checkAccount();
  }

  Future<void> _checkAccount() async {
    final acc = widget.activity.account;
    if (acc == null || acc.isEmpty) return;
    final isar = await ref.read(isarServiceProvider).getInstance();
    final match = await isar.accounts
        .filter()
        .accountNumberEqualTo(acc)
        .isActiveEqualTo(true)
        .findFirst();
    if (mounted) setState(() => _hasMatchingAccount = match != null);
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final isIncome = widget.activity.isIncome == true;
    final isActionable = widget.activity.status == ActivityStatus.pending ||
        widget.activity.status == ActivityStatus.needsReview ||
        widget.activity.status == ActivityStatus.duplicate;
    final ctxt = AppLocalizations.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: color.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Header with amount
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.activity.sender,
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('dd MMM yyyy, hh:mm a')
                              .format(widget.activity.date),
                          style: textTheme.bodySmall?.copyWith(
                            color: color.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.activity.amount != null)
                    CurrencyText(
                      amount: widget.activity.amount!,
                      showSign: true,
                      isExpense: !isIncome,
                      compact: false,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isIncome ? color.primary : color.error,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // SMS body
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  border: Border.all(
                    color: color.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  widget.activity.body,
                  style: textTheme.bodySmall?.copyWith(
                    height: 1.5,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Details card
              Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                color: color.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  side: BorderSide(
                    color: color.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    _detailRow(
                      'Status',
                      widget.activity.status.name.toUpperCase(),
                      color,
                      textTheme,
                    ),
                    if (widget.activity.confidence != null) ...[
                      _divider(color),
                      _detailRow(
                        'Confidence',
                        '${widget.activity.confidence}%',
                        color,
                        textTheme,
                      ),
                    ],
                    if (widget.activity.account != null) ...[
                      _divider(color),
                      _detailRow(
                        'Account',
                        widget.activity.account!,
                        color,
                        textTheme,
                      ),
                    ],
                    if (widget.activity.fromBank != null) ...[
                      _divider(color),
                      _detailRow(
                        'Bank',
                        widget.activity.fromBank!,
                        color,
                        textTheme,
                      ),
                    ],
                    if (widget.activity.transactionType != null) ...[
                      _divider(color),
                      _detailRow(
                        'Type',
                        widget.activity.transactionType!,
                        color,
                        textTheme,
                      ),
                    ],
                    if (widget.activity.merchant != null) ...[
                      _divider(color),
                      _detailRow(
                        'Merchant',
                        widget.activity.merchant!,
                        color,
                        textTheme,
                      ),
                    ],
                    if (widget.activity.balance != null) ...[
                      _divider(color),
                      _detailRow(
                        'Balance',
                        formatCurrency(widget.activity.balance!, code: BaseCurrency.code, decimals: 0),
                        color,
                        textTheme,
                      ),
                    ],
                    if (widget.activity.transactionRef != null) ...[
                      _divider(color),
                      _detailRow(
                        'Reference',
                        widget.activity.transactionRef!,
                        color,
                        textTheme,
                      ),
                    ],
                  ],
                ),
              ),

              // ── ACTION BUTTONS ──
              if (isActionable) ...[
                const SizedBox(height: 20),

                // Duplicate warning
                if (widget.activity.status == ActivityStatus.duplicate)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.tertiary.withValues(alpha: 0.08),
                        borderRadius:
                            BorderRadius.circular(spacing.radiusMedium),
                        border: Border.all(
                          color: color.tertiary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.triangleAlert,
                            color: color.tertiary,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'This may be a duplicate transaction. Review carefully before approving.',
                              style: textTheme.bodySmall?.copyWith(
                                color: color.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (!_hasMatchingAccount && widget.activity.account != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.tertiary.withValues(alpha: 0.08),
                        borderRadius:
                            BorderRadius.circular(spacing.radiusMedium),
                        border: Border.all(
                          color: color.tertiary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.info,
                            color: color.tertiary,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'No account found matching "${widget.activity.account}". Add one to approve.',
                              style: textTheme.bodySmall?.copyWith(
                                color: color.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (widget.activity.isLikelyTransfer == true &&
                    widget.activity.pairedActivityId != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.secondary.withValues(alpha: 0.08),
                        borderRadius:
                            BorderRadius.circular(spacing.radiusMedium),
                        border: Border.all(
                          color: color.secondary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.arrowLeftRight,
                            color: color.secondary,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'This looks like a transfer between your accounts. Approving will open the transfer screen.',
                              style: textTheme.bodySmall?.copyWith(
                                color: color.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          HapticFeedback.mediumImpact();
                          Navigator.pop(context);
                          await SmsActivityService.instance
                              .rejectActivity(widget.activity, null);
                          ref.invalidate(smsActivityProvider);
                          ref.invalidate(pendingCountProvider);
                          ref.read(smsRefreshProvider.notifier).state++;
                        },
                        icon: const Icon(LucideIcons.x, size: 16),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: color.error,
                          side: BorderSide(color: color.error),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(spacing.radiusMedium),
                          ),
                        ),
                      ),
                    ),
                    if (!_hasMatchingAccount &&
                        widget.activity.account != null) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            context.push(
                              '/manage-accounts/add',
                              extra: {
                                'accountNumber': widget.activity.account,
                                'bankName': widget.activity.fromBank,
                              },
                            ).then((result) {
                              if (result == true) {
                                _checkAccount();
                                ref.invalidate(accountsProvider);
                                ref.invalidate(allAccountsProvider);
                                ref.invalidate(frequencySortedAccountsProvider);
                              }
                            });
                          },
                          icon: const Icon(LucideIcons.plus, size: 16),
                          label: const Text('Add A/C'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: color.tertiary,
                            side: BorderSide(color: color.tertiary),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(spacing.radiusMedium),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () async {
                          HapticFeedback.mediumImpact();
                          final navigator = GoRouter.of(context);
                          Navigator.pop(context); // close sheet

                          if (widget.activity.isLikelyTransfer == true) {
                            // Try to pre-match accounts
                            Account? fromAccount;
                            Account? toAccount;

                            if (widget.activity.pairedActivityId != null) {
                              final isar = await ref
                                  .read(isarServiceProvider)
                                  .getInstance();
                              final pair = await isar.smsActivitys
                                  .get(widget.activity.pairedActivityId!);
                              final accounts = await isar.accounts
                                  .filter()
                                  .isActiveEqualTo(true)
                                  .findAll();

                              final thisAcc = accounts
                                  .where(
                                    (a) =>
                                        a.accountNumber != null &&
                                        a.accountNumber!.endsWith(
                                          widget.activity.account ?? '',
                                        ),
                                  )
                                  .firstOrNull;
                              final pairAcc = pair == null
                                  ? null
                                  : accounts
                                      .where(
                                        (a) =>
                                            a.accountNumber != null &&
                                            a.accountNumber!
                                                .endsWith(pair.account ?? ''),
                                      )
                                      .firstOrNull;

                              if (widget.activity.isIncome == true) {
                                toAccount = thisAcc;
                                fromAccount = pairAcc;
                              } else {
                                fromAccount = thisAcc;
                                toAccount = pairAcc;
                              }
                            }

                            if (!context.mounted) return;
                            navigator.push(
                              AppRoutes.transfer,
                              extra: {
                                'amount':
                                    widget.activity.amount?.toString(),
                                'note':
                                    'Auto: ${widget.activity.merchant ?? widget.activity.sender}',
                                'date': widget.activity.date,
                                if (fromAccount != null)
                                  'fromAccount': fromAccount,
                                if (toAccount != null)
                                  'toAccount': toAccount,
                              },
                            );
                          } else {
                            navigator.push(
                              AppRoutes.addTransaction,
                              extra: {
                                'smsActivity': widget.activity,
                                'isIncome': widget.activity.isIncome == true,
                              },
                            );
                          }
                        },
                        icon: Icon(
                          widget.activity.isLikelyTransfer == true
                              ? LucideIcons.arrowLeftRight
                              : LucideIcons.check,
                          size: 16,
                        ),
                        label: Text(
                          widget.activity.isLikelyTransfer == true
                              ? 'Transfer'
                              : 'Approve',
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(spacing.radiusMedium),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(
    String label,
    String value,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              color: color.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(ColorScheme color) {
    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: color.outlineVariant.withValues(alpha: 0.4),
    );
  }
}
