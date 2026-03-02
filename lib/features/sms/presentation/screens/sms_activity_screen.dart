import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/sms_activity.dart';
import 'package:mudra_manager/features/sms/data/sms_activity_service.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';

final smsActivityProvider = FutureProvider<List<SmsActivity>>((ref) async {
  return await SmsActivityService.instance.getAllActivities();
});

final pendingCountProvider = FutureProvider<int>((ref) async {
  return await SmsActivityService.instance.getPendingCount();
});

class SmsActivityScreen extends ConsumerStatefulWidget {
  const SmsActivityScreen({super.key});

  @override
  ConsumerState<SmsActivityScreen> createState() => _SmsActivityScreenState();
}

class _SmsActivityScreenState extends ConsumerState<SmsActivityScreen> {
  ActivityStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final activitiesAsync = ref.watch(smsActivityProvider);
    final pendingCount = ref.watch(pendingCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS Activity'),
        actions: [
          if (pendingCount.value != null && pendingCount.value! > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: Text('${pendingCount.value}'),
                backgroundColor: color.errorContainer,
                labelStyle: TextStyle(
                  color: color.onErrorContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          PopupMenuButton<ActivityStatus?>(
            icon: const Icon(LucideIcons.list),
            onSelected: (status) {
              setState(() => _filterStatus = status);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('All'),
              ),
              const PopupMenuItem(
                value: ActivityStatus.pending,
                child: Text('Pending'),
              ),
              const PopupMenuItem(
                value: ActivityStatus.needsReview,
                child: Text('Needs Review'),
              ),
              const PopupMenuItem(
                value: ActivityStatus.duplicate,
                child: Text('Duplicates'),
              ),
              const PopupMenuItem(
                value: ActivityStatus.approved,
                child: Text('Approved'),
              ),
              const PopupMenuItem(
                value: ActivityStatus.rejected,
                child: Text('Rejected'),
              ),
            ],
          ),
        ],
      ),
      body: activitiesAsync.when(
        data: (activities) {
          final filtered = _filterStatus == null
              ? activities
              : activities.where((a) => a.status == _filterStatus).toList();

          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.inbox,
                      size: 64, color: color.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text(
                    'No SMS activities',
                    style: textTheme.titleMedium?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final activity = filtered[index];
              return _ActivityCard(activity: activity);
            },
          );
        },
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 5,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SkeletonLoader(
              width: double.infinity,
              height: 110,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _ActivityCard extends ConsumerWidget {
  final SmsActivity activity;

  const _ActivityCard({required this.activity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isIncome = activity.isIncome == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: _getCardColor(color),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          HapticFeedback.mediumImpact();
          _showActivityDetails(context, ref);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getStatusColor(color).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getStatusIcon(),
                      color: _getStatusColor(color),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.sender,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          DateFormat('dd MMM, hh:mm a').format(activity.date),
                          style: textTheme.bodySmall?.copyWith(
                            color: color.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (activity.amount != null)
                    Text(
                      '${isIncome ? '+' : '-'} ₹${activity.amount!.toStringAsFixed(2)}',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isIncome ? color.primary : color.error,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _StatusChip(
                    label: activity.status.name.toUpperCase(),
                    color: _getStatusColor(color),
                  ),
                  if (activity.confidence != null) ...{
                    const SizedBox(width: 8),
                    _StatusChip(
                      label: '${activity.confidence}%',
                      color: _getConfidenceColor(color),
                    ),
                  },
                  if (activity.isPotentialDuplicate == true) ...{
                    const SizedBox(width: 8),
                    _StatusChip(
                      label: 'DUPLICATE',
                      color: color.error,
                    ),
                  },
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCardColor(ColorScheme color) {
    switch (activity.status) {
      case ActivityStatus.needsReview:
        return color.errorContainer.withValues(alpha: 0.3);
      case ActivityStatus.duplicate:
        return color.tertiaryContainer.withValues(alpha: 0.3);
      case ActivityStatus.approved:
        return color.surfaceContainerHighest;
      case ActivityStatus.rejected:
        return color.surfaceContainerHigh;
      default:
        return color.surfaceContainerHighest;
    }
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
        return color.error;
    }
  }

  Color _getConfidenceColor(ColorScheme color) {
    final conf = activity.confidence ?? 0;
    if (conf >= 80) return color.primary;
    if (conf >= 60) return color.tertiary;
    return color.error;
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

  void _showActivityDetails(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ActivityDetailsSheet(activity: activity),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
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

class _ActivityDetailsSheet extends ConsumerWidget {
  final SmsActivity activity;

  const _ActivityDetailsSheet({required this.activity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Activity Details',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(LucideIcons.x),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                activity.body,
                style: textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 16),
            _DetailRow('Status', activity.status.name.toUpperCase()),
            if (activity.confidence != null)
              _DetailRow('Confidence', '${activity.confidence}%'),
            if (activity.amount != null)
              _DetailRow('Amount', '₹${activity.amount}'),
            if (activity.account != null)
              _DetailRow('Account', activity.account!),
            if (activity.fromBank != null)
              _DetailRow('Bank', activity.fromBank!),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
