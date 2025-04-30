// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_transaction.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetPendingTransactionCollection on Isar {
  IsarCollection<PendingTransaction> get pendingTransactions =>
      this.collection();
}

const PendingTransactionSchema = CollectionSchema(
  name: r'PendingTransaction',
  id: -8449445791657070199,
  properties: {
    r'account': PropertySchema(
      id: 0,
      name: r'account',
      type: IsarType.string,
    ),
    r'amount': PropertySchema(
      id: 1,
      name: r'amount',
      type: IsarType.double,
    ),
    r'body': PropertySchema(
      id: 2,
      name: r'body',
      type: IsarType.string,
    ),
    r'category': PropertySchema(
      id: 3,
      name: r'category',
      type: IsarType.string,
    ),
    r'date': PropertySchema(
      id: 4,
      name: r'date',
      type: IsarType.dateTime,
    ),
    r'fromBank': PropertySchema(
      id: 5,
      name: r'fromBank',
      type: IsarType.string,
    ),
    r'isIncome': PropertySchema(
      id: 6,
      name: r'isIncome',
      type: IsarType.bool,
    ),
    r'sender': PropertySchema(
      id: 7,
      name: r'sender',
      type: IsarType.string,
    ),
    r'smsHash': PropertySchema(
      id: 8,
      name: r'smsHash',
      type: IsarType.string,
    ),
    r'toAccount': PropertySchema(
      id: 9,
      name: r'toAccount',
      type: IsarType.string,
    ),
    r'transactionRef': PropertySchema(
      id: 10,
      name: r'transactionRef',
      type: IsarType.string,
    ),
    r'type': PropertySchema(
      id: 11,
      name: r'type',
      type: IsarType.string,
    )
  },
  estimateSize: _pendingTransactionEstimateSize,
  serialize: _pendingTransactionSerialize,
  deserialize: _pendingTransactionDeserialize,
  deserializeProp: _pendingTransactionDeserializeProp,
  idName: r'id',
  indexes: {
    r'smsHash': IndexSchema(
      id: 2345896571030605512,
      name: r'smsHash',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'smsHash',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _pendingTransactionGetId,
  getLinks: _pendingTransactionGetLinks,
  attach: _pendingTransactionAttach,
  version: '3.1.0+1',
);

int _pendingTransactionEstimateSize(
  PendingTransaction object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.account;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.body.length * 3;
  {
    final value = object.category;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.fromBank;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.sender.length * 3;
  bytesCount += 3 + object.smsHash.length * 3;
  {
    final value = object.toAccount;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.transactionRef;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.type;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _pendingTransactionSerialize(
  PendingTransaction object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.account);
  writer.writeDouble(offsets[1], object.amount);
  writer.writeString(offsets[2], object.body);
  writer.writeString(offsets[3], object.category);
  writer.writeDateTime(offsets[4], object.date);
  writer.writeString(offsets[5], object.fromBank);
  writer.writeBool(offsets[6], object.isIncome);
  writer.writeString(offsets[7], object.sender);
  writer.writeString(offsets[8], object.smsHash);
  writer.writeString(offsets[9], object.toAccount);
  writer.writeString(offsets[10], object.transactionRef);
  writer.writeString(offsets[11], object.type);
}

PendingTransaction _pendingTransactionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = PendingTransaction();
  object.account = reader.readStringOrNull(offsets[0]);
  object.amount = reader.readDoubleOrNull(offsets[1]);
  object.body = reader.readString(offsets[2]);
  object.category = reader.readStringOrNull(offsets[3]);
  object.date = reader.readDateTime(offsets[4]);
  object.fromBank = reader.readStringOrNull(offsets[5]);
  object.id = id;
  object.isIncome = reader.readBoolOrNull(offsets[6]);
  object.sender = reader.readString(offsets[7]);
  object.smsHash = reader.readString(offsets[8]);
  object.toAccount = reader.readStringOrNull(offsets[9]);
  object.transactionRef = reader.readStringOrNull(offsets[10]);
  object.type = reader.readStringOrNull(offsets[11]);
  return object;
}

P _pendingTransactionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readDoubleOrNull(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readDateTime(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readBoolOrNull(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _pendingTransactionGetId(PendingTransaction object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _pendingTransactionGetLinks(
    PendingTransaction object) {
  return [];
}

void _pendingTransactionAttach(
    IsarCollection<dynamic> col, Id id, PendingTransaction object) {
  object.id = id;
}

extension PendingTransactionByIndex on IsarCollection<PendingTransaction> {
  Future<PendingTransaction?> getBySmsHash(String smsHash) {
    return getByIndex(r'smsHash', [smsHash]);
  }

  PendingTransaction? getBySmsHashSync(String smsHash) {
    return getByIndexSync(r'smsHash', [smsHash]);
  }

  Future<bool> deleteBySmsHash(String smsHash) {
    return deleteByIndex(r'smsHash', [smsHash]);
  }

  bool deleteBySmsHashSync(String smsHash) {
    return deleteByIndexSync(r'smsHash', [smsHash]);
  }

  Future<List<PendingTransaction?>> getAllBySmsHash(
      List<String> smsHashValues) {
    final values = smsHashValues.map((e) => [e]).toList();
    return getAllByIndex(r'smsHash', values);
  }

  List<PendingTransaction?> getAllBySmsHashSync(List<String> smsHashValues) {
    final values = smsHashValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'smsHash', values);
  }

  Future<int> deleteAllBySmsHash(List<String> smsHashValues) {
    final values = smsHashValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'smsHash', values);
  }

  int deleteAllBySmsHashSync(List<String> smsHashValues) {
    final values = smsHashValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'smsHash', values);
  }

  Future<Id> putBySmsHash(PendingTransaction object) {
    return putByIndex(r'smsHash', object);
  }

  Id putBySmsHashSync(PendingTransaction object, {bool saveLinks = true}) {
    return putByIndexSync(r'smsHash', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllBySmsHash(List<PendingTransaction> objects) {
    return putAllByIndex(r'smsHash', objects);
  }

  List<Id> putAllBySmsHashSync(List<PendingTransaction> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'smsHash', objects, saveLinks: saveLinks);
  }
}

extension PendingTransactionQueryWhereSort
    on QueryBuilder<PendingTransaction, PendingTransaction, QWhere> {
  QueryBuilder<PendingTransaction, PendingTransaction, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension PendingTransactionQueryWhere
    on QueryBuilder<PendingTransaction, PendingTransaction, QWhereClause> {
  QueryBuilder<PendingTransaction, PendingTransaction, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterWhereClause>
      idNotEqualTo(Id id) {
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

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterWhereClause>
      idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterWhereClause>
      smsHashEqualTo(String smsHash) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'smsHash',
        value: [smsHash],
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterWhereClause>
      smsHashNotEqualTo(String smsHash) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'smsHash',
              lower: [],
              upper: [smsHash],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'smsHash',
              lower: [smsHash],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'smsHash',
              lower: [smsHash],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'smsHash',
              lower: [],
              upper: [smsHash],
              includeUpper: false,
            ));
      }
    });
  }
}

extension PendingTransactionQueryFilter
    on QueryBuilder<PendingTransaction, PendingTransaction, QFilterCondition> {
  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      accountIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'account',
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      accountIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'account',
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      accountEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'account',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      accountGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'account',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      accountLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'account',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      accountBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'account',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      accountStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'account',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      accountEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'account',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      accountContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'account',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      accountMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'account',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      accountIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'account',
        value: '',
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      accountIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'account',
        value: '',
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      amountIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'amount',
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      amountIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'amount',
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      amountEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'amount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      amountGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'amount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      amountLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'amount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      amountBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'amount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      bodyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'body',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      bodyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'body',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      bodyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'body',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      bodyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'body',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      bodyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'body',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      bodyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'body',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      bodyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'body',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      bodyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'body',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      bodyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'body',
        value: '',
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      bodyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'body',
        value: '',
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      categoryIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'category',
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      categoryIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'category',
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      categoryEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      categoryGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      categoryLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      categoryBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'category',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      categoryStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      categoryEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      categoryContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      categoryMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'category',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      categoryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'category',
        value: '',
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      categoryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'category',
        value: '',
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      dateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      dateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      dateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      dateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'date',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      fromBankIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'fromBank',
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      fromBankIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'fromBank',
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      fromBankEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fromBank',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      fromBankGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fromBank',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      fromBankLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fromBank',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      fromBankBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fromBank',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      fromBankStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'fromBank',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      fromBankEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'fromBank',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      fromBankContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'fromBank',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      fromBankMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'fromBank',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      fromBankIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fromBank',
        value: '',
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      fromBankIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'fromBank',
        value: '',
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      isIncomeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'isIncome',
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      isIncomeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'isIncome',
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      isIncomeEqualTo(bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isIncome',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      senderEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sender',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      senderGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sender',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      senderLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sender',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      senderBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sender',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      senderStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'sender',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      senderEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'sender',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      senderContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sender',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      senderMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sender',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      senderIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sender',
        value: '',
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      senderIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sender',
        value: '',
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      smsHashEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'smsHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      smsHashGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'smsHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      smsHashLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'smsHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      smsHashBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'smsHash',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      smsHashStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'smsHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      smsHashEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'smsHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      smsHashContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'smsHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      smsHashMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'smsHash',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      smsHashIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'smsHash',
        value: '',
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      smsHashIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'smsHash',
        value: '',
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      toAccountIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'toAccount',
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      toAccountIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'toAccount',
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      toAccountEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'toAccount',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      toAccountGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'toAccount',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      toAccountLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'toAccount',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      toAccountBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'toAccount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      toAccountStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'toAccount',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      toAccountEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'toAccount',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      toAccountContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'toAccount',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      toAccountMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'toAccount',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      toAccountIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'toAccount',
        value: '',
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      toAccountIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'toAccount',
        value: '',
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      transactionRefIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'transactionRef',
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      transactionRefIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'transactionRef',
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      transactionRefEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'transactionRef',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      transactionRefGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'transactionRef',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      transactionRefLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'transactionRef',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      transactionRefBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'transactionRef',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      transactionRefStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'transactionRef',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      transactionRefEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'transactionRef',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      transactionRefContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'transactionRef',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      transactionRefMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'transactionRef',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      transactionRefIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'transactionRef',
        value: '',
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      transactionRefIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'transactionRef',
        value: '',
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      typeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'type',
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      typeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'type',
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      typeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      typeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      typeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      typeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'type',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      typeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      typeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      typeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      typeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'type',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      typeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: '',
      ));
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterFilterCondition>
      typeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'type',
        value: '',
      ));
    });
  }
}

extension PendingTransactionQueryObject
    on QueryBuilder<PendingTransaction, PendingTransaction, QFilterCondition> {}

extension PendingTransactionQueryLinks
    on QueryBuilder<PendingTransaction, PendingTransaction, QFilterCondition> {}

extension PendingTransactionQuerySortBy
    on QueryBuilder<PendingTransaction, PendingTransaction, QSortBy> {
  QueryBuilder<PendingTransaction, PendingTransaction, QAfterSortBy>
      sortByAccount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'account', Sort.asc);
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterSortBy>
      sortByAccountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'account', Sort.desc);
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterSortBy>
      sortByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterSortBy>
      sortByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterSortBy>
      sortByBody() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'body', Sort.asc);
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterSortBy>
      sortByBodyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'body', Sort.desc);
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterSortBy>
      sortByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterSortBy>
      sortByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterSortBy>
      sortByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterSortBy>
      sortByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterSortBy>
      sortByFromBank() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fromBank', Sort.asc);
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterSortBy>
      sortByFromBankDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fromBank', Sort.desc);
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterSortBy>
      sortByIsIncome() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isIncome', Sort.asc);
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterSortBy>
      sortByIsIncomeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isIncome', Sort.desc);
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterSortBy>
      sortBySender() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sender', Sort.asc);
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterSortBy>
      sortBySenderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sender', Sort.desc);
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterSortBy>
      sortBySmsHash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'smsHash', Sort.asc);
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterSortBy>
      sortBySmsHashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'smsHash', Sort.desc);
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterSortBy>
      sortByToAccount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toAccount', Sort.asc);
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterSortBy>
      sortByToAccountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toAccount', Sort.desc);
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterSortBy>
      sortByTransactionRef() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transactionRef', Sort.asc);
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterSortBy>
      sortByTransactionRefDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transactionRef', Sort.desc);
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterSortBy>
      sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterSortBy>
      sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }
}

extension PendingTransactionQuerySortThenBy
    on QueryBuilder<PendingTransaction, PendingTransaction, QSortThenBy> {
  QueryBuilder<PendingTransaction, PendingTransaction, QAfterSortBy>
      thenByAccount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'account', Sort.asc);
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterSortBy>
      thenByAccountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'account', Sort.desc);
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterSortBy>
      thenByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterSortBy>
      thenByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterSortBy>
      thenByBody() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'body', Sort.asc);
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterSortBy>
      thenByBodyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'body', Sort.desc);
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterSortBy>
      thenByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterSortBy>
      thenByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterSortBy>
      thenByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterSortBy>
      thenByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterSortBy>
      thenByFromBank() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fromBank', Sort.asc);
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterSortBy>
      thenByFromBankDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fromBank', Sort.desc);
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterSortBy>
      thenByIsIncome() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isIncome', Sort.asc);
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterSortBy>
      thenByIsIncomeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isIncome', Sort.desc);
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterSortBy>
      thenBySender() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sender', Sort.asc);
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterSortBy>
      thenBySenderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sender', Sort.desc);
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterSortBy>
      thenBySmsHash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'smsHash', Sort.asc);
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterSortBy>
      thenBySmsHashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'smsHash', Sort.desc);
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterSortBy>
      thenByToAccount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toAccount', Sort.asc);
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterSortBy>
      thenByToAccountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toAccount', Sort.desc);
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterSortBy>
      thenByTransactionRef() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transactionRef', Sort.asc);
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterSortBy>
      thenByTransactionRefDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transactionRef', Sort.desc);
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterSortBy>
      thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QAfterSortBy>
      thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }
}

extension PendingTransactionQueryWhereDistinct
    on QueryBuilder<PendingTransaction, PendingTransaction, QDistinct> {
  QueryBuilder<PendingTransaction, PendingTransaction, QDistinct>
      distinctByAccount({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'account', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QDistinct>
      distinctByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'amount');
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QDistinct>
      distinctByBody({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'body', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QDistinct>
      distinctByCategory({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'category', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QDistinct>
      distinctByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'date');
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QDistinct>
      distinctByFromBank({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fromBank', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QDistinct>
      distinctByIsIncome() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isIncome');
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QDistinct>
      distinctBySender({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sender', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QDistinct>
      distinctBySmsHash({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'smsHash', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QDistinct>
      distinctByToAccount({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'toAccount', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QDistinct>
      distinctByTransactionRef({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'transactionRef',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PendingTransaction, PendingTransaction, QDistinct>
      distinctByType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type', caseSensitive: caseSensitive);
    });
  }
}

extension PendingTransactionQueryProperty
    on QueryBuilder<PendingTransaction, PendingTransaction, QQueryProperty> {
  QueryBuilder<PendingTransaction, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<PendingTransaction, String?, QQueryOperations>
      accountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'account');
    });
  }

  QueryBuilder<PendingTransaction, double?, QQueryOperations> amountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'amount');
    });
  }

  QueryBuilder<PendingTransaction, String, QQueryOperations> bodyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'body');
    });
  }

  QueryBuilder<PendingTransaction, String?, QQueryOperations>
      categoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'category');
    });
  }

  QueryBuilder<PendingTransaction, DateTime, QQueryOperations> dateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'date');
    });
  }

  QueryBuilder<PendingTransaction, String?, QQueryOperations>
      fromBankProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fromBank');
    });
  }

  QueryBuilder<PendingTransaction, bool?, QQueryOperations> isIncomeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isIncome');
    });
  }

  QueryBuilder<PendingTransaction, String, QQueryOperations> senderProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sender');
    });
  }

  QueryBuilder<PendingTransaction, String, QQueryOperations> smsHashProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'smsHash');
    });
  }

  QueryBuilder<PendingTransaction, String?, QQueryOperations>
      toAccountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'toAccount');
    });
  }

  QueryBuilder<PendingTransaction, String?, QQueryOperations>
      transactionRefProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'transactionRef');
    });
  }

  QueryBuilder<PendingTransaction, String?, QQueryOperations> typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }
}
