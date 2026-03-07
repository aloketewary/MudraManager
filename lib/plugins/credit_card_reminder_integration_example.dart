// Example: How to integrate Credit Card Reminder Settings in your app

// 1. Add route in your router configuration (e.g., go_router)
/*
GoRoute(
  path: '/credit-card-reminders',
  builder: (context, state) => const CreditCardReminderSettings(),
),
*/

// 2. Navigate from settings or utilities screen
/*
ListTile(
  leading: const Icon(Icons.credit_card),
  title: const Text('Credit Card Reminders'),
  subtitle: const Text('Manage bill payment reminders'),
  onTap: () => context.push('/credit-card-reminders'),
),
*/

// 3. Or show as bottom sheet
/*
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  builder: (context) => const CreditCardReminderSettings(),
);
*/

// The UI provides:
// - Slider to set reminder days (1-7 days before due date)
// - Add/Edit/Delete credit cards with friendly dialog
// - Visual list of all configured cards
// - Automatic saving to SharedPreferences
// - No more manual "CardName|15" format!
