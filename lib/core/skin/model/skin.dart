import 'package:flutter/material.dart';

/// A complete skin definition that can be loaded from JSON.
/// Skins define colors (light + dark) and styling parameters.
class Skin {
  final String id;
  final String name;
  final String author;
  final int version;
  final SkinTier tier;
  final SkinPalette palette;
  final SkinStyle style;
  final SkinMeta meta;

  const Skin({
    required this.id,
    required this.name,
    required this.author,
    required this.version,
    required this.tier,
    required this.palette,
    required this.style,
    required this.meta,
  });

  factory Skin.fromJson(Map<String, dynamic> json) {
    return Skin(
      id: json['id'] as String,
      name: json['name'] as String,
      author: json['author'] as String? ?? 'Mudra',
      version: json['version'] as int? ?? 1,
      tier: SkinTier.values.firstWhere(
        (e) => e.name == json['tier'],
        orElse: () => SkinTier.free,
      ),
      palette: SkinPalette.fromJson(json['palette'] as Map<String, dynamic>),
      style: SkinStyle.fromJson(json['style'] as Map<String, dynamic>? ?? {}),
      meta: SkinMeta.fromJson(json['meta'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'author': author,
        'version': version,
        'tier': tier.name,
        'palette': palette.toJson(),
        'style': style.toJson(),
        'meta': meta.toJson(),
      };

  /// Merges a sparse override on top of this skin.
  Skin merge(SkinOverride override) {
    return Skin(
      id: id,
      name: override.customName ?? name,
      author: author,
      version: version,
      tier: tier,
      palette: palette.merge(override.palette),
      style: style.merge(override.style),
      meta: meta,
    );
  }

  Skin copyWith({
    String? id,
    String? name,
    String? author,
    int? version,
    SkinTier? tier,
    SkinPalette? palette,
    SkinStyle? style,
    SkinMeta? meta,
  }) {
    return Skin(
      id: id ?? this.id,
      name: name ?? this.name,
      author: author ?? this.author,
      version: version ?? this.version,
      tier: tier ?? this.tier,
      palette: palette ?? this.palette,
      style: style ?? this.style,
      meta: meta ?? this.meta,
    );
  }
}

enum SkinTier { free, pro }

/// Color palette with light and dark variants.
class SkinPalette {
  final SkinColorSet light;
  final SkinColorSet dark;

  const SkinPalette({required this.light, required this.dark});

  factory SkinPalette.fromJson(Map<String, dynamic> json) {
    return SkinPalette(
      light: SkinColorSet.fromJson(json['light'] as Map<String, dynamic>),
      dark: SkinColorSet.fromJson(json['dark'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'light': light.toJson(),
        'dark': dark.toJson(),
      };

  SkinPalette merge(SkinPaletteOverride? override) {
    if (override == null) return this;
    return SkinPalette(
      light: light.merge(override.light),
      dark: dark.merge(override.dark),
    );
  }
}

/// A single color set (either light or dark mode).
class SkinColorSet {
  final Color seed;
  final Color? primary;
  final Color? secondary;
  final Color? tertiary;
  final Color? primaryContainer;
  final Color? secondaryContainer;
  final Color? tertiaryContainer;
  final Color? surface;
  final Color? surfaceContainer;
  final Color? surfaceContainerLow;
  final Color? surfaceContainerHigh;
  final Color? onSurface;
  final Color? onSurfaceVariant;
  final Color? outline;
  final Color? outlineVariant;

  const SkinColorSet({
    required this.seed,
    this.primary,
    this.secondary,
    this.tertiary,
    this.primaryContainer,
    this.secondaryContainer,
    this.tertiaryContainer,
    this.surface,
    this.surfaceContainer,
    this.surfaceContainerLow,
    this.surfaceContainerHigh,
    this.onSurface,
    this.onSurfaceVariant,
    this.outline,
    this.outlineVariant,
  });

  factory SkinColorSet.fromJson(Map<String, dynamic> json) {
    return SkinColorSet(
      seed: _parseColor(json['seed'] as String),
      primary: _maybeColor(json['primary']),
      secondary: _maybeColor(json['secondary']),
      tertiary: _maybeColor(json['tertiary']),
      primaryContainer: _maybeColor(json['primaryContainer']),
      secondaryContainer: _maybeColor(json['secondaryContainer']),
      tertiaryContainer: _maybeColor(json['tertiaryContainer']),
      surface: _maybeColor(json['surface']),
      surfaceContainer: _maybeColor(json['surfaceContainer']),
      surfaceContainerLow: _maybeColor(json['surfaceContainerLow']),
      surfaceContainerHigh: _maybeColor(json['surfaceContainerHigh']),
      onSurface: _maybeColor(json['onSurface']),
      onSurfaceVariant: _maybeColor(json['onSurfaceVariant']),
      outline: _maybeColor(json['outline']),
      outlineVariant: _maybeColor(json['outlineVariant']),
    );
  }

  Map<String, dynamic> toJson() => {
        'seed': _colorToHex(seed),
        if (primary != null) 'primary': _colorToHex(primary!),
        if (secondary != null) 'secondary': _colorToHex(secondary!),
        if (tertiary != null) 'tertiary': _colorToHex(tertiary!),
        if (primaryContainer != null)
          'primaryContainer': _colorToHex(primaryContainer!),
        if (secondaryContainer != null)
          'secondaryContainer': _colorToHex(secondaryContainer!),
        if (tertiaryContainer != null)
          'tertiaryContainer': _colorToHex(tertiaryContainer!),
        if (surface != null) 'surface': _colorToHex(surface!),
        if (surfaceContainer != null)
          'surfaceContainer': _colorToHex(surfaceContainer!),
        if (surfaceContainerLow != null)
          'surfaceContainerLow': _colorToHex(surfaceContainerLow!),
        if (surfaceContainerHigh != null)
          'surfaceContainerHigh': _colorToHex(surfaceContainerHigh!),
        if (onSurface != null) 'onSurface': _colorToHex(onSurface!),
        if (onSurfaceVariant != null)
          'onSurfaceVariant': _colorToHex(onSurfaceVariant!),
        if (outline != null) 'outline': _colorToHex(outline!),
        if (outlineVariant != null)
          'outlineVariant': _colorToHex(outlineVariant!),
      };

  SkinColorSet merge(SkinColorSetOverride? override) {
    if (override == null) return this;
    return SkinColorSet(
      seed: override.seed ?? seed,
      primary: override.primary ?? primary,
      secondary: override.secondary ?? secondary,
      tertiary: override.tertiary ?? tertiary,
      primaryContainer: override.primaryContainer ?? primaryContainer,
      secondaryContainer: override.secondaryContainer ?? secondaryContainer,
      tertiaryContainer: override.tertiaryContainer ?? tertiaryContainer,
      surface: override.surface ?? surface,
      surfaceContainer: override.surfaceContainer ?? surfaceContainer,
      surfaceContainerLow: override.surfaceContainerLow ?? surfaceContainerLow,
      surfaceContainerHigh:
          override.surfaceContainerHigh ?? surfaceContainerHigh,
      onSurface: override.onSurface ?? onSurface,
      onSurfaceVariant: override.onSurfaceVariant ?? onSurfaceVariant,
      outline: override.outline ?? outline,
      outlineVariant: override.outlineVariant ?? outlineVariant,
    );
  }
}

/// Styling parameters (radii, elevation, border behavior).
class SkinStyle {
  final double cardRadius;
  final double cardElevation;
  final double buttonRadius;
  final double inputRadius;
  final double borderOpacity;
  final double borderWidth;
  final String dividerStyle; // "standard", "hairline", "none"
  final String? numberFont; // font for amounts/numbers (e.g. "GeistMono")
  final String? pdfFont; // font for PDF export (e.g. "NotoSans")

  const SkinStyle({
    this.cardRadius = 16,
    this.cardElevation = 0,
    this.buttonRadius = 12,
    this.inputRadius = 12,
    this.borderOpacity = 0.12,
    this.borderWidth = 1,
    this.dividerStyle = 'standard',
    this.numberFont,
    this.pdfFont,
  });

  factory SkinStyle.fromJson(Map<String, dynamic> json) {
    return SkinStyle(
      cardRadius: (json['cardRadius'] as num?)?.toDouble() ?? 16,
      cardElevation: (json['cardElevation'] as num?)?.toDouble() ?? 0,
      buttonRadius: (json['buttonRadius'] as num?)?.toDouble() ?? 12,
      inputRadius: (json['inputRadius'] as num?)?.toDouble() ?? 12,
      borderOpacity: (json['borderOpacity'] as num?)?.toDouble() ?? 0.12,
      borderWidth: (json['borderWidth'] as num?)?.toDouble() ?? 1,
      dividerStyle: json['dividerStyle'] as String? ?? 'standard',
      numberFont: json['numberFont'] as String?,
      pdfFont: json['pdfFont'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'cardRadius': cardRadius,
        'cardElevation': cardElevation,
        'buttonRadius': buttonRadius,
        'inputRadius': inputRadius,
        'borderOpacity': borderOpacity,
        'borderWidth': borderWidth,
        'dividerStyle': dividerStyle,
        if (numberFont != null) 'numberFont': numberFont,
        if (pdfFont != null) 'pdfFont': pdfFont,
      };

  SkinStyle merge(SkinStyleOverride? override) {
    if (override == null) return this;
    return SkinStyle(
      cardRadius: override.cardRadius ?? cardRadius,
      cardElevation: override.cardElevation ?? cardElevation,
      buttonRadius: override.buttonRadius ?? buttonRadius,
      inputRadius: override.inputRadius ?? inputRadius,
      borderOpacity: override.borderOpacity ?? borderOpacity,
      borderWidth: override.borderWidth ?? borderWidth,
      dividerStyle: override.dividerStyle ?? dividerStyle,
      numberFont: override.numberFont ?? numberFont,
      pdfFont: override.pdfFont ?? pdfFont,
    );
  }
}

/// Metadata for display in the skin picker.
class SkinMeta {
  final String description;
  final List<String> tags;

  const SkinMeta({this.description = '', this.tags = const []});

  factory SkinMeta.fromJson(Map<String, dynamic> json) {
    return SkinMeta(
      description: json['description'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
        'description': description,
        'tags': tags,
      };
}

// ── Overrides (sparse — only fields the user changed) ──────

class SkinOverride {
  final String baseSkinId;
  final String? customName;
  final SkinPaletteOverride? palette;
  final SkinStyleOverride? style;

  const SkinOverride({
    required this.baseSkinId,
    this.customName,
    this.palette,
    this.style,
  });

  bool get isEmpty => customName == null && palette == null && style == null;

  factory SkinOverride.fromJson(Map<String, dynamic> json) {
    return SkinOverride(
      baseSkinId: json['baseSkinId'] as String,
      customName: json['customName'] as String?,
      palette: json['palette'] != null
          ? SkinPaletteOverride.fromJson(json['palette'] as Map<String, dynamic>)
          : null,
      style: json['style'] != null
          ? SkinStyleOverride.fromJson(json['style'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'baseSkinId': baseSkinId,
        if (customName != null) 'customName': customName,
        if (palette != null) 'palette': palette!.toJson(),
        if (style != null) 'style': style!.toJson(),
      };
}

class SkinPaletteOverride {
  final SkinColorSetOverride? light;
  final SkinColorSetOverride? dark;

  const SkinPaletteOverride({this.light, this.dark});

  factory SkinPaletteOverride.fromJson(Map<String, dynamic> json) {
    return SkinPaletteOverride(
      light: json['light'] != null
          ? SkinColorSetOverride.fromJson(json['light'] as Map<String, dynamic>)
          : null,
      dark: json['dark'] != null
          ? SkinColorSetOverride.fromJson(json['dark'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        if (light != null) 'light': light!.toJson(),
        if (dark != null) 'dark': dark!.toJson(),
      };
}

class SkinColorSetOverride {
  final Color? seed;
  final Color? primary;
  final Color? secondary;
  final Color? tertiary;
  final Color? primaryContainer;
  final Color? secondaryContainer;
  final Color? tertiaryContainer;
  final Color? surface;
  final Color? surfaceContainer;
  final Color? surfaceContainerLow;
  final Color? surfaceContainerHigh;
  final Color? onSurface;
  final Color? onSurfaceVariant;
  final Color? outline;
  final Color? outlineVariant;

  const SkinColorSetOverride({
    this.seed,
    this.primary,
    this.secondary,
    this.tertiary,
    this.primaryContainer,
    this.secondaryContainer,
    this.tertiaryContainer,
    this.surface,
    this.surfaceContainer,
    this.surfaceContainerLow,
    this.surfaceContainerHigh,
    this.onSurface,
    this.onSurfaceVariant,
    this.outline,
    this.outlineVariant,
  });

  factory SkinColorSetOverride.fromJson(Map<String, dynamic> json) {
    return SkinColorSetOverride(
      seed: _maybeColor(json['seed']),
      primary: _maybeColor(json['primary']),
      secondary: _maybeColor(json['secondary']),
      tertiary: _maybeColor(json['tertiary']),
      primaryContainer: _maybeColor(json['primaryContainer']),
      secondaryContainer: _maybeColor(json['secondaryContainer']),
      tertiaryContainer: _maybeColor(json['tertiaryContainer']),
      surface: _maybeColor(json['surface']),
      surfaceContainer: _maybeColor(json['surfaceContainer']),
      surfaceContainerLow: _maybeColor(json['surfaceContainerLow']),
      surfaceContainerHigh: _maybeColor(json['surfaceContainerHigh']),
      onSurface: _maybeColor(json['onSurface']),
      onSurfaceVariant: _maybeColor(json['onSurfaceVariant']),
      outline: _maybeColor(json['outline']),
      outlineVariant: _maybeColor(json['outlineVariant']),
    );
  }

  Map<String, dynamic> toJson() => {
        if (seed != null) 'seed': _colorToHex(seed!),
        if (primary != null) 'primary': _colorToHex(primary!),
        if (secondary != null) 'secondary': _colorToHex(secondary!),
        if (tertiary != null) 'tertiary': _colorToHex(tertiary!),
        if (primaryContainer != null)
          'primaryContainer': _colorToHex(primaryContainer!),
        if (secondaryContainer != null)
          'secondaryContainer': _colorToHex(secondaryContainer!),
        if (tertiaryContainer != null)
          'tertiaryContainer': _colorToHex(tertiaryContainer!),
        if (surface != null) 'surface': _colorToHex(surface!),
        if (surfaceContainer != null)
          'surfaceContainer': _colorToHex(surfaceContainer!),
        if (surfaceContainerLow != null)
          'surfaceContainerLow': _colorToHex(surfaceContainerLow!),
        if (surfaceContainerHigh != null)
          'surfaceContainerHigh': _colorToHex(surfaceContainerHigh!),
        if (onSurface != null) 'onSurface': _colorToHex(onSurface!),
        if (onSurfaceVariant != null)
          'onSurfaceVariant': _colorToHex(onSurfaceVariant!),
        if (outline != null) 'outline': _colorToHex(outline!),
        if (outlineVariant != null)
          'outlineVariant': _colorToHex(outlineVariant!),
      };
}

class SkinStyleOverride {
  final double? cardRadius;
  final double? cardElevation;
  final double? buttonRadius;
  final double? inputRadius;
  final double? borderOpacity;
  final double? borderWidth;
  final String? dividerStyle;
  final String? numberFont;
  final String? pdfFont;

  const SkinStyleOverride({
    this.cardRadius,
    this.cardElevation,
    this.buttonRadius,
    this.inputRadius,
    this.borderOpacity,
    this.borderWidth,
    this.dividerStyle,
    this.numberFont,
    this.pdfFont,
  });

  factory SkinStyleOverride.fromJson(Map<String, dynamic> json) {
    return SkinStyleOverride(
      cardRadius: (json['cardRadius'] as num?)?.toDouble(),
      cardElevation: (json['cardElevation'] as num?)?.toDouble(),
      buttonRadius: (json['buttonRadius'] as num?)?.toDouble(),
      inputRadius: (json['inputRadius'] as num?)?.toDouble(),
      borderOpacity: (json['borderOpacity'] as num?)?.toDouble(),
      borderWidth: (json['borderWidth'] as num?)?.toDouble(),
      dividerStyle: json['dividerStyle'] as String?,
      numberFont: json['numberFont'] as String?,
      pdfFont: json['pdfFont'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (cardRadius != null) 'cardRadius': cardRadius,
        if (cardElevation != null) 'cardElevation': cardElevation,
        if (buttonRadius != null) 'buttonRadius': buttonRadius,
        if (inputRadius != null) 'inputRadius': inputRadius,
        if (borderOpacity != null) 'borderOpacity': borderOpacity,
        if (borderWidth != null) 'borderWidth': borderWidth,
        if (dividerStyle != null) 'dividerStyle': dividerStyle,
        if (numberFont != null) 'numberFont': numberFont,
        if (pdfFont != null) 'pdfFont': pdfFont,
      };
}

// ── Helpers ────────────────────────────────────────────────

Color _parseColor(String hex) {
  final buffer = hex.replaceFirst('#', '');
  final value = int.parse(buffer, radix: 16);
  return buffer.length == 6 ? Color(0xFF000000 | value) : Color(value);
}

Color? _maybeColor(dynamic value) {
  if (value == null) return null;
  return _parseColor(value as String);
}

String _colorToHex(Color color) {
  final r = color.r * 255 ~/ 1;
  final g = color.g * 255 ~/ 1;
  final b = color.b * 255 ~/ 1;
  return '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}'.toUpperCase();
}
