import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/theme/theme_preview_screen.dart';
import 'package:mudra_manager/theme/theme_provider.dart';

class ThemePickerScreen extends ConsumerStatefulWidget {
  const ThemePickerScreen({super.key});

  @override
  ConsumerState<ThemePickerScreen> createState() => _ThemePickerScreenState();
}

class _ThemePickerScreenState extends ConsumerState<ThemePickerScreen> {
  late AppColorTheme _tempSelectedTheme;

  @override
  void initState() {
    super.initState();
    _tempSelectedTheme = ref.read(themeNotifierProvider);
  }

  void _applyTheme() {
    ref.read(themeNotifierProvider.notifier).setTheme(_tempSelectedTheme);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Theme applied!")));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Choose Theme",
          style: textTheme.titleLarge?.copyWith(color: color.onPrimary),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children:
            AppColorTheme.values.map((theme) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(theme.name.toUpperCase(), style: textTheme.titleMedium),
                  ThemePreviewCard(
                    theme: theme,
                    isSelected: _tempSelectedTheme == theme,
                    onTap: () {
                      setState(() {
                        _tempSelectedTheme = theme;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              );
            }).toList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _applyTheme,
        icon: const Icon(Icons.save),
        label: const Text("Apply"),
      ),
    );
  }
}
