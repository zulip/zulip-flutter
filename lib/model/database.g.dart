// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $AccountsTable extends Accounts with TableInfo<$AccountsTable, Account> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _realmUrlMeta =
      const VerificationMeta('realmUrl');
  @override
  late final GeneratedColumn<String> realmUrl = GeneratedColumn<String>(
      'realm_url', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
      'user_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
      'email', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _apiKeyMeta = const VerificationMeta('apiKey');
  @override
  late final GeneratedColumn<String> apiKey = GeneratedColumn<String>(
      'api_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _zulipVersionMeta =
      const VerificationMeta('zulipVersion');
  @override
  late final GeneratedColumn<String> zulipVersion = GeneratedColumn<String>(
      'zulip_version', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _zulipFeatureLevelMeta =
      const VerificationMeta('zulipFeatureLevel');
  @override
  late final GeneratedColumn<int> zulipFeatureLevel = GeneratedColumn<int>(
      'zulip_feature_level', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, realmUrl, userId, email, apiKey, zulipVersion, zulipFeatureLevel];
  @override
  String get aliasedName => _alias ?? 'accounts';
  @override
  String get actualTableName => 'accounts';
  @override
  VerificationContext validateIntegrity(Insertable<Account> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('realm_url')) {
      context.handle(_realmUrlMeta,
          realmUrl.isAcceptableOrUnknown(data['realm_url']!, _realmUrlMeta));
    } else if (isInserting) {
      context.missing(_realmUrlMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
          _emailMeta, email.isAcceptableOrUnknown(data['email']!, _emailMeta));
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('api_key')) {
      context.handle(_apiKeyMeta,
          apiKey.isAcceptableOrUnknown(data['api_key']!, _apiKeyMeta));
    } else if (isInserting) {
      context.missing(_apiKeyMeta);
    }
    if (data.containsKey('zulip_version')) {
      context.handle(
          _zulipVersionMeta,
          zulipVersion.isAcceptableOrUnknown(
              data['zulip_version']!, _zulipVersionMeta));
    } else if (isInserting) {
      context.missing(_zulipVersionMeta);
    }
    if (data.containsKey('zulip_feature_level')) {
      context.handle(
          _zulipFeatureLevelMeta,
          zulipFeatureLevel.isAcceptableOrUnknown(
              data['zulip_feature_level']!, _zulipFeatureLevelMeta));
    } else if (isInserting) {
      context.missing(_zulipFeatureLevelMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {realmUrl, userId},
        {realmUrl, email},
      ];
  @override
  Account map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Account(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      realmUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}realm_url'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}user_id'])!,
      email: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}email'])!,
      apiKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}api_key'])!,
      zulipVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}zulip_version'])!,
      zulipFeatureLevel: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}zulip_feature_level'])!,
    );
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }
}

class Account extends DataClass implements Insertable<Account> {
  final int id;
  final String realmUrl;
  final int userId;
  final String email;
  final String apiKey;
  final String zulipVersion;
  final int zulipFeatureLevel;
  const Account(
      {required this.id,
      required this.realmUrl,
      required this.userId,
      required this.email,
      required this.apiKey,
      required this.zulipVersion,
      required this.zulipFeatureLevel});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['realm_url'] = Variable<String>(realmUrl);
    map['user_id'] = Variable<int>(userId);
    map['email'] = Variable<String>(email);
    map['api_key'] = Variable<String>(apiKey);
    map['zulip_version'] = Variable<String>(zulipVersion);
    map['zulip_feature_level'] = Variable<int>(zulipFeatureLevel);
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      id: Value(id),
      realmUrl: Value(realmUrl),
      userId: Value(userId),
      email: Value(email),
      apiKey: Value(apiKey),
      zulipVersion: Value(zulipVersion),
      zulipFeatureLevel: Value(zulipFeatureLevel),
    );
  }

  factory Account.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Account(
      id: serializer.fromJson<int>(json['id']),
      realmUrl: serializer.fromJson<String>(json['realmUrl']),
      userId: serializer.fromJson<int>(json['userId']),
      email: serializer.fromJson<String>(json['email']),
      apiKey: serializer.fromJson<String>(json['apiKey']),
      zulipVersion: serializer.fromJson<String>(json['zulipVersion']),
      zulipFeatureLevel: serializer.fromJson<int>(json['zulipFeatureLevel']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'realmUrl': serializer.toJson<String>(realmUrl),
      'userId': serializer.toJson<int>(userId),
      'email': serializer.toJson<String>(email),
      'apiKey': serializer.toJson<String>(apiKey),
      'zulipVersion': serializer.toJson<String>(zulipVersion),
      'zulipFeatureLevel': serializer.toJson<int>(zulipFeatureLevel),
    };
  }

  Account copyWith(
          {int? id,
          String? realmUrl,
          int? userId,
          String? email,
          String? apiKey,
          String? zulipVersion,
          int? zulipFeatureLevel}) =>
      Account(
        id: id ?? this.id,
        realmUrl: realmUrl ?? this.realmUrl,
        userId: userId ?? this.userId,
        email: email ?? this.email,
        apiKey: apiKey ?? this.apiKey,
        zulipVersion: zulipVersion ?? this.zulipVersion,
        zulipFeatureLevel: zulipFeatureLevel ?? this.zulipFeatureLevel,
      );
  @override
  String toString() {
    return (StringBuffer('Account(')
          ..write('id: $id, ')
          ..write('realmUrl: $realmUrl, ')
          ..write('userId: $userId, ')
          ..write('email: $email, ')
          ..write('apiKey: $apiKey, ')
          ..write('zulipVersion: $zulipVersion, ')
          ..write('zulipFeatureLevel: $zulipFeatureLevel')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, realmUrl, userId, email, apiKey, zulipVersion, zulipFeatureLevel);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Account &&
          other.id == this.id &&
          other.realmUrl == this.realmUrl &&
          other.userId == this.userId &&
          other.email == this.email &&
          other.apiKey == this.apiKey &&
          other.zulipVersion == this.zulipVersion &&
          other.zulipFeatureLevel == this.zulipFeatureLevel);
}

class AccountsCompanion extends UpdateCompanion<Account> {
  final Value<int> id;
  final Value<String> realmUrl;
  final Value<int> userId;
  final Value<String> email;
  final Value<String> apiKey;
  final Value<String> zulipVersion;
  final Value<int> zulipFeatureLevel;
  const AccountsCompanion({
    this.id = const Value.absent(),
    this.realmUrl = const Value.absent(),
    this.userId = const Value.absent(),
    this.email = const Value.absent(),
    this.apiKey = const Value.absent(),
    this.zulipVersion = const Value.absent(),
    this.zulipFeatureLevel = const Value.absent(),
  });
  AccountsCompanion.insert({
    this.id = const Value.absent(),
    required String realmUrl,
    required int userId,
    required String email,
    required String apiKey,
    required String zulipVersion,
    required int zulipFeatureLevel,
  })  : realmUrl = Value(realmUrl),
        userId = Value(userId),
        email = Value(email),
        apiKey = Value(apiKey),
        zulipVersion = Value(zulipVersion),
        zulipFeatureLevel = Value(zulipFeatureLevel);
  static Insertable<Account> custom({
    Expression<int>? id,
    Expression<String>? realmUrl,
    Expression<int>? userId,
    Expression<String>? email,
    Expression<String>? apiKey,
    Expression<String>? zulipVersion,
    Expression<int>? zulipFeatureLevel,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (realmUrl != null) 'realm_url': realmUrl,
      if (userId != null) 'user_id': userId,
      if (email != null) 'email': email,
      if (apiKey != null) 'api_key': apiKey,
      if (zulipVersion != null) 'zulip_version': zulipVersion,
      if (zulipFeatureLevel != null) 'zulip_feature_level': zulipFeatureLevel,
    });
  }

  AccountsCompanion copyWith(
      {Value<int>? id,
      Value<String>? realmUrl,
      Value<int>? userId,
      Value<String>? email,
      Value<String>? apiKey,
      Value<String>? zulipVersion,
      Value<int>? zulipFeatureLevel}) {
    return AccountsCompanion(
      id: id ?? this.id,
      realmUrl: realmUrl ?? this.realmUrl,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      apiKey: apiKey ?? this.apiKey,
      zulipVersion: zulipVersion ?? this.zulipVersion,
      zulipFeatureLevel: zulipFeatureLevel ?? this.zulipFeatureLevel,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (realmUrl.present) {
      map['realm_url'] = Variable<String>(realmUrl.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (apiKey.present) {
      map['api_key'] = Variable<String>(apiKey.value);
    }
    if (zulipVersion.present) {
      map['zulip_version'] = Variable<String>(zulipVersion.value);
    }
    if (zulipFeatureLevel.present) {
      map['zulip_feature_level'] = Variable<int>(zulipFeatureLevel.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('id: $id, ')
          ..write('realmUrl: $realmUrl, ')
          ..write('userId: $userId, ')
          ..write('email: $email, ')
          ..write('apiKey: $apiKey, ')
          ..write('zulipVersion: $zulipVersion, ')
          ..write('zulipFeatureLevel: $zulipFeatureLevel')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  late final $AccountsTable accounts = $AccountsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [accounts];
}
