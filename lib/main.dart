import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:mudra_manager/l10n/app_localizations.dart';
import 'package:mudra_manager/providers/l10n_provider.dart';
import 'package:mudra_manager/providers/shared_preference_provider.dart';
import 'package:mudra_manager/router/app_router.dart';
import 'package:mudra_manager/service/bill_service.dart';
import 'package:mudra_manager/service/notification_service.dart';
import 'package:mudra_manager/service/recurring_transaction_scheduler.dart';
import 'package:mudra_manager/service/summary_scheduler.dart';
import 'package:mudra_manager/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/theme/app_theme.dart';
import 'package:mudra_manager/theme/theme_provider.dart';
import 'package:mudra_manager/util/sms_transaction_util.dart';
import 'package:mudra_manager/util/snackbar_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telephony/telephony.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:responsive_framework/responsive_framework.dart';

export 'main.dart' show setupSmsListener;

final Telephony telephony = Telephony.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var sharedPrefs = await SharedPreferences.getInstance();
  SharedPrefsUtil.init(sharedPrefs);
  
  // Initialize critical services first
  await NotificationService.initialize();
  
  // Move heavy operations to background
  _initializeBackgroundServices();

  final completed = SharedPrefsUtil.instance.isOnboardingComplete();
  setupSmsListener();

  runApp(ProviderScope(child: MudraManagerApp(showOnboarding: !completed)));
}

// Background initialization to prevent UI blocking
Future<void> _initializeBackgroundServices() async {
  Future.microtask(() async {
    await RecurringTransactionScheduler.initialize();
    await SummaryScheduler.checkAndShowSummaries();
    await BillService.scheduleBillReminders();
    await BillService.createPendingTransactionsForDueBills();
    await HomeWidget.setAppGroupId('group.mudra_manager');
    HomeWidget.registerInteractivityCallback(backgroundCallback);
  });
}

@pragma('vm:entry-point')
void backgroundCallback(Uri? uri) async {
  if (uri?.host == 'add_transaction') {
    await HomeWidget.setAppGroupId('group.mudra_manager');
  }
}

class MudraManagerApp extends ConsumerWidget {
  final bool showOnboarding;

  const MudraManagerApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appThemeMode = ref.watch(appThemeModeProvider);
    var appTheme = AppTheme.instance;
    final appColorTheme = ref.watch(themeNotifierProvider);
    final systemBrightness = MediaQuery.platformBrightnessOf(context);

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        ColorScheme lightColorScheme;
        ColorScheme darkColorScheme;
        ColorScheme amoledColorScheme;

        if (lightDynamic != null && darkDynamic != null) {
          lightColorScheme = lightDynamic.harmonized();
          darkColorScheme = darkDynamic.harmonized();
          amoledColorScheme = appColorTheme.amoledColorScheme();
        } else {
          lightColorScheme = appColorTheme.lightColorScheme();
          darkColorScheme = appColorTheme.darkColorScheme();
          amoledColorScheme = appColorTheme.amoledColorScheme();
        }

        ThemeData currentTheme;

        switch (appThemeMode) {
          case AppThemeMode.light:
            currentTheme = appTheme.buildLightThemeWithScheme(lightColorScheme);
            break;
          case AppThemeMode.dark:
            currentTheme = appTheme.buildDarkThemeWithScheme(darkColorScheme);
            break;
          case AppThemeMode.amoled:
            currentTheme = appTheme.buildDarkThemeWithScheme(amoledColorScheme);
            break;
          case AppThemeMode.system:
            currentTheme = systemBrightness == Brightness.light
                ? appTheme.buildLightThemeWithScheme(lightColorScheme)
                : appTheme.buildDarkThemeWithScheme(darkColorScheme);
            break;
        }

        return MaterialApp.router(
          title: 'Mudra Manager',
          theme: currentTheme,
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
          builder: (context, child) {
            NotificationService.setContext(context);
            return ResponsiveBreakpoints.builder(
              child: child!,
              breakpoints: [
                const Breakpoint(start: 0, end: 450, name: MOBILE),
                const Breakpoint(start: 451, end: 800, name: TABLET),
                const Breakpoint(start: 801, end: 1920, name: DESKTOP),
                const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
              ],
            );
          },
        );
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
