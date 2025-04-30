import 'package:flutter/material.dart';

class SimpleColorPickerDialog extends StatefulWidget {
  final Color? initialColor;

  const SimpleColorPickerDialog({super.key, this.initialColor});

  @override
  State<SimpleColorPickerDialog> createState() => _SimpleColorPickerDialogState();
}

class _SimpleColorPickerDialogState extends State<SimpleColorPickerDialog> {
  late Color _selected;

  final List<Color> _colors = Colors.primaries;

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
      title: Text('Pick a color', style: textTheme.titleLarge?.copyWith(color: color.onPrimaryContainer),),
      content: Wrap(
        spacing: 25,
        runSpacing: 25,
        children: _colors
            .map((c) => GestureDetector(
          onTap: () => setState(() => _selected = c),
          child: CircleAvatar(
            backgroundColor: c,
            radius: 30,
            child: _selected.toARGB32() == c.toARGB32() ? const Icon(Icons.check, color: Colors.white) : null,
          ),
        ))
            .toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, _selected),
          child: Text('OK', style: textTheme.bodyLarge?.copyWith(color: color.onPrimaryContainer),),
        ),
      ],
    );
  }
}
