import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SimpleColorPickerDialog extends StatefulWidget {
  final Color? initialColor;

  const SimpleColorPickerDialog({super.key, this.initialColor});

  @override
  State<SimpleColorPickerDialog> createState() =>
      _SimpleColorPickerDialogState();
}

class _SimpleColorPickerDialogState extends State<SimpleColorPickerDialog> {
  late Color _selected;

  static const _palette = <_ColorGroup>[
    _ColorGroup('Red', [
      Color(0xFFFFCDD2),
      Color(0xFFEF9A9A),
      Color(0xFFE57373),
      Color(0xFFEF5350),
      Color(0xFFE53935),
      Color(0xFFD32F2F),
      Color(0xFFC62828),
      Color(0xFFB71C1C),
    ]),
    _ColorGroup('Pink', [
      Color(0xFFF8BBD0),
      Color(0xFFF48FB1),
      Color(0xFFEC407A),
      Color(0xFFE91E63),
      Color(0xFFD81B60),
      Color(0xFFC2185B),
      Color(0xFFAD1457),
      Color(0xFF880E4F),
    ]),
    _ColorGroup('Purple', [
      Color(0xFFE1BEE7),
      Color(0xFFCE93D8),
      Color(0xFFAB47BC),
      Color(0xFF9C27B0),
      Color(0xFF8E24AA),
      Color(0xFF7B1FA2),
      Color(0xFF6A1B9A),
      Color(0xFF4A148C),
    ]),
    _ColorGroup('Indigo', [
      Color(0xFFC5CAE9),
      Color(0xFF9FA8DA),
      Color(0xFF7986CB),
      Color(0xFF5C6BC0),
      Color(0xFF3F51B5),
      Color(0xFF3949AB),
      Color(0xFF283593),
      Color(0xFF1A237E),
    ]),
    _ColorGroup('Blue', [
      Color(0xFFBBDEFB),
      Color(0xFF90CAF9),
      Color(0xFF64B5F6),
      Color(0xFF42A5F5),
      Color(0xFF2196F3),
      Color(0xFF1E88E5),
      Color(0xFF1565C0),
      Color(0xFF0D47A1),
    ]),
    _ColorGroup('Cyan', [
      Color(0xFFB2EBF2),
      Color(0xFF80DEEA),
      Color(0xFF4DD0E1),
      Color(0xFF26C6DA),
      Color(0xFF00BCD4),
      Color(0xFF00ACC1),
      Color(0xFF00838F),
      Color(0xFF006064),
    ]),
    _ColorGroup('Teal', [
      Color(0xFFB2DFDB),
      Color(0xFF80CBC4),
      Color(0xFF4DB6AC),
      Color(0xFF26A69A),
      Color(0xFF009688),
      Color(0xFF00897B),
      Color(0xFF00695C),
      Color(0xFF004D40),
    ]),
    _ColorGroup('Green', [
      Color(0xFFC8E6C9),
      Color(0xFFA5D6A7),
      Color(0xFF81C784),
      Color(0xFF66BB6A),
      Color(0xFF4CAF50),
      Color(0xFF43A047),
      Color(0xFF2E7D32),
      Color(0xFF1B5E20),
    ]),
    _ColorGroup('Yellow', [
      Color(0xFFFFF9C4),
      Color(0xFFFFF176),
      Color(0xFFFFEE58),
      Color(0xFFFFEB3B),
      Color(0xFFFDD835),
      Color(0xFFFBC02D),
      Color(0xFFF9A825),
      Color(0xFFF57F17),
    ]),
    _ColorGroup('Orange', [
      Color(0xFFFFE0B2),
      Color(0xFFFFCC80),
      Color(0xFFFFB74D),
      Color(0xFFFFA726),
      Color(0xFFFF9800),
      Color(0xFFFB8C00),
      Color(0xFFEF6C00),
      Color(0xFFE65100),
    ]),
    _ColorGroup('Brown', [
      Color(0xFFD7CCC8),
      Color(0xFFBCAAA4),
      Color(0xFFA1887F),
      Color(0xFF8D6E63),
      Color(0xFF795548),
      Color(0xFF6D4C41),
      Color(0xFF5D4037),
      Color(0xFF3E2723),
    ]),
    _ColorGroup('Grey', [
      Color(0xFFCFD8DC),
      Color(0xFFB0BEC5),
      Color(0xFF90A4AE),
      Color(0xFF78909C),
      Color(0xFF607D8B),
      Color(0xFF546E7A),
      Color(0xFF455A64),
      Color(0xFF263238),
    ]),
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.initialColor ?? const Color(0xFF2196F3);
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      backgroundColor: color.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── HEADER with live preview ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _selected.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _selected.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      LucideIcons.palette,
                      color: _selected,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pick a Color',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
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
                  // Done button
                  TextButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      Navigator.pop(context, _selected);
                    },
                    child: Text(
                      'Done',
                      style: textTheme.titleSmall?.copyWith(
                        color: color.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Divider(
              height: 1,
              color: color.outlineVariant.withValues(alpha: 0.3),
            ),

            // ── COLOR GRID (grouped) ──
            Flexible(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                itemCount: _palette.length,
                itemBuilder: (context, index) {
                  final group = _palette[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          style: textTheme.labelSmall?.copyWith(
                            color: color.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
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
                                width: 34,
                                height: 34,
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
    );
  }
}

class _ColorGroup {
  final String name;
  final List<Color> colors;
  const _ColorGroup(this.name, this.colors);
}
