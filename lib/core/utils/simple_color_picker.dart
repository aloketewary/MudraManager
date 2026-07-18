import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';

class SimpleColorPickerDialog extends ConsumerStatefulWidget {
  final Color? initialColor;

  const SimpleColorPickerDialog({super.key, this.initialColor});

  @override
  ConsumerState<SimpleColorPickerDialog> createState() =>
      _SimpleColorPickerDialogState();
}

class _SimpleColorPickerDialogState
    extends ConsumerState<SimpleColorPickerDialog> {
  late Color _selected;

  // Mid-range colors only — no whites/pastels that vanish in light mode,
  // no near-blacks that vanish in dark mode.
  static const _palette = <_ColorGroup>[
    _ColorGroup('color_red', [
      Color(0xFFE57373),
      Color(0xFFEF5350),
      Color(0xFFE53935),
      Color(0xFFD32F2F),
      Color(0xFFC62828),
      Color(0xFFB71C1C),
    ]),
    _ColorGroup('color_pink', [
      Color(0xFFEC407A),
      Color(0xFFE91E63),
      Color(0xFFD81B60),
      Color(0xFFC2185B),
      Color(0xFFAD1457),
      Color(0xFF880E4F),
    ]),
    _ColorGroup('color_purple', [
      Color(0xFFAB47BC),
      Color(0xFF9C27B0),
      Color(0xFF8E24AA),
      Color(0xFF7B1FA2),
      Color(0xFF6A1B9A),
      Color(0xFF4A148C),
    ]),
    _ColorGroup('color_indigo', [
      Color(0xFF5C6BC0),
      Color(0xFF3F51B5),
      Color(0xFF3949AB),
      Color(0xFF303F9F),
      Color(0xFF283593),
      Color(0xFF1A237E),
    ]),
    _ColorGroup('color_blue', [
      Color(0xFF42A5F5),
      Color(0xFF2196F3),
      Color(0xFF1E88E5),
      Color(0xFF1976D2),
      Color(0xFF1565C0),
      Color(0xFF0D47A1),
    ]),
    _ColorGroup('color_cyan', [
      Color(0xFF26C6DA),
      Color(0xFF00BCD4),
      Color(0xFF00ACC1),
      Color(0xFF0097A7),
      Color(0xFF00838F),
      Color(0xFF006064),
    ]),
    _ColorGroup('color_teal', [
      Color(0xFF26A69A),
      Color(0xFF009688),
      Color(0xFF00897B),
      Color(0xFF00796B),
      Color(0xFF00695C),
      Color(0xFF004D40),
    ]),
    _ColorGroup('color_green', [
      Color(0xFF66BB6A),
      Color(0xFF4CAF50),
      Color(0xFF43A047),
      Color(0xFF388E3C),
      Color(0xFF2E7D32),
      Color(0xFF1B5E20),
    ]),
    _ColorGroup('color_orange', [
      Color(0xFFFFA726),
      Color(0xFFFF9800),
      Color(0xFFFB8C00),
      Color(0xFFF57C00),
      Color(0xFFEF6C00),
      Color(0xFFE65100),
    ]),
    _ColorGroup('color_brown', [
      Color(0xFFA1887F),
      Color(0xFF8D6E63),
      Color(0xFF795548),
      Color(0xFF6D4C41),
      Color(0xFF5D4037),
      Color(0xFF4E342E),
    ]),
    _ColorGroup('color_grey', [
      Color(0xFF90A4AE),
      Color(0xFF78909C),
      Color(0xFF607D8B),
      Color(0xFF546E7A),
      Color(0xFF455A64),
      Color(0xFF37474F),
    ]),
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.initialColor ?? const Color(0xFF2196F3);
  }

  String _groupLabel(String key, AppLocalizations ctxt) {
    return switch (key) {
      'color_red' => ctxt.color_red,
      'color_pink' => ctxt.color_pink,
      'color_purple' => ctxt.color_purple,
      'color_indigo' => ctxt.color_indigo,
      'color_blue' => ctxt.color_blue,
      'color_cyan' => ctxt.color_cyan,
      'color_teal' => ctxt.color_teal,
      'color_green' => ctxt.color_green,
      'color_orange' => ctxt.color_orange,
      'color_brown' => ctxt.color_brown,
      'color_grey' => ctxt.color_grey,
      _ => key,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final ctxt = AppLocalizations.of(context)!;

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (!didPop) {
          Navigator.pop(context, _selected);
        }
      },
      child: Dialog(
        backgroundColor: color.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(spacing.radiusSmall),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: EdgeInsets.fromLTRB(
                  spacing.cardHorizontalMax,
                  spacing.cardHorizontal,
                  spacing.cardHorizontalMax,
                  0,
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.all(spacing.elementGap),
                      decoration: BoxDecoration(
                        color: _selected.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selected.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child:
                          Icon(LucideIcons.palette, color: _selected, size: 22),
                    ),
                    SizedBox(width: spacing.elementGap),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ctxt.colorPicker_title,
                            style: textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '#${_selected.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
                            style: textTheme.labelSmall?.copyWith(
                              color: color.onSurfaceVariant,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(context, _selected);
                      },
                      child: Text(
                        ctxt.common_done,
                        style: textTheme.titleSmall?.copyWith(
                          color: color.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: spacing.elementGap),
              Divider(
                height: 1,
                color: color.outlineVariant.withValues(alpha: 0.3),
              ),

              // Color grid
              Flexible(
                child: ListView.builder(
                  padding: EdgeInsets.fromLTRB(
                    spacing.cardHorizontalMax,
                    spacing.elementGap,
                    spacing.cardHorizontalMax,
                    spacing.cardHorizontal,
                  ),
                  itemCount: _palette.length,
                  itemBuilder: (context, index) {
                    final group = _palette[index];
                    return Padding(
                      padding:
                          EdgeInsets.only(bottom: spacing.elementGap * 1.5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _groupLabel(group.key, ctxt),
                            style: textTheme.labelSmall?.copyWith(
                              color: color.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: spacing.elementGap),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: group.colors.map((c) {
                              final isSelected =
                                  _selected.toARGB32() == c.toARGB32();
                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  setState(() => _selected = c);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: c,
                                    shape: BoxShape.circle,
                                    border: isSelected
                                        ? Border.all(
                                            color: color.onSurface,
                                            width: 2.5,
                                          )
                                        : null,
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: c.withValues(alpha: 0.4),
                                              blurRadius: 8,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: isSelected
                                      ? Icon(
                                          LucideIcons.check,
                                          color: c.computeLuminance() > 0.5
                                              ? Colors.black
                                              : Colors.white,
                                          size: 16,
                                        )
                                      : null,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorGroup {
  final String key;
  final List<Color> colors;
  const _ColorGroup(this.key, this.colors);
}
