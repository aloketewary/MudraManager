import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/theme/theme_preview_screen.dart';
import 'package:mudra_manager/theme/theme_provider.dart';
import 'package:mudra_manager/util/snackbar_service.dart';
import 'package:mudra_manager/l10n/app_localizations.dart';
import 'package:mudra_manager/components/responsive_helper.dart';

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
    final ctxt = context.mounted ? AppLocalizations.of(context)! : null;
    ref.read(themeNotifierProvider.notifier).setTheme(_tempSelectedTheme);
    SnackbarService.success(ctxt?.theme_themeAppliedMessage ?? "Theme applied!");
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(ctxt.theme_chooseThemeTitle)),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: ResponsiveHelper.getGridCrossAxisCount(context),
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: ResponsiveHelper.getGridAspectRatio(context, defaultRatio: 0.70, singleColumnRatio: 1.2),
        ),
        itemCount: AppColorTheme.values.length,
        itemBuilder: (context, index) {
          final theme = AppColorTheme.values[index];
          final isSelected = _tempSelectedTheme == theme;

          return Column(
            children: [
              Expanded(
                child: ThemePreviewCard(
                  theme: theme,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      _tempSelectedTheme = theme;
                    });
                  },
                ),
              ),
              const SizedBox(height: 12),
              Text(
                theme.name.toUpperCase(),
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color:
                      isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _applyTheme,
        icon: const Icon(Icons.check_circle_outline),
        label: Text(ctxt.theme_applyThemeLabel),
      ),
    );
  }
}
