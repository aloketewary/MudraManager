# Mudra Plugin SDK

Build plugins for Mudra Manager - the extensible personal finance app.

## Installation

```yaml
dependencies:
  mudra_plugin_sdk:
    path: ../mudra_plugin_sdk
```

## Quick Start

```dart
import 'package:mudra_plugin_sdk/mudra_plugin_sdk.dart';

class MyPlugin extends MudraPlugin {
  @override
  String get id => 'com.example.myplugin';
  
  @override
  String get name => 'My Plugin';
  
  @override
  String get version => '1.0.0';

  @override
  void onSms(SmsEvent event) {
    if (event.body.contains('credited')) {
      api.showNotification('Money received!');
    }
  }

  @override
  void onExpense(ExpenseEvent event) {
    if (event.amount > 1000) {
      api.showNotification('Large expense: ₹${event.amount}');
    }
  }

  @override
  void onBudget(BudgetEvent event) {
    if (event.used > event.limit * 0.9) {
      api.showNotification('Budget warning: 90% used');
    }
  }

  @override
  void onGoal(GoalEvent event) {
    if (event.achieved) {
      api.showNotification('Goal achieved! 🎉');
    }
  }

  @override
  void onLoad() {
    // Initialize plugin
  }

  @override
  void onStart() {
    // Start plugin services
  }
}
```

## Events

### SmsEvent
- `sender`: SMS sender
- `body`: SMS content

### ExpenseEvent
- `category`: Expense category
- `amount`: Transaction amount
- `time`: Transaction timestamp

### BudgetEvent
- `used`: Amount spent
- `limit`: Budget limit

### GoalEvent
- `goalId`: Goal identifier
- `achieved`: Achievement status

## Secure API

Plugins can only access:

```dart
api.showNotification(String text)  // Show notification
api.addExpense(double amount)      // Add expense
```

## Security

Plugins are sandboxed and cannot:
- ❌ Access database directly
- ❌ Access file system
- ❌ Execute native code
- ❌ Access network without permission

## Publishing

1. Test your plugin
2. Document features
3. Submit to Mudra Plugin Marketplace

## Examples

See `/lib/plugins/` for reference implementations.
