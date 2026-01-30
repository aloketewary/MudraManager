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
    Color(0xFFE53935), Color(0xFFD32F2F), Color(0xFFC62828), Color(0xFFB71C1C),
    Color(0xFFFF5252), Color(0xFFFF1744), Color(0xFFD50000),
    // Pinks
    Color(0xFFEC407A), Color(0xFFE91E63), Color(0xFFC2185B), Color(0xFFAD1457),
    Color(0xFFFF4081), Color(0xFFF50057), Color(0xFFC51162),
    // Purples
    Color(0xFFAB47BC), Color(0xFF9C27B0), Color(0xFF8E24AA), Color(0xFF7B1FA2),
    Color(0xFFE040FB), Color(0xFFD500F9), Color(0xFFAA00FF),
    // Deep Purples
    Color(0xFF7E57C2), Color(0xFF673AB7), Color(0xFF5E35B1), Color(0xFF512DA8),
    Color(0xFF7C4DFF), Color(0xFF651FFF), Color(0xFF6200EA),
    // Indigos
    Color(0xFF5C6BC0), Color(0xFF3F51B5), Color(0xFF3949AB), Color(0xFF283593),
    Color(0xFF536DFE), Color(0xFF3D5AFE), Color(0xFF304FFE),
    // Blues
    Color(0xFF42A5F5), Color(0xFF2196F3), Color(0xFF1E88E5), Color(0xFF1565C0),
    Color(0xFF448AFF), Color(0xFF2979FF), Color(0xFF2962FF),
    // Light Blues
    Color(0xFF29B6F6), Color(0xFF03A9F4), Color(0xFF039BE5), Color(0xFF0277BD),
    Color(0xFF40C4FF), Color(0xFF00B0FF), Color(0xFF0091EA),
    // Cyans
    Color(0xFF26C6DA), Color(0xFF00BCD4), Color(0xFF00ACC1), Color(0xFF00838F),
    Color(0xFF18FFFF), Color(0xFF00E5FF), Color(0xFF00B8D4),
    // Teals
    Color(0xFF26A69A), Color(0xFF009688), Color(0xFF00897B), Color(0xFF00695C),
    Color(0xFF64FFDA), Color(0xFF1DE9B6), Color(0xFF00BFA5),
    // Greens
    Color(0xFF66BB6A), Color(0xFF4CAF50), Color(0xFF43A047), Color(0xFF2E7D32),
    Color(0xFF69F0AE), Color(0xFF00E676), Color(0xFF00C853),
    // Light Greens
    Color(0xFF9CCC65), Color(0xFF8BC34A), Color(0xFF7CB342), Color(0xFF558B2F),
    Color(0xFFB2FF59), Color(0xFF76FF03), Color(0xFF64DD17),
    // Limes
    Color(0xFFD4E157), Color(0xFFCDDC39), Color(0xFFC0CA33), Color(0xFFAFB42B),
    Color(0xFFEEFF41), Color(0xFFC6FF00), Color(0xFFAEEA00),
    // Yellows
    Color(0xFFFFEE58), Color(0xFFFFEB3B), Color(0xFFFDD835), Color(0xFFF9A825),
    Color(0xFFFFFF00), Color(0xFFFFEA00), Color(0xFFFFD600),
    // Ambers
    Color(0xFFFFCA28), Color(0xFFFFC107), Color(0xFFFFB300), Color(0xFFFF8F00),
    Color(0xFFFFD740), Color(0xFFFFC400), Color(0xFFFFAB00),
    // Oranges
    Color(0xFFFFA726), Color(0xFFFF9800), Color(0xFFFB8C00), Color(0xFFEF6C00),
    Color(0xFFFFAB40), Color(0xFFFF9100), Color(0xFFFF6D00),
    // Deep Oranges
    Color(0xFFFF7043), Color(0xFFFF5722), Color(0xFFF4511E), Color(0xFFD84315),
    Color(0xFFFF6E40), Color(0xFFFF3D00), Color(0xFFDD2C00),
    // Browns
    Color(0xFF8D6E63), Color(0xFF795548), Color(0xFF6D4C41), Color(0xFF5D4037),
    Color(0xFF4E342E), Color(0xFF3E2723),
    // Greys
    Color(0xFF757575), Color(0xFF616161), Color(0xFF424242), Color(0xFF212121),
    Color(0xFF9E9E9E), Color(0xFF78909C), Color(0xFF546E7A),
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
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: color.surface,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _selected.withValues(alpha: 0.8),
                    _selected,
                  ],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Text(
                'Pick a Color',
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(24),
              child: SizedBox(
                height: 400,
                child: GridView.count(
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
                        duration: Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: c.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        child: isSelected
                            ? Icon(Icons.check, color: Colors.white, size: 24)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 24, right: 24, bottom: 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    Navigator.pop(context, _selected);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _selected,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: _selected.withValues(alpha: 0.4),
                  ),
                  child: Text(
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
