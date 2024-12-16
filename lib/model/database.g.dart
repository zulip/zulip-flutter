// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: constant_identifier_names, unnecessary_cast

part of 'database.dart';

// ignore_for_file: type=lint
class $GlobalSettingsTable extends GlobalSettings
    with TableInfo<$GlobalSettingsTable, GlobalSettingsData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GlobalSettingsTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumnWithTypeConverter<ThemeSetting?, String>
  themeSetting = GeneratedColumn<String>(
    'theme_setting',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<ThemeSetting?>($GlobalSettingsTable.$converterthemeSettingn);
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
      themeSetting: $GlobalSettingsTable.$converterthemeSettingn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}theme_setting'],
        ),
      ),
    );
  }

  @override
  $GlobalSettingsTable createAlias(String alias) {
    return $GlobalSettingsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ThemeSetting, String, String>
  $converterthemeSetting = const EnumNameConverter<ThemeSetting>(
    ThemeSetting.values,
  );
  static JsonTypeConverter2<ThemeSetting?, String?, String?>
  $converterthemeSettingn = JsonTypeConverter2.asNullable(
    $converterthemeSetting,
  );
}

class GlobalSettingsData extends DataClass
    implements Insertable<GlobalSettingsData> {
  final ThemeSetting? themeSetting;
  const GlobalSettingsData({this.themeSetting});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || themeSetting != null) {
      map['theme_setting'] = Variable<String>(
        $GlobalSettingsTable.$converterthemeSettingn.toSql(themeSetting),
      );
    }
    return map;
  }

  GlobalSettingsCompanion toCompanion(bool nullToAbsent) {
    return GlobalSettingsCompanion(
      themeSetting:
          themeSetting == null && nullToAbsent
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
      themeSetting: $GlobalSettingsTable.$converterthemeSettingn.fromJson(
        serializer.fromJson<String?>(json['themeSetting']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'themeSetting': serializer.toJson<String?>(
        $GlobalSettingsTable.$converterthemeSettingn.toJson(themeSetting),
      ),
    };
  }

  GlobalSettingsData copyWith({
    Value<ThemeSetting?> themeSetting = const Value.absent(),
  }) => GlobalSettingsData(
    themeSetting: themeSetting.present ? themeSetting.value : this.themeSetting,
  );
  GlobalSettingsData copyWithCompanion(GlobalSettingsCompanion data) {
    return GlobalSettingsData(
      themeSetting:
          data.themeSetting.present
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
  final Value<ThemeSetting?> themeSetting;
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
    Value<ThemeSetting?>? themeSetting,
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
      map['theme_setting'] = Variable<String>(
        $GlobalSettingsTable.$converterthemeSettingn.toSql(themeSetting.value),
      );
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

class $AccountsTable extends Accounts with TableInfo<$AccountsTable, Account> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
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
  @override
  late final GeneratedColumnWithTypeConverter<Uri, String> realmUrl =
      GeneratedColumn<String>(
        'realm_url',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Uri>($AccountsTable.$converterrealmUrl);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _apiKeyMeta = const VerificationMeta('apiKey');
  @override
  late final GeneratedColumn<String> apiKey = GeneratedColumn<String>(
    'api_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _zulipVersionMeta = const VerificationMeta(
    'zulipVersion',
  );
  @override
  late final GeneratedColumn<String> zulipVersion = GeneratedColumn<String>(
    'zulip_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _zulipMergeBaseMeta = const VerificationMeta(
    'zulipMergeBase',
  );
  @override
  late final GeneratedColumn<String> zulipMergeBase = GeneratedColumn<String>(
    'zulip_merge_base',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _zulipFeatureLevelMeta = const VerificationMeta(
    'zulipFeatureLevel',
  );
  @override
  late final GeneratedColumn<int> zulipFeatureLevel = GeneratedColumn<int>(
    'zulip_feature_level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ackedPushTokenMeta = const VerificationMeta(
    'ackedPushToken',
  );
  @override
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
  VerificationContext validateIntegrity(
    Insertable<Account> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('api_key')) {
      context.handle(
        _apiKeyMeta,
        apiKey.isAcceptableOrUnknown(data['api_key']!, _apiKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_apiKeyMeta);
    }
    if (data.containsKey('zulip_version')) {
      context.handle(
        _zulipVersionMeta,
        zulipVersion.isAcceptableOrUnknown(
          data['zulip_version']!,
          _zulipVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_zulipVersionMeta);
    }
    if (data.containsKey('zulip_merge_base')) {
      context.handle(
        _zulipMergeBaseMeta,
        zulipMergeBase.isAcceptableOrUnknown(
          data['zulip_merge_base']!,
          _zulipMergeBaseMeta,
        ),
      );
    }
    if (data.containsKey('zulip_feature_level')) {
      context.handle(
        _zulipFeatureLevelMeta,
        zulipFeatureLevel.isAcceptableOrUnknown(
          data['zulip_feature_level']!,
          _zulipFeatureLevelMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_zulipFeatureLevelMeta);
    }
    if (data.containsKey('acked_push_token')) {
      context.handle(
        _ackedPushTokenMeta,
        ackedPushToken.isAcceptableOrUnknown(
          data['acked_push_token']!,
          _ackedPushTokenMeta,
        ),
      );
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
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      realmUrl: $AccountsTable.$converterrealmUrl.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}realm_url'],
        )!,
      ),
      userId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}user_id'],
          )!,
      email:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}email'],
          )!,
      apiKey:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}api_key'],
          )!,
      zulipVersion:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}zulip_version'],
          )!,
      zulipMergeBase: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}zulip_merge_base'],
      ),
      zulipFeatureLevel:
          attachedDatabase.typeMapping.read(
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
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }

  static TypeConverter<Uri, String> $converterrealmUrl = const UriConverter();
}

class Account extends DataClass implements Insertable<Account> {
  /// The ID of this account in the app's local database.
  ///
  /// This uniquely identifies the account within this install of the app,
  /// and never changes for a given account.  It has no meaning to the server,
  /// though, or anywhere else outside this install of the app.
  final int id;

  /// The URL of the Zulip realm this account is on.
  ///
  /// This corresponds to [GetServerSettingsResult.realmUrl].
  /// It never changes for a given account.
  final Uri realmUrl;

  /// The Zulip user ID of this account.
  ///
  /// This is the identifier the server uses for the account.
  /// It never changes for a given account.
  final int userId;
  final String email;
  final String apiKey;
  final String zulipVersion;
  final String? zulipMergeBase;
  final int zulipFeatureLevel;
  final String? ackedPushToken;
  const Account({
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
    {
      map['realm_url'] = Variable<String>(
        $AccountsTable.$converterrealmUrl.toSql(realmUrl),
      );
    }
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
      zulipMergeBase:
          zulipMergeBase == null && nullToAbsent
              ? const Value.absent()
              : Value(zulipMergeBase),
      zulipFeatureLevel: Value(zulipFeatureLevel),
      ackedPushToken:
          ackedPushToken == null && nullToAbsent
              ? const Value.absent()
              : Value(ackedPushToken),
    );
  }

  factory Account.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Account(
      id: serializer.fromJson<int>(json['id']),
      realmUrl: serializer.fromJson<Uri>(json['realmUrl']),
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
      'realmUrl': serializer.toJson<Uri>(realmUrl),
      'userId': serializer.toJson<int>(userId),
      'email': serializer.toJson<String>(email),
      'apiKey': serializer.toJson<String>(apiKey),
      'zulipVersion': serializer.toJson<String>(zulipVersion),
      'zulipMergeBase': serializer.toJson<String?>(zulipMergeBase),
      'zulipFeatureLevel': serializer.toJson<int>(zulipFeatureLevel),
      'ackedPushToken': serializer.toJson<String?>(ackedPushToken),
    };
  }

  Account copyWith({
    int? id,
    Uri? realmUrl,
    int? userId,
    String? email,
    String? apiKey,
    String? zulipVersion,
    Value<String?> zulipMergeBase = const Value.absent(),
    int? zulipFeatureLevel,
    Value<String?> ackedPushToken = const Value.absent(),
  }) => Account(
    id: id ?? this.id,
    realmUrl: realmUrl ?? this.realmUrl,
    userId: userId ?? this.userId,
    email: email ?? this.email,
    apiKey: apiKey ?? this.apiKey,
    zulipVersion: zulipVersion ?? this.zulipVersion,
    zulipMergeBase:
        zulipMergeBase.present ? zulipMergeBase.value : this.zulipMergeBase,
    zulipFeatureLevel: zulipFeatureLevel ?? this.zulipFeatureLevel,
    ackedPushToken:
        ackedPushToken.present ? ackedPushToken.value : this.ackedPushToken,
  );
  Account copyWithCompanion(AccountsCompanion data) {
    return Account(
      id: data.id.present ? data.id.value : this.id,
      realmUrl: data.realmUrl.present ? data.realmUrl.value : this.realmUrl,
      userId: data.userId.present ? data.userId.value : this.userId,
      email: data.email.present ? data.email.value : this.email,
      apiKey: data.apiKey.present ? data.apiKey.value : this.apiKey,
      zulipVersion:
          data.zulipVersion.present
              ? data.zulipVersion.value
              : this.zulipVersion,
      zulipMergeBase:
          data.zulipMergeBase.present
              ? data.zulipMergeBase.value
              : this.zulipMergeBase,
      zulipFeatureLevel:
          data.zulipFeatureLevel.present
              ? data.zulipFeatureLevel.value
              : this.zulipFeatureLevel,
      ackedPushToken:
          data.ackedPushToken.present
              ? data.ackedPushToken.value
              : this.ackedPushToken,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Account(')
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
      (other is Account &&
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

class AccountsCompanion extends UpdateCompanion<Account> {
  final Value<int> id;
  final Value<Uri> realmUrl;
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
    required Uri realmUrl,
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
  static Insertable<Account> custom({
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
    Value<Uri>? realmUrl,
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
      map['realm_url'] = Variable<String>(
        $AccountsTable.$converterrealmUrl.toSql(realmUrl.value),
      );
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

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $GlobalSettingsTable globalSettings = $GlobalSettingsTable(this);
  late final $AccountsTable accounts = $AccountsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    globalSettings,
    accounts,
  ];
}

typedef $$GlobalSettingsTableCreateCompanionBuilder =
    GlobalSettingsCompanion Function({
      Value<ThemeSetting?> themeSetting,
      Value<int> rowid,
    });
typedef $$GlobalSettingsTableUpdateCompanionBuilder =
    GlobalSettingsCompanion Function({
      Value<ThemeSetting?> themeSetting,
      Value<int> rowid,
    });

class $$GlobalSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $GlobalSettingsTable> {
  $$GlobalSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<ThemeSetting?, ThemeSetting, String>
  get themeSetting => $composableBuilder(
    column: $table.themeSetting,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );
}

class $$GlobalSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $GlobalSettingsTable> {
  $$GlobalSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get themeSetting => $composableBuilder(
    column: $table.themeSetting,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GlobalSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GlobalSettingsTable> {
  $$GlobalSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<ThemeSetting?, String> get themeSetting =>
      $composableBuilder(
        column: $table.themeSetting,
        builder: (column) => column,
      );
}

class $$GlobalSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GlobalSettingsTable,
          GlobalSettingsData,
          $$GlobalSettingsTableFilterComposer,
          $$GlobalSettingsTableOrderingComposer,
          $$GlobalSettingsTableAnnotationComposer,
          $$GlobalSettingsTableCreateCompanionBuilder,
          $$GlobalSettingsTableUpdateCompanionBuilder,
          (
            GlobalSettingsData,
            BaseReferences<
              _$AppDatabase,
              $GlobalSettingsTable,
              GlobalSettingsData
            >,
          ),
          GlobalSettingsData,
          PrefetchHooks Function()
        > {
  $$GlobalSettingsTableTableManager(
    _$AppDatabase db,
    $GlobalSettingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$GlobalSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () =>
                  $$GlobalSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$GlobalSettingsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<ThemeSetting?> themeSetting = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GlobalSettingsCompanion(
                themeSetting: themeSetting,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<ThemeSetting?> themeSetting = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GlobalSettingsCompanion.insert(
                themeSetting: themeSetting,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GlobalSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GlobalSettingsTable,
      GlobalSettingsData,
      $$GlobalSettingsTableFilterComposer,
      $$GlobalSettingsTableOrderingComposer,
      $$GlobalSettingsTableAnnotationComposer,
      $$GlobalSettingsTableCreateCompanionBuilder,
      $$GlobalSettingsTableUpdateCompanionBuilder,
      (
        GlobalSettingsData,
        BaseReferences<_$AppDatabase, $GlobalSettingsTable, GlobalSettingsData>,
      ),
      GlobalSettingsData,
      PrefetchHooks Function()
    >;
typedef $$AccountsTableCreateCompanionBuilder =
    AccountsCompanion Function({
      Value<int> id,
      required Uri realmUrl,
      required int userId,
      required String email,
      required String apiKey,
      required String zulipVersion,
      Value<String?> zulipMergeBase,
      required int zulipFeatureLevel,
      Value<String?> ackedPushToken,
    });
typedef $$AccountsTableUpdateCompanionBuilder =
    AccountsCompanion Function({
      Value<int> id,
      Value<Uri> realmUrl,
      Value<int> userId,
      Value<String> email,
      Value<String> apiKey,
      Value<String> zulipVersion,
      Value<String?> zulipMergeBase,
      Value<int> zulipFeatureLevel,
      Value<String?> ackedPushToken,
    });

class $$AccountsTableFilterComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Uri, Uri, String> get realmUrl =>
      $composableBuilder(
        column: $table.realmUrl,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get apiKey => $composableBuilder(
    column: $table.apiKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get zulipVersion => $composableBuilder(
    column: $table.zulipVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get zulipMergeBase => $composableBuilder(
    column: $table.zulipMergeBase,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get zulipFeatureLevel => $composableBuilder(
    column: $table.zulipFeatureLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ackedPushToken => $composableBuilder(
    column: $table.ackedPushToken,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get realmUrl => $composableBuilder(
    column: $table.realmUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get apiKey => $composableBuilder(
    column: $table.apiKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get zulipVersion => $composableBuilder(
    column: $table.zulipVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get zulipMergeBase => $composableBuilder(
    column: $table.zulipMergeBase,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get zulipFeatureLevel => $composableBuilder(
    column: $table.zulipFeatureLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ackedPushToken => $composableBuilder(
    column: $table.ackedPushToken,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Uri, String> get realmUrl =>
      $composableBuilder(column: $table.realmUrl, builder: (column) => column);

  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get apiKey =>
      $composableBuilder(column: $table.apiKey, builder: (column) => column);

  GeneratedColumn<String> get zulipVersion => $composableBuilder(
    column: $table.zulipVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get zulipMergeBase => $composableBuilder(
    column: $table.zulipMergeBase,
    builder: (column) => column,
  );

  GeneratedColumn<int> get zulipFeatureLevel => $composableBuilder(
    column: $table.zulipFeatureLevel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ackedPushToken => $composableBuilder(
    column: $table.ackedPushToken,
    builder: (column) => column,
  );
}

class $$AccountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AccountsTable,
          Account,
          $$AccountsTableFilterComposer,
          $$AccountsTableOrderingComposer,
          $$AccountsTableAnnotationComposer,
          $$AccountsTableCreateCompanionBuilder,
          $$AccountsTableUpdateCompanionBuilder,
          (Account, BaseReferences<_$AppDatabase, $AccountsTable, Account>),
          Account,
          PrefetchHooks Function()
        > {
  $$AccountsTableTableManager(_$AppDatabase db, $AccountsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$AccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$AccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$AccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<Uri> realmUrl = const Value.absent(),
                Value<int> userId = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> apiKey = const Value.absent(),
                Value<String> zulipVersion = const Value.absent(),
                Value<String?> zulipMergeBase = const Value.absent(),
                Value<int> zulipFeatureLevel = const Value.absent(),
                Value<String?> ackedPushToken = const Value.absent(),
              }) => AccountsCompanion(
                id: id,
                realmUrl: realmUrl,
                userId: userId,
                email: email,
                apiKey: apiKey,
                zulipVersion: zulipVersion,
                zulipMergeBase: zulipMergeBase,
                zulipFeatureLevel: zulipFeatureLevel,
                ackedPushToken: ackedPushToken,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required Uri realmUrl,
                required int userId,
                required String email,
                required String apiKey,
                required String zulipVersion,
                Value<String?> zulipMergeBase = const Value.absent(),
                required int zulipFeatureLevel,
                Value<String?> ackedPushToken = const Value.absent(),
              }) => AccountsCompanion.insert(
                id: id,
                realmUrl: realmUrl,
                userId: userId,
                email: email,
                apiKey: apiKey,
                zulipVersion: zulipVersion,
                zulipMergeBase: zulipMergeBase,
                zulipFeatureLevel: zulipFeatureLevel,
                ackedPushToken: ackedPushToken,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AccountsTable,
      Account,
      $$AccountsTableFilterComposer,
      $$AccountsTableOrderingComposer,
      $$AccountsTableAnnotationComposer,
      $$AccountsTableCreateCompanionBuilder,
      $$AccountsTableUpdateCompanionBuilder,
      (Account, BaseReferences<_$AppDatabase, $AccountsTable, Account>),
      Account,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$GlobalSettingsTableTableManager get globalSettings =>
      $$GlobalSettingsTableTableManager(_db, _db.globalSettings);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db, _db.accounts);
}
