import 'package:isar_community/isar.dart';

part 'widget_metrics.g.dart';

@collection
class WidgetMetrics {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String widgetId;

  int impressions = 0;
  int clicks = 0;
  int hides = 0;

  WidgetMetrics();

  WidgetMetrics.create({required this.widgetId});

  double get ctr => impressions > 0 ? (clicks / impressions) * 100 : 0;
  double get hideRate => impressions > 0 ? (hides / impressions) * 100 : 0;
}
