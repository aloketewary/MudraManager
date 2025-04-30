// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget_category_allocation.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetBudgetCategoryAllocationCollection on Isar {
  IsarCollection<BudgetCategoryAllocation> get budgetCategoryAllocations =>
      this.collection();
}

const BudgetCategoryAllocationSchema = CollectionSchema(
  name: r'BudgetCategoryAllocation',
  id: 3863982599658467171,
  properties: {
    r'amount': PropertySchema(
      id: 0,
      name: r'amount',
      type: IsarType.double,
    )
  },
  estimateSize: _budgetCategoryAllocationEstimateSize,
  serialize: _budgetCategoryAllocationSerialize,
  deserialize: _budgetCategoryAllocationDeserialize,
  deserializeProp: _budgetCategoryAllocationDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {
    r'category': LinkSchema(
      id: -7708069197754255179,
      name: r'category',
      target: r'Category',
      single: true,
    ),
    r'budget': LinkSchema(
      id: -2120880564262900080,
      name: r'budget',
      target: r'Budget',
      single: true,
    )
  },
  embeddedSchemas: {},
  getId: _budgetCategoryAllocationGetId,
  getLinks: _budgetCategoryAllocationGetLinks,
  attach: _budgetCategoryAllocationAttach,
  version: '3.1.0+1',
);

int _budgetCategoryAllocationEstimateSize(
  BudgetCategoryAllocation object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _budgetCategoryAllocationSerialize(
  BudgetCategoryAllocation object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.amount);
}

BudgetCategoryAllocation _budgetCategoryAllocationDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = BudgetCategoryAllocation();
  object.amount = reader.readDouble(offsets[0]);
  object.id = id;
  return object;
}

P _budgetCategoryAllocationDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDouble(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _budgetCategoryAllocationGetId(BudgetCategoryAllocation object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _budgetCategoryAllocationGetLinks(
    BudgetCategoryAllocation object) {
  return [object.category, object.budget];
}

void _budgetCategoryAllocationAttach(
    IsarCollection<dynamic> col, Id id, BudgetCategoryAllocation object) {
  object.id = id;
  object.category.attach(col, col.isar.collection<Category>(), r'category', id);
  object.budget.attach(col, col.isar.collection<Budget>(), r'budget', id);
}

extension BudgetCategoryAllocationQueryWhereSort on QueryBuilder<
    BudgetCategoryAllocation, BudgetCategoryAllocation, QWhere> {
  QueryBuilder<BudgetCategoryAllocation, BudgetCategoryAllocation, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension BudgetCategoryAllocationQueryWhere on QueryBuilder<
    BudgetCategoryAllocation, BudgetCategoryAllocation, QWhereClause> {
  QueryBuilder<BudgetCategoryAllocation, BudgetCategoryAllocation,
      QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<BudgetCategoryAllocation, BudgetCategoryAllocation,
      QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<BudgetCategoryAllocation, BudgetCategoryAllocation,
      QAfterWhereClause> idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<BudgetCategoryAllocation, BudgetCategoryAllocation,
      QAfterWhereClause> idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<BudgetCategoryAllocation, BudgetCategoryAllocation,
      QAfterWhereClause> idBetween(
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
}

extension BudgetCategoryAllocationQueryFilter on QueryBuilder<
    BudgetCategoryAllocation, BudgetCategoryAllocation, QFilterCondition> {
  QueryBuilder<BudgetCategoryAllocation, BudgetCategoryAllocation,
      QAfterFilterCondition> amountEqualTo(
    double value, {
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

  QueryBuilder<BudgetCategoryAllocation, BudgetCategoryAllocation,
      QAfterFilterCondition> amountGreaterThan(
    double value, {
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

  QueryBuilder<BudgetCategoryAllocation, BudgetCategoryAllocation,
      QAfterFilterCondition> amountLessThan(
    double value, {
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

  QueryBuilder<BudgetCategoryAllocation, BudgetCategoryAllocation,
      QAfterFilterCondition> amountBetween(
    double lower,
    double upper, {
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

  QueryBuilder<BudgetCategoryAllocation, BudgetCategoryAllocation,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<BudgetCategoryAllocation, BudgetCategoryAllocation,
      QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<BudgetCategoryAllocation, BudgetCategoryAllocation,
      QAfterFilterCondition> idLessThan(
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

  QueryBuilder<BudgetCategoryAllocation, BudgetCategoryAllocation,
      QAfterFilterCondition> idBetween(
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
}

extension BudgetCategoryAllocationQueryObject on QueryBuilder<
    BudgetCategoryAllocation, BudgetCategoryAllocation, QFilterCondition> {}

extension BudgetCategoryAllocationQueryLinks on QueryBuilder<
    BudgetCategoryAllocation, BudgetCategoryAllocation, QFilterCondition> {
  QueryBuilder<BudgetCategoryAllocation, BudgetCategoryAllocation,
      QAfterFilterCondition> category(FilterQuery<Category> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'category');
    });
  }

  QueryBuilder<BudgetCategoryAllocation, BudgetCategoryAllocation,
      QAfterFilterCondition> categoryIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'category', 0, true, 0, true);
    });
  }

  QueryBuilder<BudgetCategoryAllocation, BudgetCategoryAllocation,
      QAfterFilterCondition> budget(FilterQuery<Budget> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'budget');
    });
  }

  QueryBuilder<BudgetCategoryAllocation, BudgetCategoryAllocation,
      QAfterFilterCondition> budgetIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'budget', 0, true, 0, true);
    });
  }
}

extension BudgetCategoryAllocationQuerySortBy on QueryBuilder<
    BudgetCategoryAllocation, BudgetCategoryAllocation, QSortBy> {
  QueryBuilder<BudgetCategoryAllocation, BudgetCategoryAllocation, QAfterSortBy>
      sortByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<BudgetCategoryAllocation, BudgetCategoryAllocation, QAfterSortBy>
      sortByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }
}

extension BudgetCategoryAllocationQuerySortThenBy on QueryBuilder<
    BudgetCategoryAllocation, BudgetCategoryAllocation, QSortThenBy> {
  QueryBuilder<BudgetCategoryAllocation, BudgetCategoryAllocation, QAfterSortBy>
      thenByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<BudgetCategoryAllocation, BudgetCategoryAllocation, QAfterSortBy>
      thenByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<BudgetCategoryAllocation, BudgetCategoryAllocation, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<BudgetCategoryAllocation, BudgetCategoryAllocation, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }
}

extension BudgetCategoryAllocationQueryWhereDistinct on QueryBuilder<
    BudgetCategoryAllocation, BudgetCategoryAllocation, QDistinct> {
  QueryBuilder<BudgetCategoryAllocation, BudgetCategoryAllocation, QDistinct>
      distinctByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'amount');
    });
  }
}

extension BudgetCategoryAllocationQueryProperty on QueryBuilder<
    BudgetCategoryAllocation, BudgetCategoryAllocation, QQueryProperty> {
  QueryBuilder<BudgetCategoryAllocation, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<BudgetCategoryAllocation, double, QQueryOperations>
      amountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'amount');
    });
  }
}
