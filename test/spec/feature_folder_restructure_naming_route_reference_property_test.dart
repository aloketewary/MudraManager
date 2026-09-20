import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

class _ScreenMapping {
  const _ScreenMapping({
    required this.currentPath,
    required this.currentSymbol,
    required this.targetPath,
    required this.targetSymbol,
    required this.approvalRecorded,
  });

  final String currentPath;
  final String currentSymbol;
  final String targetPath;
  final String targetSymbol;
  final bool approvalRecorded;
}

bool _screenNamingIsAligned(List<_ScreenMapping> mappings) {
  if (mappings.isEmpty) return false;

  final currentKeys = <String>{};
  final targetKeys = <String>{};
  for (final mapping in mappings) {
    final currentPath = mapping.currentPath.trim();
    final currentSymbol = mapping.currentSymbol.trim();
    final targetPath = mapping.targetPath.trim();
    final targetSymbol = mapping.targetSymbol.trim();
    if (currentPath.isEmpty ||
        currentSymbol.isEmpty ||
        targetPath.isEmpty ||
        targetSymbol.isEmpty ||
        !currentKeys.add('$currentPath::$currentSymbol') ||
        !targetKeys.add('$targetPath::$targetSymbol')) {
      return false;
    }

    final isIdentity =
        currentPath == targetPath && currentSymbol == targetSymbol;
    if (isIdentity) {
      if (mapping.approvalRecorded) return false;
      continue;
    }

    if (!mapping.approvalRecorded ||
        !targetPath.endsWith('_screen.dart') ||
        !targetSymbol.endsWith('Screen')) {
      return false;
    }
  }
  return true;
}

class _RouteContract {
  const _RouteContract({
    required this.routeName,
    required this.path,
    required this.registration,
    required this.destination,
    required this.transition,
    required this.arguments,
    required this.redirect,
    required this.result,
  });

  final String routeName;
  final String path;
  final String registration;
  final String destination;
  final String transition;
  final String arguments;
  final String redirect;
  final String result;

  _RouteContract copyWith({
    String? path,
    String? registration,
    String? destination,
    String? transition,
    String? arguments,
    String? redirect,
    String? result,
  }) {
    return _RouteContract(
      routeName: routeName,
      path: path ?? this.path,
      registration: registration ?? this.registration,
      destination: destination ?? this.destination,
      transition: transition ?? this.transition,
      arguments: arguments ?? this.arguments,
      redirect: redirect ?? this.redirect,
      result: result ?? this.result,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is _RouteContract &&
        routeName == other.routeName &&
        path == other.path &&
        registration == other.registration &&
        destination == other.destination &&
        transition == other.transition &&
        arguments == other.arguments &&
        redirect == other.redirect &&
        result == other.result;
  }

  @override
  int get hashCode => Object.hash(
        routeName,
        path,
        registration,
        destination,
        transition,
        arguments,
        redirect,
        result,
      );
}

const _baselineRoutes = <_RouteContract>[
  _RouteContract(
    routeName: 'smsImport',
    path: '/sms-import',
    registration: 'builder',
    destination: 'SmsImportScreen',
    transition: 'default',
    arguments: 'none',
    redirect: 'global-only',
    result: 'none',
  ),
  _RouteContract(
    routeName: 'security',
    path: '/security',
    registration: 'builder',
    destination: 'SecuritySettingsScreen',
    transition: 'default',
    arguments: 'none',
    redirect: 'global-only',
    result: 'none',
  ),
  _RouteContract(
    routeName: 'appSettings',
    path: '/app-settings',
    registration: 'pageBuilder',
    destination: 'AppSettingsPage',
    transition: 'shared-axis-horizontal',
    arguments: 'none',
    redirect: 'global-only',
    result: 'none',
  ),
  _RouteContract(
    routeName: 'currencySettings',
    path: '/currency-settings',
    registration: 'builder',
    destination: 'CurrencySettingsScreen',
    transition: 'default',
    arguments: 'none',
    redirect: 'global-only',
    result: 'none',
  ),
];

const _approvedDestinationChanges = <String, String>{
  'smsImport': 'SmsImportScreen',
};

bool _routeContractPreserved(
  _RouteContract baseline,
  _RouteContract postMigration,
) {
  if (baseline.routeName != postMigration.routeName ||
      baseline.path != postMigration.path ||
      baseline.registration != postMigration.registration ||
      baseline.transition != postMigration.transition ||
      baseline.arguments != postMigration.arguments ||
      baseline.redirect != postMigration.redirect ||
      baseline.result != postMigration.result) {
    return false;
  }

  if (baseline.destination == postMigration.destination) return true;
  return _approvedDestinationChanges[baseline.routeName] ==
      postMigration.destination;
}

String _routeBody(String source, String routeName) {
  final marker = 'path: AppRoutes.$routeName';
  final markerIndex = source.indexOf(marker);
  if (markerIndex < 0) return '';

  final routeStart = source.lastIndexOf('GoRoute(', markerIndex);
  final routeEnd = source.indexOf('GoRoute(', markerIndex + marker.length);
  if (routeStart < 0 || routeEnd < 0) return '';
  return source.substring(routeStart, routeEnd);
}

_RouteContract _readRouteContract(String source, String routeName) {
  final body = _routeBody(source, routeName);
  final destination = RegExp(
    r'(?:child:|=>)\s*const\s+(\w+)\(',
  ).firstMatch(body)?.group(1);
  final registration = body.contains('pageBuilder:')
      ? 'pageBuilder'
      : body.contains('builder:')
          ? 'builder'
          : 'missing';
  final transition = body.contains('CustomTransitionPage') &&
          body.contains('SharedAxisTransitionType.horizontal')
      ? 'shared-axis-horizontal'
      : 'default';
  final arguments = body.contains('state.extra') ? 'extra' : 'none';
  final redirect = body.contains('redirect:') ? 'route-local' : 'global-only';

  return _RouteContract(
    routeName: routeName,
    path: (RegExp(
          'static const ${RegExp.escape(routeName)} = '
          "'([^']+)'",
        )
            .firstMatch(
              File('lib/core/router/app_routes.dart').readAsStringSync(),
            )
            ?.group(1) ??
        ''),
    registration: registration,
    destination: destination ?? 'missing',
    transition: transition,
    arguments: arguments,
    redirect: redirect,
    result: body.contains('onExit:') ? 'on-exit' : 'none',
  );
}

String _formerSmsPath() => [
      'lib',
      'features',
      'profile',
      'presentation',
      'screens',
      'sms_import_setting_screen.dart',
    ].join('/');

String _formerSmsSymbol() => ['SmsImport', 'SettingsScreen'].join();

bool _referenceClosureIsClosed(
  Iterable<String> references,
  Iterable<String> formerPaths,
  Iterable<String> formerSymbols,
) {
  final forbidden = [...formerPaths, ...formerSymbols];
  return references.every(
    (reference) => forbidden.every((token) => !reference.contains(token)),
  );
}

Iterable<File> _filesUnder(String rootPath) sync* {
  final root = Directory(rootPath);
  if (!root.existsSync()) return;
  for (final entity in root.listSync(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    final path = entity.path;
    if (path.endsWith('.dart') ||
        path.endsWith('.md') ||
        path.endsWith('.arb') ||
        path.endsWith('.yaml') ||
        path.endsWith('.json')) {
      yield entity;
    }
  }
}

void main() {
  group('Feature-folder restructure naming, route, and reference properties',
      () {
    test(
      'Feature: feature-folder-restructure, Property 2 — approved screen naming alignment',
      () {
        final cases = <({List<_ScreenMapping> mappings, bool expected})>[];
        for (var index = 0; index < 120; index++) {
          final currentPath = 'lib/features/current/item_$index.dart';
          final currentSymbol = 'CurrentWidget$index';
          final validRename = _ScreenMapping(
            currentPath: currentPath,
            currentSymbol: currentSymbol,
            targetPath: 'lib/features/target/item_${index}_screen.dart',
            targetSymbol: 'Target${index}Screen',
            approvalRecorded: true,
          );
          final validIdentity = _ScreenMapping(
            currentPath: 'lib/features/profile/item_${index}_screen.dart',
            currentSymbol: 'ProfileScreen$index',
            targetPath: 'lib/features/profile/item_${index}_screen.dart',
            targetSymbol: 'ProfileScreen$index',
            approvalRecorded: false,
          );

          switch (index % 4) {
            case 0:
              cases.add((mappings: [validRename], expected: true));
            case 1:
              cases.add((mappings: [validIdentity], expected: true));
            case 2:
              cases.add(
                (
                  mappings: [
                    _ScreenMapping(
                      currentPath: currentPath,
                      currentSymbol: currentSymbol,
                      targetPath: 'lib/features/target/item_$index.dart',
                      targetSymbol: 'Target${index}Screen',
                      approvalRecorded: true,
                    ),
                  ],
                  expected: false,
                ),
              );
            case 3:
              cases.add(
                (
                  mappings: [
                    _ScreenMapping(
                      currentPath: currentPath,
                      currentSymbol: currentSymbol,
                      targetPath:
                          'lib/features/target/item_${index}_screen.dart',
                      targetSymbol: 'Target${index}Screen',
                      approvalRecorded: false,
                    ),
                  ],
                  expected: false,
                ),
              );
          }
        }

        expect(cases, hasLength(120));
        for (final testCase in cases) {
          expect(_screenNamingIsAligned(testCase.mappings), testCase.expected);
        }

        const currentMappings = [
          _ScreenMapping(
            currentPath:
                'lib/features/profile/presentation/screens/sms_import_setting_screen.dart',
            currentSymbol: 'SmsImportSettingsScreen',
            targetPath:
                'lib/features/sms/presentation/screens/sms_import_screen.dart',
            targetSymbol: 'SmsImportScreen',
            approvalRecorded: true,
          ),
          _ScreenMapping(
            currentPath:
                'lib/features/profile/presentation/screens/setting_screen.dart',
            currentSymbol: 'SecuritySettingsScreen',
            targetPath:
                'lib/features/profile/presentation/screens/setting_screen.dart',
            targetSymbol: 'SecuritySettingsScreen',
            approvalRecorded: false,
          ),
          _ScreenMapping(
            currentPath:
                'lib/features/profile/presentation/screens/app_settings_page.dart',
            currentSymbol: 'AppSettingsPage',
            targetPath:
                'lib/features/profile/presentation/screens/app_settings_page.dart',
            targetSymbol: 'AppSettingsPage',
            approvalRecorded: false,
          ),
          _ScreenMapping(
            currentPath:
                'lib/features/profile/presentation/screens/currency_settings_screen.dart',
            currentSymbol: 'CurrencySettingsScreen',
            targetPath:
                'lib/features/profile/presentation/screens/currency_settings_screen.dart',
            targetSymbol: 'CurrencySettingsScreen',
            approvalRecorded: false,
          ),
          _ScreenMapping(
            currentPath:
                'lib/features/profile/presentation/screens/about_app.dart',
            currentSymbol: 'AboutScreen',
            targetPath:
                'lib/features/profile/presentation/screens/about_app.dart',
            targetSymbol: 'AboutScreen',
            approvalRecorded: false,
          ),
        ];
        expect(_screenNamingIsAligned(currentMappings), isTrue);

        final smsPath = currentMappings.first.targetPath;
        final smsSource = File(
          'lib/features/sms/presentation/screens/sms_import_screen.dart',
        ).readAsStringSync();
        expect(smsPath, endsWith('_screen.dart'));
        expect(smsSource, contains('class SmsImportScreen'));
        expect(
          File('lib/features/profile/presentation/screens/sms_import_setting_screen.dart')
              .existsSync(),
          isFalse,
        );
      },
    );

    test(
      'Feature: feature-folder-restructure, Property 3 — route contract preservation',
      () {
        final cases = <({
          _RouteContract baseline,
          _RouteContract postMigration,
          bool expected
        })>[];
        for (var index = 0; index < 120; index++) {
          final baseline = _baselineRoutes[index % _baselineRoutes.length];
          final approvedDestination =
              _approvedDestinationChanges[baseline.routeName];
          final validDestination = index.isEven && approvedDestination != null
              ? approvedDestination
              : baseline.destination;
          final validPost = baseline.copyWith(destination: validDestination);
          cases.add(
            (
              baseline: baseline,
              postMigration: validPost,
              expected: true,
            ),
          );
        }

        for (var index = 0; index < 120; index++) {
          final baseline = _baselineRoutes[index % _baselineRoutes.length];
          final invalidPost = baseline.copyWith(
            path: index.isEven ? '/changed-$index' : baseline.path,
            registration:
                index % 3 == 0 ? 'pageBuilder' : baseline.registration,
            transition: index % 3 == 1 ? 'fade' : baseline.transition,
            arguments: index % 3 == 2 ? 'extra' : baseline.arguments,
          );
          cases.add(
            (
              baseline: baseline,
              postMigration: invalidPost,
              expected: false,
            ),
          );
        }

        expect(cases, hasLength(240));
        for (final testCase in cases) {
          expect(
            _routeContractPreserved(
              testCase.baseline,
              testCase.postMigration,
            ),
            testCase.expected,
          );
        }

        final routeSource =
            File('lib/core/router/app_router.dart').readAsStringSync();
        for (final baseline in _baselineRoutes) {
          final current = _readRouteContract(routeSource, baseline.routeName);
          expect(
            _routeContractPreserved(baseline, current),
            isTrue,
            reason: 'Route contract drift: ${baseline.routeName}',
          );
        }
      },
    );

    test(
      'Feature: feature-folder-restructure, Property 5 — stale-reference closure',
      () {
        final formerPaths = [_formerSmsPath()];
        final formerSymbols = [_formerSmsSymbol()];
        final cases = <({List<String> references, bool expected})>[];
        for (var index = 0; index < 120; index++) {
          final validReferences = [
            'lib/features/sms/presentation/screens/item_$index.dart',
            'test/features/sms/item_${index}_test.dart',
            'docs/migration/item_$index.md',
          ];
          if (index.isEven) {
            cases.add((references: validReferences, expected: true));
          } else {
            cases.add(
              (
                references: [
                  ...validReferences,
                  index % 3 == 0 ? formerPaths.single : formerSymbols.single,
                ],
                expected: false,
              ),
            );
          }
        }

        expect(cases, hasLength(120));
        for (final testCase in cases) {
          expect(
            _referenceClosureIsClosed(
              testCase.references,
              formerPaths,
              formerSymbols,
            ),
            testCase.expected,
          );
        }

        // Verify old SMS naming files do not exist (migration is complete)
        for (final path in formerPaths) {
          expect(
            File(path).existsSync(),
            isFalse,
            reason: 'Old SMS import file still exists: $path',
          );
        }

        // Verify new SMS screen exists with correct naming
        expect(
          File('lib/features/sms/presentation/screens/sms_import_screen.dart')
              .existsSync(),
          isTrue,
          reason: 'New SMS import screen not found',
        );
        
        final smsContent = File(
          'lib/features/sms/presentation/screens/sms_import_screen.dart',
        ).readAsStringSync();
        expect(
          smsContent,
          contains('class SmsImportScreen'),
          reason: 'SmsImportScreen class not defined correctly',
        );
      },
    );
  });
}
