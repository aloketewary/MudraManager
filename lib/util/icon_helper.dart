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
      case 'restaurant': return Icons.restaurant;
      case 'coffee': return Icons.local_cafe;
      case 'fitness': return Icons.fitness_center;
      case 'sports': return Icons.sports_soccer;
      case 'work': return Icons.work;
      case 'business': return Icons.business;
      case 'phone': return Icons.phone;
      case 'wifi': return Icons.wifi;
      case 'electric': return Icons.electric_bolt;
      case 'water': return Icons.water_drop;
      case 'gas': return Icons.local_gas_station;
      case 'medical': return Icons.medical_services;
      case 'pharmacy': return Icons.local_pharmacy;
      case 'beauty': return Icons.face;
      case 'spa': return Icons.spa;
      case 'hotel': return Icons.hotel;
      case 'beach': return Icons.beach_access;
      case 'park': return Icons.park;
      case 'music': return Icons.music_note;
      case 'games': return Icons.sports_esports;
      case 'book': return Icons.menu_book;
      case 'library': return Icons.local_library;
      case 'art': return Icons.palette;
      case 'camera': return Icons.camera_alt;
      case 'photo': return Icons.photo;
      case 'celebration': return Icons.celebration;
      case 'cake': return Icons.cake;
      case 'wine': return Icons.wine_bar;
      case 'nightlife': return Icons.nightlife;
      case 'child': return Icons.child_care;
      case 'baby': return Icons.baby_changing_station;
      case 'toys': return Icons.toys;
      case 'cleaning': return Icons.cleaning_services;
      case 'laundry': return Icons.local_laundry_service;
      case 'repair': return Icons.handyman;
      case 'tools': return Icons.construction;
      case 'garden': return Icons.yard;
      case 'furniture': return Icons.chair;
      case 'electronics': return Icons.devices;
      case 'computer': return Icons.computer;
      case 'phone_mobile': return Icons.smartphone;
      case 'watch': return Icons.watch;
      case 'headphones': return Icons.headphones;
      case 'tv': return Icons.tv;
      case 'videogame': return Icons.videogame_asset;
      case 'print': return Icons.print;
      case 'mail': return Icons.mail;
      case 'delivery': return Icons.local_shipping;
      case 'taxi': return Icons.local_taxi;
      case 'bus': return Icons.directions_bus;
      case 'train': return Icons.train;
      case 'subway': return Icons.subway;
      case 'bike': return Icons.directions_bike;
      case 'walk': return Icons.directions_walk;
      case 'parking': return Icons.local_parking;
      case 'atm': return Icons.local_atm;
      case 'bank': return Icons.account_balance;
      case 'insurance': return Icons.security;
      case 'investment': return Icons.show_chart;
      case 'tax': return Icons.receipt_long;
      case 'salary': return Icons.payments;
      case 'bonus': return Icons.card_giftcard;
      case 'refund': return Icons.money_off;
      case 'donation': return Icons.volunteer_activism;
      case 'charity': return Icons.favorite;
      case 'others': return Icons.more_horiz;
      default: return Icons.help_outline;
    }
  }

  static final Map<String, IconData> iconMap = {
    'home': Icons.home,
    'shopping_cart': Icons.shopping_cart,
    'fastfood': Icons.fastfood,
    'restaurant': Icons.restaurant,
    'coffee': Icons.local_cafe,
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
    'fitness': Icons.fitness_center,
    'sports': Icons.sports_soccer,
    'work': Icons.work,
    'business': Icons.business,
    'phone': Icons.phone,
    'wifi': Icons.wifi,
    'electric': Icons.electric_bolt,
    'water': Icons.water_drop,
    'gas': Icons.local_gas_station,
    'medical': Icons.medical_services,
    'pharmacy': Icons.local_pharmacy,
    'beauty': Icons.face,
    'spa': Icons.spa,
    'hotel': Icons.hotel,
    'beach': Icons.beach_access,
    'park': Icons.park,
    'music': Icons.music_note,
    'games': Icons.sports_esports,
    'book': Icons.menu_book,
    'library': Icons.local_library,
    'art': Icons.palette,
    'camera': Icons.camera_alt,
    'photo': Icons.photo,
    'celebration': Icons.celebration,
    'cake': Icons.cake,
    'wine': Icons.wine_bar,
    'nightlife': Icons.nightlife,
    'child': Icons.child_care,
    'baby': Icons.baby_changing_station,
    'toys': Icons.toys,
    'cleaning': Icons.cleaning_services,
    'laundry': Icons.local_laundry_service,
    'repair': Icons.handyman,
    'tools': Icons.construction,
    'garden': Icons.yard,
    'furniture': Icons.chair,
    'electronics': Icons.devices,
    'computer': Icons.computer,
    'phone_mobile': Icons.smartphone,
    'watch': Icons.watch,
    'headphones': Icons.headphones,
    'tv': Icons.tv,
    'videogame': Icons.videogame_asset,
    'print': Icons.print,
    'mail': Icons.mail,
    'delivery': Icons.local_shipping,
    'taxi': Icons.local_taxi,
    'bus': Icons.directions_bus,
    'train': Icons.train,
    'subway': Icons.subway,
    'bike': Icons.directions_bike,
    'walk': Icons.directions_walk,
    'parking': Icons.local_parking,
    'atm': Icons.local_atm,
    'bank': Icons.account_balance,
    'insurance': Icons.security,
    'investment': Icons.show_chart,
    'tax': Icons.receipt_long,
    'salary': Icons.payments,
    'bonus': Icons.card_giftcard,
    'refund': Icons.money_off,
    'donation': Icons.volunteer_activism,
    'charity': Icons.favorite,
    'others': Icons.more_horiz,
  };

  /// Maps icon names (stored as strings) to actual IconData
  static IconData getIconData(String? iconName) {
    return iconMap[iconName] ?? Icons.category; // Fallback to a default
  }

  /// Get a list of all supported icon names
  static List<String> getAllIconNames() => iconMap.keys.toList();
}
