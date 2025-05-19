import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/db/models/account.dart' show Account;
import 'package:mudra_manager/db/models/category.dart';
import 'package:mudra_manager/db/models/tag.dart';
import 'package:mudra_manager/db/models/transaction.dart' show Transaction;
import 'package:mudra_manager/l10n/app_localizations.dart' show AppLocalizations;
import 'package:mudra_manager/util/account_type_extension.dart';
import 'package:mudra_manager/util/case_extension.dart';
import 'package:mudra_manager/util/icon_helper.dart';
import 'package:mudra_manager/util/localization_extension.dart';
import 'package:mudra_manager/util/string_util.dart';

class TransactionCard extends StatefulWidget {
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
  });

  @override
  State<TransactionCard> createState() => _TransactionCardState();
}

class _TransactionCardState extends State<TransactionCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    widget.related?.category.load();
    widget.related?.account.load();
    final ctxt = AppLocalizations.of(context)!;

    return Card.outlined(
      shadowColor: color.surface,
      color: _isExpanded ? color.primary : null,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0), side: BorderSide(width: 1, color: color.primary)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.0),
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              widget.isTransfer ? buildTransferCard(_isExpanded) : buildNormalCard(_isExpanded),

              if (_isExpanded && !widget.isTransfer)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    ctxt.transaction_noteDescriptionText(widget.description ?? ''),
                    style: textTheme.labelLarge?.copyWith(color: color.onPrimary),
                  ),
                ),
              if (_isExpanded)
                Wrap(
                  spacing: 4.0,
                  runSpacing: 4.0,
                  children:
                      widget.tags.map((tag) {
                        return Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            runSpacing: 2,
                            children: [
                              Icon(Icons.tag, color: color.onPrimary, size: 12),
                              Text(tag.name, style: textTheme.labelSmall?.copyWith(color: color.onPrimary)),
                            ],
                          ),
                        );
                      }).toList(),
                ),
              if (_isExpanded) Padding(padding: EdgeInsets.only(top: 4), child: Divider(color: color.onPrimary)),
              if (_isExpanded)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton.filledTonal(onPressed: widget.onEdit, icon: Icon(Icons.edit)),
                    IconButton.filledTonal(tooltip: 'Delete Transaction', onPressed: widget.onRemove, icon: Icon(Icons.delete)),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  buildNormalCard(bool isExpanded) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;

    return Row(
      children: <Widget>[
        Container(
          width: 48.0,
          height: 48.0,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Color(widget.category?.colorValue ?? 0xFF000000)),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(
              IconHelper.getIconData(widget.category?.iconName),
              // color: color.onPrimary,
              size: 24.0,
            ),
          ),
        ),
        const SizedBox(width: 16.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text("${widget.category?.name}", style: textTheme.titleMedium?.copyWith(color: isExpanded ? color.onPrimary : color.primary)),
              Text(
                '${widget.account?.name} - ${widget.account?.accountType.name.toTitleCase()}',
                style: textTheme.labelMedium?.copyWith(color: isExpanded ? color.onPrimary : color.primary),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16.0),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Text(
              '${widget.isExpense ? '-' : '+'} ${ctxt.formatCurrencyWithSign(2, widget.amount.toDouble())}',
              style: textTheme.titleLarge?.copyWith(color: isExpanded ? color.onPrimary : color.primary),
            ),
            Text(
              DateFormat('EEE, dd MMM yyyy', ctxt.localeName).format(widget.date),
              style: textTheme.labelSmall?.copyWith(color: isExpanded ? color.onPrimary : color.primary),
            ),
          ],
        ),
      ],
    );
  }

  buildTransferCard(bool isExpanded) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    var related = widget.related;
    final ctxt = AppLocalizations.of(context)!;

    return Column(
      children: [
        Row(
          children: <Widget>[
            Container(
              width: 48.0,
              height: 48.0,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Color(related?.account.value?.colorValue ?? 0xFF000000)),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  related?.account.value?.accountType.icon,
                  size: 24.0,
                ),
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    related?.account.value?.name ?? '',
                    style: textTheme.titleMedium?.copyWith(color: _isExpanded ? color.onPrimary : color.primary),
                  ),
                  Text(
                    related?.account.value?.accountType.name.toUpperCase() ?? '',
                    style: textTheme.labelMedium?.copyWith(color: _isExpanded ? color.onPrimary : color.primary),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  ctxt.formatCurrencyWithSign(2, related?.amount ?? 0.0),
                  style: textTheme.titleLarge?.copyWith(color: _isExpanded ? color.onPrimary : color.primary),
                ),
                Text(
                  DateFormat('EEE, dd MMM yyyy', ctxt.localeName).format(related?.date ?? DateTime.now()),
                  style: textTheme.labelSmall?.copyWith(color: _isExpanded ? color.onPrimary : color.primary),
                ),
              ],
            ),
          ],
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 0),
          child: IconButton.filledTonal(
            onPressed: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            icon: Icon(Icons.arrow_downward),
          ),
        ),
        Row(
          children: <Widget>[
            Container(
              width: 48.0,
              height: 48.0,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16.0), color: Color(widget.account?.colorValue ?? 0xFF000000)),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  widget.account?.accountType.icon,
                  // color: color.onPrimary,
                  size: 24.0,
                ),
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(widget.account?.name ?? '', style: textTheme.titleMedium?.copyWith(color: _isExpanded ? color.onPrimary : color.primary)),
                  Text(
                    widget.account?.accountType.name.toUpperCase() ?? '',
                    style: textTheme.labelMedium?.copyWith(color: _isExpanded ? color.onPrimary : color.primary),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  ctxt.formatCurrencyWithSign(2, widget.amount.toDouble()),
                  style: textTheme.titleLarge?.copyWith(color: _isExpanded ? color.onPrimary : color.primary),
                ),
                Text(
                  DateFormat('EEE, dd MMM yyyy', ctxt.localeName).format(widget.date),
                  style: textTheme.labelSmall?.copyWith(color: _isExpanded ? color.onPrimary : color.primary),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
