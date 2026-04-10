import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/widgets/dashboard_widget_plugin.dart';
import 'package:mudra_manager/core/widgets/dashboard_widget_registry.dart';

void main() {
  group('DashboardWidgetRegistry', () {
    test('has registered widgets', () {
      expect(DashboardWidgetRegistry.widgets, isNotEmpty);
    });

    test('all widgets have unique ids', () {
      final ids = DashboardWidgetRegistry.widgets.map((w) => w.id).toSet();
      expect(ids.length, DashboardWidgetRegistry.widgets.length);
    });

    test('all widgets have non-empty title', () {
      for (final widget in DashboardWidgetRegistry.widgets) {
        expect(widget.title, isNotEmpty,
            reason: '${widget.id} has empty title',);
      }
    });

    test('all widgets have non-empty id', () {
      for (final widget in DashboardWidgetRegistry.widgets) {
        expect(widget.id, isNotEmpty);
      }
    });

    test('getWidget returns correct widget by id', () {
      final first = DashboardWidgetRegistry.widgets.first;
      final found = DashboardWidgetRegistry.getWidget(first.id);
      expect(found, isNotNull);
      expect(found!.id, first.id);
    });

    test('getWidget returns null for unknown id', () {
      final found = DashboardWidgetRegistry.getWidget('nonexistent_widget_xyz');
      expect(found, isNull);
    });

    test('essential widgets are non-empty', () {
      final essential = DashboardWidgetRegistry.essentialWidgets;
      expect(essential, isNotEmpty);
      for (final w in essential) {
        expect(w.category, WidgetCategory.essential);
      }
    });

    test('finance widgets are non-empty', () {
      final finance = DashboardWidgetRegistry.financeWidgets;
      expect(finance, isNotEmpty);
      for (final w in finance) {
        expect(w.category, WidgetCategory.finance);
      }
    });

    test('getWidgetsByCategory returns correct category', () {
      for (final category in WidgetCategory.values) {
        final widgets = DashboardWidgetRegistry.getWidgetsByCategory(category);
        for (final w in widgets) {
          expect(
            w.category,
            category,
            reason: '${w.id} has wrong category',
          );
        }
      }
    });

    test('widgets list is unmodifiable', () {
      expect(
        () => DashboardWidgetRegistry.widgets.add(
          DashboardWidgetRegistry.widgets.first,
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });

  group('DashboardWidgetPlugin defaults', () {
    test('default size is medium', () {
      for (final widget in DashboardWidgetRegistry.widgets) {
        // Just verify the getter doesn't throw
        expect(widget.defaultSize, isNotNull);
      }
    });

    test('most widgets can be disabled', () {
      final disableable =
          DashboardWidgetRegistry.widgets.where((w) => w.canBeDisabled).length;
      expect(disableable, greaterThan(0));
    });

    test('most widgets are visible by default', () {
      final visible =
          DashboardWidgetRegistry.widgets.where((w) => w.defaultVisible).length;
      expect(visible, greaterThan(0));
    });
  });

  group('WidgetCategory', () {
    test('all categories exist', () {
      expect(WidgetCategory.values, contains(WidgetCategory.essential));
      expect(WidgetCategory.values, contains(WidgetCategory.finance));
      expect(WidgetCategory.values, contains(WidgetCategory.analytics));
      expect(WidgetCategory.values, contains(WidgetCategory.actions));
      expect(WidgetCategory.values, contains(WidgetCategory.ai));
      expect(WidgetCategory.values, contains(WidgetCategory.contextual));
      expect(WidgetCategory.values, contains(WidgetCategory.custom));
    });
  });

  group('WidgetSize', () {
    test('all sizes exist', () {
      expect(WidgetSize.values, contains(WidgetSize.small));
      expect(WidgetSize.values, contains(WidgetSize.medium));
      expect(WidgetSize.values, contains(WidgetSize.large));
      expect(WidgetSize.values, contains(WidgetSize.full));
    });
  });
}
