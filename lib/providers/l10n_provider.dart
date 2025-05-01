import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/l10n/app_localizations.dart';
import 'package:mudra_manager/providers/shared_preference_provider.dart';
import 'package:mudra_manager/util/localization_extension.dart';

final localeProvider = StateProvider<Locale>((ref) {
  try {
    var language = SharedPrefsUtil.instance.getLanguage();
    return Locale(language);
  } catch(exception) {
    return const Locale('en');
  }

});

final languageService = StateProvider<LanguageService>((ref) {
  return LanguageService();
});

class LanguageService {
  static void changeLanguage(
    BuildContext context,
    WidgetRef ref,
    Locale newLocale,
  ) {
    SharedPrefsUtil.instance.setLanguage(newLocale.languageCode);
    ref.read(localeProvider.notifier).state = newLocale;
  }

  static void showLanguagePicker(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.read(localeProvider);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
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
        );
      },
    );
  }

  static Widget _buildLanguageTile(
    BuildContext context,
    WidgetRef ref, {
    required String language,
    required Locale locale,
    required bool isSelected,
  }) {
    return ListTile(
      leading: Icon(Icons.language),
      title: Text(language),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
      onTap: () => changeLanguage(context, ref, locale),
    );
  }
}
