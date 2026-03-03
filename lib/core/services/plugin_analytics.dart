class PluginAnalytics {
  final Map<String, int> _eventCounts = {};
  final Map<String, int> _errorCounts = {};

  void trackEvent(String pluginId, String eventType) {
    final key = '$pluginId:$eventType';
    _eventCounts[key] = (_eventCounts[key] ?? 0) + 1;
  }

  void trackError(String pluginId) {
    _errorCounts[pluginId] = (_errorCounts[pluginId] ?? 0) + 1;
  }

  int getEventCount(String pluginId, String eventType) {
    return _eventCounts['$pluginId:$eventType'] ?? 0;
  }

  int getErrorCount(String pluginId) {
    return _errorCounts[pluginId] ?? 0;
  }

  Map<String, int> getPluginStats(String pluginId) {
    return {
      'sms': getEventCount(pluginId, 'sms'),
      'expense': getEventCount(pluginId, 'expense'),
      'budget': getEventCount(pluginId, 'budget'),
      'goal': getEventCount(pluginId, 'goal'),
      'errors': getErrorCount(pluginId),
    };
  }

  void reset() {
    _eventCounts.clear();
    _errorCounts.clear();
  }
}
