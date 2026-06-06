import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/tag.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/extension/account_type_extenstion.dart';
import 'package:mudra_manager/core/extension/case_extention.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/core/utils/dialog_utils.dart';
import 'package:mudra_manager/core/utils/icon_helper.dart';
import 'package:mudra_manager/core/utils/string_util.dart';
import 'package:mudra_manager/shared/widgets/adaptive_text.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:mudra_manager/shared/widgets/safe_text.dart';
import 'package:mudra_manager/shared/widgets/swipe_action_wrapper.dart';
import 'package:mudra_manager/features/transactions/presentation/widgets/card_variants/card_variants.dart';

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
  final int? index;
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
    this.index,
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
  void initState() {
    super.initState();
  }

  bool get _hasDetails =>
      (widget.description?.isNotEmpty == true) || widget.tags.isNotEmpty;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isGuestMode = ref.watch(guestModeProvider);
    displayAmount =
        GuestModeUtil.applyGuestMode(widget.amount.toDouble(), isGuestMode);

    final card = SwipeActionWrapper(
      enablePeek: widget.enablePeek,
      onEdit: widget.onEdit,
      onDelete: widget.onRemove,
      child: GestureDetector(
        onTap: _hasDetails
            ? () {
                HapticFeedback.lightImpact();
                setState(() => _expanded = !_expanded);
              }
            : null,
        child: Card(
          margin: EdgeInsets.symmetric(
            horizontal: spacing.cardHorizontal,
            vertical: spacing.cardVertical,
          ),
          elevation: 0,
          color: color.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(spacing.radiusMedium),
            side: BorderSide(color: color.outlineVariant, width: 0.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildVariantBody(),
                if (_hasDetails)
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: _expanded &&
                            (widget.description?.isNotEmpty == true ||
                                widget.tags.isNotEmpty)
                        ? AnimatedOpacity(
                            opacity: _expanded ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  child: Container(
                                    height: 1,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          color.outlineVariant
                                              .withValues(alpha: 0.0),
                                          color.outlineVariant
                                              .withValues(alpha: 0.4),
                                          color.outlineVariant
                                              .withValues(alpha: 0.0),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                if (widget.description?.isNotEmpty == true)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: color.surfaceContainerHighest
                                          .withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(
                                          spacing.radiusSmall),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          LucideIcons.notepadText,
                                          size: 14,
                                          color: color.onSurfaceVariant
                                              .withValues(alpha: 0.6),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            widget.description.safe(),
                                            style:
                                                textTheme.bodySmall?.copyWith(
                                              color: color.onSurfaceVariant,
                                              height: 1.4,
                                            ),
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (widget.description?.isNotEmpty == true &&
                                    widget.tags.isNotEmpty)
                                  const SizedBox(height: 8),
                                if (widget.tags.isNotEmpty)
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: widget.tags
                                        .map(
                                          (tag) => Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: color.secondaryContainer
                                                  .withValues(
                                                alpha: 0.5,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                8,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  LucideIcons.tag,
                                                  size: 12,
                                                  color: color
                                                      .onSecondaryContainer,
                                                ),
                                                const SizedBox(
                                                  width: 4,
                                                ),
                                                Text(
                                                  tag.name,
                                                  style: textTheme.labelSmall
                                                      ?.copyWith(
                                                    color: color
                                                        .onSecondaryContainer,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    if (widget.index != null) {
      return card;
    }
    return card;
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

  Widget _buildVariantBody() {
    if (widget.isTransfer) {
      return TransferTransactionCardBody(data: _cardData);
    }
    if (widget.isRecurring) {
      return SubscriptionTransactionCardBody(data: _cardData);
    }
    if (widget.tripName != null) {
      return TripTransactionCardBody(data: _cardData);
    }
    return NormalTransactionCardBody(data: _cardData);
  }
}
