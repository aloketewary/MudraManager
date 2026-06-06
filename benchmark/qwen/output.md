To create a Flutter `ConsumerWidget` using Riverpod that integrates with Isar, utilizes 
`LucideIcons`, `CurrencyText` for displaying monetary values, and leverages `AppLocalizations` for 
internationalization, you can follow the example below:

First, ensure that your Flutter project includes the necessary dependencies in `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.0.0
  isar: ^2.0.0
  isar_flutter_libs: ^2.0.0
  currency_text_input_formatter: ^2.0.0
  lucide_icons: ^1.0.0
  provider: ^6.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
```

### Step 1: Define the Isar Stream Provider

First, you'll need to set up a `StreamProvider` for your data from Isar.

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:isar_flutter_libs/isar_flutter_libs.dart';

final isar = Isar.openSync([YourCollectionSchema.schema]);

class YourCollection {
  Id id = Isar.autoIncrement;
  int amount = 0;
}

final budgetProvider = StreamProvider<YourCollection>((ref) async* {
  final data = await isar.yourCollections.where().findFirst();
  yield data ?? YourCollection();
});
```

### Step 2: Define the Spacing Provider

You might have a provider for spacing that you use throughout your app:

```dart
final spacingProvider = StateProvider<double>((ref) => 16.0);
```

### Step 3: Create the ConsumerWidget

Now, create the `ConsumerWidget` to display the budget card.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:lucide_icons/lucide_icons.dart';

class BudgetCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final budgetAsyncValue = ref.watch(budgetProvider);

    return budgetAsyncValue.when(
      data: (budgetData) {
        return Card(
          margin: EdgeInsets.all(spacing),
          child: Padding(
            padding: EdgeInsets.all(spacing),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.wallet, size: 48),
                SizedBox(height: spacing / 2),
                Text(
                  AppLocalizations.of(context)!.remainingBudgetTitle,
                  style: Theme.of(context).textTheme.headline6,
                ),
                SizedBox(height: spacing / 2),
                CurrencyText(
                  budgetData.amount.toString(),
                  style: Theme.of(context).textTheme.headline4!,
                  inputFormatters: [
                    CurrencyTextInputFormatter(decimalDigits: 0),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => Text('Error: $err'),
    );
  }
}
```

### Explanation:

- **Isar Stream Provider**: The `budgetProvider` is a `StreamProvider` that fetches data from Isar.
- **Spacing Provider**: `spacingProvider` is used to provide consistent spacing throughout the 
widget.
- **Lucide Icons**: `LucideIcons.wallet` is used for the icon.
- **CurrencyText Widget**: This widget formats and displays the budget amount as currency.
- **AppLocalizations**: The widget uses `AppLocalizations.of(context)!.remainingBudgetTitle` to fetch 
localized strings.

### Step 4: Localization

Ensure that you have set up localization in your Flutter app. You can use the `flutter_localization` 
package for this purpose:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BudgetCard(),
    );
  }
}
```

### Step 5: Add Localized Strings

In your `intl_en.arb` file (or other locale files), add the following entry:

```json
{
  "remainingBudgetTitle": "Remaining Budget",
  "@remainingBudgetTitle": {
    "description": "The title of the remaining budget card"
  }
}
```

This setup provides a fully functional budget card that integrates with Riverpod, Isar, and leverages 
localization for internationalization.