import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/l10n/app_localizations.dart';
import 'package:mudra_manager/providers/l10n_provider.dart';
import 'package:mudra_manager/providers/shared_preference_provider.dart';
import 'package:mudra_manager/screens/home_screen.dart';
import 'package:mudra_manager/screens/onboarding/onboarding_screen.dart';
import 'package:mudra_manager/service/notification_service.dart';
import 'package:mudra_manager/theme/app_theme.dart';
import 'package:mudra_manager/theme/theme_provider.dart';
import 'package:mudra_manager/util/auth_gate.dart';
import 'package:mudra_manager/util/sms_transaction_util.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telephony/telephony.dart'; // Re-export setupSmsListener so it can be called from settings\nexport 'main.dart' show setupSmsListener;

final Telephony telephony = Telephony.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  // Workmanager().registerPeriodicTask(
  //   "budgetRollover",
  //   "budgetRolloverTask",
  //   frequency: const Duration(hours: 24),
  // );
  var sharedPrefs = await SharedPreferences.getInstance();
  SharedPrefsUtil.init(sharedPrefs);
  await NotificationService.initialize();

  final completed = SharedPrefsUtil.instance.isOnboardingComplete();

  // Set up SMS listener if user has enabled it
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

    return MaterialApp(
      title: 'Mudra Manager',
      theme: appTheme.buildLightTheme(appColorTheme),
      darkTheme: appTheme.buildDarkTheme(appColorTheme),
      themeMode: themeMode,
      // You can toggle this
      debugShowCheckedModeBanner: false,
      home: AuthGate(
        child: showOnboarding ? const OnboardingScreen() : const HomePage(),
      ),
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
  // Only set up listener if user has enabled SMS import
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

// Background handler for SMS received when app is closed
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
