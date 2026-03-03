import 'package:mudra_manager/core/services/mudra_api_impl.dart';

import 'event_bus.dart';
import 'plugin.dart';

class MudraSDK {
  static final MudraSDK _instance = MudraSDK._();
  factory MudraSDK() => _instance;
  MudraSDK._();

  final _bus = EventBus();
  final _pluginManager = PluginManager();
  final _api = MudraApiImpl();

  EventBus get bus => _bus;
  PluginManager get plugins => _pluginManager;

  Future<void> initialize(List<Plugin> plugins) async {
    for (final plugin in plugins) {
      await _pluginManager.register(plugin, _api);
    }
  }

  void emit(String type, Map<String, dynamic> data) {
    _bus.emit(type, data);
  }

  Future<void> dispose() async {
    await _pluginManager.disposeAll();
    _bus.dispose();
  }
}
