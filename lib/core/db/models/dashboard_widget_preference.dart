import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/widgets/dashboard_widget_plugin.dart';

part 'dashboard_widget_preference.g.dart';

@collection
class DashboardWidgetPreference {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String widgetId;

  late int order;
  late bool visible;
  late bool pinned;

  @enumerated
  late WidgetSize size;

  DashboardWidgetPreference();

  DashboardWidgetPreference.create({
    required this.widgetId,
    required this.order,
    this.visible = true,
    this.pinned = false,
    this.size = WidgetSize.medium,
  });
}


