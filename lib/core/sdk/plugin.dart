import 'dart:async';
import 'package:mudra_plugin_sdk/api.dart';

import 'event_bus.dart';

abstract class Plugin {
  String get name;
  List<String> get subscribedEvents;

  MudraApi? _api;

  void setApi(MudraApi api) => _api = api;
  MudraApi get api => _api!;

  Future<void> initialize();
  Future<void> handle(Event event);
  Future<void> dispose();
}

class PluginManager {
  static final PluginManager _instance = PluginManager._();
  factory PluginManager() => _instance;
  PluginManager._();

  final _plugins = <Plugin>[];
  final _subscriptions = <StreamSubscription>[];
  final _bus = EventBus();

  Future<void> register(Plugin plugin, MudraApi api) async {
    plugin.setApi(api);
    await plugin.initialize();
    _plugins.add(plugin);

    for (final eventType in plugin.subscribedEvents) {
      final sub = _bus.on(eventType, (event) => plugin.handle(event));
      _subscriptions.add(sub);
    }
  }

  Future<void> disposeAll() async {
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    for (final plugin in _plugins) {
      await plugin.dispose();
    }
    _subscriptions.clear();
    _plugins.clear();
  }
}
