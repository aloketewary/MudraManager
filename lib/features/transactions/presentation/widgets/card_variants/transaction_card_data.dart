import 'package:flutter/foundation.dart' hide Category;
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/tag.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';

/// Common display data passed to all card variant widgets.
/// Avoids each variant needing 10+ constructor params from TransactionCard.
class TransactionCardData {
  final Category? category;
  final String? description;
  final Account? account;
  final double displayAmount;
  final DateTime date;
  final bool isExpense;
  final bool isTransfer;
  final List<Tag> tags;
  final Transaction? related;
  final String? tripName;
  final bool isRecurring;
  final String? currencyCode;
  final double? convertedAmount;
  final bool hasDetails;
  final bool expanded;
  final VoidCallback? onUnlinkRecurring;

  const TransactionCardData({
    required this.category,
    required this.description,
    required this.account,
    required this.displayAmount,
    required this.date,
    required this.isExpense,
    required this.isTransfer,
    required this.tags,
    required this.related,
    required this.tripName,
    required this.isRecurring,
    required this.currencyCode,
    required this.convertedAmount,
    required this.hasDetails,
    required this.expanded,
    this.onUnlinkRecurring,
  });
}
