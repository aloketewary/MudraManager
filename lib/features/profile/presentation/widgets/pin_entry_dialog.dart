import 'package:mudra_manager/core/tone/tone_provider.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PinEntryDialog extends StatefulWidget {
  /// Length of the PIN to collect
  final int length;
  const PinEntryDialog({super.key, this.length = 4});

  @override
  State<PinEntryDialog> createState() => _PinEntryDialogState();
}

class _PinEntryDialogState extends State<PinEntryDialog> {
  late List<int> _keys; // randomized digits 0–9
  final List<String> _input = [];

  @override
  void initState() {
    super.initState();
    _shuffleKeys();
  }

  void _shuffleKeys() {
    _keys = List.generate(10, (i) => i);
    _keys.shuffle(Random());
  }

  void _onKeyTap(int digit) {
    if (_input.length >= widget.length) return;
    setState(() => _input.add(digit.toString()));
    if (_input.length == widget.length) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (context.mounted) Navigator.of(context).pop(_input.join());
      });
    }
  }

  void _onBackspace() {
    if (_input.isEmpty) return;
    setState(() => _input.removeLast());
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tone.current.borderRadius)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Text('Enter PIN', style: textTheme.titleLarge),
          const SizedBox(height: 16),
          // Obscured input display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.length, (i) {
              final filled = i < _input.length;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled ? color.primary : Colors.grey.shade300,
                ),
              );
            }),
          ),
          const SizedBox(height: 24),

          // Numeric keypad grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 12, // 0–9 + blank + backspace
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              itemBuilder: (context, idx) {
                // positions 0–8: digits[0]..digits[8]
                // pos 9: digit[9]
                // pos 10: blank
                // pos 11: backspace
                if (idx < 10) {
                  final digit = _keys[idx];
                  return _buildKey(digit.toString(), () => _onKeyTap(digit));
                } else if (idx == 10) {
                  return const SizedBox.shrink();
                } else {
                  return _buildKey(const Icon(LucideIcons.delete), _onBackspace);
                }
              },
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildKey(Object label, VoidCallback onTap) {
    final color = Theme.of(context).colorScheme;
    Widget child;
    if (label is String) {
      child = Text(
        label,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: color.onSecondaryContainer,
        ),
      );
    } else {
      child = label as Widget;
    }

    return Material(
      color: color.onSecondary.withAlpha(80),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Center(child: child),
      ),
    );
  }
}
