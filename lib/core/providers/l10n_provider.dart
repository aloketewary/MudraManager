import 'package:mudra_manager/core/tone/tone_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/extension/localization_extenstion.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';


final localeProvider = NotifierProvider<_LocaleNotifier, Locale>(_LocaleNotifier.new);

class _LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    try {
      final language = SharedPrefsUtil.instance.getLanguage();
      return Locale(language);
    } catch (_) {
      return const Locale('en');
    }
  }

  void set(Locale value) => state = value;
}

final languageService = Provider<LanguageService>((ref) => LanguageService());

class LanguageService {
  static void changeLanguage(
    BuildContext context,
    WidgetRef ref,
    Locale newLocale,
  ) {
    SharedPrefsUtil.instance.setLanguage(newLocale.languageCode);
    ref.read(localeProvider.notifier).set(newLocale);
  }

  static void showLanguagePicker(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.read(localeProvider);

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Tone.current.borderRadius * 2)),
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
      leading: const Icon(LucideIcons.languages),
      title: Text(language),
      trailing: isSelected ? const Icon(LucideIcons.check, color: Colors.blue) : null,
      onTap: () => changeLanguage(context, ref, locale),
    );
  }
}
