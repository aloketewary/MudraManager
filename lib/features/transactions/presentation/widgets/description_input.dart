import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';

class DescriptionInput extends StatelessWidget {
  final TextEditingController controller;
  final String? hintText;
  final int maxLines;

  const DescriptionInput({
    super.key,
    required this.controller,
    this.hintText,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: 'Description',
        hintText: hintText ?? 'Enter description',
        prefixIcon: const Icon(LucideIcons.fileText),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
