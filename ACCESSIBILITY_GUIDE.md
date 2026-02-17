# Accessibility Implementation Guide

## Screen Reader Support - App-Wide Implementation

### 1. **Transaction Cards**
```dart
// lib/screens/transaction/transaction_card.dart
Semantics(
  label: '${isExpense ? "Expense" : "Income"} transaction. ${category?.name ?? "Uncategorized"}. Amount: ${formatCurrency(amount)}. Date: ${formatDate(date)}',
  hint: 'Double tap to edit transaction',
  button: true,
  child: TransactionCard(...),
)
```

### 2. **Account Cards**
```dart
// lib/screens/dashboard/swipeable_account_card.dart
Semantics(
  label: '${account.name} account. Balance: ${formatCurrency(balance)}. Type: ${account.accountType.name}',
  hint: 'Double tap to view account details',
  button: true,
  child: AccountCard(...),
)
```

### 3. **Budget Cards**
```dart
// lib/screens/budget/budget_card.dart
Semantics(
  label: '${budget.name} budget. Spent: ${formatCurrency(spent)} of ${formatCurrency(total)}. ${percentage}% used',
  hint: 'Double tap to view budget details',
  button: true,
  child: BudgetCard(...),
)
```

### 4. **Category Selector**
```dart
// lib/screens/reusable/category_card.dart
Semantics(
  label: '${category.name} category',
  hint: 'Double tap to select category',
  selected: isSelected,
  button: true,
  child: CategoryCard(...),
)
```

### 5. **Action Buttons**
```dart
// All buttons across app
Semantics(
  label: 'Add transaction',
  hint: 'Opens transaction form',
  button: true,
  child: FloatingActionButton(...),
)
```

### 6. **Form Fields**
```dart
// All text fields
TextField(
  decoration: InputDecoration(
    labelText: 'Amount',
    semanticsLabel: 'Transaction amount in rupees',
  ),
)
```

### 7. **Navigation Items**
```dart
// lib/screens/home_screen.dart
NavigationDestination(
  icon: Icon(Icons.home_outlined),
  selectedIcon: Icon(Icons.home),
  label: 'Home',
  tooltip: 'Navigate to home screen',
)
```

### 8. **Statistics Charts**
```dart
// lib/screens/statistics/statistics_screen.dart
Semantics(
  label: 'Spending chart. Total expenses: ${formatCurrency(total)}. Top category: ${topCategory}',
  hint: 'Chart showing spending breakdown by category',
  child: PieChart(...),
)
```

### 9. **Date Pickers**
```dart
// Date selection widgets
Semantics(
  label: 'Selected date: ${formatDate(selectedDate)}',
  hint: 'Double tap to change date',
  button: true,
  child: DatePicker(...),
)
```

### 10. **Amount Display**
```dart
// Currency amounts
Semantics(
  label: '${formatCurrency(amount)} rupees',
  child: Text('₹$amount'),
)
```

## Implementation Checklist

### High Priority (Core Screens)
- [x] Dashboard - Cash flow cards
- [ ] Transaction List - Transaction cards
- [ ] Add/Edit Transaction - Form fields
- [ ] Account List - Account cards
- [ ] Budget List - Budget cards

### Medium Priority (Secondary Screens)
- [ ] Statistics - Charts and graphs
- [ ] Profile - Settings items
- [ ] SMS Review - Pending transaction cards
- [ ] Category Management - Category cards

### Low Priority (Utility Screens)
- [ ] About Screen
- [ ] Settings Screen
- [ ] Notification Settings

## Testing Guidelines

### Manual Testing with Screen Readers
1. **iOS - VoiceOver**
   - Enable: Settings > Accessibility > VoiceOver
   - Test navigation with swipe gestures
   - Verify all elements are announced

2. **Android - TalkBack**
   - Enable: Settings > Accessibility > TalkBack
   - Test navigation with swipe gestures
   - Verify all elements are announced

### Automated Testing
```dart
testWidgets('Transaction card is accessible', (tester) async {
  await tester.pumpWidget(MyApp());
  
  final semantics = tester.getSemantics(find.byType(TransactionCard));
  expect(semantics.label, contains('transaction'));
  expect(semantics.hint, isNotNull);
});
```

## Best Practices

### 1. **Descriptive Labels**
- Include all relevant information
- Use natural language
- Avoid technical jargon

### 2. **Action Hints**
- Describe what happens on interaction
- Use "Double tap to..." format
- Keep hints concise

### 3. **Button Identification**
- Mark interactive elements as buttons
- Use `button: true` in Semantics

### 4. **State Information**
- Include selected/unselected state
- Announce loading states
- Indicate errors clearly

### 5. **Grouping**
- Use `Semantics(container: true)` for groups
- Merge related information
- Avoid over-announcing

## Common Patterns

### Pattern 1: Card with Action
```dart
Semantics(
  label: 'Main information here',
  hint: 'Double tap to perform action',
  button: true,
  child: Card(...),
)
```

### Pattern 2: List Item
```dart
Semantics(
  label: 'Item name and details',
  hint: 'Double tap to view details',
  button: true,
  customSemanticsActions: {
    CustomSemanticsAction(label: 'Delete'): () => deleteItem(),
  },
  child: ListTile(...),
)
```

### Pattern 3: Form Field
```dart
TextField(
  decoration: InputDecoration(
    labelText: 'Field Name',
    semanticsLabel: 'Detailed description for screen reader',
    hintText: 'Visual hint',
  ),
)
```

### Pattern 4: Icon Button
```dart
IconButton(
  icon: Icon(Icons.delete),
  tooltip: 'Delete transaction',
  onPressed: () => delete(),
)
```

## Exclusions

### When to Exclude from Semantics
```dart
// Decorative elements
ExcludeSemantics(
  child: Container(decoration: ...),
)

// Redundant information
Semantics(
  excludeSemantics: true,
  child: Icon(Icons.arrow_forward),
)
```

## Implementation Priority by File

### Immediate (Week 1)
1. `lib/screens/transaction/transaction_card.dart`
2. `lib/screens/transaction/add_edit_transaction_screen.dart`
3. `lib/screens/dashboard/swipeable_account_card.dart`

### Short-term (Week 2)
4. `lib/screens/budget/budget_card.dart`
5. `lib/screens/statistics/statistics_screen.dart`
6. `lib/screens/sms/review_pending_transactions_screen.dart`

### Medium-term (Week 3-4)
7. All remaining screens
8. Custom widgets and components
9. Dialog boxes and bottom sheets

## Resources

- [Flutter Accessibility Guide](https://docs.flutter.dev/development/accessibility-and-localization/accessibility)
- [Material Design Accessibility](https://material.io/design/usability/accessibility.html)
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)

## Metrics

### Target Metrics
- 100% of interactive elements have semantic labels
- 100% of buttons have action hints
- 100% of form fields have descriptive labels
- All navigation flows work with screen readers

### Testing Coverage
- Manual testing on iOS VoiceOver: Required
- Manual testing on Android TalkBack: Required
- Automated semantic tests: 80% coverage
