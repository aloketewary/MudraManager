import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/plugin_metadata.dart';

class OfflinePluginLoader {
  Future<List<PluginMetadata>> loadBundledPlugins() async {
    final manifestJson = await rootBundle.loadString('assets/plugins/manifest.json');
    final List data = json.decode(manifestJson);
    return data.map((json) => PluginMetadata.fromJson(json)).toList();
  }

  Future<String> loadPluginCode(String pluginId) async {
    return await rootBundle.loadString('assets/plugins/$pluginId/plugin.dart');
  }
}
