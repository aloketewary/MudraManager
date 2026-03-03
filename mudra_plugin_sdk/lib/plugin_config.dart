class PluginConfig {
  final String pluginId;
  final Map<String, dynamic> settings;

  PluginConfig(this.pluginId, this.settings);

  T? get<T>(String key) => settings[key] as T?;
  
  void set(String key, dynamic value) => settings[key] = value;
  
  bool has(String key) => settings.containsKey(key);
}

class PluginConfigManager {
  final Map<String, PluginConfig> _configs = {};

  void setConfig(String pluginId, Map<String, dynamic> settings) {
    _configs[pluginId] = PluginConfig(pluginId, settings);
  }

  PluginConfig? getConfig(String pluginId) => _configs[pluginId];

  T? getSetting<T>(String pluginId, String key, {T? defaultValue}) {
    return _configs[pluginId]?.get<T>(key) ?? defaultValue;
  }

  void updateSetting(String pluginId, String key, dynamic value) {
    if (_configs[pluginId] == null) {
      _configs[pluginId] = PluginConfig(pluginId, {});
    }
    _configs[pluginId]!.set(key, value);
  }
}
