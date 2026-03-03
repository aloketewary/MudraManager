import 'package:shared_preferences/shared_preferences.dart';
import '../models/plugin_metadata.dart';
import 'package:mudra_manager/features/category/data/category_management_service.dart';

class MarketplaceService {
  final _prefs = SharedPreferences.getInstance();

  Future<List<PluginMetadata>> fetchPlugins() async {
    return [
      // SMS Parser Plugins
      PluginMetadata(
        id: 'hdfc_sms_parser',
        name: 'HDFC Bank',
        version: '1.0.0',
        description: 'Parse SMS from HDFC Bank',
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
        description: 'Parse SMS from ICICI Bank',
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
        description: 'Parse SMS from State Bank of India',
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
        description: 'Parse SMS from Axis Bank',
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
        description: 'Parse SMS from Kotak Mahindra Bank',
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
        description: 'Parse SMS from Paytm UPI',
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
        description: 'Parse SMS from PhonePe UPI',
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
        description: 'Parse SMS from Google Pay UPI',
        author: 'Mudra Team',
        iconUrl: 'assets/logo/banks/gpay.svg',
        downloads: 0,
        rating: 5.0,
        packageUrl: 'bundled',
        group: PluginGroup.smsParser,
      ),
      PluginMetadata(
        id: 'yes_sms_parser',
        name: 'Yes Bank',
        version: '1.0.0',
        description: 'Parse SMS from Yes Bank',
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
        description: 'Parse SMS from IndusInd Bank',
        author: 'Mudra Team',
        iconUrl: 'assets/logo/banks/indusind.svg',
        downloads: 0,
        rating: 5.0,
        packageUrl: 'bundled',
        group: PluginGroup.smsParser,
      ),
      PluginMetadata(
        id: 'idfc_sms_parser',
        name: 'IDFC Fisrt Bank',
        version: '1.0.0',
        description: 'Parse SMS from IDFC Fisrt Bank',
        author: 'Mudra Team',
        iconUrl: 'assets/logo/banks/idfc.svg',
        downloads: 0,
        rating: 5.0,
        packageUrl: 'bundled',
        group: PluginGroup.smsParser,
      ),
      PluginMetadata(
        id: 'au_sms_parser',
        name: 'AU Small Finance Bank',
        version: '1.0.0',
        description: 'Parse SMS from AU Small Finance Bank',
        author: 'Mudra Team',
        iconUrl: 'assets/logo/banks/au.svg',
        downloads: 0,
        rating: 5.0,
        packageUrl: 'bundled',
        group: PluginGroup.smsParser,
      ),


      // Notification Plugins
      PluginMetadata(
        id: 'com.mudra.sms_alert',
        name: 'SMS Alert',
        version: '1.1.0',
        description: 'Get notified when money is credited via SMS',
        author: 'Mudra Team',
        iconUrl: 'assets/logo/file/default.svg',
        downloads: 0,
        rating: 5.0,
        packageUrl: 'bundled',
        group: PluginGroup.notification,
        configOptions: [
          PluginConfigOption(
            key: 'min_amount',
            label: 'Minimum Amount',
            type: 'number',
            defaultValue: 0.0,
            prefix: '₹',
          ),
        ],
      ),
      PluginMetadata(
        id: 'com.mudra.large_expense',
        name: 'Large Expense Alert',
        version: '1.1.0',
        description: 'Get notified for expenses over ₹1000',
        author: 'Mudra Team',
        iconUrl: 'assets/logo/file/default.svg',
        downloads: 0,
        rating: 5.0,
        packageUrl: 'bundled',
        group: PluginGroup.notification,
        configOptions: [
          PluginConfigOption(
            key: 'threshold',
            label: 'Threshold Amount',
            type: 'number',
            defaultValue: 1000.0,
            prefix: '₹',
          ),
        ],
      ),
      PluginMetadata(
        id: 'com.mudra.daily_summary',
        name: 'Daily Summary',
        version: '1.0.0',
        description: 'Daily spending summary notifications',
        author: 'Mudra Team',
        iconUrl: 'assets/logo/file/default.svg',
        downloads: 0,
        rating: 5.0,
        packageUrl: 'bundled',
        group: PluginGroup.notification,
      ),
      PluginMetadata(
        id: 'com.mudra.bill_reminder',
        name: 'Bill Reminder',
        version: '1.0.0',
        description: 'Never miss recurring bill payments',
        author: 'Mudra Team',
        iconUrl: 'assets/logo/file/default.svg',
        downloads: 0,
        rating: 5.0,
        packageUrl: 'bundled',
        group: PluginGroup.notification,
      ),
      PluginMetadata(
        id: 'com.mudra.low_balance_alert',
        name: 'Low Balance Alert',
        version: '1.0.0',
        description: 'Get notified when account balance is low',
        author: 'Mudra Team',
        iconUrl: 'assets/logo/file/default.svg',
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
        iconUrl: 'assets/logo/file/default.svg',
        downloads: 0,
        rating: 5.0,
        packageUrl: 'bundled',
        group: PluginGroup.notification,
        configOptions: [
          PluginConfigOption(
            key: 'reminder_days',
            label: 'Remind me before (days)',
            type: 'number',
            defaultValue: 1,
          ),
        ],
      ),

      // Budget Plugins
      PluginMetadata(
        id: 'com.mudra.budget_guard',
        name: 'Budget Guard',
        version: '1.2.0',
        description: 'Alert when budget limit is exceeded',
        author: 'Mudra Team',
        iconUrl: 'assets/logo/file/default.svg',
        downloads: 0,
        rating: 5.0,
        packageUrl: 'bundled',
        group: PluginGroup.budget,
        configOptions: [
          PluginConfigOption(
            key: 'warning_threshold',
            label: 'Warning Percentage',
            type: 'number',
            defaultValue: 90.0,
            suffix: '%',
          ),
        ],
      ),
      PluginMetadata(
        id: 'com.mudra.category_alert',
        name: 'Category Alert',
        version: '1.0.0',
        description: 'Alert for high category spending',
        author: 'Mudra Team',
        iconUrl: 'assets/logo/file/default.svg',
        downloads: 0,
        rating: 5.0,
        packageUrl: 'bundled',
        group: PluginGroup.budget,
      ),

      // Goals Plugins
      PluginMetadata(
        id: 'com.mudra.goal_tracker',
        name: 'Goal Tracker',
        version: '1.1.0',
        description: 'Get notified when financial goals are achieved',
        author: 'Mudra Team',
        iconUrl: 'assets/logo/file/default.svg',
        downloads: 0,
        rating: 5.0,
        packageUrl: 'bundled',
        group: PluginGroup.goals,
      ),
      PluginMetadata(
        id: 'com.mudra.savings_milestone',
        name: 'Savings Milestone',
        version: '1.0.0',
        description: 'Celebrate savings achievements',
        author: 'Mudra Team',
        iconUrl: 'assets/logo/file/default.svg',
        downloads: 0,
        rating: 5.0,
        packageUrl: 'bundled',
        group: PluginGroup.goals,
      ),

      // Export Template Plugins
      PluginMetadata(
        id: 'standard_excel_export',
        name: 'Standard Excel',
        version: '1.0.0',
        description: 'Basic Excel export with summary and transactions',
        author: 'Mudra Team',
        iconUrl: 'assets/logo/file/excel.svg',
        downloads: 0,
        rating: 5.0,
        packageUrl: 'bundled',
        group: PluginGroup.exportTemplate,
      ),
      PluginMetadata(
        id: 'standard_pdf_export',
        name: 'Standard PDF',
        version: '1.0.0',
        description: 'Basic PDF export with summary and charts',
        author: 'Mudra Team',
        iconUrl: 'assets/logo/file/pdf.svg',
        downloads: 0,
        rating: 5.0,
        packageUrl: 'bundled',
        group: PluginGroup.exportTemplate,
      ),
      PluginMetadata(
        id: 'business_excel_export',
        name: 'Business Excel',
        version: '1.0.0',
        description: 'Professional Excel with P&L and cash flow',
        author: 'Mudra Team',
        iconUrl: 'assets/logo/file/excel.svg',
        downloads: 0,
        rating: 5.0,
        packageUrl: 'bundled',
        group: PluginGroup.exportTemplate,
      ),
      PluginMetadata(
        id: 'business_pdf_export',
        name: 'Business PDF',
        version: '1.0.0',
        description: 'Professional PDF with detailed analytics',
        author: 'Mudra Team',
        iconUrl: 'assets/logo/file/pdf.svg',
        downloads: 0,
        rating: 5.0,
        packageUrl: 'bundled',
        group: PluginGroup.exportTemplate,
      ),

      // Custom Plugins
      PluginMetadata(
        id: 'com.mudra.guest_mode',
        name: 'Guest Mode',
        version: '1.0.0',
        description: 'Hide sensitive financial information',
        author: 'Mudra Team',
        iconUrl: 'assets/logo/file/default.svg',
        downloads: 0,
        rating: 5.0,
        packageUrl: 'bundled',
        group: PluginGroup.custom,
      ),
      PluginMetadata(
        id: 'com.mudra.split_bills',
        name: 'Split Bills',
        version: '1.0.0',
        description: 'Split expenses with friends and family',
        author: 'Mudra Team',
        iconUrl: 'assets/logo/file/default.svg',
        downloads: 0,
        rating: 5.0,
        packageUrl: 'bundled',
        group: PluginGroup.custom,
      ),
      PluginMetadata(
        id: 'com.mudra.travel_expenses',
        name: 'Travel Expenses',
        version: '1.0.0',
        description: 'Track and manage travel expenses separately',
        author: 'Mudra Team',
        iconUrl: 'assets/logo/file/default.svg',
        downloads: 0,
        rating: 5.0,
        packageUrl: 'bundled',
        group: PluginGroup.custom,
      ),
      PluginMetadata(
        id: 'com.mudra.advanced_analytics',
        name: 'Advanced Analytics',
        version: '1.0.0',
        description: 'Deep insights and spending analysis',
        author: 'Mudra Team',
        iconUrl: 'assets/logo/file/default.svg',
        downloads: 0,
        rating: 5.0,
        packageUrl: 'bundled',
        group: PluginGroup.custom,
      ),
      // Backup & Sync Plugin
      PluginMetadata(
        id: 'com.mudra.backup_sync',
        name: 'Backup & Sync',
        version: '1.0.0',
        description: 'Backup data locally and share to cloud',
        author: 'Mudra Team',
        iconUrl: 'assets/logo/file/default.svg',
        downloads: 0,
        rating: 5.0,
        packageUrl: 'bundled',
        group: PluginGroup.utility,
      ),

      // Category Management Plugins
      PluginMetadata(
        id: 'com.mudra.business_categories',
        name: 'Business Categories',
        version: '1.0.0',
        description: 'Industry-specific business expense categories',
        author: 'Mudra Team',
        iconUrl: 'assets/logo/file/default.svg',
        downloads: 0,
        rating: 5.0,
        packageUrl: 'bundled',
        group: PluginGroup.categoryManagement,
      ),
      PluginMetadata(
        id: 'com.mudra.regional_categories',
        name: 'Regional Categories',
        version: '1.0.0',
        description: 'India-specific regional expense categories',
        author: 'Mudra Team',
        iconUrl: 'assets/logo/file/default.svg',
        downloads: 0,
        rating: 5.0,
        packageUrl: 'bundled',
        group: PluginGroup.categoryManagement,
      ),
    ];
  }

  Future<Map<PluginGroup, List<PluginMetadata>>> fetchPluginsByGroup() async {
    final plugins = await fetchPlugins();
    final grouped = <PluginGroup, List<PluginMetadata>>{};

    for (final group in PluginGroup.values) {
      grouped[group] = plugins.where((p) => p.group == group).toList();
    }

    return grouped;
  }

  Future<void> togglePlugin(String pluginId, bool enabled) async {
    final prefs = await _prefs;

    // Standard templates cannot be disabled
    if (pluginId == 'standard_excel_export' ||
        pluginId == 'standard_pdf_export') {
      return;
    }

    await prefs.setBool('plugin_$pluginId', enabled);

    // Handle category management plugins
    if (pluginId == 'com.mudra.business_categories' ||
        pluginId == 'com.mudra.regional_categories') {
      if (enabled) {
        await _installCategoryPlugin(pluginId);
      } else {
        await _removeCategoryPlugin(pluginId);
      }
    }

    // When Guest Mode plugin is disabled, also disable guest mode
    if (pluginId == 'com.mudra.guest_mode' && !enabled) {
      await prefs.setBool('guest_mode', false);
    }

    if (!enabled) {
      await clearPluginConfig(pluginId);
    }
  }

  Future<void> _installCategoryPlugin(String pluginId) async {
    await CategoryManagementService.installPluginCategories(pluginId);
  }

  Future<void> _removeCategoryPlugin(String pluginId) async {
    await CategoryManagementService.removePluginCategories(pluginId);
  }

  Future<bool> isPluginEnabled(String pluginId) async {
    // Standard templates are always enabled
    if (pluginId == 'standard_excel_export' ||
        pluginId == 'standard_pdf_export') {
      return true;
    }

    // SMS parsers are enabled by default
    final smsParserIds = [
      'hdfc_sms_parser',
      'icici_sms_parser',
      'sbi_sms_parser',
      'axis_sms_parser',
      'kotak_sms_parser',
      'paytm_sms_parser',
      'phonepe_sms_parser',
      'gpay_sms_parser',
      'yes_sms_parser',
      'indusind_sms_parser',
      'idfc_sms_parser',
      'au_sms_parser',
    ];
    
    if (smsParserIds.contains(pluginId)) {
      final prefs = await _prefs;
      return prefs.getBool('plugin_$pluginId') ?? true;
    }

    final prefs = await _prefs;
    return prefs.getBool('plugin_$pluginId') ?? false;
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

  Future<void> installPlugin(String packageUrl) async {
    // For bundled plugins, just enable them
  }

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

  Future<void> clearPluginConfig(String pluginId) async {
    final prefs = await _prefs;
    final plugins = await fetchPlugins();
    final plugin = plugins.firstWhere((p) => p.id == pluginId);

    if (plugin.configOptions != null) {
      for (final option in plugin.configOptions!) {
        await prefs.remove('plugin_${pluginId}_${option.key}');
      }
    }
  }
}
