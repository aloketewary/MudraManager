import 'export_plugin.dart';
import 'export_plugins/standard_excel_export.dart';
import 'export_plugins/standard_pdf_export.dart';
import 'export_plugins/business_excel_export.dart';
import 'export_plugins/business_pdf_export.dart';
import 'package:mudra_manager/features/marketplace/services/marketplace_service.dart';

class ExportPluginManager {
  static final ExportPluginManager _instance = ExportPluginManager._();
  static ExportPluginManager get instance => _instance;
  
  final Map<String, ExportPlugin> _allPlugins = {};
  final _marketplaceService = MarketplaceService();
  
  ExportPluginManager._() {
    _registerAllPlugins();
  }

  void _registerAllPlugins() {
    final plugins = [
      StandardExcelExportPlugin(),
      StandardPdfExportPlugin(),
      BusinessExcelExportPlugin(),
      BusinessPdfExportPlugin(),
    ];
    
    for (final plugin in plugins) {
      _allPlugins[plugin.id] = plugin;
      plugin.onLoad();
      plugin.onStart();
    }
  }

  Future<List<ExportPlugin>> getPluginsByType(String exportType) async {
    final enabledIds = await _marketplaceService.getEnabledExportTemplates(exportType);
    return _allPlugins.entries
        .where((e) => enabledIds.contains(e.key) && e.value.exportType == exportType)
        .map((e) => e.value)
        .toList();
  }

  Future<ExportPlugin?> getPlugin(String exportType, String templateName) async {
    final plugins = await getPluginsByType(exportType);
    return plugins.firstWhere(
      (p) => p.templateName == templateName,
      orElse: () => plugins.first,
    );
  }

  Future<List<String>> getSupportedFormats() async {
    final allEnabled = await Future.wait([
      _marketplaceService.getEnabledExportTemplates('Excel'),
      _marketplaceService.getEnabledExportTemplates('PDF'),
    ]);
    
    final formats = <String>{};
    for (final ids in allEnabled) {
      for (final id in ids) {
        final plugin = _allPlugins[id];
        if (plugin != null) formats.add(plugin.exportType);
      }
    }
    return formats.toList();
  }

  Future<List<String>> getTemplatesForFormat(String exportType) async {
    final plugins = await getPluginsByType(exportType);
    return plugins.map((p) => p.templateName).toList();
  }
}
