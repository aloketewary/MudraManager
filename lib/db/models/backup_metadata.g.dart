// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backup_metadata.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetBackupMetadataCollection on Isar {
  IsarCollection<BackupMetadata> get backupMetadatas => this.collection();
}

const BackupMetadataSchema = CollectionSchema(
  name: r'BackupMetadata',
  id: 8223742757090384385,
  properties: {
    r'backupDate': PropertySchema(
      id: 0,
      name: r'backupDate',
      type: IsarType.dateTime,
    ),
    r'fileName': PropertySchema(
      id: 1,
      name: r'fileName',
      type: IsarType.string,
    ),
    r'filePath': PropertySchema(
      id: 2,
      name: r'filePath',
      type: IsarType.string,
    ),
    r'fileSize': PropertySchema(id: 3, name: r'fileSize', type: IsarType.long),
    r'includesAttachments': PropertySchema(
      id: 4,
      name: r'includesAttachments',
      type: IsarType.bool,
    ),
    r'recordCount': PropertySchema(
      id: 5,
      name: r'recordCount',
      type: IsarType.long,
    ),
  },

  estimateSize: _backupMetadataEstimateSize,
  serialize: _backupMetadataSerialize,
  deserialize: _backupMetadataDeserialize,
  deserializeProp: _backupMetadataDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},

  getId: _backupMetadataGetId,
  getLinks: _backupMetadataGetLinks,
  attach: _backupMetadataAttach,
  version: '3.3.0',
);

int _backupMetadataEstimateSize(
  BackupMetadata object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.fileName.length * 3;
  {
    final value = object.filePath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _backupMetadataSerialize(
  BackupMetadata object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.backupDate);
  writer.writeString(offsets[1], object.fileName);
  writer.writeString(offsets[2], object.filePath);
  writer.writeLong(offsets[3], object.fileSize);
  writer.writeBool(offsets[4], object.includesAttachments);
  writer.writeLong(offsets[5], object.recordCount);
}

BackupMetadata _backupMetadataDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = BackupMetadata();
  object.backupDate = reader.readDateTime(offsets[0]);
  object.fileName = reader.readString(offsets[1]);
  object.filePath = reader.readStringOrNull(offsets[2]);
  object.fileSize = reader.readLong(offsets[3]);
  object.id = id;
  object.includesAttachments = reader.readBool(offsets[4]);
  object.recordCount = reader.readLong(offsets[5]);
  return object;
}

P _backupMetadataDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _backupMetadataGetId(BackupMetadata object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _backupMetadataGetLinks(BackupMetadata object) {
  return [];
}

void _backupMetadataAttach(
  IsarCollection<dynamic> col,
  Id id,
  BackupMetadata object,
) {
  object.id = id;
}

extension BackupMetadataQueryWhereSort
    on QueryBuilder<BackupMetadata, BackupMetadata, QWhere> {
  QueryBuilder<BackupMetadata, BackupMetadata, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension BackupMetadataQueryWhere
    on QueryBuilder<BackupMetadata, BackupMetadata, QWhereClause> {
  QueryBuilder<BackupMetadata, BackupMetadata, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterWhereClause> idNotEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension BackupMetadataQueryFilter
    on QueryBuilder<BackupMetadata, BackupMetadata, QFilterCondition> {
  QueryBuilder<BackupMetadata, BackupMetadata, QAfterFilterCondition>
  backupDateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'backupDate', value: value),
      );
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterFilterCondition>
  backupDateGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'backupDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterFilterCondition>
  backupDateLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'backupDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterFilterCondition>
  backupDateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'backupDate',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterFilterCondition>
  fileNameEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'fileName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterFilterCondition>
  fileNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'fileName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterFilterCondition>
  fileNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'fileName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterFilterCondition>
  fileNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'fileName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterFilterCondition>
  fileNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'fileName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterFilterCondition>
  fileNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'fileName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterFilterCondition>
  fileNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'fileName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterFilterCondition>
  fileNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'fileName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterFilterCondition>
  fileNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'fileName', value: ''),
      );
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterFilterCondition>
  fileNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'fileName', value: ''),
      );
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterFilterCondition>
  filePathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'filePath'),
      );
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterFilterCondition>
  filePathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'filePath'),
      );
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterFilterCondition>
  filePathEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'filePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterFilterCondition>
  filePathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'filePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterFilterCondition>
  filePathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'filePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterFilterCondition>
  filePathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'filePath',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterFilterCondition>
  filePathStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'filePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterFilterCondition>
  filePathEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'filePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterFilterCondition>
  filePathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'filePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterFilterCondition>
  filePathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'filePath',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterFilterCondition>
  filePathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'filePath', value: ''),
      );
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterFilterCondition>
  filePathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'filePath', value: ''),
      );
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterFilterCondition>
  fileSizeEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'fileSize', value: value),
      );
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterFilterCondition>
  fileSizeGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'fileSize',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterFilterCondition>
  fileSizeLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'fileSize',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterFilterCondition>
  fileSizeBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'fileSize',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterFilterCondition>
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterFilterCondition>
  idLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterFilterCondition>
  includesAttachmentsEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'includesAttachments', value: value),
      );
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterFilterCondition>
  recordCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'recordCount', value: value),
      );
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterFilterCondition>
  recordCountGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'recordCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterFilterCondition>
  recordCountLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'recordCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterFilterCondition>
  recordCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'recordCount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension BackupMetadataQueryObject
    on QueryBuilder<BackupMetadata, BackupMetadata, QFilterCondition> {}

extension BackupMetadataQueryLinks
    on QueryBuilder<BackupMetadata, BackupMetadata, QFilterCondition> {}

extension BackupMetadataQuerySortBy
    on QueryBuilder<BackupMetadata, BackupMetadata, QSortBy> {
  QueryBuilder<BackupMetadata, BackupMetadata, QAfterSortBy>
  sortByBackupDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'backupDate', Sort.asc);
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterSortBy>
  sortByBackupDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'backupDate', Sort.desc);
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterSortBy> sortByFileName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileName', Sort.asc);
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterSortBy>
  sortByFileNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileName', Sort.desc);
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterSortBy> sortByFilePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filePath', Sort.asc);
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterSortBy>
  sortByFilePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filePath', Sort.desc);
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterSortBy> sortByFileSize() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileSize', Sort.asc);
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterSortBy>
  sortByFileSizeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileSize', Sort.desc);
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterSortBy>
  sortByIncludesAttachments() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'includesAttachments', Sort.asc);
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterSortBy>
  sortByIncludesAttachmentsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'includesAttachments', Sort.desc);
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterSortBy>
  sortByRecordCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recordCount', Sort.asc);
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterSortBy>
  sortByRecordCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recordCount', Sort.desc);
    });
  }
}

extension BackupMetadataQuerySortThenBy
    on QueryBuilder<BackupMetadata, BackupMetadata, QSortThenBy> {
  QueryBuilder<BackupMetadata, BackupMetadata, QAfterSortBy>
  thenByBackupDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'backupDate', Sort.asc);
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterSortBy>
  thenByBackupDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'backupDate', Sort.desc);
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterSortBy> thenByFileName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileName', Sort.asc);
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterSortBy>
  thenByFileNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileName', Sort.desc);
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterSortBy> thenByFilePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filePath', Sort.asc);
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterSortBy>
  thenByFilePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filePath', Sort.desc);
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterSortBy> thenByFileSize() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileSize', Sort.asc);
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterSortBy>
  thenByFileSizeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileSize', Sort.desc);
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterSortBy>
  thenByIncludesAttachments() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'includesAttachments', Sort.asc);
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterSortBy>
  thenByIncludesAttachmentsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'includesAttachments', Sort.desc);
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterSortBy>
  thenByRecordCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recordCount', Sort.asc);
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QAfterSortBy>
  thenByRecordCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recordCount', Sort.desc);
    });
  }
}

extension BackupMetadataQueryWhereDistinct
    on QueryBuilder<BackupMetadata, BackupMetadata, QDistinct> {
  QueryBuilder<BackupMetadata, BackupMetadata, QDistinct>
  distinctByBackupDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'backupDate');
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QDistinct> distinctByFileName({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fileName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QDistinct> distinctByFilePath({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'filePath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QDistinct> distinctByFileSize() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fileSize');
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QDistinct>
  distinctByIncludesAttachments() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'includesAttachments');
    });
  }

  QueryBuilder<BackupMetadata, BackupMetadata, QDistinct>
  distinctByRecordCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'recordCount');
    });
  }
}

extension BackupMetadataQueryProperty
    on QueryBuilder<BackupMetadata, BackupMetadata, QQueryProperty> {
  QueryBuilder<BackupMetadata, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<BackupMetadata, DateTime, QQueryOperations>
  backupDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'backupDate');
    });
  }

  QueryBuilder<BackupMetadata, String, QQueryOperations> fileNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fileName');
    });
  }

  QueryBuilder<BackupMetadata, String?, QQueryOperations> filePathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'filePath');
    });
  }

  QueryBuilder<BackupMetadata, int, QQueryOperations> fileSizeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fileSize');
    });
  }

  QueryBuilder<BackupMetadata, bool, QQueryOperations>
  includesAttachmentsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'includesAttachments');
    });
  }

  QueryBuilder<BackupMetadata, int, QQueryOperations> recordCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'recordCount');
    });
  }
}
