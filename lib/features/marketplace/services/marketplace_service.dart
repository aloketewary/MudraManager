import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/entitlement/entitlement_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/plugin_metadata.dart';
import 'package:mudra_manager/features/category/data/category_management_service.dart';
import 'package:mudra_manager/plugins/category_packs/category_pack.dart';

class MarketplaceService {
  static final MarketplaceService _instance = MarketplaceService._();
  factory MarketplaceService() => _instance;
  MarketplaceService._();

  final _prefs = SharedPreferences.getInstance();

  final Map<String, bool> _enabledCache = {};
  bool _cacheLoaded = false;

  Future<void> loadEnabledStates() async {
    if (_cacheLoaded) return;
    final prefs = await _prefs;
    final plugins = await fetchPlugins();
    for (final plugin in plugins) {
      _enabledCache[plugin.id] = _resolveDefault(prefs, plugin.id);
    }
    _cacheLoaded = true;
  }

  bool _resolveDefault(SharedPreferences prefs, String pluginId) {
    if (pluginId == 'standard_excel_export' ||
        pluginId == 'standard_pdf_export') {
      return true;
    }

    final stored = prefs.getBool('plugin_$pluginId');
    if (stored != null) return stored;

    if (_smsParserIds.contains(pluginId)) return true;
    if (_defaultEnabledIds.contains(pluginId)) return true;

    return false;
  }

  static const _smsParserIds = {
    'hdfc_sms_parser',
    'icici_sms_parser',
    'sbi_sms_parser',
    'axis_sms_parser',
    'kotak_sms_parser',
    'paytm_sms_parser',
    'phonepe_sms_parser',
    'gpay_sms_parser',
    'yesbank_sms_parser',
    'indusind_sms_parser',
    'idfc_sms_parser',
    'aubank_sms_parser',
    'rbl_sms_parser',
    'brazil_sms_parser',
    'indonesia_sms_parser',
    'mea_region_sms_parser',
    'latam_sms_parser',
    'europe_sms_parser',
    'generic_international_parser',
  };

  static const _defaultEnabledIds = {
    'com.mudra.pack.default',
    'com.mudra.sms_alert',
    'com.mudra.budget_guard',
    'com.mudra.goal_tracker',
    'com.mudra.large_expense',
    'com.mudra.daily_summary',
    'com.mudra.bill_reminder',
    'com.mudra.savings_milestone',
    'com.mudra.category_alert',
    'com.mudra.low_balance_alert',
    'com.mudra.credit_card_reminder',
  };

  bool isPluginEnabledSync(String pluginId) {
    return _enabledCache[pluginId] ?? false;
  }

  Future<bool> isPluginEnabled(String pluginId) async {
    if (_cacheLoaded) return _enabledCache[pluginId] ?? false;

    if (pluginId == 'standard_excel_export' ||
        pluginId == 'standard_pdf_export') {
      return true;
    }
    final prefs = await _prefs;
    return prefs.getBool('plugin_$pluginId') ??
        _smsParserIds.contains(pluginId) ||
            _defaultEnabledIds.contains(pluginId);
  }

  /// Collect all currently-enabled pack IDs (for protected-name resolution).
  Future<Set<String>> _getEnabledPackIds() async {
    final result = <String>{};
    for (final pack in CategoryPackRegistry.all) {
      if (await isPluginEnabled(pack.id)) result.add(pack.id);
    }
    return result;
  }

  Future<bool> togglePlugin(String pluginId, bool enabled) async {
    if (pluginId == 'standard_excel_export' ||
        pluginId == 'standard_pdf_export') {
      return false;
    }

    if (enabled) {
      final plugin = _allPlugins.firstWhere((p) => p.id == pluginId);
      if (plugin.isPro) {
        final entitlement = EntitlementService(IsarService());
        if (!await entitlement.isPro() &&
            !await entitlement.isInTrialPeriod()) {
          return false;
        }
      }
    }

    final prefs = await _prefs;
    await prefs.setBool('plugin_$pluginId', enabled);
    _enabledCache[pluginId] = enabled;

    if (CategoryPackRegistry.isPack(pluginId)) {
      if (enabled) {
        await CategoryManagementService.installPack(pluginId);
      } else {
        final enabledPacks = await _getEnabledPackIds();
        await CategoryManagementService.removePack(pluginId, enabledPacks);
        if (enabledPacks.isEmpty) {
          await CategoryManagementService.clearAll();
        }
      }
    }

    if (pluginId == 'com.mudra.guest_mode' && !enabled) {
      await prefs.setBool('guest_mode', false);
    }

    if (!enabled) {
      await clearPluginConfig(pluginId);
    }

    return true;
  }

  // ── All plugins defined inline ──

  Future<List<PluginMetadata>> fetchPlugins() async {
    return _allPlugins;
  }

  static final List<PluginMetadata> _allPlugins = [
    // ── SMS Parsers ──
    PluginMetadata(
      id: 'hdfc_sms_parser',
      name: 'HDFC Bank',
      version: '1.0.0',
      description: 'Parse HDFC Bank SMS messages',
      author: 'Mudra Team',
      iconUrl: 'assets/logo/banks/hdfc.svg',
      downloads: 0,
      rating: 5.0,
      packageUrl: 'bundled',
      group: PluginGroup.smsParser,
    ),
    PluginMetadata(
      id: 'icici_sms_parser',
      name: 'ICICI Bank',
      version: '1.0.0',
      description: 'Parse ICICI Bank SMS messages',
      author: 'Mudra Team',
      iconUrl: 'assets/logo/banks/icici.svg',
      downloads: 0,
      rating: 5.0,
      packageUrl: 'bundled',
      group: PluginGroup.smsParser,
    ),
    PluginMetadata(
      id: 'sbi_sms_parser',
      name: 'SBI Bank',
      version: '1.0.0',
      description: 'Parse SBI SMS messages',
      author: 'Mudra Team',
      iconUrl: 'assets/logo/banks/sbi.svg',
      downloads: 0,
      rating: 5.0,
      packageUrl: 'bundled',
      group: PluginGroup.smsParser,
    ),
    PluginMetadata(
      id: 'axis_sms_parser',
      name: 'Axis Bank',
      version: '1.0.0',
      description: 'Parse Axis Bank SMS messages',
      author: 'Mudra Team',
      iconUrl: 'assets/logo/banks/axis.svg',
      downloads: 0,
      rating: 5.0,
      packageUrl: 'bundled',
      group: PluginGroup.smsParser,
    ),
    PluginMetadata(
      id: 'kotak_sms_parser',
      name: 'Kotak Bank',
      version: '1.0.0',
      description: 'Parse Kotak Mahindra Bank SMS messages',
      author: 'Mudra Team',
      iconUrl: 'assets/logo/banks/kotak.svg',
      downloads: 0,
      rating: 5.0,
      packageUrl: 'bundled',
      group: PluginGroup.smsParser,
    ),
    PluginMetadata(
      id: 'paytm_sms_parser',
      name: 'Paytm',
      version: '1.0.0',
      description: 'Parse Paytm UPI SMS messages',
      author: 'Mudra Team',
      iconUrl: 'assets/logo/banks/paytm.svg',
      downloads: 0,
      rating: 5.0,
      packageUrl: 'bundled',
      group: PluginGroup.smsParser,
    ),
    PluginMetadata(
      id: 'phonepe_sms_parser',
      name: 'PhonePe',
      version: '1.0.0',
      description: 'Parse PhonePe UPI SMS messages',
      author: 'Mudra Team',
      iconUrl: 'assets/logo/banks/phonepe.svg',
      downloads: 0,
      rating: 5.0,
      packageUrl: 'bundled',
      group: PluginGroup.smsParser,
    ),
    PluginMetadata(
      id: 'gpay_sms_parser',
      name: 'Google Pay',
      version: '1.0.0',
      description: 'Parse Google Pay UPI SMS messages',
      author: 'Mudra Team',
      iconUrl: 'assets/logo/banks/gpay.svg',
      downloads: 0,
      rating: 5.0,
      packageUrl: 'bundled',
      group: PluginGroup.smsParser,
    ),
    PluginMetadata(
      id: 'yesbank_sms_parser',
      name: 'Yes Bank',
      version: '1.0.0',
      description: 'Parse Yes Bank SMS messages',
      author: 'Mudra Team',
      iconUrl: 'assets/logo/banks/yes.svg',
      downloads: 0,
      rating: 5.0,
      packageUrl: 'bundled',
      group: PluginGroup.smsParser,
    ),
    PluginMetadata(
      id: 'indusind_sms_parser',
      name: 'IndusInd Bank',
      version: '1.0.0',
      description: 'Parse IndusInd Bank SMS messages',
      author: 'Mudra Team',
      iconUrl: 'assets/logo/banks/indusind.svg',
      downloads: 0,
      rating: 5.0,
      packageUrl: 'bundled',
      group: PluginGroup.smsParser,
    ),
    PluginMetadata(
      id: 'idfc_sms_parser',
      name: 'IDFC Bank',
      version: '1.0.0',
      description: 'Parse IDFC First Bank SMS messages',
      author: 'Mudra Team',
      iconUrl: 'assets/logo/banks/idfc.svg',
      downloads: 0,
      rating: 5.0,
      packageUrl: 'bundled',
      group: PluginGroup.smsParser,
    ),
    PluginMetadata(
      id: 'aubank_sms_parser',
      name: 'AU Bank',
      version: '1.0.0',
      description: 'Parse AU Small Finance Bank SMS messages',
      author: 'Mudra Team',
      iconUrl: 'assets/logo/banks/au.svg',
      downloads: 0,
      rating: 5.0,
      packageUrl: 'bundled',
      group: PluginGroup.smsParser,
    ),
    PluginMetadata(
      id: 'rbl_sms_parser',
      name: 'RBL Bank',
      version: '1.0.0',
      description: 'Parse RBL Bank SMS messages',
      author: 'Mudra Team',
      iconUrl: 'assets/logo/banks/rbl.svg',
      downloads: 0,
      rating: 5.0,
      packageUrl: 'bundled',
      group: PluginGroup.smsParser,
    ),

    // ── International SMS Parsers ──
    PluginMetadata(
      id: 'brazil_sms_parser',
      name: 'Brazil Banks',
      version: '1.0.0',
      description: 'Nubank, Itaú, Bradesco, BB, Caixa, C6, Inter, PicPay',
      author: 'Mudra Team',
      iconUrl: 'assets/logo/banks/generic.svg',
      downloads: 0,
      rating: 5.0,
      packageUrl: 'bundled',
      group: PluginGroup.smsParser,
    ),
    PluginMetadata(
      id: 'indonesia_sms_parser',
      name: 'Indonesia Banks',
      version: '1.0.0',
      description: 'BCA, Mandiri, BNI, BRI, GoPay, OVO, Dana, ShopeePay',
      author: 'Mudra Team',
      iconUrl: 'assets/logo/banks/generic.svg',
      downloads: 0,
      rating: 5.0,
      packageUrl: 'bundled',
      group: PluginGroup.smsParser,
    ),
    PluginMetadata(
      id: 'mea_region_sms_parser',
      name: 'Middle East & Africa',
      version: '1.0.0',
      description: 'UAE, Saudi, Egypt, Nigeria, Kenya, South Africa banks & M-Pesa',
      author: 'Mudra Team',
      iconUrl: 'assets/logo/banks/generic.svg',
      downloads: 0,
      rating: 5.0,
      packageUrl: 'bundled',
      group: PluginGroup.smsParser,
    ),
    PluginMetadata(
      id: 'latam_sms_parser',
      name: 'Latin America',
      version: '1.0.0',
      description: 'Mexico, Colombia, Argentina, Peru, Chile banks & wallets',
      author: 'Mudra Team',
      iconUrl: 'assets/logo/banks/generic.svg',
      downloads: 0,
      rating: 5.0,
      packageUrl: 'bundled',
      group: PluginGroup.smsParser,
    ),
    PluginMetadata(
      id: 'europe_sms_parser',
      name: 'Europe Banks',
      version: '1.0.0',
      description: 'France, Germany, Turkey, Revolut, N26, ING & more',
      author: 'Mudra Team',
      iconUrl: 'assets/logo/banks/generic.svg',
      downloads: 0,
      rating: 5.0,
      packageUrl: 'bundled',
      group: PluginGroup.smsParser,
    ),
    PluginMetadata(
      id: 'generic_international_parser',
      name: 'Generic International',
      version: '1.0.0',
      description: 'Fallback parser for any bank worldwide — 30+ currencies',
      author: 'Mudra Team',
      iconUrl: 'assets/logo/banks/generic.svg',
      downloads: 0,
      rating: 5.0,
      packageUrl: 'bundled',
      group: PluginGroup.smsParser,
    ),

    // ── Export Templates ──
    PluginMetadata(
      id: 'standard_excel_export',
      name: 'Standard Excel Export',
      version: '1.0.0',
      description: 'Export financial data to Excel format',
      author: 'Mudra Team',
      iconUrl: 'assets/logo/file/excel.svg',
      downloads: 0,
      rating: 5.0,
      packageUrl: 'bundled',
      group: PluginGroup.exportTemplate,
    ),
    PluginMetadata(
      id: 'standard_pdf_export',
      name: 'Standard PDF Export',
      version: '1.0.0',
      description: 'Export financial data to PDF format',
      author: 'Mudra Team',
      iconUrl: 'assets/logo/file/pdf.svg',
      downloads: 0,
      rating: 5.0,
      packageUrl: 'bundled',
      group: PluginGroup.exportTemplate,
    ),
    PluginMetadata(
      id: 'business_excel_export',
      name: 'Business Excel Export',
      version: '1.0.0',
      description: 'Professional business report in Excel',
      author: 'Mudra Team',
      iconUrl: 'assets/logo/file/excel.svg',
      downloads: 0,
      rating: 5.0,
      packageUrl: 'bundled',
      group: PluginGroup.exportTemplate,
      isPro: true,
    ),
    PluginMetadata(
      id: 'business_pdf_export',
      name: 'Business PDF Export',
      version: '1.0.0',
      description: 'Professional business report in PDF',
      author: 'Mudra Team',
      iconUrl: 'assets/logo/file/pdf.svg',
      downloads: 0,
      rating: 5.0,
      packageUrl: 'bundled',
      group: PluginGroup.exportTemplate,
      isPro: true,
    ),

    // ── Notifications ──
    PluginMetadata(
      id: 'com.mudra.sms_alert',
      name: 'Transaction Alert',
      version: '1.0.0',
      description: 'Get notified when money is credited',
      author: 'Mudra Team',
      iconUrl: 'message',
      downloads: 0,
      rating: 5.0,
      packageUrl: 'bundled',
      group: PluginGroup.notification,
    ),
    PluginMetadata(
      id: 'com.mudra.large_expense',
      name: 'Large Expense Alert',
      version: '1.2.0',
      description: 'Alert when spending exceeds threshold',
      author: 'Mudra Team',
      iconUrl: 'bolt',
      downloads: 0,
      rating: 5.0,
      packageUrl: 'bundled',
      group: PluginGroup.notification,
      configOptions: [
        PluginConfigOption(
          key: 'threshold',
          label: 'Alert Threshold',
          type: 'number',
          defaultValue: 1000.0,
          prefix: BaseCurrency.symbol,
        ),
      ],
    ),
    PluginMetadata(
      id: 'com.mudra.daily_summary',
      name: 'Daily Summary',
      version: '1.0.0',
      description: 'Daily spending summary notification',
      author: 'Mudra Team',
      iconUrl: 'clipboard-check',
      downloads: 0,
      rating: 5.0,
      packageUrl: 'bundled',
      group: PluginGroup.notification,
    ),
    PluginMetadata(
      id: 'com.mudra.bill_reminder',
      name: 'Bill Reminder',
      version: '1.0.0',
      description: 'Reminders for recurring bills',
      author: 'Mudra Team',
      iconUrl: 'calendar',
      downloads: 0,
      rating: 5.0,
      packageUrl: 'bundled',
      group: PluginGroup.notification,
    ),
    PluginMetadata(
      id: 'com.mudra.low_balance_alert',
      name: 'Low Balance Alert',
      version: '1.1.0',
      description: 'Alert when account balance is low',
      author: 'Mudra Team',
      iconUrl: 'wallet',
      downloads: 0,
      rating: 5.0,
      packageUrl: 'bundled',
      group: PluginGroup.notification,
    ),
    PluginMetadata(
      id: 'com.mudra.credit_card_reminder',
      name: 'Credit Card Reminder',
      version: '1.0.0',
      description: 'Get notified before credit card bill due dates',
      author: 'Mudra Team',
      iconUrl: 'wallet',
      downloads: 0,
      rating: 5.0,
      packageUrl: 'bundled',
      group: PluginGroup.notification,
      configOptions: [
        PluginConfigOption(
          key: 'reminder_days',
          label: 'Remind me before (days)',
          type: 'number',
          defaultValue: 1.0,
        ),
      ],
    ),
    PluginMetadata(
      id: 'com.mudra.category_alert',
      name: 'Category Alert',
      version: '1.0.0',
      description: 'Alert on spending in specific categories',
      author: 'Mudra Team',
      iconUrl: 'grid',
      downloads: 0,
      rating: 5.0,
      packageUrl: 'bundled',
      group: PluginGroup.notification,
    ),

    // ── Budget & Spending ──
    PluginMetadata(
      id: 'com.mudra.budget_guard',
      name: 'Budget Guard',
      version: '1.0.0',
      description: 'Alert when budget is exceeded',
      author: 'Mudra Team',
      iconUrl: 'shield',
      downloads: 0,
      rating: 5.0,
      packageUrl: 'bundled',
      group: PluginGroup.budget,
    ),

    // ── Goals & Savings ──
    PluginMetadata(
      id: 'com.mudra.goal_tracker',
      name: 'Goal Tracker',
      version: '1.0.0',
      description: 'Track your financial goals',
      author: 'Mudra Team',
      iconUrl: 'goal',
      downloads: 0,
      rating: 5.0,
      packageUrl: 'bundled',
      group: PluginGroup.goals,
    ),
    PluginMetadata(
      id: 'com.mudra.savings_milestone',
      name: 'Savings Milestone',
      version: '1.0.0',
      description: 'Celebrate when you hit savings milestones',
      author: 'Mudra Team',
      iconUrl: 'trophy',
      downloads: 0,
      rating: 5.0,
      packageUrl: 'bundled',
      group: PluginGroup.goals,
    ),

    // ── Category Packs ──
    PluginMetadata(
      id: 'com.mudra.pack.default',
      name: 'Default',
      version: '1.0.0',
      description: 'Essential categories for everyday tracking',
      author: 'Mudra Team',
      iconUrl: 'wallet',
      downloads: 0,
      rating: 5.0,
      packageUrl: 'bundled',
      group: PluginGroup.categoryManagement,
    ),
    PluginMetadata(
      id: 'com.mudra.pack.student',
      name: 'Student',
      version: '1.0.0',
      description: 'Campus, hostel & college life',
      author: 'Mudra Team',
      iconUrl: 'backpack',
      downloads: 0,
      rating: 5.0,
      packageUrl: 'bundled',
      group: PluginGroup.categoryManagement,
      isPro: true,
    ),
    PluginMetadata(
      id: 'com.mudra.pack.family',
      name: 'Family',
      version: '1.0.0',
      description: 'Household, kids & elder care',
      author: 'Mudra Team',
      iconUrl: 'home',
      downloads: 0,
      rating: 5.0,
      packageUrl: 'bundled',
      group: PluginGroup.categoryManagement,
      isPro: true,
    ),
    PluginMetadata(
      id: 'com.mudra.pack.freelancer',
      name: 'Freelancer',
      version: '1.0.0',
      description: 'Gig economy, WFH & self-employed',
      author: 'Mudra Team',
      iconUrl: 'freelance',
      downloads: 0,
      rating: 5.0,
      packageUrl: 'bundled',
      group: PluginGroup.categoryManagement,
      isPro: true,
    ),
    PluginMetadata(
      id: 'com.mudra.pack.foodie',
      name: 'Foodie',
      version: '1.0.0',
      description: 'Dining, delivery & culinary adventures',
      author: 'Mudra Team',
      iconUrl: 'restaurant',
      downloads: 0,
      rating: 5.0,
      packageUrl: 'bundled',
      group: PluginGroup.categoryManagement,
      isPro: true,
    ),
    PluginMetadata(
      id: 'com.mudra.pack.traveller',
      name: 'Traveller',
      version: '1.0.0',
      description: 'Flights, hotels & adventures',
      author: 'Mudra Team',
      iconUrl: 'flight',
      downloads: 0,
      rating: 5.0,
      packageUrl: 'bundled',
      group: PluginGroup.categoryManagement,
      isPro: true,
    ),
    PluginMetadata(
      id: 'com.mudra.pack.health',
      name: 'Health & Wellness',
      version: '1.0.0',
      description: 'Fitness, diet & medical tracking',
      author: 'Mudra Team',
      iconUrl: 'medical',
      downloads: 0,
      rating: 5.0,
      packageUrl: 'bundled',
      group: PluginGroup.categoryManagement,
      isPro: true,
    ),
    PluginMetadata(
      id: 'com.mudra.pack.indian_north',
      name: 'Indian (North)',
      version: '1.0.0',
      description: 'North India lifestyle & festivals',
      author: 'Mudra Team',
      iconUrl: 'map',
      downloads: 0,
      rating: 5.0,
      packageUrl: 'bundled',
      group: PluginGroup.categoryManagement,
      isPro: true,
    ),
    PluginMetadata(
      id: 'com.mudra.pack.indian_south',
      name: 'Indian (South)',
      version: '1.0.0',
      description: 'South India cuisine & culture',
      author: 'Mudra Team',
      iconUrl: 'map',
      downloads: 0,
      rating: 5.0,
      packageUrl: 'bundled',
      group: PluginGroup.categoryManagement,
      isPro: true,
    ),
    PluginMetadata(
      id: 'com.mudra.pack.indian_east',
      name: 'Indian (East)',
      version: '1.0.0',
      description: 'East India sweets, festivals & transport',
      author: 'Mudra Team',
      iconUrl: 'map',
      downloads: 0,
      rating: 5.0,
      packageUrl: 'bundled',
      group: PluginGroup.categoryManagement,
      isPro: true,
    ),
    PluginMetadata(
      id: 'com.mudra.pack.indian_west',
      name: 'Indian (West)',
      version: '1.0.0',
      description: 'West India street food & festivals',
      author: 'Mudra Team',
      iconUrl: 'map',
      downloads: 0,
      rating: 5.0,
      packageUrl: 'bundled',
      group: PluginGroup.categoryManagement,
      isPro: true,
    ),
    PluginMetadata(
      id: 'com.mudra.pack.business',
      name: 'Business',
      version: '1.0.0',
      description: 'Business accounting & professional expenses',
      author: 'Mudra Team',
      iconUrl: 'briefcase',
      downloads: 0,
      rating: 5.0,
      packageUrl: 'bundled',
      group: PluginGroup.categoryManagement,
      isPro: true,
    ),
    PluginMetadata(
      id: 'com.mudra.pack.investor',
      name: 'Investor',
      version: '1.0.0',
      description: 'SIP, stocks, crypto & portfolio tracking',
      author: 'Mudra Team',
      iconUrl: 'trending_up',
      downloads: 0,
      rating: 5.0,
      packageUrl: 'bundled',
      group: PluginGroup.categoryManagement,
      isPro: true,
    ),
    PluginMetadata(
      id: 'com.mudra.pack.pet_owner',
      name: 'Pet Owner',
      version: '1.0.0',
      description: 'Vet, food & care for your pets',
      author: 'Mudra Team',
      iconUrl: 'pets',
      downloads: 0,
      rating: 5.0,
      packageUrl: 'bundled',
      group: PluginGroup.categoryManagement,
      isPro: true,
    ),
    PluginMetadata(
      id: 'com.mudra.pack.couple',
      name: 'Couple',
      version: '1.0.0',
      description: 'Shared expenses, dates & household',
      author: 'Mudra Team',
      iconUrl: 'heart',
      downloads: 0,
      rating: 5.0,
      packageUrl: 'bundled',
      group: PluginGroup.categoryManagement,
      isPro: true,
    ),
    PluginMetadata(
      id: 'com.mudra.pack.vehicle_enthusiast',
      name: 'Vehicle Enthusiast',
      version: '1.0.0',
      description: 'Track car & bike expenses — fuel, service, mods & more',
      author: 'Mudra Team',
      iconUrl: 'directions_car',
      downloads: 0,
      rating: 5.0,
      packageUrl: 'bundled',
      group: PluginGroup.categoryManagement,
      isPro: true,
    ),
    PluginMetadata(
      id: 'com.mudra.pack.homeowner',
      name: 'Homeowner',
      version: '1.0.0',
      description: 'EMI, maintenance, bills & home upkeep',
      author: 'Mudra Team',
      iconUrl: 'home',
      downloads: 0,
      rating: 5.0,
      packageUrl: 'bundled',
      group: PluginGroup.categoryManagement,
      isPro: true,
    ),
    PluginMetadata(
      id: 'com.mudra.pack.new_parent',
      name: 'New Parent',
      version: '1.0.0',
      description: 'Diapers, doctor visits, daycare & baby essentials',
      author: 'Mudra Team',
      iconUrl: 'baby',
      downloads: 0,
      rating: 5.0,
      packageUrl: 'bundled',
      group: PluginGroup.categoryManagement,
      isPro: true,
    ),
    PluginMetadata(
      id: 'com.mudra.pack.gamer',
      name: 'Gamer',
      version: '1.0.0',
      description: 'Games, subscriptions, hardware & in-app purchases',
      author: 'Mudra Team',
      iconUrl: 'gaming_console',
      downloads: 0,
      rating: 5.0,
      packageUrl: 'bundled',
      group: PluginGroup.categoryManagement,
      isPro: true,
    ),
    PluginMetadata(
      id: 'com.mudra.pack.wedding_planner',
      name: 'Wedding Planner',
      version: '1.0.0',
      description: 'Venue, catering, outfits, jewellery & all shaadi expenses',
      author: 'Mudra Team',
      iconUrl: 'gift',
      downloads: 0,
      rating: 5.0,
      packageUrl: 'bundled',
      group: PluginGroup.categoryManagement,
      isPro: true,
    ),
    PluginMetadata(
      id: 'com.mudra.pack.fitness_freak',
      name: 'Fitness Freak',
      version: '1.0.0',
      description: 'Gym, supplements, gear & event fees',
      author: 'Mudra Team',
      iconUrl: 'fitness',
      downloads: 0,
      rating: 5.0,
      packageUrl: 'bundled',
      group: PluginGroup.categoryManagement,
      isPro: true,
    ),

    // ── Utilities ──
    PluginMetadata(
      id: 'com.mudra.backup_sync',
      name: 'Backup & Sync',
      version: '1.0.0',
      description: 'Backup data locally and share to cloud',
      author: 'Mudra Team',
      iconUrl: 'download',
      downloads: 0,
      rating: 5.0,
      packageUrl: 'bundled',
      group: PluginGroup.utility,
      isPro: true,
    ),
  ];

  Future<Map<PluginGroup, List<PluginMetadata>>> fetchPluginsByGroup() async {
    final plugins = await fetchPlugins();
    final grouped = <PluginGroup, List<PluginMetadata>>{};
    for (final group in PluginGroup.values) {
      grouped[group] = plugins.where((p) => p.group == group).toList();
    }
    return grouped;
  }

  Future<List<String>> getEnabledExportTemplates(String exportType) async {
    final plugins = await fetchPlugins();
    final exportPlugins = plugins
        .where(
          (p) =>
              p.group == PluginGroup.exportTemplate &&
              p.name.contains(exportType),
        )
        .toList();

    final enabled = <String>[];
    for (final plugin in exportPlugins) {
      if (await isPluginEnabled(plugin.id)) {
        enabled.add(plugin.id);
      }
    }
    return enabled;
  }

  Future<void> installPlugin(String packageUrl) async {}

  // ── Config: double values ──

  Future<void> updatePluginConfig(
    String pluginId,
    String key,
    dynamic value,
  ) async {
    final prefs = await _prefs;
    await prefs.setDouble('plugin_${pluginId}_$key', value as double);
  }

  Future<double?> getPluginConfig(String pluginId, String key) async {
    final prefs = await _prefs;
    return prefs.getDouble('plugin_${pluginId}_$key');
  }

  // ── Config: string list values (for multi_select) ──

  Future<void> updatePluginConfigStringList(
    String pluginId,
    String key,
    List<String> value,
  ) async {
    final prefs = await _prefs;
    await prefs.setStringList('plugin_${pluginId}_$key', value);
  }

  Future<List<String>?> getPluginConfigStringList(
    String pluginId,
    String key,
  ) async {
    final prefs = await _prefs;
    return prefs.getStringList('plugin_${pluginId}_$key');
  }

  // ── Cleanup ──

  Future<void> clearPluginConfig(String pluginId) async {
    final prefs = await _prefs;
    final plugins = await fetchPlugins();
    try {
      final plugin = plugins.firstWhere((p) => p.id == pluginId);
      if (plugin.configOptions != null) {
        for (final option in plugin.configOptions!) {
          await prefs.remove('plugin_${pluginId}_${option.key}');
        }
      }
    } catch (_) {}
  }

  /// Disable all Pro-only plugins (call on Pro revocation/expiry).
  Future<void> disableProPlugins() async {
    final prefs = await _prefs;
    for (final plugin in _allPlugins.where((p) => p.isPro)) {
      if (_enabledCache[plugin.id] == true) {
        await prefs.setBool('plugin_${plugin.id}', false);
        _enabledCache[plugin.id] = false;
        // Don't remove category packs — soft-lock instead
      }
    }
  }
}
