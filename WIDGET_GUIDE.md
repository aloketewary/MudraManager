# Quick Add Widget Implementation Guide

## ✅ Files Created

1. **lib/service/widget_service.dart** - Widget update service
2. **android/app/src/main/res/layout/quick_add_widget.xml** - Widget UI layout
3. **android/app/src/main/res/xml/quick_add_widget_info.xml** - Widget metadata
4. **android/app/src/main/res/values/strings.xml** - Widget strings
5. **android/app/src/main/kotlin/.../QuickAddWidgetProvider.kt** - Widget provider
6. **AndroidManifest.xml** - Updated with widget receiver
7. **main.dart** - Added widget initialization
8. **pubspec.yaml** - Added home_widget dependency

## 📋 Next Steps

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Update Widget from Your App

Add this to your transaction save method:

```dart
import 'package:mudra_manager/service/widget_service.dart';

// After saving transaction
await WidgetService.updateWidget(ref);
```

### 3. Handle Widget Click

Update your router to handle widget clicks:

```dart
// In app_router.dart or main screen
HomeWidget.widgetClicked.listen((uri) {
  if (uri?.host == 'add_transaction') {
    context.push('/add-transaction');
  }
});
```

### 4. Build and Test

```bash
flutter build apk
# or
flutter run
```

### 5. Add Widget to Home Screen

1. Long press on home screen
2. Select "Widgets"
3. Find "Mudra Manager"
4. Drag "Quick Add Widget" to home screen

## 🎨 Widget Features

- **Balance Display**: Shows total balance across all accounts
- **Today's Stats**: Shows today's income and expense
- **Quick Add Button**: Opens app to add transaction
- **Auto-Update**: Updates every 30 minutes or when transaction added

## 🔧 Customization

### Change Widget Colors
Edit `android/app/src/main/res/layout/quick_add_widget.xml`:
- Background: `android:background="#6200EE"`
- Button: `android:background="#3700B3"`

### Change Update Frequency
Edit `android/app/src/main/res/xml/quick_add_widget_info.xml`:
- `android:updatePeriodMillis="1800000"` (30 minutes in milliseconds)

### Change Widget Size
Edit `android/app/src/main/res/xml/quick_add_widget_info.xml`:
- `android:minWidth="250dp"`
- `android:minHeight="180dp"`

## 📱 Widget Preview

```
┌─────────────────────────┐
│ Mudra Manager           │
│ ₹45,230                 │
│                         │
│ Expense    Income       │
│ ₹1,200     ₹5,000      │
│                         │
│ [+ Add Transaction]     │
└─────────────────────────┘
```

## 🐛 Troubleshooting

**Widget not showing?**
- Check AndroidManifest.xml has receiver registered
- Rebuild app: `flutter clean && flutter build apk`

**Widget not updating?**
- Call `WidgetService.updateWidget(ref)` after transactions
- Check widget update interval in widget_info.xml

**Click not working?**
- Verify HomeWidget.widgetClicked listener is set up
- Check pending intent in QuickAddWidgetProvider.kt

## 🚀 Future Enhancements

- [ ] Multiple widget sizes (small, medium, large)
- [ ] Dark mode support
- [ ] Quick expense categories buttons
- [ ] Last transaction display
- [ ] Weekly/monthly summary toggle
