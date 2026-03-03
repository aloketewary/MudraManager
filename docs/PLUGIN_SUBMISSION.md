# Plugin Submission Guide

## Prerequisites

1. Working plugin that extends `MudraPlugin`
2. Tested on multiple devices
3. Documentation
4. Icon (512x512 PNG)

## Submission Process

### 1. Create plugin.yaml

```yaml
id: com.yourname.pluginname
name: Plugin Name
version: 1.0.0
description: Short description of your plugin
author: Your Name
email: your@email.com
homepage: https://github.com/yourname/plugin
license: MIT
minSdkVersion: 1.0.0
permissions:
  - notifications
  - expenses
```

### 2. Package Structure

```
my_plugin/
├── plugin.yaml
├── lib/
│   └── my_plugin.dart
├── README.md
├── LICENSE
└── icon.png
```

### 3. Submit

```bash
# Install CLI
dart pub global activate mudra_cli

# Login
mudra_cli login

# Publish
mudra_cli publish
```

### 4. Review Process

- Automated security scan
- Code review (1-3 days)
- Approval/Rejection notification

## Best Practices

- Follow Dart style guide
- Handle errors gracefully
- Minimal API usage
- Clear documentation
- Semantic versioning

## Example Plugin

```dart
import 'package:mudra_plugin_sdk/mudra_plugin_sdk.dart';

class ExpenseTrackerPlugin extends MudraPlugin {
  @override
  String get id => 'com.example.tracker';
  
  @override
  String get name => 'Expense Tracker';
  
  @override
  String get version => '1.0.0';

  @override
  void onExpense(ExpenseEvent e) {
    if (e.amount > 500) {
      api.showNotification('Large expense: ₹${e.amount}');
    }
  }

  @override
  void onLoad() {}
  
  @override
  void onStart() {}
}
```

## Monetization

- Free plugins
- Paid plugins (coming soon)
- Donations via GitHub Sponsors
