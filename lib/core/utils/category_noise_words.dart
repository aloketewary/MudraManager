/// Common banking/SMS noise words that should be excluded from category
/// keyword matching. Shared across all category matchers.
const kCategoryNoiseWords = <String>{
  // Banking terms
  'debited', 'credited', 'account', 'balance', 'available',
  'transaction', 'transfer', 'payment', 'received', 'sent',
  'bank', 'upi', 'neft', 'imps', 'rtgs', 'ref', 'inr',
  // English stop words
  'your', 'from', 'has', 'been', 'the', 'for', 'with',
  'on', 'at', 'to', 'and', 'or', 'a', 'an', 'is', 'of',
};
