import 'package:flutter/material.dart';

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
    ...Colors.primaries,
    ...Colors.accents.map((c) => c.shade100),
    ...Colors.primaries.map((c) => c.shade100),
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
    return AlertDialog(
      title: Text(
        'Pick a color',
        style: textTheme.titleLarge?.copyWith(color: color.onPrimaryContainer),
      ),
      content: SizedBox(
        height: 450,
        width: double.maxFinite,
        child: GridView.count(
          crossAxisCount: 5,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: _colors.map((c) {
            return GestureDetector(
              onTap: () => setState(() => _selected = c),
              child: CircleAvatar(
                backgroundColor: c,
                radius: 24,
                child: _selected.toARGB32() == c.toARGB32()
                    ? const Icon(Icons.check, color: Colors.white)
                    : null,
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, _selected),
          child: Text(
            'OK',
            style: textTheme.bodyLarge?.copyWith(
              color: color.onPrimaryContainer,
            ),
          ),
        ),
      ],
    );
  }
}
