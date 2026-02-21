import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/providers/l10n_provider.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';
import 'package:mudra_manager/core/router/app_router.dart';
import 'package:mudra_manager/core/services/app_update_service.dart';
import 'package:mudra_manager/core/services/notification_service.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/core/theme/app_theme.dart';
import 'package:mudra_manager/core/theme/theme_provider.dart';
import 'package:mudra_manager/core/utils/error_handler.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:mudra_manager/features/budget/data/bill_service.dart';
import 'package:mudra_manager/features/dashboard/data/summary_scheduler.dart';
import 'package:mudra_manager/features/sms/data/sms_cleanup_service.dart';
import 'package:mudra_manager/features/sms/data/sms_processor_service.dart';
import 'package:mudra_manager/features/transactions/data/recurring_transaction_scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:another_telephony/telephony.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:responsive_framework/responsive_framework.dart';

export 'main.dart' show setupSmsListener;

final Telephony telephony = Telephony.instance;

void main() async {
  final log = AppLog(getLogger(), 'Main');
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  final sharedPrefs = await SharedPreferences.getInstance();
  SharedPrefsUtil.init(sharedPrefs);

  log.i('App starting...');

  // Initialize critical services first
  await NotificationService.initialize();

  final completed = SharedPrefsUtil.instance.isOnboardingComplete();
  setupSmsListener();

  final container = ProviderContainer();
  // Move heavy operations to background
  _initializeBackgroundServices(container);

  runApp(UncontrolledProviderScope(
    container: container,
    child: MudraManagerApp(showOnboarding: !completed),
  ));
}

// Background initialization to prevent UI blocking
Future<void> _initializeBackgroundServices(ProviderContainer container) async {
  final log = AppLog(getLogger(), 'Init');
  Future.microtask(() async {
    // 1. Initialize Isar first
    log.i('🔄 Initializing Isar...');
    final isar = await safeExecute(() => container.read(isarServiceProvider).getInstance());
    if (isar != null) {
      log.i('✅ Isar initialized');
    } else {
      log.e('❌ Isar initialization failed');
      return;
    }
    
    // 2. Initialize gamification service (depends on Isar)
    log.i('🔄 Initializing Gamification service...');
    final gamification = await safeExecute(() => container.read(gamificationServiceInitProvider.future));
    if (gamification != null) {
      log.i('✅ Gamification service initialized');
    } else {
      log.e('❌ Gamification service initialization failed');
    }

    // 3. Run other services in parallel
    log.i('🔄 Initializing background services...');
    await Future.wait(
      [
        safeExecute(() async {
          await RecurringTransactionScheduler.initialize();
          log.i('✅ RecurringTransactionScheduler initialized');
        }),
        safeExecute(() async {
          await SummaryScheduler.checkAndShowSummaries();
          log.i('✅ SummaryScheduler initialized');
        }),
        safeExecute(() async {
          await BillService.scheduleBillReminders();
          log.i('✅ BillService reminders scheduled');
        }),
        safeExecute(() async {
          await BillService.createPendingTransactionsForDueBills();
          log.i('✅ BillService pending transactions created');
        }),
        safeExecute(() async {
          await _initializeHomeWidget();
          log.i('✅ HomeWidget initialized');
        }),
        safeExecute(() async {
          await SmsHashCleanupService.cleanupOldHashes();
          log.i('✅ SmsHashCleanupService initialized');
        }),
      ].map((f) => f.catchError((e) => null)),
    );
    log.i('✅ All background services initialized');
  });
}

Future<void> _initializeHomeWidget() async {
  await HomeWidget.setAppGroupId('group.mudra_manager');
  HomeWidget.registerInteractivityCallback(backgroundCallback);
}

@pragma('vm:entry-point')
void backgroundCallback(Uri? uri) async {
  if (uri?.host == 'add_transaction') {
    await HomeWidget.setAppGroupId('group.mudra_manager');
    // Navigation handled by widgetClicked listener in home screen
  }
}

class MudraManagerApp extends ConsumerWidget {
  final bool showOnboarding;

  const MudraManagerApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appThemeMode = ref.watch(themeModeProvider);
    final appTheme = AppTheme.instance;
    final appColorTheme = ref.watch(themeNotifierProvider);

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        ColorScheme lightScheme;
        ColorScheme darkScheme;
        ColorScheme amoledScheme;

        if (appColorTheme == AppColorTheme.dynamic &&
            lightDynamic != null &&
            darkDynamic != null) {
          lightScheme = lightDynamic.harmonized();
          darkScheme = darkDynamic.harmonized();
          amoledScheme = darkDynamic.harmonized().copyWith(
            surface: Colors.black,
          ); // Using black for amoled
        } else {
          lightScheme = appColorTheme.lightColorScheme();
          darkScheme = appColorTheme.darkColorScheme();
          amoledScheme = appColorTheme.amoledColorScheme();
        }

        final router = AppRouter.router(showOnboarding);
        return MaterialApp.router(
          title: 'Mudra Manager',
          theme: appTheme.buildTheme(lightScheme),
          darkTheme: appThemeMode == AppThemeMode.amoled
              ? appTheme.buildTheme(amoledScheme)
              : appTheme.buildTheme(darkScheme),
          themeMode: switch (appThemeMode) {
            AppThemeMode.light => ThemeMode.light,
            AppThemeMode.dark => ThemeMode.dark,
            AppThemeMode.amoled => ThemeMode.dark,
            AppThemeMode.system => ThemeMode.system,
          },
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: SnackbarService.scaffoldMessengerKey,
          routerConfig: router,
          locale: ref.watch(localeProvider),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          localeResolutionCallback: (locale, supportedLocales) {
            if (locale == null) return supportedLocales.first;

            return supportedLocales.firstWhere(
              (l) => l.languageCode == locale.languageCode,
              orElse: () => supportedLocales.first,
            );
          },
          builder: (context, child) {
            NotificationService.setContext(context);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              AppUpdateService.checkForUpdate(context);
            });
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
          themeAnimationCurve: Curves.easeOutCubic,
          themeAnimationDuration: const Duration(milliseconds: 350),
        );
      },
    );
  }
}

Future<void> setupSmsListener() async {
  final log = AppLog(getLogger(), 'SMS');
  if (!SharedPrefsUtil.instance.getSmsImportEnabled()) {
    log.i('SMS import disabled');
    return;
  }

  final telephony = Telephony.instance;
  final bool? permissionsGranted =
      await telephony.requestPhoneAndSmsPermissions;

  if (permissionsGranted == true) {
    log.i('SMS listener setup complete');
    telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) {
        SmsProcessorService.instance.parseAndSaveTransaction(
          body: message.body ?? '',
          address: message.address ?? '',
          sender: message.address ?? '',
          timestamp: message.date ?? DateTime.now().millisecondsSinceEpoch,
        );
      },
      listenInBackground: true,
      onBackgroundMessage: backgroundMessageHandler,
    );
  } else {
    log.w('SMS permissions not granted');
  }
}

@pragma('vm:entry-point')
void backgroundMessageHandler(SmsMessage message) {
  final log = AppLog(getLogger(), 'SMS');
  log.i('Background SMS received from: ${message.address}');
  SmsProcessorService.instance.parseAndSaveTransaction(
    body: message.body ?? '',
    address: message.address ?? '',
    sender: message.address ?? '',
    timestamp: message.date ?? DateTime.now().millisecondsSinceEpoch,
  );
}
