import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/entitlement/entitlement_provider.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/core/utils/icon_helper.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/core/widgets/skeleton_loader.dart';
import 'package:mudra_manager/features/marketplace/models/plugin_metadata.dart';
import 'package:mudra_manager/features/account/data/account_providers.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/features/category/data/category_provider.dart';
import 'package:mudra_manager/features/marketplace/services/marketplace_service.dart';
import 'package:mudra_manager/shared/widgets/pro_gate.dart';
import 'package:shared_preferences/shared_preferences.dart';

final pluginGroupsProvider = FutureProvider((ref) async {
  final service = ref.watch(marketplaceServiceProvider);
  return service.fetchPluginsByGroup();
});

final marketplaceServiceProvider = Provider((ref) => MarketplaceService());

final pluginStatesProvider =
    StateNotifierProvider<PluginStatesNotifier, Map<String, bool>>((ref) {
  return PluginStatesNotifier(ref.watch(marketplaceServiceProvider));
});

class PluginStatesNotifier extends StateNotifier<Map<String, bool>> {
  final MarketplaceService _service;

  PluginStatesNotifier(this._service) : super({});

  Future<void> loadStates(List<PluginMetadata> plugins) async {
    final states = <String, bool>{};
    for (final plugin in plugins) {
      states[plugin.id] = await _service.isPluginEnabled(plugin.id);
    }
    state = states;
  }

  Future<void> togglePlugin(String pluginId, bool enabled) async {
    await _service.togglePlugin(pluginId, enabled);
    state = {...state, pluginId: enabled};
  }
}

class PluginGroupsScreen extends ConsumerStatefulWidget {
  const PluginGroupsScreen({super.key});

  @override
  ConsumerState<PluginGroupsScreen> createState() => _PluginGroupsScreenState();
}

class _PluginGroupsScreenState extends ConsumerState<PluginGroupsScreen> {
  final Set<PluginGroup> _expanded = {};

  bool _isStandardTemplate(String id) =>
      id == 'standard_excel_export' || id == 'standard_pdf_export';

  String _getBankDisplayName(String name) {
    const names = {
      'SBI Bank': 'State Bank of India',
      'Kotak Bank': 'Kotak Mahindra Bank',
    };
    return names[name] ?? name;
  }

  IconData _groupIcon(PluginGroup group) {
    switch (group) {
      case PluginGroup.smsParser:
        return LucideIcons.messageSquare;
      case PluginGroup.exportTemplate:
        return LucideIcons.fileOutput;
      case PluginGroup.notification:
        return LucideIcons.bell;
      case PluginGroup.budget:
        return LucideIcons.chartPie;
      case PluginGroup.goals:
        return LucideIcons.target;
      case PluginGroup.categoryManagement:
        return LucideIcons.tags;
      case PluginGroup.utility:
        return LucideIcons.wrench;
      case PluginGroup.custom:
        return LucideIcons.puzzle;
    }
  }

  int _activeCount(List<PluginMetadata> plugins, Map<String, bool> states) =>
      plugins.where((p) => states[p.id] == true).length;

  @override
  Widget build(BuildContext context) {
    final groupedAsync = ref.watch(pluginGroupsProvider);
    final pluginStates = ref.watch(pluginStatesProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Plugins')),
      body: groupedAsync.when(
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 6,
          itemBuilder: (_, __) => TransactionCardSkeleton(),
        ),
        error: (err, _) => Center(child: Text(BuddyMessages.errorWith('$err'))),
        data: (grouped) {
          final activeGroups =
              grouped.entries.where((e) => e.value.isNotEmpty).toList();
          final allPlugins = grouped.values.expand((p) => p).toList();

          if (pluginStates.isEmpty) {
            Future.microtask(
              () => ref
                  .read(pluginStatesProvider.notifier)
                  .loadStates(allPlugins),
            );
          }

          final totalActive = pluginStates.values.where((v) => v).length;

          return ListView(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.cardHorizontal,
              vertical: spacing.cardVertical,
            ),
            children: [
              // ── HERO ──
              _buildHeroCard(
                color,
                textTheme,
                spacing,
                isDark,
                allPlugins.length,
                totalActive,
              ),
              const SizedBox(height: 24),

              // ── COLLAPSIBLE GROUPS ──
              ...activeGroups.map((entry) {
                final group = entry.key;
                final plugins = entry.value;
                final isOpen = _expanded.contains(group);
                final groupActive = _activeCount(plugins, pluginStates);

                return Padding(
                  padding: EdgeInsets.only(bottom: spacing.elementGap),
                  child: _buildCollapsibleGroup(
                    group: group,
                    plugins: plugins,
                    pluginStates: pluginStates,
                    isOpen: isOpen,
                    groupActive: groupActive,
                    color: color,
                    textTheme: textTheme,
                    spacing: spacing,
                  ),
                );
              }),

              const SizedBox(height: 16),

              // ── INFO ──
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  color: color.primary.withValues(alpha: 0.06),
                  border: Border.all(
                    color: color.primary.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(LucideIcons.info, color: color.primary, size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Plugins extend app features. Some plugins '
                        'require additional permissions or configuration.',
                        style: textTheme.bodySmall?.copyWith(
                          color: color.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── HERO CARD ──
  Widget _buildHeroCard(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    bool isDark,
    int total,
    int active,
  ) {
    final accent = color.primary;
    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: isDark ? 0.2 : 0.12),
            accent.withValues(alpha: isDark ? 0.08 : 0.04),
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutBack,
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) =>
                Transform.scale(scale: value, child: child),
            child: Container(
              padding: EdgeInsets.all(spacing.cardInner),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.puzzle, color: accent, size: 28),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$active of $total active',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Toggle plugins to extend app features',
                  style: textTheme.bodySmall?.copyWith(
                    color: color.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  // ── COLLAPSIBLE GROUP ──
  Widget _buildCollapsibleGroup({
    required PluginGroup group,
    required List<PluginMetadata> plugins,
    required Map<String, bool> pluginStates,
    required bool isOpen,
    required int groupActive,
    required ColorScheme color,
    required TextTheme textTheme,
    required AppSpacing spacing,
  }) {
    final isSmsGroup = group == PluginGroup.smsParser;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: color.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        side: BorderSide(
          color: color.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ── GROUP HEADER (tappable) ──
          InkWell(
            onTap: () {
              HapticFeedback.mediumImpact();
              setState(() {
                if (isOpen) {
                  _expanded.remove(group);
                } else {
                  _expanded.add(group);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _groupIcon(group),
                      color: color.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.label,
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          group.description,
                          style: textTheme.bodySmall?.copyWith(
                            color: color.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Active count pill
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$groupActive/${plugins.length}',
                      style: textTheme.labelSmall?.copyWith(
                        color: color.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: isOpen ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      LucideIcons.chevronDown,
                      color: color.onSurfaceVariant,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── EXPANDED PLUGIN ROWS ──
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(
              children: [
                Divider(
                  height: 1,
                  color: color.outlineVariant.withValues(alpha: 0.4),
                ),
                ...plugins.asMap().entries.map((entry) {
                  final plugin = entry.value;
                  final isLast = entry.key == plugins.length - 1;
                  final isEnabled = pluginStates[plugin.id] ?? false;
                  final isStandard = _isStandardTemplate(plugin.id);
                  final hasConfig = plugin.configOptions?.isNotEmpty ?? false;

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            // Plugin icon
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: color.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: _pluginIcon(plugin, color),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Name + description
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isSmsGroup
                                        ? _getBankDisplayName(plugin.name)
                                        : plugin.name,
                                    style: textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    isSmsGroup
                                        ? 'v${plugin.version}'
                                        : plugin.description,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: color.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),

                            // Config gear
                            if (hasConfig && isEnabled && !isStandard)
                              IconButton(
                                icon: Icon(
                                  LucideIcons.settings,
                                  size: 16,
                                  color: color.primary,
                                ),
                                visualDensity: VisualDensity.compact,
                                onPressed: () =>
                                    _showPluginConfigDialog(plugin),
                              ),

                            // Default badge or switch
                            if (isStandard)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: color.secondaryContainer,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Default',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: color.onSecondaryContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                            else if (plugin.isPro)
                              Consumer(
                                builder: (context, ref, _) {
                                  final hasAccess = ref
                                          .watch(hasFullAccessProvider)
                                          .valueOrNull ??
                                      false;
                                  if (hasAccess) {
                                    return Switch(
                                      value: isEnabled,
                                      onChanged: (val) async {
                                        HapticFeedback.mediumImpact();
                                        await ref
                                            .read(pluginStatesProvider.notifier)
                                            .togglePlugin(plugin.id, val);
                                        if (plugin.group ==
                                            PluginGroup.categoryManagement) {
                                          ref.invalidate(categoryListProvider);
                                          ref.invalidate(
                                            expenseCategoriesProvider,
                                          );
                                          ref.invalidate(
                                            incomeCategoriesProvider,
                                          );
                                        }
                                        SnackbarService.info(
                                          val
                                              ? '${plugin.name} enabled'
                                              : '${plugin.name} disabled',
                                        );
                                      },
                                    );
                                  }
                                  return GestureDetector(
                                    onTap: () {
                                      HapticFeedback.mediumImpact();
                                      context.push(AppRoutes.upgrade);
                                    },
                                    child: const ProBadge(),
                                  );
                                },
                              )
                            else
                              Switch(
                                value: isEnabled,
                                onChanged: (val) async {
                                  HapticFeedback.mediumImpact();
                                  await ref
                                      .read(pluginStatesProvider.notifier)
                                      .togglePlugin(plugin.id, val);
                                  if (plugin.group ==
                                      PluginGroup.categoryManagement) {
                                    ref.invalidate(categoryListProvider);
                                    ref.invalidate(expenseCategoriesProvider);
                                    ref.invalidate(incomeCategoriesProvider);
                                  }
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
                      if (!isLast)
                        Divider(
                          height: 1,
                          indent: 64,
                          color: color.outlineVariant.withValues(alpha: 0.3),
                        ),
                    ],
                  );
                }),
              ],
            ),
            crossFadeState:
                isOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }

  // ── CONFIG DIALOGS ──
  void _showPluginConfigDialog(PluginMetadata plugin) {
    if (plugin.id == 'com.mudra.credit_card_reminder') {
      _showCreditCardConfigDialog(plugin);
      return;
    }

    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final service = ref.read(marketplaceServiceProvider);

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
              Icon(LucideIcons.settings, size: 48, color: color.primary),
              const SizedBox(height: 16),
              Text(
                plugin.name,
                style:
                    textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Configure plugin settings',
                style: textTheme.bodyMedium
                    ?.copyWith(color: color.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              ...plugin.configOptions!.map(
                (option) => Padding(
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
                      fillColor:
                          color.surfaceContainerHighest.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
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
                          SnackbarService.success(BuddyMessages.settingsSaved);
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

  Widget _pluginIcon(PluginMetadata plugin, ColorScheme color) {
    final url = plugin.iconUrl;
    if (url.endsWith('.svg')) {
      return SvgPicture.asset(
        url,
        width: 20,
        height: 20,
        placeholderBuilder: (_) => Icon(
          _groupIcon(plugin.group),
          color: color.primary,
          size: 16,
        ),
      );
    }
    if (url.endsWith('.png')) {
      return Image.asset(
        url,
        width: 20,
        height: 20,
        errorBuilder: (_, __, ___) => Icon(
          _groupIcon(plugin.group),
          color: color.primary,
          size: 16,
        ),
      );
    }
    if (url.isNotEmpty) {
      return Icon(
        IconHelper.getIconData(url),
        color: color.primary,
        size: 16,
      );
    }
    return Icon(_groupIcon(plugin.group), color: color.primary, size: 16);
  }

  void _showCreditCardConfigDialog(PluginMetadata plugin) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final service = ref.read(marketplaceServiceProvider);
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
              loading: () => ListView(children: List.generate(3, (_) => DashboardCardSkeleton())),
              error: (err, _) => Center(child: Text(BuddyMessages.errorWith('$err'))),
              data: (accounts) {
                final creditCards = accounts
                    .where((a) => a.accountType == AccountType.creditCard)
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
                            Icon(
                              LucideIcons.creditCard,
                              size: 48,
                              color: color.primary,
                            ),
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
                            if (creditCards.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: color.primary.withValues(alpha: 0.06),
                                  border: Border.all(
                                    color:
                                        color.primary.withValues(alpha: 0.15),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      LucideIcons.info,
                                      color: color.primary,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'No credit card accounts found. Add one first.',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: color.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else ...[
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Credit Card Accounts',
                                  style: textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...creditCards.map((account) {
                                final existing = cardConfigs.firstWhere(
                                  (c) => c['accountId'] == account.id,
                                  orElse: () {
                                    final config = {
                                      'accountId': account.id,
                                      'accountName': account.name,
                                      'billDay': 15,
                                      'enabled': false,
                                    };
                                    cardConfigs.add(config);
                                    return config;
                                  },
                                );

                                return Card(
                                  elevation: 0,
                                  margin: const EdgeInsets.only(bottom: 8),
                                  color: color.surfaceContainerLow,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Checkbox(
                                              value: existing['enabled'],
                                              onChanged: (val) {
                                                setState(() {
                                                  existing['enabled'] =
                                                      val ?? false;
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
                                        if (existing['enabled'] == true)
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
                                                      text: existing['billDay']
                                                          .toString(),
                                                    ),
                                                    onChanged: (value) {
                                                      final day =
                                                          int.tryParse(value);
                                                      if (day != null &&
                                                          day >= 1 &&
                                                          day <= 31) {
                                                        existing['billDay'] =
                                                            day;
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
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
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
                                      final reminderDays = int.tryParse(
                                            reminderController.text,
                                          ) ??
                                          1;
                                      final enabledCards = cardConfigs
                                          .where((c) => c['enabled'] == true)
                                          .map(
                                            (c) =>
                                                '${c['accountName']}|${c['billDay']}',
                                          )
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
                                        enabledCards,
                                      );

                                      if (ctx.mounted) {
                                        Navigator.pop(ctx);
                                        SnackbarService.success(
                                          'Credit card reminders configured',
                                        );
                                      }
                                    },
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
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
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
