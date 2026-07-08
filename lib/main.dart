import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/db/models/trip.dart';
import 'package:mudra_manager/core/entitlement/billing_provider.dart';
import 'package:mudra_manager/core/entitlement/entitlement_provider.dart';
import 'package:mudra_manager/core/entitlement/entitlement_service.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/services/plugin_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:mudra_manager/core/db/category_seeder.dart';
import 'package:mudra_manager/core/db/field_encryption_service.dart';
import 'package:mudra_manager/core/db/encryption_migration.dart';
import 'package:mudra_manager/core/db/account_encryption_migration.dart';
import 'package:mudra_manager/core/db/account_suffix_hash_migration.dart';
import 'package:mudra_manager/core/db/pin_migration.dart';
import 'package:mudra_manager/core/db/signal_fields_migration.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/providers/l10n_provider.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';
import 'package:mudra_manager/core/router/app_router.dart';
import 'package:mudra_manager/core/services/app_update_service.dart';
import 'package:mudra_manager/core/services/background_task_manager.dart';
import 'package:mudra_manager/core/services/auto_backup_service.dart';
import 'package:mudra_manager/core/services/notification_service.dart';
import 'package:mudra_manager/core/skin/skin.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/core/theme/app_theme.dart';
import 'package:mudra_manager/core/theme/theme_provider.dart';
import 'package:mudra_manager/core/tone/tone_provider.dart';
import 'package:mudra_manager/core/utils/error_handler.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:mudra_manager/features/marketplace/services/marketplace_service.dart';
import 'package:mudra_manager/features/sms/data/notification_listener_service.dart';
import 'package:mudra_manager/core/utils/overflow_detector.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:responsive_framework/responsive_framework.dart';

void main() async {
  final log = AppLog(getLogger(), 'Main');
  WidgetsFlutterBinding.ensureInitialized();
  OverflowDetector.init();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  final sharedPrefs = await SharedPreferences.getInstance();
  SharedPrefsUtil.init(sharedPrefs);
  NotificationListenerBridge.instance.initialize();
  if (kDebugMode) {
    sharedPrefs.remove('has_seen_swipe_peek');
    debugPrint('🔍 PEEK: cleared has_seen_swipe_peek');
  }

  log.i('App starting...');

  // Initialize plugin system
  await PluginService().initialize();

  // Initialize critical services first
  await NotificationService.initialize();

  final completed = SharedPrefsUtil.instance.isOnboardingComplete();

  final container = ProviderContainer();
  // Move heavy operations to background
  _initializeBackgroundServices(container);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: MudraManagerApp(showOnboarding: !completed),
    ),
  );
}

void invalidateEntitlementsFromRef(Ref ref) {
  ref.invalidate(isProProvider);
  ref.invalidate(proPlanInfoProvider);
  ref.invalidate(hasFullAccessProvider);
  ref.invalidate(isInTrialProvider);
  ref.invalidate(trialDaysRemainingProvider);
}

// Background initialization to prevent UI blocking
Future<void> _initializeBackgroundServices(ProviderContainer container) async {
  final log = AppLog(getLogger(), 'Init');
  Future.microtask(() async {
    // 1. Initialize Isar first (critical — needed for UI)
    log.i('🔄 Initializing Isar...');
    final isar = await safeExecute(
      () => container.read(isarServiceProvider).getInstance(),
    );
    if (isar == null) {
      log.e('❌ Isar initialization failed');
      return;
    }
    log.i('✅ Isar initialized');

    // 2. Initialize field encryption (needs Android Keystore / iOS Keychain)
    await safeExecute(() async {
      await FieldEncryptionService.initialize();
      log.i('✅ Field encryption initialized');
    });

    // 3. Critical seeds (fast, needed before UI renders categories)
    await safeExecute(() async {
      await CategorySeeder.seedDefaultKeywords(isar);
      await CategorySeeder.seedSystemCategories(isar);
      log.i('✅ Categories seeded');
    });

    // 4. Entitlement (needed for pro gates in UI)
    await safeExecute(() async {
      final entitlement =
          EntitlementService(container.read(isarServiceProvider));
      await entitlement.stampInstallDate();
      await entitlement.snapshotGrandfatheredCounts();
      final isPro = await entitlement.isPro();
      final inTrial = await entitlement.isInTrialPeriod();
      if (!isPro && !inTrial) {
        await MarketplaceService().disableProPlugins();
      }
      log.i('✅ Entitlement initialized');
    });

    // 5. Schedule workmanager (no heavy work, just registers)
    await safeExecute(() async {
      await BackgroundTaskManager.initialize();
      log.i('✅ Background tasks scheduled');
    });

    // 6. Defer everything else — run 3s after UI is visible
    Future.delayed(const Duration(seconds: 3), () async {
      await safeExecute(() async {
        final billing = container.read(billingServiceProvider);
        await billing.initialize();
        log.i('✅ Billing initialized (deferred)');
      });

      await safeExecute(() async {
        await CategorySeeder.seedCategoryIcons(isar);
        log.i('✅ Category icons synced (deferred)');
      });

      await safeExecute(() async {
        await container.read(gamificationServiceInitProvider.future);
        log.i('✅ Gamification initialized (deferred)');
      });

      await safeExecute(() async {
        await _initializeHomeWidget();
        log.i('✅ HomeWidget initialized (deferred)');
      });

      // Migrations (one-time, guarded by SharedPrefs flags)
      await safeExecute(() => _migrateTransactionFields(isar));
      await safeExecute(() => _migrateCategoryAndParticipantFields(isar));
      await safeExecute(() => EncryptionMigration.run(isar));
      await safeExecute(() => AccountEncryptionMigration.run(isar));
      await safeExecute(() => AccountSuffixHashMigration.run(isar));
      await safeExecute(() => PinMigration.run());
      await safeExecute(() => SignalFieldsMigration.run(isar));

      // Run recurring/bill/notification tasks
      await BackgroundTaskManager.runDeferredTasks();

      // Cleanup old auto backups (rolling 7-day retention)
      await safeExecute(() => AutoBackupService.cleanupOldBackups());

      log.i('✅ All deferred tasks completed');

      // Check for app updates (once per session)
      await safeExecute(() => AppUpdateService.checkForUpdate());
    });
  });
}

/// One-time migration: seed isSettlement and isSharedExpense on old transactions.
/// Isar stores null for fields that didn't exist when the record was created.
/// This ensures query filters like isSettlementEqualTo(false) work correctly.
Future<void> _migrateTransactionFields(Isar isar) async {
  final prefs = await SharedPreferences.getInstance();
  const key = 'migration_txn_settlement_v1';
  if (prefs.getBool(key) == true) return; // already done

  final all = await isar.transactions.where().findAll();
  if (all.isEmpty) {
    await prefs.setBool(key, true);
    return;
  }

  await isar.writeTxn(() async {
    for (final txn in all) {
      // Dart defaults are false, but Isar may have null on disk.
      // Re-putting ensures the field is written.
      await isar.transactions.put(txn);
    }
  });

  await prefs.setBool(key, true);
}

/// One-time migration: seed isSystem on old categories and isOwner on old participants.
Future<void> _migrateCategoryAndParticipantFields(Isar isar) async {
  final prefs = await SharedPreferences.getInstance();
  const key = 'migration_category_system_v1';
  if (prefs.getBool(key) == true) return;

  // Re-put all categories to write isSystem = false to disk
  final categories = await isar.categorys.where().findAll();
  if (categories.isNotEmpty) {
    await isar.writeTxn(() async {
      for (final cat in categories) {
        await isar.categorys.put(cat);
      }
    });
  }

  // Re-put all trip participants to write isOwner = false to disk
  final participants = await isar.tripParticipants.where().findAll();
  if (participants.isNotEmpty) {
    await isar.writeTxn(() async {
      for (final p in participants) {
        await isar.tripParticipants.put(p);
      }
    });
  }

  // Re-put all accounts to write isPrimary = false to disk
  // Then set the first active account as primary if none exists
  final accounts = await isar.accounts.where().findAll();
  if (accounts.isNotEmpty) {
    final hasPrimary = accounts.any((a) => a.isPrimary);
    await isar.writeTxn(() async {
      for (final acc in accounts) {
        await isar.accounts.put(acc);
      }
      // Auto-set first active account as primary
      if (!hasPrimary) {
        final first = accounts.where((a) => a.isActive).firstOrNull;
        if (first != null) {
          first.isPrimary = true;
          await isar.accounts.put(first);
        }
      }
    });
  }

  await prefs.setBool(key, true);
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

class MudraManagerApp extends ConsumerStatefulWidget {
  final bool showOnboarding;

  const MudraManagerApp({super.key, required this.showOnboarding});
  @override
  ConsumerState<MudraManagerApp> createState() => _MudraManagerAppState();
}

class _MudraManagerAppState extends ConsumerState<MudraManagerApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AppRouter.router(widget.showOnboarding);
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeTone = ref.watch(tonePackProvider);
    final activeSkin = ref.watch(activeSkinProvider).value;
    final spacing = ref.watch(spacingProvider);
    // Merge skin style into tone for radii/elevation
    final effectiveTone = activeSkin != null
        ? SkinAwareTone(activeTone, activeSkin.style)
        : activeTone;
    Tone.sync(effectiveTone);

    final appThemeMode = ref.watch(themeModeProvider);
    final appTheme = AppTheme.instance;

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        ColorScheme lightScheme;
        ColorScheme darkScheme;
        ColorScheme amoledScheme;

        if (activeSkin != null && activeSkin.id == 'dynamic' &&
            lightDynamic != null &&
            darkDynamic != null) {
          lightScheme = lightDynamic.harmonized();
          darkScheme = darkDynamic.harmonized();
          amoledScheme = darkDynamic.harmonized().copyWith(
                surface: Colors.black,
              );
        } else if (activeSkin != null) {
          lightScheme = SkinToTheme.lightScheme(activeSkin);
          darkScheme = SkinToTheme.darkScheme(activeSkin);
          amoledScheme = SkinToTheme.amoledScheme(activeSkin);
        } else {
          // Fallback while skin loads
          lightScheme = AppColorTheme.finance.lightColorScheme();
          darkScheme = AppColorTheme.finance.darkColorScheme();
          amoledScheme = AppColorTheme.finance.amoledColorScheme();
        }

        return MaterialApp.router(
          key: ValueKey(activeSkin?.id ?? 'default'),
          title: 'Mudra Manager',
          theme: appTheme.buildTheme(lightScheme, effectiveTone, spacing),
          darkTheme: appThemeMode == AppThemeMode.amoled
              ? appTheme.buildTheme(amoledScheme, effectiveTone, spacing)
              : appTheme.buildTheme(darkScheme, effectiveTone, spacing),
          themeMode: switch (appThemeMode) {
            AppThemeMode.light => ThemeMode.light,
            AppThemeMode.dark => ThemeMode.dark,
            AppThemeMode.amoled => ThemeMode.dark,
            AppThemeMode.system => ThemeMode.system,
          },
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: SnackbarService.scaffoldMessengerKey,
          routerConfig: _router,
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
            final l10n = AppLocalizations.of(context);
            if (l10n != null) Tone.syncL10n(l10n);
            NotificationService.setNavigatorKey(rootNavigatorKey);
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
