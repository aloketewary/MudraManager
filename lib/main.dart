import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/l10n/app_localizations.dart';
import 'package:mudra_manager/providers/l10n_provider.dart';
import 'package:mudra_manager/providers/shared_preference_provider.dart';
import 'package:mudra_manager/router/app_router.dart';
import 'package:mudra_manager/service/notification_service.dart';
import 'package:mudra_manager/theme/app_theme.dart';
import 'package:mudra_manager/theme/theme_provider.dart';
import 'package:mudra_manager/util/sms_transaction_util.dart';
import 'package:mudra_manager/util/snackbar_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telephony/telephony.dart';

export 'main.dart' show setupSmsListener;

final Telephony telephony = Telephony.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var sharedPrefs = await SharedPreferences.getInstance();
  SharedPrefsUtil.init(sharedPrefs);
  await NotificationService.initialize();

  final completed = SharedPrefsUtil.instance.isOnboardingComplete();
  setupSmsListener();

  runApp(ProviderScope(child: MudraManagerApp(showOnboarding: !completed)));
}

class MudraManagerApp extends ConsumerWidget {
  final bool showOnboarding;

  const MudraManagerApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    var appTheme = AppTheme.instance;
    final appColorTheme = ref.watch(themeNotifierProvider);

    return MaterialApp.router(
      title: 'Mudra Manager',
      theme: appTheme.buildLightTheme(appColorTheme),
      darkTheme: appTheme.buildDarkTheme(appColorTheme),
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: SnackbarService.scaffoldMessengerKey,
      routerConfig: AppRouter.router(showOnboarding),
      locale: ref.watch(localeProvider),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      localeResolutionCallback: (locale, supportedLocales) {
        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale?.languageCode) {
            return supportedLocale;
          }
        }
        return supportedLocales.first;
      },
    );
  }
}

Future<void> setupSmsListener() async {
  if (!SharedPrefsUtil.instance.getSmsImportEnabled()) {
    debugPrint('SMS import is disabled, skipping listener setup');
    return;
  }

  final bool? permissionsGranted = await telephony.requestSmsPermissions;

  if (permissionsGranted ?? false) {
    debugPrint('Setting up SMS listener for automatic transaction detection');
    telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) {
        SmsProcessorService.instance.parseAndSaveTransaction(
          body: message.body ?? '',
          address: message.address ?? '',
          sender: message.address,
          timestamp: message.date ?? DateTime.now().millisecondsSinceEpoch,
        );
      },
      listenInBackground: true,
      onBackgroundMessage: backgroundMessageHandler,
    );
  } else {
    debugPrint('SMS permissions not granted');
  }
}

@pragma('vm:entry-point')
void backgroundMessageHandler(SmsMessage message) {
  debugPrint('Background SMS received from: ${message.address}');
  SmsProcessorService.instance.parseAndSaveTransaction(
    body: message.body ?? '',
    address: message.address ?? '',
    sender: message.address,
    timestamp: message.date ?? DateTime.now().millisecondsSinceEpoch,
  );
}
