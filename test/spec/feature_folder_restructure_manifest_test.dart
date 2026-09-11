import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

enum _TargetStatus { approved, blocked, identity }

enum _MappingStatus { approved, blocked, identity }

class _OwnershipEntry {
  const _OwnershipEntry({
    required this.currentPath,
    required this.symbols,
    required this.ownerFeature,
    required this.sharedException,
    required this.evidence,
    required this.productionConsumers,
    required this.testConsumers,
    required this.conflictStatus,
    required this.migrationConsequence,
    required this.targetStatus,
    required this.targetPath,
    required this.reverseMapping,
    required this.checkpoint,
    required this.validationCommand,
    required this.independentFeatureCount,
    required this.featureSpecificBehavior,
    required this.approvedInversion,
  });

  final String currentPath;
  final List<String> symbols;
  final String? ownerFeature;
  final bool sharedException;
  final List<String> evidence;
  final List<String> productionConsumers;
  final List<String> testConsumers;
  final String conflictStatus;
  final String migrationConsequence;
  final _TargetStatus targetStatus;
  final String? targetPath;
  final String reverseMapping;
  final String checkpoint;
  final String validationCommand;
  final int independentFeatureCount;
  final bool featureSpecificBehavior;
  final bool approvedInversion;
}

class _MigrationEntry {
  const _MigrationEntry({
    required this.currentPath,
    required this.currentSymbol,
    required this.targetPath,
    required this.targetSymbol,
    required this.status,
    required this.approvalRecorded,
    required this.checkpoint,
    required this.validationCommand,
    required this.rollbackAction,
    required this.isCompatibilityAlias,
    required this.aliasOwner,
    required this.aliasLifetime,
    required this.aliasRemovalCheckpoint,
    required this.aliasStaleReferenceRule,
  });

  final String currentPath;
  final String currentSymbol;
  final String? targetPath;
  final String? targetSymbol;
  final _MappingStatus status;
  final bool approvalRecorded;
  final String checkpoint;
  final String validationCommand;
  final String rollbackAction;
  final bool isCompatibilityAlias;
  final String? aliasOwner;
  final String? aliasLifetime;
  final String? aliasRemovalCheckpoint;
  final String? aliasStaleReferenceRule;
}

bool _ownershipManifestIsClosed(List<_OwnershipEntry> entries) {
  if (entries.isEmpty) return false;

  final currentPaths = <String>{};
  final targetPaths = <String>{};
  for (final entry in entries) {
    final hasFeatureOwner = entry.ownerFeature?.trim().isNotEmpty == true;
    if (hasFeatureOwner == entry.sharedException) return false;
    if (entry.currentPath.trim().isEmpty ||
        !currentPaths.add(entry.currentPath)) {
      return false;
    }
    if (entry.symbols.isEmpty ||
        entry.symbols.any((symbol) => symbol.trim().isEmpty)) {
      return false;
    }
    if (entry.evidence.isEmpty ||
        entry.evidence.any((item) => item.trim().isEmpty)) {
      return false;
    }
    if (entry.productionConsumers.isEmpty ||
        entry.testConsumers.isEmpty ||
        entry.productionConsumers.any((item) => item.trim().isEmpty) ||
        entry.testConsumers.any((item) => item.trim().isEmpty)) {
      return false;
    }
    if (entry.conflictStatus.trim().isEmpty ||
        entry.migrationConsequence.trim().isEmpty ||
        entry.reverseMapping.trim().isEmpty ||
        entry.checkpoint.trim().isEmpty ||
        entry.validationCommand.trim().isEmpty) {
      return false;
    }

    final target = entry.targetPath?.trim();
    switch (entry.targetStatus) {
      case _TargetStatus.approved:
        if (target == null || target.isEmpty || !targetPaths.add(target)) {
          return false;
        }
      case _TargetStatus.blocked:
        if (target != null && target.isNotEmpty) return false;
      case _TargetStatus.identity:
        if (target != entry.currentPath) return false;
    }

    if (entry.sharedException &&
        (entry.independentFeatureCount < 2 ||
            (entry.featureSpecificBehavior && !entry.approvedInversion))) {
      return false;
    }
  }
  return true;
}

bool _migrationManifestIsReversible(List<_MigrationEntry> entries) {
  if (entries.isEmpty) return false;

  final currentKeys = <String>{};
  final targetKeys = <String>{};
  for (final entry in entries) {
    final currentPath = entry.currentPath.trim();
    final currentSymbol = entry.currentSymbol.trim();
    if (currentPath.isEmpty || currentSymbol.isEmpty) return false;
    if (!currentKeys.add('$currentPath::$currentSymbol')) return false;
    if (entry.checkpoint.trim().isEmpty ||
        entry.validationCommand.trim().isEmpty ||
        entry.rollbackAction.trim().isEmpty) {
      return false;
    }

    final targetPath = entry.targetPath?.trim();
    final targetSymbol = entry.targetSymbol?.trim();
    if ((targetPath == null) != (targetSymbol == null) ||
        (targetPath != null && targetPath.isEmpty) ||
        (targetSymbol != null && targetSymbol.isEmpty)) {
      return false;
    }

    switch (entry.status) {
      case _MappingStatus.identity:
        if (targetPath != currentPath || targetSymbol != currentSymbol) {
          return false;
        }
        if (entry.approvalRecorded) return false;
      case _MappingStatus.blocked:
        if (targetPath != null || targetSymbol != null) return false;
        if (entry.approvalRecorded) return false;
      case _MappingStatus.approved:
        if (targetPath == null ||
            targetSymbol == null ||
            targetPath == currentPath && targetSymbol == currentSymbol ||
            !entry.approvalRecorded ||
            !targetKeys.add('$targetPath::$targetSymbol')) {
          return false;
        }
    }

    if (entry.isCompatibilityAlias &&
        [
          entry.aliasOwner,
          entry.aliasLifetime,
          entry.aliasRemovalCheckpoint,
          entry.aliasStaleReferenceRule,
        ].any((value) => value?.trim().isNotEmpty != true)) {
      return false;
    }
  }
  return true;
}

_OwnershipEntry _validOwnershipEntry(int index) {
  final isShared = index.isOdd;
  final targetStatus = switch (index % 3) {
    0 => _TargetStatus.identity,
    1 => _TargetStatus.blocked,
    _ => _TargetStatus.approved,
  };
  return _OwnershipEntry(
    currentPath: 'lib/features/generated/item_$index.dart',
    symbols: ['GeneratedItem$index'],
    ownerFeature: isShared ? null : 'transactions',
    sharedException: isShared,
    evidence: ['imports and responsibility evidence $index'],
    productionConsumers: ['lib/features/consumer_$index.dart'],
    testConsumers: ['test/features/consumer_${index}_test.dart'],
    conflictStatus: isShared ? 'shared exception reviewed' : 'no conflict',
    migrationConsequence: 'reverse mapping retained at checkpoint C1',
    targetStatus: targetStatus,
    targetPath: switch (targetStatus) {
      _TargetStatus.identity => 'lib/features/generated/item_$index.dart',
      _TargetStatus.blocked => null,
      _TargetStatus.approved => 'lib/features/transactions/item_$index.dart',
    },
    reverseMapping: 'target item $index maps to current item $index',
    checkpoint: 'C${index % 7}',
    validationCommand: 'flutter analyze',
    independentFeatureCount: isShared ? 2 : 1,
    featureSpecificBehavior: isShared && index % 5 == 0,
    approvedInversion: isShared && index % 5 == 0,
  );
}

_MigrationEntry _validMigrationEntry(int index) {
  final status = switch (index % 3) {
    0 => _MappingStatus.identity,
    1 => _MappingStatus.blocked,
    _ => _MappingStatus.approved,
  };
  final currentPath = 'lib/features/current/item_$index.dart';
  final currentSymbol = 'CurrentItem$index';
  return _MigrationEntry(
    currentPath: currentPath,
    currentSymbol: currentSymbol,
    targetPath: switch (status) {
      _MappingStatus.identity => currentPath,
      _MappingStatus.blocked => null,
      _MappingStatus.approved => 'lib/features/target/item_$index.dart',
    },
    targetSymbol: switch (status) {
      _MappingStatus.identity => currentSymbol,
      _MappingStatus.blocked => null,
      _MappingStatus.approved => 'TargetItem$index',
    },
    status: status,
    approvalRecorded: status == _MappingStatus.approved,
    checkpoint: 'C${index % 7}',
    validationCommand: 'flutter analyze',
    rollbackAction: 'restore $currentPath and $currentSymbol',
    isCompatibilityAlias: false,
    aliasOwner: null,
    aliasLifetime: null,
    aliasRemovalCheckpoint: null,
    aliasStaleReferenceRule: null,
  );
}

String _readArtifact(String name) =>
    File('.kiro/specs/feature-folder-restructure/$name').readAsStringSync();

List<String> _tableCells(String row) {
  final content =
      row.substring(1, row.endsWith('|') ? row.length - 1 : row.length);
  return content.split('|').map((cell) => cell.trim()).toList();
}

void main() {
  group('Feature-folder restructure manifest properties', () {
    test(
      'Feature: feature-folder-restructure, Property 1 — ownership manifest closure',
      () {
        final cases = <({List<_OwnershipEntry> entries, bool expected})>[];
        for (var index = 0; index < 120; index++) {
          final entry = _validOwnershipEntry(index);
          switch (index % 10) {
            case 0:
              cases.add((entries: [entry], expected: true));
            case 1:
              cases.add(
                (
                  entries: [
                    _OwnershipEntry(
                      currentPath: entry.currentPath,
                      symbols: entry.symbols,
                      ownerFeature: null,
                      sharedException: false,
                      evidence: entry.evidence,
                      productionConsumers: entry.productionConsumers,
                      testConsumers: entry.testConsumers,
                      conflictStatus: entry.conflictStatus,
                      migrationConsequence: entry.migrationConsequence,
                      targetStatus: entry.targetStatus,
                      targetPath: entry.targetPath,
                      reverseMapping: entry.reverseMapping,
                      checkpoint: entry.checkpoint,
                      validationCommand: entry.validationCommand,
                      independentFeatureCount: entry.independentFeatureCount,
                      featureSpecificBehavior: entry.featureSpecificBehavior,
                      approvedInversion: entry.approvedInversion,
                    ),
                  ],
                  expected: false,
                ),
              );
            case 2:
              cases.add(
                (
                  entries: [
                    _OwnershipEntry(
                      currentPath: entry.currentPath,
                      symbols: entry.symbols,
                      ownerFeature: 'transactions',
                      sharedException: true,
                      evidence: entry.evidence,
                      productionConsumers: entry.productionConsumers,
                      testConsumers: entry.testConsumers,
                      conflictStatus: entry.conflictStatus,
                      migrationConsequence: entry.migrationConsequence,
                      targetStatus: entry.targetStatus,
                      targetPath: entry.targetPath,
                      reverseMapping: entry.reverseMapping,
                      checkpoint: entry.checkpoint,
                      validationCommand: entry.validationCommand,
                      independentFeatureCount: entry.independentFeatureCount,
                      featureSpecificBehavior: entry.featureSpecificBehavior,
                      approvedInversion: entry.approvedInversion,
                    ),
                  ],
                  expected: false,
                ),
              );
            case 3:
              cases.add(
                (
                  entries: [
                    _OwnershipEntry(
                      currentPath: entry.currentPath,
                      symbols: entry.symbols,
                      ownerFeature: entry.ownerFeature,
                      sharedException: entry.sharedException,
                      evidence: const [],
                      productionConsumers: entry.productionConsumers,
                      testConsumers: entry.testConsumers,
                      conflictStatus: entry.conflictStatus,
                      migrationConsequence: entry.migrationConsequence,
                      targetStatus: entry.targetStatus,
                      targetPath: entry.targetPath,
                      reverseMapping: entry.reverseMapping,
                      checkpoint: entry.checkpoint,
                      validationCommand: entry.validationCommand,
                      independentFeatureCount: entry.independentFeatureCount,
                      featureSpecificBehavior: entry.featureSpecificBehavior,
                      approvedInversion: entry.approvedInversion,
                    ),
                  ],
                  expected: false,
                ),
              );
            case 4:
              final duplicateTarget = _validOwnershipEntry(index + 1);
              cases.add(
                (
                  entries: [
                    entry,
                    _OwnershipEntry(
                      currentPath: duplicateTarget.currentPath,
                      symbols: duplicateTarget.symbols,
                      ownerFeature: duplicateTarget.ownerFeature,
                      sharedException: duplicateTarget.sharedException,
                      evidence: duplicateTarget.evidence,
                      productionConsumers: duplicateTarget.productionConsumers,
                      testConsumers: duplicateTarget.testConsumers,
                      conflictStatus: duplicateTarget.conflictStatus,
                      migrationConsequence:
                          duplicateTarget.migrationConsequence,
                      targetStatus: _TargetStatus.approved,
                      targetPath: entry.targetPath ??
                          'lib/features/target/duplicate.dart',
                      reverseMapping: duplicateTarget.reverseMapping,
                      checkpoint: duplicateTarget.checkpoint,
                      validationCommand: duplicateTarget.validationCommand,
                      independentFeatureCount:
                          duplicateTarget.independentFeatureCount,
                      featureSpecificBehavior:
                          duplicateTarget.featureSpecificBehavior,
                      approvedInversion: duplicateTarget.approvedInversion,
                    ),
                  ],
                  expected: entry.targetStatus != _TargetStatus.approved,
                ),
              );
            case 5:
              cases.add(
                (
                  entries: [
                    _OwnershipEntry(
                      currentPath: entry.currentPath,
                      symbols: entry.symbols,
                      ownerFeature: null,
                      sharedException: true,
                      evidence: entry.evidence,
                      productionConsumers: entry.productionConsumers,
                      testConsumers: entry.testConsumers,
                      conflictStatus: entry.conflictStatus,
                      migrationConsequence: entry.migrationConsequence,
                      targetStatus: entry.targetStatus,
                      targetPath: entry.targetPath,
                      reverseMapping: entry.reverseMapping,
                      checkpoint: entry.checkpoint,
                      validationCommand: entry.validationCommand,
                      independentFeatureCount: 1,
                      featureSpecificBehavior: true,
                      approvedInversion: false,
                    ),
                  ],
                  expected: false,
                ),
              );
            case 6:
              cases.add(
                (
                  entries: [
                    _OwnershipEntry(
                      currentPath: entry.currentPath,
                      symbols: entry.symbols,
                      ownerFeature: entry.ownerFeature,
                      sharedException: entry.sharedException,
                      evidence: entry.evidence,
                      productionConsumers: entry.productionConsumers,
                      testConsumers: entry.testConsumers,
                      conflictStatus: entry.conflictStatus,
                      migrationConsequence: entry.migrationConsequence,
                      targetStatus: entry.targetStatus,
                      targetPath: entry.targetPath,
                      reverseMapping: '',
                      checkpoint: entry.checkpoint,
                      validationCommand: entry.validationCommand,
                      independentFeatureCount: entry.independentFeatureCount,
                      featureSpecificBehavior: entry.featureSpecificBehavior,
                      approvedInversion: entry.approvedInversion,
                    ),
                  ],
                  expected: false,
                ),
              );
            case 7:
              cases.add(
                (
                  entries: [
                    _OwnershipEntry(
                      currentPath: entry.currentPath,
                      symbols: entry.symbols,
                      ownerFeature: entry.ownerFeature,
                      sharedException: entry.sharedException,
                      evidence: entry.evidence,
                      productionConsumers: const [],
                      testConsumers: entry.testConsumers,
                      conflictStatus: entry.conflictStatus,
                      migrationConsequence: entry.migrationConsequence,
                      targetStatus: entry.targetStatus,
                      targetPath: entry.targetPath,
                      reverseMapping: entry.reverseMapping,
                      checkpoint: entry.checkpoint,
                      validationCommand: entry.validationCommand,
                      independentFeatureCount: entry.independentFeatureCount,
                      featureSpecificBehavior: entry.featureSpecificBehavior,
                      approvedInversion: entry.approvedInversion,
                    ),
                  ],
                  expected: false,
                ),
              );
            case 8:
              cases.add(
                (
                  entries: [
                    _OwnershipEntry(
                      currentPath: entry.currentPath,
                      symbols: entry.symbols,
                      ownerFeature: entry.ownerFeature,
                      sharedException: entry.sharedException,
                      evidence: entry.evidence,
                      productionConsumers: entry.productionConsumers,
                      testConsumers: entry.testConsumers,
                      conflictStatus: entry.conflictStatus,
                      migrationConsequence: entry.migrationConsequence,
                      targetStatus: _TargetStatus.blocked,
                      targetPath: 'lib/features/unapproved/item_$index.dart',
                      reverseMapping: entry.reverseMapping,
                      checkpoint: entry.checkpoint,
                      validationCommand: entry.validationCommand,
                      independentFeatureCount: entry.independentFeatureCount,
                      featureSpecificBehavior: entry.featureSpecificBehavior,
                      approvedInversion: entry.approvedInversion,
                    ),
                  ],
                  expected: false,
                ),
              );
            case 9:
              cases.add((entries: [entry, entry], expected: false));
          }
        }

        expect(cases, hasLength(120));
        for (final testCase in cases) {
          expect(
            _ownershipManifestIsClosed(testCase.entries),
            testCase.expected,
          );
        }

        final inventory = _readArtifact('c0-ownership-inventory.md');
        final sharedManifest =
            _readArtifact('c0-shared-widget-ownership-manifest.md');
        expect(inventory, contains('Current path / symbols'));
        expect(inventory, contains('Evidence + production consumers'));
        expect(inventory, contains('Conflict / candidate owner'));
        expect(inventory, contains('Target + reverse mapping'));
        expect(
          inventory
              .split('\n')
              .where((line) => RegExp(r'^\| `').hasMatch(line))
              .length,
          greaterThanOrEqualTo(13),
        );
        expect(sharedManifest, contains('Independent features'));
        expect(
          sharedManifest,
          contains('Disposition / candidate owner/action'),
        );
        expect(sharedManifest, contains('Reverse map'));
        expect(
          sharedManifest
              .split('\n')
              .where((line) => RegExp(r'^\| `').hasMatch(line))
              .length,
          greaterThanOrEqualTo(74),
        );
      },
    );

    test(
      'Feature: feature-folder-restructure, Property 8 — reversible migration mapping',
      () {
        final cases = <({List<_MigrationEntry> entries, bool expected})>[];
        for (var index = 0; index < 120; index++) {
          final entry = _validMigrationEntry(index);
          switch (index % 10) {
            case 0:
            case 1:
            case 2:
              cases.add((entries: [entry], expected: true));
            case 3:
              cases.add(
                (
                  entries: [
                    _MigrationEntry(
                      currentPath: entry.currentPath,
                      currentSymbol: entry.currentSymbol,
                      targetPath: entry.targetPath,
                      targetSymbol: entry.targetSymbol,
                      status: entry.status,
                      approvalRecorded: entry.approvalRecorded,
                      checkpoint: '',
                      validationCommand: entry.validationCommand,
                      rollbackAction: entry.rollbackAction,
                      isCompatibilityAlias: entry.isCompatibilityAlias,
                      aliasOwner: entry.aliasOwner,
                      aliasLifetime: entry.aliasLifetime,
                      aliasRemovalCheckpoint: entry.aliasRemovalCheckpoint,
                      aliasStaleReferenceRule: entry.aliasStaleReferenceRule,
                    ),
                  ],
                  expected: false,
                ),
              );
            case 4:
              cases.add(
                (
                  entries: [entry, entry],
                  expected: false,
                ),
              );
            case 5:
              cases.add(
                (
                  entries: [
                    _MigrationEntry(
                      currentPath: entry.currentPath,
                      currentSymbol: entry.currentSymbol,
                      targetPath: 'lib/features/partial/item_$index.dart',
                      targetSymbol: null,
                      status: _MappingStatus.approved,
                      approvalRecorded: true,
                      checkpoint: entry.checkpoint,
                      validationCommand: entry.validationCommand,
                      rollbackAction: entry.rollbackAction,
                      isCompatibilityAlias: entry.isCompatibilityAlias,
                      aliasOwner: entry.aliasOwner,
                      aliasLifetime: entry.aliasLifetime,
                      aliasRemovalCheckpoint: entry.aliasRemovalCheckpoint,
                      aliasStaleReferenceRule: entry.aliasStaleReferenceRule,
                    ),
                  ],
                  expected: false,
                ),
              );
            case 6:
              cases.add(
                (
                  entries: [
                    _MigrationEntry(
                      currentPath: entry.currentPath,
                      currentSymbol: entry.currentSymbol,
                      targetPath: entry.targetPath,
                      targetSymbol: entry.targetSymbol,
                      status: entry.status,
                      approvalRecorded: entry.approvalRecorded,
                      checkpoint: entry.checkpoint,
                      validationCommand: entry.validationCommand,
                      rollbackAction: '',
                      isCompatibilityAlias: entry.isCompatibilityAlias,
                      aliasOwner: entry.aliasOwner,
                      aliasLifetime: entry.aliasLifetime,
                      aliasRemovalCheckpoint: entry.aliasRemovalCheckpoint,
                      aliasStaleReferenceRule: entry.aliasStaleReferenceRule,
                    ),
                  ],
                  expected: false,
                ),
              );
            case 7:
              cases.add(
                (
                  entries: [
                    _MigrationEntry(
                      currentPath: entry.currentPath,
                      currentSymbol: entry.currentSymbol,
                      targetPath: entry.targetPath,
                      targetSymbol: entry.targetSymbol,
                      status: _MappingStatus.approved,
                      approvalRecorded: false,
                      checkpoint: entry.checkpoint,
                      validationCommand: entry.validationCommand,
                      rollbackAction: entry.rollbackAction,
                      isCompatibilityAlias: entry.isCompatibilityAlias,
                      aliasOwner: entry.aliasOwner,
                      aliasLifetime: entry.aliasLifetime,
                      aliasRemovalCheckpoint: entry.aliasRemovalCheckpoint,
                      aliasStaleReferenceRule: entry.aliasStaleReferenceRule,
                    ),
                  ],
                  expected: false,
                ),
              );
            case 8:
              cases.add(
                (
                  entries: [
                    _MigrationEntry(
                      currentPath: entry.currentPath,
                      currentSymbol: entry.currentSymbol,
                      targetPath: entry.targetPath,
                      targetSymbol: entry.targetSymbol,
                      status: entry.status,
                      approvalRecorded: entry.approvalRecorded,
                      checkpoint: entry.checkpoint,
                      validationCommand: entry.validationCommand,
                      rollbackAction: entry.rollbackAction,
                      isCompatibilityAlias: true,
                      aliasOwner: null,
                      aliasLifetime: null,
                      aliasRemovalCheckpoint: null,
                      aliasStaleReferenceRule: null,
                    ),
                  ],
                  expected: false,
                ),
              );
            case 9:
              cases.add(
                (
                  entries: [
                    _MigrationEntry(
                      currentPath: entry.currentPath,
                      currentSymbol: entry.currentSymbol,
                      targetPath: entry.currentPath,
                      targetSymbol: entry.currentSymbol,
                      status: _MappingStatus.approved,
                      approvalRecorded: true,
                      checkpoint: entry.checkpoint,
                      validationCommand: entry.validationCommand,
                      rollbackAction: entry.rollbackAction,
                      isCompatibilityAlias: false,
                      aliasOwner: null,
                      aliasLifetime: null,
                      aliasRemovalCheckpoint: null,
                      aliasStaleReferenceRule: null,
                    ),
                  ],
                  expected: false,
                ),
              );
          }
        }

        expect(cases, hasLength(120));
        for (final testCase in cases) {
          expect(
            _migrationManifestIsReversible(testCase.entries),
            testCase.expected,
          );
        }

        final manifest = _readArtifact('c0-migration-manifest.md');
        expect(manifest, contains('Forward/reverse manifest entries'));
        expect(manifest, contains('Target → current rollback'));
        expect(manifest, contains('No compatibility alias exists'));
        final rows = manifest
            .split('\n')
            .where((line) => RegExp(r'^\| C[1-6] \|').hasMatch(line))
            .toList();
        expect(rows, isNotEmpty);
        for (final row in rows) {
          final cells = _tableCells(row);
          expect(cells.length, anyOf(10, 6));
          expect(cells[0], matches(RegExp(r'^C[1-6]$')));
          expect(cells[1], isNotEmpty);
          expect(cells[2], isNotEmpty);
          if (cells.length == 10) {
            expect(cells[3], isNotEmpty);
            expect(cells[8], isNotEmpty);
            expect(cells[9], isNotEmpty);
          } else {
            expect(cells[3], isNotEmpty);
            expect(cells[4], isNotEmpty);
            expect(cells[5], isNotEmpty);
          }
        }
      },
    );
  });
}
