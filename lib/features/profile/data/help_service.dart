import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:mudra_manager/features/profile/data/help_item.dart';

class HelpService {
  static List<HelpItem>? _cachedItems;

  static Future<List<HelpItem>> loadHelpContent() async {
    if (_cachedItems != null) return _cachedItems!;

    final jsonString = await rootBundle.loadString('assets/help_content.json');
    final List<dynamic> jsonList = json.decode(jsonString);
    _cachedItems = jsonList.map((json) => HelpItem.fromJson(json)).toList();
    return _cachedItems!;
  }

  static Future<List<HelpItem>> searchHelp(String query) async {
    final items = await loadHelpContent();
    if (query.isEmpty) return items;

    final lowerQuery = query.toLowerCase();
    return items.where((item) {
      return item.title.toLowerCase().contains(lowerQuery) ||
          item.shortDescription.toLowerCase().contains(lowerQuery) ||
          item.description.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  static Future<HelpItem?> getHelpById(String id) async {
    final items = await loadHelpContent();
    try {
      return items.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }
}
