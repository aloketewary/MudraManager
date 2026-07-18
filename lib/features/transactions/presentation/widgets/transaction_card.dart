import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/tag.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/string_util.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:mudra_manager/shared/widgets/safe_text.dart';
import 'package:mudra_manager/shared/widgets/swipe_action_wrapper.dart';
import 'package:mudra_manager/features/transactions/presentation/widgets/card_variants/card_variants.dart';

/// Transaction card with expandable details and swipe actions.
///
/// Features:
/// - Swipe-to-edit and swipe-to-delete actions
/// - Expandable description and tags
/// - Guest mode support
/// - Smooth animations
/// - Accessibility with reduced motion
class TransactionCard extends ConsumerStatefulWidget {
  final Category? category;
  final String? description;
  final Account? account;
  final String amount;
  final DateTime date;
  final bool isExpense;
  final bool isTransfer;
  final List<Tag> tags;
  final VoidCallback onEdit;
  final VoidCallback onRemove;
  final Transaction? related;
  final String? tripName;
  final bool isRecurring;
  final bool enablePeek;
  final String? currencyCode;
  final double? convertedAmount;
  final VoidCallback? onUnlinkRecurring;

  const TransactionCard({
    super.key,
    required this.category,
    required this.description,
    required this.account,
    required this.amount,
    required this.date,
    required this.isExpense,
    required this.tags,
    required this.onEdit,
    required this.onRemove,
    required this.isTransfer,
    required this.related,
    this.tripName,
    this.isRecurring = false,
    this.enablePeek = false,
    this.currencyCode,
    this.convertedAmount,
    this.onUnlinkRecurring,
  });

  @override
  ConsumerState<TransactionCard> createState() => _TransactionCardState();
}

class _TransactionCardState extends ConsumerState<TransactionCard> {
  late double displayAmount;
  bool _expanded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isGuestMode = ref.read(guestModeProvider);
    displayAmount = GuestModeUtil.applyGuestMode(
      widget.amount.toDouble(),
      isGuestMode,
    );
  }

  bool get _hasDetails =>
      (widget.description?.isNotEmpty == true) || widget.tags.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final spacing = ref.watch(spacingProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isReducedMotion = MediaQuery.of(context).disableAnimations;

    return SwipeActionWrapper(
      enablePeek: widget.enablePeek,
      onEdit: widget.onEdit,
      onDelete: widget.onRemove,
      child: _CardContent(
        data: _cardData,
        hasDetails: _hasDetails,
        expanded: _expanded,
        isReducedMotion: isReducedMotion,
        spacing: spacing,
        colorScheme: colorScheme,
        onToggleExpand: _hasDetails
            ? () {
                HapticFeedback.lightImpact();
                setState(() => _expanded = !_expanded);
              }
            : null,
      ),
    );
  }

  TransactionCardData get _cardData => TransactionCardData(
        category: widget.category,
        description: widget.description,
        account: widget.account,
        displayAmount: displayAmount,
        date: widget.date,
        isExpense: widget.isExpense,
        isTransfer: widget.isTransfer,
        tags: widget.tags,
        related: widget.related,
        tripName: widget.tripName,
        isRecurring: widget.isRecurring,
        currencyCode: widget.currencyCode,
        convertedAmount: widget.convertedAmount,
        hasDetails: _hasDetails,
        expanded: _expanded,
        onUnlinkRecurring: widget.onUnlinkRecurring,
      );
}

/// Card content with expandable details.
class _CardContent extends StatelessWidget {
  final TransactionCardData data;
  final bool hasDetails;
  final bool expanded;
  final bool isReducedMotion;
  final AppSpacing spacing;
  final ColorScheme colorScheme;
  final VoidCallback? onToggleExpand;

  const _CardContent({
    required this.data,
    required this.hasDetails,
    required this.expanded,
    required this.isReducedMotion,
    required this.spacing,
    required this.colorScheme,
    this.onToggleExpand,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontal,
        vertical: spacing.cardVertical,
      ),
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: spacing.strokeThin,
        ),
      ),
      child: InkWell(
        onTap: onToggleExpand,
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        child: Padding(
          padding: EdgeInsets.all(spacing.cardInner - 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildVariantBody(),
              if (hasDetails) _buildExpandableDetails(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVariantBody() {
    if (data.isTransfer) {
      return TransferTransactionCardBody(data: data);
    }
    if (data.isRecurring) {
      return SubscriptionTransactionCardBody(data: data);
    }
    if (data.tripName != null) {
      return TripTransactionCardBody(data: data);
    }
    return NormalTransactionCardBody(data: data);
  }

  Widget _buildExpandableDetails() {
    return AnimatedSize(
      duration: isReducedMotion ? Duration.zero : spacing.animFast,
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: expanded && hasDetails
          ? _ExpandedDetails(
              description: data.description,
              tags: data.tags,
              spacing: spacing,
              colorScheme: colorScheme,
              isReducedMotion: isReducedMotion,
            )
          : const SizedBox.shrink(),
    );
  }
}

/// Expanded details section with description and tags.
class _ExpandedDetails extends StatelessWidget {
  final String? description;
  final List<Tag> tags;
  final AppSpacing spacing;
  final ColorScheme colorScheme;
  final bool isReducedMotion;

  const _ExpandedDetails({
    required this.description,
    required this.tags,
    required this.spacing,
    required this.colorScheme,
    required this.isReducedMotion,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: isReducedMotion ? Duration.zero : spacing.animFast,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDivider(),
          if (description?.isNotEmpty == true) ...[
            _buildDescription(),
            if (tags.isNotEmpty) SizedBox(height: spacing.elementGap),
          ],
          if (tags.isNotEmpty) _buildTags(),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: spacing.elementGap + 2),
      child: Container(
        height: spacing.strokeThin,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.outlineVariant.withValues(alpha: 0.0),
              colorScheme.outlineVariant.withValues(alpha: 0.4),
              colorScheme.outlineVariant.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDescription() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontalMin + 4,
        vertical: spacing.elementGap,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(spacing.radiusSmall),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            LucideIcons.notepadText,
            size: spacing.iconXS,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          SizedBox(width: spacing.elementGapMin),
          Expanded(
            child: Text(
              description.safe(),
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 13,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTags() {
    return Wrap(
      spacing: spacing.elementGapMin,
      runSpacing: spacing.elementGapMin,
      children: tags.map((tag) => _TagChip(tag: tag, spacing: spacing, colorScheme: colorScheme)).toList(),
    );
  }
}

/// Individual tag chip.
class _TagChip extends StatelessWidget {
  final Tag tag;
  final AppSpacing spacing;
  final ColorScheme colorScheme;

  const _TagChip({
    required this.tag,
    required this.spacing,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.elementGap,
        vertical: spacing.elementGapMin,
      ),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(spacing.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.tag,
            size: spacing.iconXS - 2,
            color: colorScheme.onSecondaryContainer,
          ),
          SizedBox(width: spacing.elementGapUltraMin),
          Text(
            tag.name,
            style: TextStyle(
              color: colorScheme.onSecondaryContainer,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}