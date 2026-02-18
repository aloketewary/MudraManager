import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SimpleColorPickerDialog extends StatefulWidget {
  final Color? initialColor;

  const SimpleColorPickerDialog({super.key, this.initialColor});

  @override
  State<SimpleColorPickerDialog> createState() =>
      _SimpleColorPickerDialogState();
}

class _SimpleColorPickerDialogState extends State<SimpleColorPickerDialog> {
  late Color _selected;

  final List<Color> _colors = [
    // Reds
    const Color(0xFFE53935), const Color(0xFFD32F2F), const Color(0xFFC62828), const Color(0xFFB71C1C),
    const Color(0xFFFF5252), const Color(0xFFFF1744), const Color(0xFFD50000),
    // Pinks
    const Color(0xFFEC407A), const Color(0xFFE91E63), const Color(0xFFC2185B), const Color(0xFFAD1457),
    const Color(0xFFFF4081), const Color(0xFFF50057), const Color(0xFFC51162),
    // Purples
    const Color(0xFFAB47BC), const Color(0xFF9C27B0), const Color(0xFF8E24AA), const Color(0xFF7B1FA2),
    const Color(0xFFE040FB), const Color(0xFFD500F9), const Color(0xFFAA00FF),
    // Deep Purples
    const Color(0xFF7E57C2), const Color(0xFF673AB7), const Color(0xFF5E35B1), const Color(0xFF512DA8),
    const Color(0xFF7C4DFF), const Color(0xFF651FFF), const Color(0xFF6200EA),
    // Indigos
    const Color(0xFF5C6BC0), const Color(0xFF3F51B5), const Color(0xFF3949AB), const Color(0xFF283593),
    const Color(0xFF536DFE), const Color(0xFF3D5AFE), const Color(0xFF304FFE),
    // Blues
    const Color(0xFF42A5F5), const Color(0xFF2196F3), const Color(0xFF1E88E5), const Color(0xFF1565C0),
    const Color(0xFF448AFF), const Color(0xFF2979FF), const Color(0xFF2962FF),
    // Light Blues
    const Color(0xFF29B6F6), const Color(0xFF03A9F4), const Color(0xFF039BE5), const Color(0xFF0277BD),
    const Color(0xFF40C4FF), const Color(0xFF00B0FF), const Color(0xFF0091EA),
    // Cyans
    const Color(0xFF26C6DA), const Color(0xFF00BCD4), const Color(0xFF00ACC1), const Color(0xFF00838F),
    const Color(0xFF18FFFF), const Color(0xFF00E5FF), const Color(0xFF00B8D4),
    // Teals
    const Color(0xFF26A69A), const Color(0xFF009688), const Color(0xFF00897B), const Color(0xFF00695C),
    const Color(0xFF64FFDA), const Color(0xFF1DE9B6), const Color(0xFF00BFA5),
    // Greens
    const Color(0xFF66BB6A), const Color(0xFF4CAF50), const Color(0xFF43A047), const Color(0xFF2E7D32),
    const Color(0xFF69F0AE), const Color(0xFF00E676), const Color(0xFF00C853),
    // Light Greens
    const Color(0xFF9CCC65), const Color(0xFF8BC34A), const Color(0xFF7CB342), const Color(0xFF558B2F),
    const Color(0xFFB2FF59), const Color(0xFF76FF03), const Color(0xFF64DD17),
    // Limes
    const Color(0xFFD4E157), const Color(0xFFCDDC39), const Color(0xFFC0CA33), const Color(0xFFAFB42B),
    const Color(0xFFEEFF41), const Color(0xFFC6FF00), const Color(0xFFAEEA00),
    // Yellows
    const Color(0xFFFFEE58), const Color(0xFFFFEB3B), const Color(0xFFFDD835), const Color(0xFFF9A825),
    const Color(0xFFFFFF00), const Color(0xFFFFEA00), const Color(0xFFFFD600),
    // Ambers
    const Color(0xFFFFCA28), const Color(0xFFFFC107), const Color(0xFFFFB300), const Color(0xFFFF8F00),
    const Color(0xFFFFD740), const Color(0xFFFFC400), const Color(0xFFFFAB00),
    // Oranges
    const Color(0xFFFFA726), const Color(0xFFFF9800), const Color(0xFFFB8C00), const Color(0xFFEF6C00),
    const Color(0xFFFFAB40), const Color(0xFFFF9100), const Color(0xFFFF6D00),
    // Deep Oranges
    const Color(0xFFFF7043), const Color(0xFFFF5722), const Color(0xFFF4511E), const Color(0xFFD84315),
    const Color(0xFFFF6E40), const Color(0xFFFF3D00), const Color(0xFFDD2C00),
    // Browns
    const Color(0xFF8D6E63), const Color(0xFF795548), const Color(0xFF6D4C41), const Color(0xFF5D4037),
    const Color(0xFF4E342E), const Color(0xFF3E2723),
    // Greys
    const Color(0xFF757575), const Color(0xFF616161), const Color(0xFF424242), const Color(0xFF212121),
    const Color(0xFF9E9E9E), const Color(0xFF78909C), const Color(0xFF546E7A),
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.initialColor ?? Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    var color = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;
    
    return Dialog(
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        decoration: BoxDecoration(
          color: color.surface,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _selected.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.palette, color: _selected, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Pick a Color',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 5,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: _colors.map((c) {
                    final isSelected = _selected.toARGB32() == c.toARGB32();
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        setState(() => _selected = c);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: color.outline, width: 3)
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 24)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    Navigator.pop(context, _selected);
                  },
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'SELECT COLOR',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
