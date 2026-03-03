import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mudra_manager/features/account/data/account_providers.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import '../models/plugin_metadata.dart';
import '../services/marketplace_service.dart';

final pluginGroupsProvider = FutureProvider((ref) async {
  final service = MarketplaceService();
  return service.fetchPluginsByGroup();
});

final pluginStatesProvider =
    StateNotifierProvider<PluginStatesNotifier, Map<String, bool>>((ref) {
  return PluginStatesNotifier();
});

class PluginStatesNotifier extends StateNotifier<Map<String, bool>> {
  PluginStatesNotifier() : super({});

  Future<void> loadStates(List<PluginMetadata> plugins) async {
    final service = MarketplaceService();
    final states = <String, bool>{};
    for (final plugin in plugins) {
      states[plugin.id] = await service.isPluginEnabled(plugin.id);
    }
    state = states;
  }

  Future<void> togglePlugin(String pluginId, bool enabled) async {
    final service = MarketplaceService();
    await service.togglePlugin(pluginId, enabled);
    state = {...state, pluginId: enabled};
  }
}

class PluginGroupsScreen extends ConsumerStatefulWidget {
  const PluginGroupsScreen({super.key});

  @override
  ConsumerState<PluginGroupsScreen> createState() => _PluginGroupsScreenState();
}

class _PluginGroupsScreenState extends ConsumerState<PluginGroupsScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  bool _isStandardTemplate(String pluginId) {
    return pluginId == 'standard_excel_export' ||
        pluginId == 'standard_pdf_export';
  }

  String _getBankDisplayName(String name) {
    final bankNames = {
      'HDFC Bank': 'HDFC Bank',
      'ICICI Bank': 'ICICI Bank',
      'SBI Bank': 'State Bank of India',
      'Axis Bank': 'Axis Bank',
      'Kotak Bank': 'Kotak Mahindra Bank',
      'Paytm': 'Paytm',
      'PhonePe': 'PhonePe',
      'Google Pay': 'Google Pay',
    };
    return bankNames[name] ?? name;
  }

  void _showCreditCardConfigDialog(PluginMetadata plugin) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final service = MarketplaceService();
    final reminderController = TextEditingController(text: '1');
    final cardConfigs = <Map<String, dynamic>>[];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final accountsAsync = ref.watch(accountsProvider);

            return accountsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (accounts) {
                final creditCardAccounts = accounts
                    .where((acc) => acc.accountType == AccountType.creditCard)
                    .toList();

                return StatefulBuilder(
                  builder: (context, setState) {
                    return SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
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
                                color: color.onSurfaceVariant
                                    .withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Icon(Icons.credit_card,
                                size: 48, color: color.primary,),
                            const SizedBox(height: 16),
                            Text(
                              'Credit Card Reminders',
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 24),
                            TextField(
                              controller: reminderController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Remind me before (days)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (creditCardAccounts.isEmpty)
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    'No credit card accounts found. Please add a credit card account first.',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: color.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              )
                            else ...[
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Credit Card Accounts',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...creditCardAccounts.map((account) {
                                final existingConfig = cardConfigs.firstWhere(
                                  (config) => config['accountId'] == account.id,
                                  orElse: () => {
                                    'accountId': account.id,
                                    'accountName': account.name,
                                    'billDay': 15,
                                    'enabled': false,
                                  },
                                );

                                if (!cardConfigs
                                    .any((c) => c['accountId'] == account.id)) {
                                  cardConfigs.add(existingConfig);
                                }

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Checkbox(
                                              value: existingConfig['enabled'],
                                              onChanged: (value) {
                                                setState(() {
                                                  existingConfig['enabled'] =
                                                      value ?? false;
                                                });
                                              },
                                            ),
                                            Expanded(
                                              child: Text(
                                                account.name,
                                                style: textTheme.titleSmall
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (existingConfig['enabled'])
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 8),
                                            child: Row(
                                              children: [
                                                const SizedBox(width: 48),
                                                Expanded(
                                                  child: TextField(
                                                    keyboardType:
                                                        TextInputType.number,
                                                    decoration: InputDecoration(
                                                      labelText:
                                                          'Bill Day (1-31)',
                                                      border:
                                                          OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                      contentPadding:
                                                          const EdgeInsets
                                                              .symmetric(
                                                        horizontal: 12,
                                                        vertical: 8,
                                                      ),
                                                    ),
                                                    controller:
                                                        TextEditingController(
                                                      text: existingConfig[
                                                              'billDay']
                                                          .toString(),
                                                    ),
                                                    onChanged: (value) {
                                                      final day =
                                                          int.tryParse(value);
                                                      if (day != null &&
                                                          day >= 1 &&
                                                          day <= 31) {
                                                        existingConfig[
                                                            'billDay'] = day;
                                                      }
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Cancel'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: () async {
                                      final reminderDays = int.tryParse(
                                              reminderController.text,) ??
                                          1;
                                      final enabledCards = cardConfigs
                                          .where((config) =>
                                              config['enabled'] == true,)
                                          .map((config) =>
                                              '${config['accountName']}|${config['billDay']}',)
                                          .toList();

                                      await service.updatePluginConfig(
                                        plugin.id,
                                        'reminder_days',
                                        reminderDays.toDouble(),
                                      );

                                      final prefs =
                                          await SharedPreferences.getInstance();
                                      await prefs.setStringList(
                                          'credit_card_bill_dates',
                                          enabledCards,);

                                      if (ctx.mounted) {
                                        Navigator.pop(ctx);
                                        SnackbarService.success(
                                            'Credit card reminders configured',);
                                      }
                                    },
                                    child: const Text('Save'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  void _showPluginConfigDialog(PluginMetadata plugin) {
    if (plugin.id == 'com.mudra.credit_card_reminder') {
      _showCreditCardConfigDialog(plugin);
      return;
    }

    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final service = MarketplaceService();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final controllers = <String, TextEditingController>{};
        for (final option in plugin.configOptions ?? []) {
          controllers[option.key] = TextEditingController(
            text: option.defaultValue.toString(),
          );
        }

        return Padding(
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
              Icon(Icons.settings, size: 48, color: color.primary),
              const SizedBox(height: 16),
              Text(
                plugin.name,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Configure plugin settings',
                style: textTheme.bodyMedium?.copyWith(
                  color: color.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              ...plugin.configOptions!.map((option) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextField(
                    controller: controllers[option.key],
                    keyboardType: option.type == 'number'
                        ? const TextInputType.numberWithOptions(decimal: true)
                        : TextInputType.text,
                    decoration: InputDecoration(
                      labelText: option.label,
                      prefixText: option.prefix,
                      suffixText: option.suffix,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: color.surfaceContainerHighest.withValues(
                        alpha: 0.3,
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
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
                      onPressed: () async {
                        for (final option in plugin.configOptions!) {
                          final value = double.tryParse(
                            controllers[option.key]!.text.trim(),
                          );
                          if (value != null) {
                            await service.updatePluginConfig(
                              plugin.id,
                              option.key,
                              value,
                            );
                          }
                        }
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          SnackbarService.success('Settings saved');
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupedAsync = ref.watch(pluginGroupsProvider);
    final pluginStates = ref.watch(pluginStatesProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return groupedAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        body: Center(child: Text('Error: $err')),
      ),
      data: (grouped) {
        final activeGroups =
            grouped.entries.where((e) => e.value.isNotEmpty).toList();

        if (_tabController == null ||
            _tabController!.length != activeGroups.length) {
          _tabController?.dispose();
          _tabController =
              TabController(length: activeGroups.length, vsync: this);

          final allPlugins = grouped.values.expand((p) => p).toList();
          Future.microtask(
            () =>
                ref.read(pluginStatesProvider.notifier).loadStates(allPlugins),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Plugins'),
            elevation: 0,
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: activeGroups.map((e) => Tab(text: e.key.label)).toList(),
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: activeGroups.map((entry) {
              final group = entry.key;
              final plugins = entry.value;
              final isSmsParserGroup = group == PluginGroup.smsParser;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
                    child: Text(
                      group.description,
                      style: textTheme.bodyMedium?.copyWith(
                        color: color.onSurfaceVariant,
                      ),
                    ),
                  ),
                  ...plugins.map((plugin) {
                    final isEnabled = pluginStates[plugin.id] ?? true;
                    final isStandard = _isStandardTemplate(plugin.id);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      color: color.surfaceContainerHighest,
                      child: InkWell(
                        onTap: isStandard
                            ? null
                            : () async {
                                await ref
                                    .read(pluginStatesProvider.notifier)
                                    .togglePlugin(plugin.id, !isEnabled);
                                SnackbarService.info(
                                  !isEnabled
                                      ? '${plugin.name} enabled'
                                      : '${plugin.name} disabled',
                                );
                              },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Icon
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: color.primary.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: SvgPicture.asset(
                                  plugin.iconUrl,
                                  width: 20,
                                  height: 20,
                                  placeholderBuilder: (context) => Icon(
                                    LucideIcons.building2,
                                    color: color.primary,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isSmsParserGroup
                                          ? _getBankDisplayName(plugin.name)
                                          : plugin.name,
                                      style: textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      isSmsParserGroup
                                          ? 'SMS Parser Plugin'
                                          : plugin.description,
                                      style: textTheme.bodySmall?.copyWith(
                                        color: color.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'v${plugin.version}',
                                      style: textTheme.labelSmall?.copyWith(
                                        color: color.onSurfaceVariant
                                            .withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Status Badge & Edit Button
                              if (isStandard)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.secondaryContainer,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Default',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: color.onSecondaryContainer,
                                    ),
                                  ),
                                )
                              else ...[
                                if (plugin.configOptions?.isNotEmpty ?? false)
                                  IconButton(
                                    icon: Icon(
                                      Icons.settings,
                                      size: 20,
                                      color: color.primary,
                                    ),
                                    onPressed: () {
                                      _showPluginConfigDialog(plugin);
                                    },
                                  ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isEnabled
                                        ? color.primary.withValues(alpha: 0.2)
                                        : color.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isEnabled ? 'ACTIVE' : 'DISABLED',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isEnabled
                                          ? color.primary
                                          : color.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
