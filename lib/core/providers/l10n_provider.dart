import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/extension/localization_extenstion.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';

final localeProvider =
    NotifierProvider<_LocaleNotifier, Locale>(_LocaleNotifier.new);

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
    final spacing = ref.watch(spacingProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(spacing.radiusSmall * 2),
        ),
      ),
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.45,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          final color = Theme.of(context).colorScheme;

          return Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: color.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Consumer(
                  builder: (context, sheetRef, _) {
                    final currentLocale = sheetRef.watch(localeProvider);

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.only(bottom: 10),
                      itemCount: AppLocalizations.supportedLocales.length,
                      itemBuilder: (context, index) {
                        final locale = AppLocalizations.supportedLocales[index];
                        return _buildLanguageTile(
                          sheetContext,
                          sheetRef,
                          language: locale.displayName(),
                          locale: locale,
                          isSelected:
                              currentLocale.languageCode == locale.languageCode,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
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
    return ListTile(
      leading: const Icon(LucideIcons.languages),
      title: Text(language),
      trailing:
          isSelected ? const Icon(LucideIcons.check, color: Colors.blue) : null,
      onTap: () => changeLanguage(context, ref, locale),
    );
  }
}
