import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/tag.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/extension/account_type_extenstion.dart';
import 'package:mudra_manager/core/extension/case_extention.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/utils/icon_helper.dart';
import 'package:mudra_manager/core/utils/string_util.dart';
import 'package:mudra_manager/shared/widgets/adaptive_text.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:mudra_manager/shared/widgets/swipe_action_wrapper.dart';

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
  });

  @override
  ConsumerState<TransactionCard> createState() => _TransactionCardState();
}

class _TransactionCardState extends ConsumerState<TransactionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late double displayAmount;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isGuestMode = ref.watch(guestModeProvider);
    displayAmount = GuestModeUtil.applyGuestMode(widget.amount.toDouble(), isGuestMode);
    widget.related?.category.load();
    widget.related?.account.load();

    final card = SwipeActionWrapper(
      onEdit: widget.onEdit,
      onDelete: widget.onRemove,
      child: GestureDetector(
        onTapDown: (_) => _scaleController.forward(),
        onTapUp: (_) => _scaleController.reverse(),
        onTapCancel: () => _scaleController.reverse(),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
            elevation: 0,
            color: color.surfaceContainerLow,
        child: Stack(
          children: [
            if (widget.tripName != null)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.tertiaryContainer,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.flight_takeoff,
                        size: 12,
                        color: color.onTertiaryContainer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'TRIP',
                        style: TextStyle(
                          color: color.onTertiaryContainer,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (widget.isRecurring)
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.errorContainer,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.repeat,
                        size: 12,
                        color: color.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'SUBSCRIPTION',
                        style: TextStyle(
                          color: color.error,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  widget.isTransfer ? buildTransferCard() : buildNormalCard(),
                  if (widget.description?.isNotEmpty == true ||
                      widget.tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    if (widget.description?.isNotEmpty == true)
                      Text(
                        widget.description!,
                        style: textTheme.bodySmall?.copyWith(
                          color: color.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (widget.tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
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
                                  color: color.secondaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.tag,
                                      size: 12,
                                      color: color.onSecondaryContainer,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      tag.name,
                                      style: textTheme.labelSmall?.copyWith(
                                        color: color.onSecondaryContainer,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
          ),
        ),
      ),
    );

    if (widget.index != null) {
      return card.animate()
          .fadeIn(delay: Duration(milliseconds: widget.index! * 30), duration: 250.ms)
          .slideX(begin: 0.1, delay: Duration(milliseconds: widget.index! * 30), duration: 250.ms);
    }
    return card;
  }

  Widget buildNormalCard() {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;
    final categoryColor = Color(widget.category?.colorValue ?? 0xFF000000);

    return Row(
      children: <Widget>[
        Container(
          width: 48.0,
          height: 48.0,
          decoration: BoxDecoration(
            color: categoryColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            IconHelper.getIconData(widget.category?.iconName),
            color: categoryColor,
            size: 24.0,
          ),
        ),
        const SizedBox(width: 14.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AdaptiveText(
                '${widget.category?.name}',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
              ),
              const SizedBox(height: 4),
              Flexible(
                child: AdaptiveText(
                  '${widget.account?.name} • ${widget.account?.accountType.name.toTitleCase()}',
                  style: textTheme.bodySmall?.copyWith(
                    color: color.onSurfaceVariant,
                  ),
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (widget.tripName != null) const SizedBox(height: 20),
            CurrencyText(
              amount: displayAmount,
              showSign: true,
              isExpense: widget.isExpense,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: widget.isExpense ? color.error : color.primary,
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM dd', ctxt.localeName).format(widget.date),
              style: textTheme.bodySmall?.copyWith(
                color: color.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildTransferCard() {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final related = widget.related;
    final ctxt = AppLocalizations.of(context)!;

    return Column(
      children: [
        Row(
          children: [
            // FROM Account
            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      related?.account.value?.accountType.icon,
                      size: 16,
                      color: color.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ctxt.common_fromLabel,
                          style: textTheme.labelSmall?.copyWith(
                            color: color.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                        AdaptiveText(
                          related?.account.value?.name ?? '',
                          style: textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Transfer Icon
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Icon(
                Icons.arrow_forward_rounded,
                color: color.tertiary,
                size: 20,
              ),
            ),

            // TO Account
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          ctxt.common_toLabel,
                          style: textTheme.labelSmall?.copyWith(
                            color: color.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                        AdaptiveText(
                          widget.account?.name ?? '',
                          style: textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.account?.accountType.icon,
                      size: 16,
                      color: color.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CurrencyText(
              amount: displayAmount,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color.primary,
              ),
            ),
          ],
        ),
        Text(
          DateFormat('MMM dd, yyyy', ctxt.localeName).format(widget.date),
          style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
        ),
      ],
    );
  }
}
