# RobustCategoryMatcher - Intelligent Multi-Strategy Category Matching

## Overview

`RobustCategoryMatcher` is a sophisticated, production-ready category matching system that uses a **layered fallback strategy** to match transactions, SMS, and other text to appropriate expense/income categories. It guarantees a result while maintaining high-quality confidence scoring for better decision-making.

## Key Features

✅ **Always Returns a Result** - Never fails; uses fallback strategies if needed
✅ **Confidence Scoring** - 0-100 scale for informed decision-making
✅ **Strategy Tracking** - Know how each match was made
✅ **Noise Filtering** - Ignores common banking terminology to avoid false matches
✅ **Amount Heuristics** - Considers transaction amounts for better guesses
✅ **Flexible Type Filtering** - Works with income, expense, or both
✅ **High Performance** - O(n*m) complexity, suitable for real-time matching

## Architecture: 5-Layer Fallback Strategy

### Layer 1: Exact Name Match (95% confidence)
```
Text contains the exact category name
Example: "Food & Dining subscription" → Food & Dining (exact match detected)
```

### Layer 2: Keyword Exact Word Boundary Match (70-95% confidence)
```
Keywords match with word boundaries (\b)
Example: "spent at swiggy" → Food & Dining (swiggy keyword matched exactly)
```

### Layer 3: Keyword Substring Match (50-70% confidence)
```
Keywords found as substrings (filter noise words)
Example: "swiggyapp checkout" → Food & Dining (swiggy found, noise filtered)
```

### Layer 4: Amount-Based Heuristics (40-50% confidence)
```
Transaction amount suggests category
Example: Amount=50 + contains "coffee" → Food & Dining
Example: Amount=5000 (round) + contains "utility" → Utilities
```

### Layer 5: Default Fallback (20-40% confidence)
```
Use "Others"/"Miscellaneous" or first available category
Always provides a result, even for ambiguous text
```

## Usage

### Basic Example

```dart
final result = RobustCategoryMatcher.match(
  text: 'Rs.500 paid to Swiggy for food',
  allCategories: categories,
  relevantCategories: expenseCategories,
  amount: 500,
  isIncome: false,
);

print('Category: ${result.category?.name}');           // Food & Dining
print('Confidence: ${result.confidenceScore}');       // 85
print('Is High Confidence: ${result.isHighConfidence}'); // true
print('Strategy: ${result.matchStrategy}');            // keyword_exact_match
```

### Decision Making Based on Confidence

```dart
final result = RobustCategoryMatcher.match(
  text: smsBody,
  allCategories: categories,
  relevantCategories: relevantCategories,
);

// Use confidence to decide next action:
if (result.confidenceScore >= 75) {
  // Auto-approve with high confidence
  approveTransaction(result.category!);
} else if (result.confidenceScore >= 50) {
  // Suggest but require review
  suggestAndWaitForReview(result.category!);
} else {
  // Flag for manual categorization
  flagForManualReview(result.category!);
}
```

### Input Parameters

```dart
RobustCategoryMatcher.match({
  required String text,              // SMS body, description, or transaction text
  required List<Category> allCategories,      // All available categories
  required List<Category> relevantCategories,  // Pre-filtered by income/expense
  double? amount,                   // Transaction amount (optional, for heuristics)
  bool? isIncome,                   // Transaction direction (optional)
})
```

### Output: CategoryMatchResult

```dart
class CategoryMatchResult {
  final Category? category;           // Matched category (never null unless no categories)
  final int confidenceScore;          // 0-100 confidence
  final String matchStrategy;         // Which strategy was used
  final bool isHighConfidence;        // >= 70
}
```

## Recommended Confidence Thresholds

| Confidence | Range | Action | Use Case |
|---|---|---|---|
| Very High | 75-100 | Auto-approve | Trust the system |
| High | 50-74 | Suggest + confirm | Manual verification |
| Medium | 30-49 | Flag for review | Inspect before approval |
| Low | 0-29 | Default fallback | Use default category |

## Noise Words Filtered

To prevent false matches, the matcher ignores these banking-related terms:

`debited`, `credited`, `account`, `balance`, `available`, `transaction`, `transfer`, `payment`, `received`, `sent`, `bank`, `upi`, `neft`, `imps`, `rtgs`, `ref`, `inr`, `your`, `from`, `has`, `been`, `the`, `for`, `with`, `on`, `at`, `to`, `and`, `or`, `a`, `an`

## Integration Examples

### With SMS Activity Service
```dart
// In sms_activity_service.dart
activity.category ??= _getSuggestedCategory(body, categories, activity.isIncome);

String? _getSuggestedCategory(String body, List<Category> categories, bool? isIncome) {
  final relevant = categories.where((c) =>
      isIncome == null || (isIncome ? c.categoryType == CategoryType.income : 
                                       c.categoryType == CategoryType.expense)
  ).toList();

  final result = RobustCategoryMatcher.match(
    text: body,
    allCategories: categories,
    relevantCategories: relevant,
    isIncome: isIncome,
  );
  
  return result.confidenceScore >= 50 ? result.category?.name : null;
}
```

### With Transaction Matching Service
```dart
// Use as primary matcher before fallback to empty/default
final result = RobustCategoryMatcher.match(
  text: transaction.description,
  allCategories: categories,
  relevantCategories: categories,
  isIncome: false,
);

if (result.isHighConfidence) {
  transaction.category = result.category;
  transaction.autoApproved = true;
}
```

## Advantages Over Previous Matchers

| Feature | Old Approach | RobustCategoryMatcher |
|---|---|---|
| Always returns result | ❌ Could return null | ✅ Always has fallback |
| Confidence scoring | ❌ Boolean only | ✅ 0-100 with semantics |
| Strategy tracking | ❌ Hidden | ✅ Visible for debugging |
| Noise filtering | ⚠️ Incomplete | ✅ Comprehensive |
| Amount heuristics | ❌ Not supported | ✅ Smart patterns |
| Type flexibility | ❌ Required bool | ✅ Accepts bool? |

## Performance

- **Time Complexity**: O(n × m) where n = categories, m = keywords per category
- **Typical Performance**: < 5ms for 50 categories on modern device
- **Suitable for**: Real-time SMS processing, UI suggestions, batch processing

## Testing

The matcher comes with **22 comprehensive unit tests** covering:
- All 5 strategies
- Confidence scoring ranges
- Strategy priority (exact > keyword > amount > fallback)
- Edge cases (empty categories, missing keywords, noise words)
- Type filtering (income vs expense)

Run tests:
```bash
flutter test test/core/utils/robust_category_matcher_test.dart
```

## Future Enhancements

Potential improvements for future versions:

1. **Machine Learning Integration** - Learn from user corrections
2. **Contextual Awareness** - Time-based patterns (salary on specific dates)
3. **Fuzzy Matching** - Handle typos and variations
4. **Rules Engine** - Custom rules per user/account
5. **Multi-language Support** - Keyword matching in multiple languages
6. **Merchant Database** - Integration with merchant categorization services

## Migration from Old Matchers

The `RobustCategoryMatcher` can coexist with existing matchers:

```dart
// Old approach (still works)
final oldResult = CategoryMatcher.matchByKeywords(text, categories);

// New approach (recommended)
final newResult = RobustCategoryMatcher.match(
  text: text,
  allCategories: allCategories,
  relevantCategories: relevant,
);

// Gradually migrate by checking newResult.isHighConfidence
if (newResult.isHighConfidence) {
  useNewMatcher(newResult);
} else {
  useOldMatcher(oldResult);  // Fallback to old system if uncertain
}
```

## File Location

- **Implementation**: `lib/core/utils/robust_category_matcher.dart`
- **Tests**: `test/core/utils/robust_category_matcher_test.dart`
- **Examples**: `lib/core/utils/robust_category_matcher_example.dart` (this file)

## Questions?

See the example file for more usage patterns and real-world scenarios.
