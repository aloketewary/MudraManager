import 'package:flutter/material.dart';

class IconHelper {
  static IconData iconFromName(String name) {
    switch (name) {
      case 'home': return Icons.home;
      case 'shopping_cart': return Icons.shopping_cart;
      case 'fastfood': return Icons.fastfood;
      case 'flight': return Icons.flight;
      case 'directions_car': return Icons.directions_car;
      case 'local_hospital': return Icons.local_hospital;
      case 'savings': return Icons.savings;
      case 'attach_money': return Icons.attach_money;
      case 'credit_card': return Icons.credit_card;
      case 'wallet': return Icons.account_balance_wallet;
      case 'subscriptions': return Icons.subscriptions;
      case 'school': return Icons.school;
      case 'pets': return Icons.pets;
      case 'gift': return Icons.card_giftcard;
      case 'travel': return Icons.travel_explore;
      case 'entertainment': return Icons.movie;
      case 'groceries': return Icons.local_grocery_store;
      case 'clothing': return Icons.checkroom;
      case 'bills': return Icons.receipt;
      case 'trending_up': return Icons.trending_up;
      case 'shopping_bag': return Icons.shopping_bag;
      case 'others': return Icons.more_horiz;
      default: return Icons.help_outline;
    }
  }

  static final Map<String, IconData> iconMap = {
    'home': Icons.home,
    'shopping_cart': Icons.shopping_cart,
    'fastfood': Icons.fastfood,
    'flight': Icons.flight,
    'directions_car': Icons.directions_car,
    'local_hospital': Icons.local_hospital,
    'savings': Icons.savings,
    'attach_money': Icons.attach_money,
    'credit_card': Icons.credit_card,
    'wallet': Icons.account_balance_wallet,
    'subscriptions': Icons.subscriptions,
    'school': Icons.school,
    'pets': Icons.pets,
    'gift': Icons.card_giftcard,
    'travel': Icons.travel_explore,
    'entertainment': Icons.movie,
    'groceries': Icons.local_grocery_store,
    'clothing': Icons.checkroom,
    'bills': Icons.receipt,
    'trending_up': Icons.trending_up,
    'shopping_bag': Icons.shopping_bag,
    'others': Icons.more_horiz,
  };

  /// Maps icon names (stored as strings) to actual IconData
  static IconData getIconData(String? iconName) {
    return iconMap[iconName] ?? Icons.category; // Fallback to a default
  }

  /// Get a list of all supported icon names
  static List<String> getAllIconNames() => [
    'shopping_cart',
    'restaurant',
    'directions_car',
    'home',
    'school',
    'flight',
    'movie',
    'attach_money',
    'money_off',
    'savings',
    'credit_card',
    'wallet',
    'gift',
    'work',
    'health',
    'subscriptions',
    'fitness',
    'food',
    'trending_up',
    'local_grocery_store',
    'shopping_bag',
    'other',
  ];

}
