// dart format width=80
// GENERATED CODE, DO NOT EDIT BY HAND.
// ignore_for_file: type=lint
import 'package:drift/drift.dart';

class GlobalSettings extends Table
    with TableInfo<GlobalSettings, GlobalSettingsData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  GlobalSettings(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> themeSetting = GeneratedColumn<String>(
    'theme_setting',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [themeSetting];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'global_settings';
  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  GlobalSettingsData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GlobalSettingsData(
      themeSetting: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme_setting'],
      ),
    );
  }

  @override
  GlobalSettings createAlias(String alias) {
    return GlobalSettings(attachedDatabase, alias);
  }
}

class GlobalSettingsData extends DataClass
    implements Insertable<GlobalSettingsData> {
  final String? themeSetting;
  const GlobalSettingsData({this.themeSetting});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || themeSetting != null) {
      map['theme_setting'] = Variable<String>(themeSetting);
    }
    return map;
  }

  GlobalSettingsCompanion toCompanion(bool nullToAbsent) {
    return GlobalSettingsCompanion(
      themeSetting: themeSetting == null && nullToAbsent
          ? const Value.absent()
          : Value(themeSetting),
    );
  }

  factory GlobalSettingsData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GlobalSettingsData(
      themeSetting: serializer.fromJson<String?>(json['themeSetting']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'themeSetting': serializer.toJson<String?>(themeSetting),
    };
  }

  GlobalSettingsData copyWith({
    Value<String?> themeSetting = const Value.absent(),
  }) => GlobalSettingsData(
    themeSetting: themeSetting.present ? themeSetting.value : this.themeSetting,
  );
  GlobalSettingsData copyWithCompanion(GlobalSettingsCompanion data) {
    return GlobalSettingsData(
      themeSetting: data.themeSetting.present
          ? data.themeSetting.value
          : this.themeSetting,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GlobalSettingsData(')
          ..write('themeSetting: $themeSetting')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => themeSetting.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GlobalSettingsData && other.themeSetting == this.themeSetting);
}

class GlobalSettingsCompanion extends UpdateCompanion<GlobalSettingsData> {
  final Value<String?> themeSetting;
  final Value<int> rowid;
  const GlobalSettingsCompanion({
    this.themeSetting = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GlobalSettingsCompanion.insert({
    this.themeSetting = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  static Insertable<GlobalSettingsData> custom({
    Expression<String>? themeSetting,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (themeSetting != null) 'theme_setting': themeSetting,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GlobalSettingsCompanion copyWith({
    Value<String?>? themeSetting,
    Value<int>? rowid,
  }) {
    return GlobalSettingsCompanion(
      themeSetting: themeSetting ?? this.themeSetting,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (themeSetting.present) {
      map['theme_setting'] = Variable<String>(themeSetting.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GlobalSettingsCompanion(')
          ..write('themeSetting: $themeSetting, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Accounts extends Table with TableInfo<Accounts, AccountsData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Accounts(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  late final GeneratedColumn<String> realmUrl = GeneratedColumn<String>(
    'realm_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> apiKey = GeneratedColumn<String>(
    'api_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> zulipVersion = GeneratedColumn<String>(
    'zulip_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> zulipMergeBase = GeneratedColumn<String>(
    'zulip_merge_base',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<int> zulipFeatureLevel = GeneratedColumn<int>(
    'zulip_feature_level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> ackedPushToken = GeneratedColumn<String>(
    'acked_push_token',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    realmUrl,
    userId,
    email,
    apiKey,
    zulipVersion,
    zulipMergeBase,
    zulipFeatureLevel,
    ackedPushToken,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {realmUrl, userId},
    {realmUrl, email},
  ];
  @override
  AccountsData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AccountsData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      realmUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}realm_url'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      apiKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}api_key'],
      )!,
      zulipVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}zulip_version'],
      )!,
      zulipMergeBase: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}zulip_merge_base'],
      ),
      zulipFeatureLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}zulip_feature_level'],
      )!,
      ackedPushToken: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}acked_push_token'],
      ),
    );
  }

  @override
  Accounts createAlias(String alias) {
    return Accounts(attachedDatabase, alias);
  }
}

class AccountsData extends DataClass implements Insertable<AccountsData> {
  final int id;
  final String realmUrl;
  final int userId;
  final String email;
  final String apiKey;
  final String zulipVersion;
  final String? zulipMergeBase;
  final int zulipFeatureLevel;
  final String? ackedPushToken;
  const AccountsData({
    required this.id,
    required this.realmUrl,
    required this.userId,
    required this.email,
    required this.apiKey,
    required this.zulipVersion,
    this.zulipMergeBase,
    required this.zulipFeatureLevel,
    this.ackedPushToken,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['realm_url'] = Variable<String>(realmUrl);
    map['user_id'] = Variable<int>(userId);
    map['email'] = Variable<String>(email);
    map['api_key'] = Variable<String>(apiKey);
    map['zulip_version'] = Variable<String>(zulipVersion);
    if (!nullToAbsent || zulipMergeBase != null) {
      map['zulip_merge_base'] = Variable<String>(zulipMergeBase);
    }
    map['zulip_feature_level'] = Variable<int>(zulipFeatureLevel);
    if (!nullToAbsent || ackedPushToken != null) {
      map['acked_push_token'] = Variable<String>(ackedPushToken);
    }
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
      zulipMergeBase: zulipMergeBase == null && nullToAbsent
          ? const Value.absent()
          : Value(zulipMergeBase),
      zulipFeatureLevel: Value(zulipFeatureLevel),
      ackedPushToken: ackedPushToken == null && nullToAbsent
          ? const Value.absent()
          : Value(ackedPushToken),
    );
  }

  factory AccountsData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AccountsData(
      id: serializer.fromJson<int>(json['id']),
      realmUrl: serializer.fromJson<String>(json['realmUrl']),
      userId: serializer.fromJson<int>(json['userId']),
      email: serializer.fromJson<String>(json['email']),
      apiKey: serializer.fromJson<String>(json['apiKey']),
      zulipVersion: serializer.fromJson<String>(json['zulipVersion']),
      zulipMergeBase: serializer.fromJson<String?>(json['zulipMergeBase']),
      zulipFeatureLevel: serializer.fromJson<int>(json['zulipFeatureLevel']),
      ackedPushToken: serializer.fromJson<String?>(json['ackedPushToken']),
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
      'zulipMergeBase': serializer.toJson<String?>(zulipMergeBase),
      'zulipFeatureLevel': serializer.toJson<int>(zulipFeatureLevel),
      'ackedPushToken': serializer.toJson<String?>(ackedPushToken),
    };
  }

  AccountsData copyWith({
    int? id,
    String? realmUrl,
    int? userId,
    String? email,
    String? apiKey,
    String? zulipVersion,
    Value<String?> zulipMergeBase = const Value.absent(),
    int? zulipFeatureLevel,
    Value<String?> ackedPushToken = const Value.absent(),
  }) => AccountsData(
    id: id ?? this.id,
    realmUrl: realmUrl ?? this.realmUrl,
    userId: userId ?? this.userId,
    email: email ?? this.email,
    apiKey: apiKey ?? this.apiKey,
    zulipVersion: zulipVersion ?? this.zulipVersion,
    zulipMergeBase: zulipMergeBase.present
        ? zulipMergeBase.value
        : this.zulipMergeBase,
    zulipFeatureLevel: zulipFeatureLevel ?? this.zulipFeatureLevel,
    ackedPushToken: ackedPushToken.present
        ? ackedPushToken.value
        : this.ackedPushToken,
  );
  AccountsData copyWithCompanion(AccountsCompanion data) {
    return AccountsData(
      id: data.id.present ? data.id.value : this.id,
      realmUrl: data.realmUrl.present ? data.realmUrl.value : this.realmUrl,
      userId: data.userId.present ? data.userId.value : this.userId,
      email: data.email.present ? data.email.value : this.email,
      apiKey: data.apiKey.present ? data.apiKey.value : this.apiKey,
      zulipVersion: data.zulipVersion.present
          ? data.zulipVersion.value
          : this.zulipVersion,
      zulipMergeBase: data.zulipMergeBase.present
          ? data.zulipMergeBase.value
          : this.zulipMergeBase,
      zulipFeatureLevel: data.zulipFeatureLevel.present
          ? data.zulipFeatureLevel.value
          : this.zulipFeatureLevel,
      ackedPushToken: data.ackedPushToken.present
          ? data.ackedPushToken.value
          : this.ackedPushToken,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AccountsData(')
          ..write('id: $id, ')
          ..write('realmUrl: $realmUrl, ')
          ..write('userId: $userId, ')
          ..write('email: $email, ')
          ..write('apiKey: $apiKey, ')
          ..write('zulipVersion: $zulipVersion, ')
          ..write('zulipMergeBase: $zulipMergeBase, ')
          ..write('zulipFeatureLevel: $zulipFeatureLevel, ')
          ..write('ackedPushToken: $ackedPushToken')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    realmUrl,
    userId,
    email,
    apiKey,
    zulipVersion,
    zulipMergeBase,
    zulipFeatureLevel,
    ackedPushToken,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccountsData &&
          other.id == this.id &&
          other.realmUrl == this.realmUrl &&
          other.userId == this.userId &&
          other.email == this.email &&
          other.apiKey == this.apiKey &&
          other.zulipVersion == this.zulipVersion &&
          other.zulipMergeBase == this.zulipMergeBase &&
          other.zulipFeatureLevel == this.zulipFeatureLevel &&
          other.ackedPushToken == this.ackedPushToken);
}

class AccountsCompanion extends UpdateCompanion<AccountsData> {
  final Value<int> id;
  final Value<String> realmUrl;
  final Value<int> userId;
  final Value<String> email;
  final Value<String> apiKey;
  final Value<String> zulipVersion;
  final Value<String?> zulipMergeBase;
  final Value<int> zulipFeatureLevel;
  final Value<String?> ackedPushToken;
  const AccountsCompanion({
    this.id = const Value.absent(),
    this.realmUrl = const Value.absent(),
    this.userId = const Value.absent(),
    this.email = const Value.absent(),
    this.apiKey = const Value.absent(),
    this.zulipVersion = const Value.absent(),
    this.zulipMergeBase = const Value.absent(),
    this.zulipFeatureLevel = const Value.absent(),
    this.ackedPushToken = const Value.absent(),
  });
  AccountsCompanion.insert({
    this.id = const Value.absent(),
    required String realmUrl,
    required int userId,
    required String email,
    required String apiKey,
    required String zulipVersion,
    this.zulipMergeBase = const Value.absent(),
    required int zulipFeatureLevel,
    this.ackedPushToken = const Value.absent(),
  }) : realmUrl = Value(realmUrl),
       userId = Value(userId),
       email = Value(email),
       apiKey = Value(apiKey),
       zulipVersion = Value(zulipVersion),
       zulipFeatureLevel = Value(zulipFeatureLevel);
  static Insertable<AccountsData> custom({
    Expression<int>? id,
    Expression<String>? realmUrl,
    Expression<int>? userId,
    Expression<String>? email,
    Expression<String>? apiKey,
    Expression<String>? zulipVersion,
    Expression<String>? zulipMergeBase,
    Expression<int>? zulipFeatureLevel,
    Expression<String>? ackedPushToken,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (realmUrl != null) 'realm_url': realmUrl,
      if (userId != null) 'user_id': userId,
      if (email != null) 'email': email,
      if (apiKey != null) 'api_key': apiKey,
      if (zulipVersion != null) 'zulip_version': zulipVersion,
      if (zulipMergeBase != null) 'zulip_merge_base': zulipMergeBase,
      if (zulipFeatureLevel != null) 'zulip_feature_level': zulipFeatureLevel,
      if (ackedPushToken != null) 'acked_push_token': ackedPushToken,
    });
  }

  AccountsCompanion copyWith({
    Value<int>? id,
    Value<String>? realmUrl,
    Value<int>? userId,
    Value<String>? email,
    Value<String>? apiKey,
    Value<String>? zulipVersion,
    Value<String?>? zulipMergeBase,
    Value<int>? zulipFeatureLevel,
    Value<String?>? ackedPushToken,
  }) {
    return AccountsCompanion(
      id: id ?? this.id,
      realmUrl: realmUrl ?? this.realmUrl,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      apiKey: apiKey ?? this.apiKey,
      zulipVersion: zulipVersion ?? this.zulipVersion,
      zulipMergeBase: zulipMergeBase ?? this.zulipMergeBase,
      zulipFeatureLevel: zulipFeatureLevel ?? this.zulipFeatureLevel,
      ackedPushToken: ackedPushToken ?? this.ackedPushToken,
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
    if (zulipMergeBase.present) {
      map['zulip_merge_base'] = Variable<String>(zulipMergeBase.value);
    }
    if (zulipFeatureLevel.present) {
      map['zulip_feature_level'] = Variable<int>(zulipFeatureLevel.value);
    }
    if (ackedPushToken.present) {
      map['acked_push_token'] = Variable<String>(ackedPushToken.value);
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
          ..write('zulipMergeBase: $zulipMergeBase, ')
          ..write('zulipFeatureLevel: $zulipFeatureLevel, ')
          ..write('ackedPushToken: $ackedPushToken')
          ..write(')'))
        .toString();
  }
}

class DatabaseAtV3 extends GeneratedDatabase {
  DatabaseAtV3(QueryExecutor e) : super(e);
  late final GlobalSettings globalSettings = GlobalSettings(this);
  late final Accounts accounts = Accounts(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    globalSettings,
    accounts,
  ];
  @override
  int get schemaVersion => 3;
}
