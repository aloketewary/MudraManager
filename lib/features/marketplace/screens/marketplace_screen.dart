import 'package:flutter/material.dart';
import 'package:mudra_manager/core/utils/utils.dart';
import 'package:mudra_manager/core/widgets/skeleton_loader.dart';
import '../models/plugin_metadata.dart';
import '../services/marketplace_service.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final _service = MarketplaceService();
  List<PluginMetadata> _plugins = [];
  Map<String, bool> _pluginStates = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPlugins();
  }

  Future<void> _loadPlugins() async {
    final plugins = await _service.fetchPlugins();
    final states = <String, bool>{};
    for (final plugin in plugins) {
      states[plugin.id] = await _service.isPluginEnabled(plugin.id);
    }
    setState(() {
      _plugins = plugins;
      _pluginStates = states;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugins'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Extend Mudra Manager with powerful plugins',
              style: textTheme.bodyMedium?.copyWith(
                color: color.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 4,
              itemBuilder: (context, index) => const SkeletonCard(),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _plugins.length,
              itemBuilder: (context, index) {
                final plugin = _plugins[index];
                final isEnabled = _pluginStates[plugin.id] ?? true;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  color: color.surfaceContainerLow,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: color.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.extension,
                                color: color.onPrimaryContainer,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    plugin.name,
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    plugin.description,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: color.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: color.secondaryContainer,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'v${plugin.version}',
                                          style: textTheme.labelSmall?.copyWith(
                                            color: color.onSecondaryContainer,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.verified,
                                        size: 14,
                                        color: color.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Official',
                                        style: textTheme.labelSmall?.copyWith(
                                          color: color.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: isEnabled,
                              onChanged: (val) async {
                                await _service.togglePlugin(plugin.id, val);
                                setState(() => _pluginStates[plugin.id] = val);
                                SnackbarService.info(
                                  val
                                      ? '${plugin.name} enabled'
                                      : '${plugin.name} disabled',
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      if (isEnabled && _hasConfig(plugin.id))
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Column(
                            children: [
                              Divider(color: color.outlineVariant),
                              const SizedBox(height: 8),
                              ..._buildConfigOptions(plugin.id, color, textTheme),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  bool _hasConfig(String pluginId) {
    final plugin = _plugins.firstWhere((p) => p.id == pluginId);
    return plugin.configOptions != null && plugin.configOptions!.isNotEmpty;
  }

  List<Widget> _buildConfigOptions(String pluginId, ColorScheme color, TextTheme textTheme) {
    final plugin = _plugins.firstWhere((p) => p.id == pluginId);
    if (plugin.configOptions == null) return [];

    return plugin.configOptions!.map((config) {
      return FutureBuilder<double?>(
        future: _service.getPluginConfig(pluginId, config.key),
        builder: (context, snapshot) {
          final value = snapshot.data ?? config.defaultValue;
          return ListTile(
            dense: true,
            leading: Icon(Icons.tune, size: 20, color: color.primary),
            title: Text(config.label, style: textTheme.bodyMedium),
            subtitle: Text(
              '${config.prefix ?? ''}$value${config.suffix ?? ''}',
              style: textTheme.bodySmall,
            ),
            trailing: Icon(Icons.edit, size: 18, color: color.onSurfaceVariant),
            onTap: () => _showConfigDialog(pluginId, config, value),
          );
        },
      );
    }).toList();
  }

  void _showConfigDialog(String pluginId, PluginConfigOption config, double currentValue) {
    final controller = TextEditingController(
      text: currentValue.toString(),
    );
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: color.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Icon(Icons.tune, size: 48, color: color.primary),
            const SizedBox(height: 16),
            Text(
              'Configure Plugin',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: config.label,
                prefixText: config.prefix != null ? '${config.prefix} ' : null,
                suffixText: config.suffix,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      final value = double.tryParse(controller.text);
                      if (value != null) {
                        _service.updatePluginConfig(pluginId, config.key, value);
                        setState(() {});
                        Navigator.pop(ctx);
                        SnackbarService.success('Configuration updated');
                      }
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
