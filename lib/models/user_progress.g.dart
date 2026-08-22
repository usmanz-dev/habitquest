// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_progress.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetUserProgressCollection on Isar {
  IsarCollection<UserProgress> get userProgress => this.collection();
}

const UserProgressSchema = CollectionSchema(
  name: r'UserProgress',
  id: 518958300452706037,
  properties: {
    r'currentAvatarLevel': PropertySchema(
      id: 0,
      name: r'currentAvatarLevel',
      type: IsarType.long,
    ),
    r'currentHP': PropertySchema(
      id: 1,
      name: r'currentHP',
      type: IsarType.long,
    ),
    r'currentStreak': PropertySchema(
      id: 2,
      name: r'currentStreak',
      type: IsarType.long,
    ),
    r'longestStreak': PropertySchema(
      id: 3,
      name: r'longestStreak',
      type: IsarType.long,
    ),
    r'premiumAvatarUnlocked': PropertySchema(
      id: 4,
      name: r'premiumAvatarUnlocked',
      type: IsarType.bool,
    ),
    r'totalGold': PropertySchema(
      id: 5,
      name: r'totalGold',
      type: IsarType.long,
    ),
    r'totalXP': PropertySchema(
      id: 6,
      name: r'totalXP',
      type: IsarType.long,
    )
  },
  estimateSize: _userProgressEstimateSize,
  serialize: _userProgressSerialize,
  deserialize: _userProgressDeserialize,
  deserializeProp: _userProgressDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _userProgressGetId,
  getLinks: _userProgressGetLinks,
  attach: _userProgressAttach,
  version: '3.1.0+1',
);

int _userProgressEstimateSize(
  UserProgress object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _userProgressSerialize(
  UserProgress object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.currentAvatarLevel);
  writer.writeLong(offsets[1], object.currentHP);
  writer.writeLong(offsets[2], object.currentStreak);
  writer.writeLong(offsets[3], object.longestStreak);
  writer.writeBool(offsets[4], object.premiumAvatarUnlocked);
  writer.writeLong(offsets[5], object.totalGold);
  writer.writeLong(offsets[6], object.totalXP);
}

UserProgress _userProgressDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = UserProgress();
  object.currentAvatarLevel = reader.readLong(offsets[0]);
  object.currentHP = reader.readLong(offsets[1]);
  object.currentStreak = reader.readLong(offsets[2]);
  object.id = id;
  object.longestStreak = reader.readLong(offsets[3]);
  object.premiumAvatarUnlocked = reader.readBool(offsets[4]);
  object.totalGold = reader.readLong(offsets[5]);
  object.totalXP = reader.readLong(offsets[6]);
  return object;
}

P _userProgressDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _userProgressGetId(UserProgress object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _userProgressGetLinks(UserProgress object) {
  return [];
}

void _userProgressAttach(
    IsarCollection<dynamic> col, Id id, UserProgress object) {
  object.id = id;
}

extension UserProgressQueryWhereSort
    on QueryBuilder<UserProgress, UserProgress, QWhere> {
  QueryBuilder<UserProgress, UserProgress, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension UserProgressQueryWhere
    on QueryBuilder<UserProgress, UserProgress, QWhereClause> {
  QueryBuilder<UserProgress, UserProgress, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<UserProgress, UserProgress, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterWhereClause> idBetween(
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

extension UserProgressQueryFilter
    on QueryBuilder<UserProgress, UserProgress, QFilterCondition> {
  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
      currentAvatarLevelEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currentAvatarLevel',
        value: value,
      ));
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
      currentAvatarLevelGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'currentAvatarLevel',
        value: value,
      ));
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
      currentAvatarLevelLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'currentAvatarLevel',
        value: value,
      ));
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
      currentAvatarLevelBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'currentAvatarLevel',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
      currentHPEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currentHP',
        value: value,
      ));
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
      currentHPGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'currentHP',
        value: value,
      ));
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
      currentHPLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'currentHP',
        value: value,
      ));
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
      currentHPBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'currentHP',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
      currentStreakEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currentStreak',
        value: value,
      ));
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
      currentStreakGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'currentStreak',
        value: value,
      ));
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
      currentStreakLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'currentStreak',
        value: value,
      ));
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
      currentStreakBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'currentStreak',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition> idBetween(
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

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
      longestStreakEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'longestStreak',
        value: value,
      ));
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
      longestStreakGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'longestStreak',
        value: value,
      ));
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
      longestStreakLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'longestStreak',
        value: value,
      ));
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
      longestStreakBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'longestStreak',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
      premiumAvatarUnlockedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'premiumAvatarUnlocked',
        value: value,
      ));
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
      totalGoldEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalGold',
        value: value,
      ));
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
      totalGoldGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalGold',
        value: value,
      ));
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
      totalGoldLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalGold',
        value: value,
      ));
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
      totalGoldBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalGold',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
      totalXPEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalXP',
        value: value,
      ));
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
      totalXPGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalXP',
        value: value,
      ));
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
      totalXPLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalXP',
        value: value,
      ));
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterFilterCondition>
      totalXPBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalXP',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension UserProgressQueryObject
    on QueryBuilder<UserProgress, UserProgress, QFilterCondition> {}

extension UserProgressQueryLinks
    on QueryBuilder<UserProgress, UserProgress, QFilterCondition> {}

extension UserProgressQuerySortBy
    on QueryBuilder<UserProgress, UserProgress, QSortBy> {
  QueryBuilder<UserProgress, UserProgress, QAfterSortBy>
      sortByCurrentAvatarLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentAvatarLevel', Sort.asc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy>
      sortByCurrentAvatarLevelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentAvatarLevel', Sort.desc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy> sortByCurrentHP() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentHP', Sort.asc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy> sortByCurrentHPDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentHP', Sort.desc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy> sortByCurrentStreak() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentStreak', Sort.asc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy>
      sortByCurrentStreakDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentStreak', Sort.desc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy> sortByLongestStreak() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longestStreak', Sort.asc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy>
      sortByLongestStreakDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longestStreak', Sort.desc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy>
      sortByPremiumAvatarUnlocked() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'premiumAvatarUnlocked', Sort.asc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy>
      sortByPremiumAvatarUnlockedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'premiumAvatarUnlocked', Sort.desc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy> sortByTotalGold() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalGold', Sort.asc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy> sortByTotalGoldDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalGold', Sort.desc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy> sortByTotalXP() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalXP', Sort.asc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy> sortByTotalXPDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalXP', Sort.desc);
    });
  }
}

extension UserProgressQuerySortThenBy
    on QueryBuilder<UserProgress, UserProgress, QSortThenBy> {
  QueryBuilder<UserProgress, UserProgress, QAfterSortBy>
      thenByCurrentAvatarLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentAvatarLevel', Sort.asc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy>
      thenByCurrentAvatarLevelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentAvatarLevel', Sort.desc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy> thenByCurrentHP() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentHP', Sort.asc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy> thenByCurrentHPDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentHP', Sort.desc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy> thenByCurrentStreak() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentStreak', Sort.asc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy>
      thenByCurrentStreakDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentStreak', Sort.desc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy> thenByLongestStreak() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longestStreak', Sort.asc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy>
      thenByLongestStreakDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longestStreak', Sort.desc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy>
      thenByPremiumAvatarUnlocked() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'premiumAvatarUnlocked', Sort.asc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy>
      thenByPremiumAvatarUnlockedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'premiumAvatarUnlocked', Sort.desc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy> thenByTotalGold() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalGold', Sort.asc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy> thenByTotalGoldDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalGold', Sort.desc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy> thenByTotalXP() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalXP', Sort.asc);
    });
  }

  QueryBuilder<UserProgress, UserProgress, QAfterSortBy> thenByTotalXPDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalXP', Sort.desc);
    });
  }
}

extension UserProgressQueryWhereDistinct
    on QueryBuilder<UserProgress, UserProgress, QDistinct> {
  QueryBuilder<UserProgress, UserProgress, QDistinct>
      distinctByCurrentAvatarLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'currentAvatarLevel');
    });
  }

  QueryBuilder<UserProgress, UserProgress, QDistinct> distinctByCurrentHP() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'currentHP');
    });
  }

  QueryBuilder<UserProgress, UserProgress, QDistinct>
      distinctByCurrentStreak() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'currentStreak');
    });
  }

  QueryBuilder<UserProgress, UserProgress, QDistinct>
      distinctByLongestStreak() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'longestStreak');
    });
  }

  QueryBuilder<UserProgress, UserProgress, QDistinct>
      distinctByPremiumAvatarUnlocked() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'premiumAvatarUnlocked');
    });
  }

  QueryBuilder<UserProgress, UserProgress, QDistinct> distinctByTotalGold() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalGold');
    });
  }

  QueryBuilder<UserProgress, UserProgress, QDistinct> distinctByTotalXP() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalXP');
    });
  }
}

extension UserProgressQueryProperty
    on QueryBuilder<UserProgress, UserProgress, QQueryProperty> {
  QueryBuilder<UserProgress, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<UserProgress, int, QQueryOperations>
      currentAvatarLevelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currentAvatarLevel');
    });
  }

  QueryBuilder<UserProgress, int, QQueryOperations> currentHPProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currentHP');
    });
  }

  QueryBuilder<UserProgress, int, QQueryOperations> currentStreakProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currentStreak');
    });
  }

  QueryBuilder<UserProgress, int, QQueryOperations> longestStreakProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'longestStreak');
    });
  }

  QueryBuilder<UserProgress, bool, QQueryOperations>
      premiumAvatarUnlockedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'premiumAvatarUnlocked');
    });
  }

  QueryBuilder<UserProgress, int, QQueryOperations> totalGoldProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalGold');
    });
  }

  QueryBuilder<UserProgress, int, QQueryOperations> totalXPProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalXP');
    });
  }
}
