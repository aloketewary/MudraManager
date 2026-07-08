import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/skin/model/skin.dart';
import 'package:mudra_manager/core/skin/provider/skin_provider.dart';
import 'package:mudra_manager/core/skin/converter/skin_to_theme.dart';

import 'package:mudra_manager/core/utils/snackbar_service.dart';

class SkinEditorScreen extends ConsumerStatefulWidget {
  const SkinEditorScreen({super.key});

  @override
  ConsumerState<SkinEditorScreen> createState() => _SkinEditorScreenState();
}

class _SkinEditorScreenState extends ConsumerState<SkinEditorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── Color overrides (all 15 slots × 2 modes) ──
  final Map<String, Color?> _lightColors = {};
  final Map<String, Color?> _darkColors = {};

  // ── Style overrides ──
  late double _cardRadius;
  late double _cardElevation;
  late double _buttonRadius;
  late double _inputRadius;
  late double _borderOpacity;
  late double _borderWidth;
  late String _dividerStyle;

  Skin? _baseSkin;
  bool _hasChanges = false;

  static const _colorSlots = [
    'seed',
    'primary',
    'secondary',
    'tertiary',
    'primaryContainer',
    'secondaryContainer',
    'tertiaryContainer',
    'surface',
    'surfaceContainer',
    'surfaceContainerLow',
    'surfaceContainerHigh',
    'onSurface',
    'onSurfaceVariant',
    'outline',
    'outlineVariant',
  ];

  static const _colorSlotLabels = {
    'seed': 'Seed Color',
    'primary': 'Primary',
    'secondary': 'Secondary',
    'tertiary': 'Tertiary',
    'primaryContainer': 'Primary Container',
    'secondaryContainer': 'Secondary Container',
    'tertiaryContainer': 'Tertiary Container',
    'surface': 'Surface',
    'surfaceContainer': 'Surface Container',
    'surfaceContainerLow': 'Surface Container Low',
    'surfaceContainerHigh': 'Surface Container High',
    'onSurface': 'On Surface',
    'onSurfaceVariant': 'On Surface Variant',
    'outline': 'Outline',
    'outlineVariant': 'Outline Variant',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initFromSkin();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initFromSkin() {
    final skin = ref.read(activeSkinProvider).value;
    if (skin == null) return;
    _baseSkin = skin;

    // Load style
    _cardRadius = skin.style.cardRadius;
    _cardElevation = skin.style.cardElevation;
    _buttonRadius = skin.style.buttonRadius;
    _inputRadius = skin.style.inputRadius;
    _borderOpacity = skin.style.borderOpacity;
    _borderWidth = skin.style.borderWidth;
    _dividerStyle = skin.style.dividerStyle;

    // Load colors from skin's palette into maps
    _loadColorSet(skin.palette.light, _lightColors);
    _loadColorSet(skin.palette.dark, _darkColors);
  }

  void _loadColorSet(SkinColorSet set, Map<String, Color?> map) {
    map['seed'] = set.seed;
    map['primary'] = set.primary;
    map['secondary'] = set.secondary;
    map['tertiary'] = set.tertiary;
    map['primaryContainer'] = set.primaryContainer;
    map['secondaryContainer'] = set.secondaryContainer;
    map['tertiaryContainer'] = set.tertiaryContainer;
    map['surface'] = set.surface;
    map['surfaceContainer'] = set.surfaceContainer;
    map['surfaceContainerLow'] = set.surfaceContainerLow;
    map['surfaceContainerHigh'] = set.surfaceContainerHigh;
    map['onSurface'] = set.onSurface;
    map['onSurfaceVariant'] = set.onSurfaceVariant;
    map['outline'] = set.outline;
    map['outlineVariant'] = set.outlineVariant;
  }

  void _markChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  Future<void> _save(AppSpacing spacing) async {
    if (_baseSkin == null) return;

    final override = SkinOverride(
      baseSkinId: _baseSkin!.id,
      palette: SkinPaletteOverride(
        light: _buildColorSetOverride(_lightColors),
        dark: _buildColorSetOverride(_darkColors),
      ),
      style: SkinStyleOverride(
        cardRadius: _cardRadius,
        cardElevation: _cardElevation,
        buttonRadius: _buttonRadius,
        inputRadius: _inputRadius,
        borderOpacity: _borderOpacity,
        borderWidth: _borderWidth,
        dividerStyle: _dividerStyle,
      ),
    );

    await ref.read(activeSkinProvider.notifier).applyOverride(override);
    SnackbarService.success('Skin customized!', spacing);
    if (mounted) Navigator.of(context).pop();
  }

  SkinColorSetOverride _buildColorSetOverride(Map<String, Color?> map) {
    return SkinColorSetOverride(
      seed: map['seed'],
      primary: map['primary'],
      secondary: map['secondary'],
      tertiary: map['tertiary'],
      primaryContainer: map['primaryContainer'],
      secondaryContainer: map['secondaryContainer'],
      tertiaryContainer: map['tertiaryContainer'],
      surface: map['surface'],
      surfaceContainer: map['surfaceContainer'],
      surfaceContainerLow: map['surfaceContainerLow'],
      surfaceContainerHigh: map['surfaceContainerHigh'],
      onSurface: map['onSurface'],
      onSurfaceVariant: map['onSurfaceVariant'],
      outline: map['outline'],
      outlineVariant: map['outlineVariant'],
    );
  }

  Future<void> _reset(AppSpacing spacing) async {
    await ref.read(activeSkinProvider.notifier).resetToDefault();
    _initFromSkin();
    setState(() => _hasChanges = false);
    SnackbarService.success('Reset to default', spacing);
  }

  @override
  Widget build(BuildContext context) {
    final skin = ref.watch(activeSkinProvider).value;
    final spacing = ref.watch(spacingProvider);
    if (skin == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Customize ${skin.name}'),
        actions: [
          TextButton(
            onPressed:() => _hasChanges ? _save(spacing) : null,
            child: const Text('Save'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Colors'),
            Tab(text: 'Style'),
            Tab(text: 'Preview'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildColorsTab(),
          _buildStyleTab(spacing),
          _buildPreviewTab(skin),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TAB 1: COLORS
  // ═══════════════════════════════════════════════════════════

  Widget _buildColorsTab() {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [
              Tab(text: 'Light Mode'),
              Tab(text: 'Dark Mode'),
            ],
            labelColor: color.primary,
            unselectedLabelColor: color.onSurfaceVariant,
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildColorList(_lightColors, textTheme, color),
                _buildColorList(_darkColors, textTheme, color),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorList(
    Map<String, Color?> colorMap,
    TextTheme textTheme,
    ColorScheme color,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: _colorSlots.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final slot = _colorSlots[index];
        final label = _colorSlotLabels[slot]!;
        final currentColor = colorMap[slot];

        return _ColorSlotTile(
          label: label,
          color: currentColor,
          fallbackColor: color.surface,
          onColorChanged: (c) {
            setState(() => colorMap[slot] = c);
            _markChanged();
          },
          onClear: currentColor != null && slot != 'seed'
              ? () {
                  setState(() => colorMap[slot] = null);
                  _markChanged();
                }
              : null,
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TAB 2: STYLE
  // ═══════════════════════════════════════════════════════════

  Widget _buildStyleTab(AppSpacing spacing) {
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        _sectionTitle('Radii', textTheme, color),
        const SizedBox(height: 8),
        _buildSlider('Card Radius', _cardRadius, 0, 32, (v) {
          setState(() => _cardRadius = v);
          _markChanged();
        }),
        _buildSlider('Button Radius', _buttonRadius, 0, 32, (v) {
          setState(() => _buttonRadius = v);
          _markChanged();
        }),
        _buildSlider('Input Radius', _inputRadius, 0, 32, (v) {
          setState(() => _inputRadius = v);
          _markChanged();
        }),
        const SizedBox(height: 20),

        _sectionTitle('Borders & Dividers', textTheme, color),
        const SizedBox(height: 8),
        _buildSlider('Border Opacity', _borderOpacity, 0, 0.5, (v) {
          setState(() => _borderOpacity = v);
          _markChanged();
        }),
        _buildSlider('Border Width', _borderWidth, 0, 3, (v) {
          setState(() => _borderWidth = v);
          _markChanged();
        }),
        _buildSlider('Card Elevation', _cardElevation, 0, 8, (v) {
          setState(() => _cardElevation = v);
          _markChanged();
        }),
        const SizedBox(height: 16),
        _buildDividerStylePicker(),
        const SizedBox(height: 32),

        // ── Reset ──
        OutlinedButton.icon(
          onPressed: () => _reset(spacing),
          icon: const Icon(LucideIcons.rotateCcw, size: 18),
          label: const Text('Reset to Default'),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TAB 3: PREVIEW
  // ═══════════════════════════════════════════════════════════

  Widget _buildPreviewTab(Skin skin) {
    final lightScheme = SkinToTheme.lightScheme(skin);
    final darkScheme = SkinToTheme.darkScheme(skin);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _previewSection('Light Mode', lightScheme),
        const SizedBox(height: 24),
        _previewSection('Dark Mode', darkScheme),
      ],
    );
  }

  Widget _previewSection(String title, ColorScheme cs) {
    final textTheme = Theme.of(context).textTheme;
    final borderColor = cs.outline.withValues(alpha: _borderOpacity);
    final isHairline = _dividerStyle == 'hairline';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: textTheme.titleSmall),
        const SizedBox(height: 8),
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // AppBar mock
              Container(
                height: 40,
                color: cs.surface,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(LucideIcons.arrowLeft, size: 16, color: cs.onSurface),
                    const SizedBox(width: 10),
                    Container(
                      height: 8,
                      width: 60,
                      decoration: BoxDecoration(
                        color: cs.onSurface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                height: _borderWidth,
                thickness: _borderWidth,
                color: borderColor,
              ),
              // Body
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: isHairline
                      ? _hairlineBody(cs, borderColor)
                      : _standardBody(cs, borderColor),
                ),
              ),
              // Bottom nav mock
              Container(
                height: 36,
                color: cs.surface,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Icon(LucideIcons.house, size: 16, color: cs.primary),
                    Icon(LucideIcons.wallet, size: 16, color: cs.onSurfaceVariant),
                    Icon(LucideIcons.chartPie, size: 16, color: cs.onSurfaceVariant),
                    Icon(LucideIcons.user, size: 16, color: cs.onSurfaceVariant),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _standardBody(ColorScheme cs, Color borderColor) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(_cardRadius),
              border: Border.all(color: borderColor, width: _borderWidth),
            ),
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 7,
                  width: 50,
                  decoration: BoxDecoration(
                    color: cs.onPrimaryContainer,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 5,
                  width: 35,
                  decoration: BoxDecoration(
                    color: cs.onPrimaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: cs.secondaryContainer,
              borderRadius: BorderRadius.circular(_cardRadius),
              border: Border.all(color: borderColor, width: _borderWidth),
            ),
            child: Center(
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(_buttonRadius),
                ),
                child: Icon(LucideIcons.plus, size: 16, color: cs.onPrimary),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _hairlineBody(ColorScheme cs, Color borderColor) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Center(
                  child: Text(
                    '₹24.5K',
                    style: TextStyle(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              VerticalDivider(
                width: _borderWidth,
                thickness: _borderWidth,
                color: borderColor,
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '₹8.2K',
                    style: TextStyle(
                      color: cs.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(
          height: _borderWidth,
          thickness: _borderWidth,
          color: borderColor,
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Center(
                  child: Text(
                    '91%',
                    style: TextStyle(
                      color: cs.tertiary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              VerticalDivider(
                width: _borderWidth,
                thickness: _borderWidth,
                color: borderColor,
              ),
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      value: 0.75,
                      strokeWidth: 2.5,
                      color: cs.primary,
                      backgroundColor: borderColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SHARED WIDGETS
  // ═══════════════════════════════════════════════════════════

  Widget _sectionTitle(String title, TextTheme textTheme, ColorScheme color) {
    return Text(
      title,
      style: textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: color.primary,
      ),
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 36,
            child: Text(
              value.toStringAsFixed(value < 1 ? 2 : 0),
              style: Theme.of(context).textTheme.labelSmall,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDividerStylePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Divider Style', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'standard', label: Text('Standard')),
            ButtonSegment(value: 'hairline', label: Text('Hairline')),
            ButtonSegment(value: 'none', label: Text('None')),
          ],
          selected: {_dividerStyle},
          onSelectionChanged: (v) {
            setState(() => _dividerStyle = v.first);
            _markChanged();
          },
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// COLOR SLOT TILE (reusable per-slot row)
// ═══════════════════════════════════════════════════════════════

class _ColorSlotTile extends StatelessWidget {
  final String label;
  final Color? color;
  final Color fallbackColor;
  final ValueChanged<Color> onColorChanged;
  final VoidCallback? onClear;

  const _ColorSlotTile({
    required this.label,
    required this.color,
    required this.fallbackColor,
    required this.onColorChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayColor = color ?? fallbackColor;
    final isSet = color != null;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: isSet
              ? theme.colorScheme.onSurface
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
      subtitle: isSet
          ? Text(
              _colorToHexString(displayColor),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontFamily: 'GeistMono',
              ),
            )
          : Text(
              'Auto (from seed)',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => _showPicker(context, displayColor),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: displayColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant,
                ),
              ),
            ),
          ),
          if (onClear != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onClear,
              child: Icon(
                LucideIcons.x,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showPicker(BuildContext context, Color current) {
    const presets = [
      Color(0xFF10B981), Color(0xFF3B82F6), Color(0xFFEF4444),
      Color(0xFFF59E0B), Color(0xFF8B5CF6), Color(0xFFEC4899),
      Color(0xFF06B6D4), Color(0xFFD09C60), Color(0xFF9A5129),
      Color(0xFF5E544B), Color(0xFF1A237E), Color(0xFF0B0908),
      Color(0xFFFFFFFF), Color(0xFF424242), Color(0xFF2D6A4F),
      Color(0xFFE85D04), Color(0xFF0077B6), Color(0xFF6D28D9),
      Color(0xFFC2185B), Color(0xFF1B5E20), Color(0xFF000000),
      Color(0xFF141110), Color(0xFF1A1614), Color(0xFF242018),
      Color(0xFFE8E0D8), Color(0xFFA89888), Color(0xFF3A3330),
      Color(0xFFFFF9F4), Color(0xFFF5EDE5), Color(0xFF1C1410),
    ];

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pick a color', style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: presets.map((c) {
                final isActive = c == current;
                return GestureDetector(
                  onTap: () {
                    onColorChanged(c);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isActive
                            ? Theme.of(ctx).colorScheme.primary
                            : Theme.of(ctx).colorScheme.outlineVariant,
                        width: isActive ? 3 : 1,
                      ),
                    ),
                    child: isActive
                        ? Icon(
                            LucideIcons.check,
                            size: 16,
                            color: c.computeLuminance() > 0.5
                                ? Colors.black
                                : Colors.white,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  static String _colorToHexString(Color color) {
    final r = (color.r * 255).round();
    final g = (color.g * 255).round();
    final b = (color.b * 255).round();
    return '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}'.toUpperCase();
  }
}
