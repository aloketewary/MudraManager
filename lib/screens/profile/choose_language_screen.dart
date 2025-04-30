import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/l10n/app_localizations.dart'
    show AppLocalizations;
import 'package:mudra_manager/providers/l10n_provider.dart';
import 'package:mudra_manager/util/localization_extension.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChooseLanguageScreen extends ConsumerStatefulWidget {
  const ChooseLanguageScreen({super.key});

  @override
  ConsumerState<ChooseLanguageScreen> createState() =>
      _ChooseLanguageScreenState();
}

class _ChooseLanguageScreenState extends ConsumerState<ChooseLanguageScreen> {
  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.read(localeProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Choose Language',
          style: textTheme.titleLarge?.copyWith(color: color.onPrimary),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...AppLocalizations.supportedLocales.map(
              (locale) => _buildLanguageTile(
                context,
                ref,
                language: locale.displayName(),
                locale: locale,
                isSelected: currentLocale.languageCode == locale.languageCode,
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  static Widget _buildLanguageTile(
    BuildContext context,
    WidgetRef ref, {
    required String language,
    required Locale locale,
    required bool isSelected,
  }) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListTile(
      leading: Icon(Icons.language),
      title: Text(language),
      trailing: isSelected ? Icon(Icons.check, color: color.primary) : null,
      onTap: () => LanguageService.changeLanguage(context, ref, locale),
    );
  }
}
