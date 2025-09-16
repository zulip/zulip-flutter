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
  late final GeneratedColumnWithTypeConverter<BrowserPreference?, String>
  browserPreference =
      GeneratedColumn<String>(
        'browser_preference',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<BrowserPreference?>(
        $GlobalSettingsTable.$converterbrowserPreferencen,
      );
  @override
  late final GeneratedColumnWithTypeConverter<VisitFirstUnreadSetting?, String>
  visitFirstUnread =
      GeneratedColumn<String>(
        'visit_first_unread',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<VisitFirstUnreadSetting?>(
        $GlobalSettingsTable.$convertervisitFirstUnreadn,
      );
  @override
  late final GeneratedColumnWithTypeConverter<MarkReadOnScrollSetting?, String>
  markReadOnScroll =
      GeneratedColumn<String>(
        'mark_read_on_scroll',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<MarkReadOnScrollSetting?>(
        $GlobalSettingsTable.$convertermarkReadOnScrolln,
      );
  @override
  late final GeneratedColumnWithTypeConverter<LegacyUpgradeState?, String>
  legacyUpgradeState =
      GeneratedColumn<String>(
        'legacy_upgrade_state',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<LegacyUpgradeState?>(
        $GlobalSettingsTable.$converterlegacyUpgradeStaten,
      );
  @override
  List<GeneratedColumn> get $columns => [
    themeSetting,
    browserPreference,
    visitFirstUnread,
    markReadOnScroll,
    legacyUpgradeState,
  ];
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
      browserPreference: $GlobalSettingsTable.$converterbrowserPreferencen
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}browser_preference'],
            ),
          ),
      visitFirstUnread: $GlobalSettingsTable.$convertervisitFirstUnreadn
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}visit_first_unread'],
            ),
          ),
      markReadOnScroll: $GlobalSettingsTable.$convertermarkReadOnScrolln
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}mark_read_on_scroll'],
            ),
          ),
      legacyUpgradeState: $GlobalSettingsTable.$converterlegacyUpgradeStaten
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}legacy_upgrade_state'],
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
  static JsonTypeConverter2<BrowserPreference, String, String>
  $converterbrowserPreference = const EnumNameConverter<BrowserPreference>(
    BrowserPreference.values,
  );
  static JsonTypeConverter2<BrowserPreference?, String?, String?>
  $converterbrowserPreferencen = JsonTypeConverter2.asNullable(
    $converterbrowserPreference,
  );
  static JsonTypeConverter2<VisitFirstUnreadSetting, String, String>
  $convertervisitFirstUnread = const EnumNameConverter<VisitFirstUnreadSetting>(
    VisitFirstUnreadSetting.values,
  );
  static JsonTypeConverter2<VisitFirstUnreadSetting?, String?, String?>
  $convertervisitFirstUnreadn = JsonTypeConverter2.asNullable(
    $convertervisitFirstUnread,
  );
  static JsonTypeConverter2<MarkReadOnScrollSetting, String, String>
  $convertermarkReadOnScroll = const EnumNameConverter<MarkReadOnScrollSetting>(
    MarkReadOnScrollSetting.values,
  );
  static JsonTypeConverter2<MarkReadOnScrollSetting?, String?, String?>
  $convertermarkReadOnScrolln = JsonTypeConverter2.asNullable(
    $convertermarkReadOnScroll,
  );
  static JsonTypeConverter2<LegacyUpgradeState, String, String>
  $converterlegacyUpgradeState = const EnumNameConverter<LegacyUpgradeState>(
    LegacyUpgradeState.values,
  );
  static JsonTypeConverter2<LegacyUpgradeState?, String?, String?>
  $converterlegacyUpgradeStaten = JsonTypeConverter2.asNullable(
    $converterlegacyUpgradeState,
  );
}

class GlobalSettingsData extends DataClass
    implements Insertable<GlobalSettingsData> {
  final ThemeSetting? themeSetting;
  final BrowserPreference? browserPreference;
  final VisitFirstUnreadSetting? visitFirstUnread;
  final MarkReadOnScrollSetting? markReadOnScroll;
  final LegacyUpgradeState? legacyUpgradeState;
  const GlobalSettingsData({
    this.themeSetting,
    this.browserPreference,
    this.visitFirstUnread,
    this.markReadOnScroll,
    this.legacyUpgradeState,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || themeSetting != null) {
      map['theme_setting'] = Variable<String>(
        $GlobalSettingsTable.$converterthemeSettingn.toSql(themeSetting),
      );
    }
    if (!nullToAbsent || browserPreference != null) {
      map['browser_preference'] = Variable<String>(
        $GlobalSettingsTable.$converterbrowserPreferencen.toSql(
          browserPreference,
        ),
      );
    }
    if (!nullToAbsent || visitFirstUnread != null) {
      map['visit_first_unread'] = Variable<String>(
        $GlobalSettingsTable.$convertervisitFirstUnreadn.toSql(
          visitFirstUnread,
        ),
      );
    }
    if (!nullToAbsent || markReadOnScroll != null) {
      map['mark_read_on_scroll'] = Variable<String>(
        $GlobalSettingsTable.$convertermarkReadOnScrolln.toSql(
          markReadOnScroll,
        ),
      );
    }
    if (!nullToAbsent || legacyUpgradeState != null) {
      map['legacy_upgrade_state'] = Variable<String>(
        $GlobalSettingsTable.$converterlegacyUpgradeStaten.toSql(
          legacyUpgradeState,
        ),
      );
    }
    return map;
  }

  GlobalSettingsCompanion toCompanion(bool nullToAbsent) {
    return GlobalSettingsCompanion(
      themeSetting: themeSetting == null && nullToAbsent
          ? const Value.absent()
          : Value(themeSetting),
      browserPreference: browserPreference == null && nullToAbsent
          ? const Value.absent()
          : Value(browserPreference),
      visitFirstUnread: visitFirstUnread == null && nullToAbsent
          ? const Value.absent()
          : Value(visitFirstUnread),
      markReadOnScroll: markReadOnScroll == null && nullToAbsent
          ? const Value.absent()
          : Value(markReadOnScroll),
      legacyUpgradeState: legacyUpgradeState == null && nullToAbsent
          ? const Value.absent()
          : Value(legacyUpgradeState),
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
      browserPreference: $GlobalSettingsTable.$converterbrowserPreferencen
          .fromJson(serializer.fromJson<String?>(json['browserPreference'])),
      visitFirstUnread: $GlobalSettingsTable.$convertervisitFirstUnreadn
          .fromJson(serializer.fromJson<String?>(json['visitFirstUnread'])),
      markReadOnScroll: $GlobalSettingsTable.$convertermarkReadOnScrolln
          .fromJson(serializer.fromJson<String?>(json['markReadOnScroll'])),
      legacyUpgradeState: $GlobalSettingsTable.$converterlegacyUpgradeStaten
          .fromJson(serializer.fromJson<String?>(json['legacyUpgradeState'])),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'themeSetting': serializer.toJson<String?>(
        $GlobalSettingsTable.$converterthemeSettingn.toJson(themeSetting),
      ),
      'browserPreference': serializer.toJson<String?>(
        $GlobalSettingsTable.$converterbrowserPreferencen.toJson(
          browserPreference,
        ),
      ),
      'visitFirstUnread': serializer.toJson<String?>(
        $GlobalSettingsTable.$convertervisitFirstUnreadn.toJson(
          visitFirstUnread,
        ),
      ),
      'markReadOnScroll': serializer.toJson<String?>(
        $GlobalSettingsTable.$convertermarkReadOnScrolln.toJson(
          markReadOnScroll,
        ),
      ),
      'legacyUpgradeState': serializer.toJson<String?>(
        $GlobalSettingsTable.$converterlegacyUpgradeStaten.toJson(
          legacyUpgradeState,
        ),
      ),
    };
  }

  GlobalSettingsData copyWith({
    Value<ThemeSetting?> themeSetting = const Value.absent(),
    Value<BrowserPreference?> browserPreference = const Value.absent(),
    Value<VisitFirstUnreadSetting?> visitFirstUnread = const Value.absent(),
    Value<MarkReadOnScrollSetting?> markReadOnScroll = const Value.absent(),
    Value<LegacyUpgradeState?> legacyUpgradeState = const Value.absent(),
  }) => GlobalSettingsData(
    themeSetting: themeSetting.present ? themeSetting.value : this.themeSetting,
    browserPreference: browserPreference.present
        ? browserPreference.value
        : this.browserPreference,
    visitFirstUnread: visitFirstUnread.present
        ? visitFirstUnread.value
        : this.visitFirstUnread,
    markReadOnScroll: markReadOnScroll.present
        ? markReadOnScroll.value
        : this.markReadOnScroll,
    legacyUpgradeState: legacyUpgradeState.present
        ? legacyUpgradeState.value
        : this.legacyUpgradeState,
  );
  GlobalSettingsData copyWithCompanion(GlobalSettingsCompanion data) {
    return GlobalSettingsData(
      themeSetting: data.themeSetting.present
          ? data.themeSetting.value
          : this.themeSetting,
      browserPreference: data.browserPreference.present
          ? data.browserPreference.value
          : this.browserPreference,
      visitFirstUnread: data.visitFirstUnread.present
          ? data.visitFirstUnread.value
          : this.visitFirstUnread,
      markReadOnScroll: data.markReadOnScroll.present
          ? data.markReadOnScroll.value
          : this.markReadOnScroll,
      legacyUpgradeState: data.legacyUpgradeState.present
          ? data.legacyUpgradeState.value
          : this.legacyUpgradeState,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GlobalSettingsData(')
          ..write('themeSetting: $themeSetting, ')
          ..write('browserPreference: $browserPreference, ')
          ..write('visitFirstUnread: $visitFirstUnread, ')
          ..write('markReadOnScroll: $markReadOnScroll, ')
          ..write('legacyUpgradeState: $legacyUpgradeState')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    themeSetting,
    browserPreference,
    visitFirstUnread,
    markReadOnScroll,
    legacyUpgradeState,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GlobalSettingsData &&
          other.themeSetting == this.themeSetting &&
          other.browserPreference == this.browserPreference &&
          other.visitFirstUnread == this.visitFirstUnread &&
          other.markReadOnScroll == this.markReadOnScroll &&
          other.legacyUpgradeState == this.legacyUpgradeState);
}

class GlobalSettingsCompanion extends UpdateCompanion<GlobalSettingsData> {
  final Value<ThemeSetting?> themeSetting;
  final Value<BrowserPreference?> browserPreference;
  final Value<VisitFirstUnreadSetting?> visitFirstUnread;
  final Value<MarkReadOnScrollSetting?> markReadOnScroll;
  final Value<LegacyUpgradeState?> legacyUpgradeState;
  final Value<int> rowid;
  const GlobalSettingsCompanion({
    this.themeSetting = const Value.absent(),
    this.browserPreference = const Value.absent(),
    this.visitFirstUnread = const Value.absent(),
    this.markReadOnScroll = const Value.absent(),
    this.legacyUpgradeState = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GlobalSettingsCompanion.insert({
    this.themeSetting = const Value.absent(),
    this.browserPreference = const Value.absent(),
    this.visitFirstUnread = const Value.absent(),
    this.markReadOnScroll = const Value.absent(),
    this.legacyUpgradeState = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  static Insertable<GlobalSettingsData> custom({
    Expression<String>? themeSetting,
    Expression<String>? browserPreference,
    Expression<String>? visitFirstUnread,
    Expression<String>? markReadOnScroll,
    Expression<String>? legacyUpgradeState,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (themeSetting != null) 'theme_setting': themeSetting,
      if (browserPreference != null) 'browser_preference': browserPreference,
      if (visitFirstUnread != null) 'visit_first_unread': visitFirstUnread,
      if (markReadOnScroll != null) 'mark_read_on_scroll': markReadOnScroll,
      if (legacyUpgradeState != null)
        'legacy_upgrade_state': legacyUpgradeState,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GlobalSettingsCompanion copyWith({
    Value<ThemeSetting?>? themeSetting,
    Value<BrowserPreference?>? browserPreference,
    Value<VisitFirstUnreadSetting?>? visitFirstUnread,
    Value<MarkReadOnScrollSetting?>? markReadOnScroll,
    Value<LegacyUpgradeState?>? legacyUpgradeState,
    Value<int>? rowid,
  }) {
    return GlobalSettingsCompanion(
      themeSetting: themeSetting ?? this.themeSetting,
      browserPreference: browserPreference ?? this.browserPreference,
      visitFirstUnread: visitFirstUnread ?? this.visitFirstUnread,
      markReadOnScroll: markReadOnScroll ?? this.markReadOnScroll,
      legacyUpgradeState: legacyUpgradeState ?? this.legacyUpgradeState,
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
    if (browserPreference.present) {
      map['browser_preference'] = Variable<String>(
        $GlobalSettingsTable.$converterbrowserPreferencen.toSql(
          browserPreference.value,
        ),
      );
    }
    if (visitFirstUnread.present) {
      map['visit_first_unread'] = Variable<String>(
        $GlobalSettingsTable.$convertervisitFirstUnreadn.toSql(
          visitFirstUnread.value,
        ),
      );
    }
    if (markReadOnScroll.present) {
      map['mark_read_on_scroll'] = Variable<String>(
        $GlobalSettingsTable.$convertermarkReadOnScrolln.toSql(
          markReadOnScroll.value,
        ),
      );
    }
    if (legacyUpgradeState.present) {
      map['legacy_upgrade_state'] = Variable<String>(
        $GlobalSettingsTable.$converterlegacyUpgradeStaten.toSql(
          legacyUpgradeState.value,
        ),
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
          ..write('browserPreference: $browserPreference, ')
          ..write('visitFirstUnread: $visitFirstUnread, ')
          ..write('markReadOnScroll: $markReadOnScroll, ')
          ..write('legacyUpgradeState: $legacyUpgradeState, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BoolGlobalSettingsTable extends BoolGlobalSettings
    with TableInfo<$BoolGlobalSettingsTable, BoolGlobalSettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BoolGlobalSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<bool> value = GeneratedColumn<bool>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("value" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [name, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bool_global_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<BoolGlobalSettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {name};
  @override
  BoolGlobalSettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BoolGlobalSettingRow(
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $BoolGlobalSettingsTable createAlias(String alias) {
    return $BoolGlobalSettingsTable(attachedDatabase, alias);
  }
}

class BoolGlobalSettingRow extends DataClass
    implements Insertable<BoolGlobalSettingRow> {
  /// The setting's name, a possible name from [BoolGlobalSetting].
  ///
  /// The table may have rows where [name] is not the name of any
  /// enum value in [BoolGlobalSetting].
  /// This happens if the app has previously run at a future or modified
  /// version which had additional values in that enum,
  /// and the user set one of those additional settings.
  /// The app ignores any such unknown rows.
  final String name;

  /// The user's chosen value for the setting.
  ///
  /// This is non-nullable; if the user wants to revert to
  /// following the app's default for the setting,
  /// that can be expressed by deleting the row.
  final bool value;
  const BoolGlobalSettingRow({required this.name, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['name'] = Variable<String>(name);
    map['value'] = Variable<bool>(value);
    return map;
  }

  BoolGlobalSettingsCompanion toCompanion(bool nullToAbsent) {
    return BoolGlobalSettingsCompanion(name: Value(name), value: Value(value));
  }

  factory BoolGlobalSettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BoolGlobalSettingRow(
      name: serializer.fromJson<String>(json['name']),
      value: serializer.fromJson<bool>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'name': serializer.toJson<String>(name),
      'value': serializer.toJson<bool>(value),
    };
  }

  BoolGlobalSettingRow copyWith({String? name, bool? value}) =>
      BoolGlobalSettingRow(name: name ?? this.name, value: value ?? this.value);
  BoolGlobalSettingRow copyWithCompanion(BoolGlobalSettingsCompanion data) {
    return BoolGlobalSettingRow(
      name: data.name.present ? data.name.value : this.name,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BoolGlobalSettingRow(')
          ..write('name: $name, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(name, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BoolGlobalSettingRow &&
          other.name == this.name &&
          other.value == this.value);
}

class BoolGlobalSettingsCompanion
    extends UpdateCompanion<BoolGlobalSettingRow> {
  final Value<String> name;
  final Value<bool> value;
  final Value<int> rowid;
  const BoolGlobalSettingsCompanion({
    this.name = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BoolGlobalSettingsCompanion.insert({
    required String name,
    required bool value,
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       value = Value(value);
  static Insertable<BoolGlobalSettingRow> custom({
    Expression<String>? name,
    Expression<bool>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (name != null) 'name': name,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BoolGlobalSettingsCompanion copyWith({
    Value<String>? name,
    Value<bool>? value,
    Value<int>? rowid,
  }) {
    return BoolGlobalSettingsCompanion(
      name: name ?? this.name,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (value.present) {
      map['value'] = Variable<bool>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BoolGlobalSettingsCompanion(')
          ..write('name: $name, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $IntGlobalSettingsTable extends IntGlobalSettings
    with TableInfo<$IntGlobalSettingsTable, IntGlobalSettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IntGlobalSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<int> value = GeneratedColumn<int>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [name, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'int_global_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<IntGlobalSettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {name};
  @override
  IntGlobalSettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IntGlobalSettingRow(
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $IntGlobalSettingsTable createAlias(String alias) {
    return $IntGlobalSettingsTable(attachedDatabase, alias);
  }
}

class IntGlobalSettingRow extends DataClass
    implements Insertable<IntGlobalSettingRow> {
  /// The setting's name, a possible name from [IntGlobalSetting].
  ///
  /// The table may have rows where [name] is not the name of any
  /// enum value in [IntGlobalSetting].
  /// This happens if the app has previously run at a future or modified
  /// version which had additional values in that enum,
  /// and the user set one of those additional settings.
  /// The app ignores any such unknown rows.
  final String name;

  /// The user's chosen value for the setting.
  final int value;
  const IntGlobalSettingRow({required this.name, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['name'] = Variable<String>(name);
    map['value'] = Variable<int>(value);
    return map;
  }

  IntGlobalSettingsCompanion toCompanion(bool nullToAbsent) {
    return IntGlobalSettingsCompanion(name: Value(name), value: Value(value));
  }

  factory IntGlobalSettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IntGlobalSettingRow(
      name: serializer.fromJson<String>(json['name']),
      value: serializer.fromJson<int>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'name': serializer.toJson<String>(name),
      'value': serializer.toJson<int>(value),
    };
  }

  IntGlobalSettingRow copyWith({String? name, int? value}) =>
      IntGlobalSettingRow(name: name ?? this.name, value: value ?? this.value);
  IntGlobalSettingRow copyWithCompanion(IntGlobalSettingsCompanion data) {
    return IntGlobalSettingRow(
      name: data.name.present ? data.name.value : this.name,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IntGlobalSettingRow(')
          ..write('name: $name, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(name, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IntGlobalSettingRow &&
          other.name == this.name &&
          other.value == this.value);
}

class IntGlobalSettingsCompanion extends UpdateCompanion<IntGlobalSettingRow> {
  final Value<String> name;
  final Value<int> value;
  final Value<int> rowid;
  const IntGlobalSettingsCompanion({
    this.name = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IntGlobalSettingsCompanion.insert({
    required String name,
    required int value,
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       value = Value(value);
  static Insertable<IntGlobalSettingRow> custom({
    Expression<String>? name,
    Expression<int>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (name != null) 'name': name,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IntGlobalSettingsCompanion copyWith({
    Value<String>? name,
    Value<int>? value,
    Value<int>? rowid,
  }) {
    return IntGlobalSettingsCompanion(
      name: name ?? this.name,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (value.present) {
      map['value'] = Variable<int>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IntGlobalSettingsCompanion(')
          ..write('name: $name, ')
          ..write('value: $value, ')
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
  static const VerificationMeta _realmNameMeta = const VerificationMeta(
    'realmName',
  );
  @override
  late final GeneratedColumn<String> realmName = GeneratedColumn<String>(
    'realm_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Uri?, String> realmIcon =
      GeneratedColumn<String>(
        'realm_icon',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<Uri?>($AccountsTable.$converterrealmIconn);
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
    realmName,
    realmIcon,
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
    if (data.containsKey('realm_name')) {
      context.handle(
        _realmNameMeta,
        realmName.isAcceptableOrUnknown(data['realm_name']!, _realmNameMeta),
      );
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
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      realmUrl: $AccountsTable.$converterrealmUrl.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}realm_url'],
        )!,
      ),
      realmName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}realm_name'],
      ),
      realmIcon: $AccountsTable.$converterrealmIconn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}realm_icon'],
        ),
      ),
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
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }

  static TypeConverter<Uri, String> $converterrealmUrl = const UriConverter();
  static TypeConverter<Uri, String> $converterrealmIcon = const UriConverter();
  static TypeConverter<Uri?, String?> $converterrealmIconn =
      NullAwareTypeConverter.wrap($converterrealmIcon);
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

  /// The name of the Zulip realm this account is on.
  ///
  /// This corresponds to [GetServerSettingsResult.realmName].
  ///
  /// Nullable just because older versions of the app didn't store this.
  final String? realmName;

  /// The icon URL of the Zulip realm this account is on.
  ///
  /// This corresponds to [GetServerSettingsResult.realmIcon].
  ///
  /// Nullable just because older versions of the app didn't store this.
  final Uri? realmIcon;

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
    this.realmName,
    this.realmIcon,
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
    if (!nullToAbsent || realmName != null) {
      map['realm_name'] = Variable<String>(realmName);
    }
    if (!nullToAbsent || realmIcon != null) {
      map['realm_icon'] = Variable<String>(
        $AccountsTable.$converterrealmIconn.toSql(realmIcon),
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
      realmName: realmName == null && nullToAbsent
          ? const Value.absent()
          : Value(realmName),
      realmIcon: realmIcon == null && nullToAbsent
          ? const Value.absent()
          : Value(realmIcon),
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

  factory Account.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Account(
      id: serializer.fromJson<int>(json['id']),
      realmUrl: serializer.fromJson<Uri>(json['realmUrl']),
      realmName: serializer.fromJson<String?>(json['realmName']),
      realmIcon: serializer.fromJson<Uri?>(json['realmIcon']),
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
      'realmName': serializer.toJson<String?>(realmName),
      'realmIcon': serializer.toJson<Uri?>(realmIcon),
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
    Value<String?> realmName = const Value.absent(),
    Value<Uri?> realmIcon = const Value.absent(),
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
    realmName: realmName.present ? realmName.value : this.realmName,
    realmIcon: realmIcon.present ? realmIcon.value : this.realmIcon,
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
  Account copyWithCompanion(AccountsCompanion data) {
    return Account(
      id: data.id.present ? data.id.value : this.id,
      realmUrl: data.realmUrl.present ? data.realmUrl.value : this.realmUrl,
      realmName: data.realmName.present ? data.realmName.value : this.realmName,
      realmIcon: data.realmIcon.present ? data.realmIcon.value : this.realmIcon,
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
    return (StringBuffer('Account(')
          ..write('id: $id, ')
          ..write('realmUrl: $realmUrl, ')
          ..write('realmName: $realmName, ')
          ..write('realmIcon: $realmIcon, ')
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
    realmName,
    realmIcon,
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
          other.realmName == this.realmName &&
          other.realmIcon == this.realmIcon &&
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
  final Value<String?> realmName;
  final Value<Uri?> realmIcon;
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
    this.realmName = const Value.absent(),
    this.realmIcon = const Value.absent(),
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
    this.realmName = const Value.absent(),
    this.realmIcon = const Value.absent(),
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
    Expression<String>? realmName,
    Expression<String>? realmIcon,
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
      if (realmName != null) 'realm_name': realmName,
      if (realmIcon != null) 'realm_icon': realmIcon,
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
    Value<String?>? realmName,
    Value<Uri?>? realmIcon,
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
      realmName: realmName ?? this.realmName,
      realmIcon: realmIcon ?? this.realmIcon,
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
    if (realmName.present) {
      map['realm_name'] = Variable<String>(realmName.value);
    }
    if (realmIcon.present) {
      map['realm_icon'] = Variable<String>(
        $AccountsTable.$converterrealmIconn.toSql(realmIcon.value),
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
          ..write('realmName: $realmName, ')
          ..write('realmIcon: $realmIcon, ')
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
  late final $BoolGlobalSettingsTable boolGlobalSettings =
      $BoolGlobalSettingsTable(this);
  late final $IntGlobalSettingsTable intGlobalSettings =
      $IntGlobalSettingsTable(this);
  late final $AccountsTable accounts = $AccountsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    globalSettings,
    boolGlobalSettings,
    intGlobalSettings,
    accounts,
  ];
}

typedef $$GlobalSettingsTableCreateCompanionBuilder =
    GlobalSettingsCompanion Function({
      Value<ThemeSetting?> themeSetting,
      Value<BrowserPreference?> browserPreference,
      Value<VisitFirstUnreadSetting?> visitFirstUnread,
      Value<MarkReadOnScrollSetting?> markReadOnScroll,
      Value<LegacyUpgradeState?> legacyUpgradeState,
      Value<int> rowid,
    });
typedef $$GlobalSettingsTableUpdateCompanionBuilder =
    GlobalSettingsCompanion Function({
      Value<ThemeSetting?> themeSetting,
      Value<BrowserPreference?> browserPreference,
      Value<VisitFirstUnreadSetting?> visitFirstUnread,
      Value<MarkReadOnScrollSetting?> markReadOnScroll,
      Value<LegacyUpgradeState?> legacyUpgradeState,
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

  ColumnWithTypeConverterFilters<BrowserPreference?, BrowserPreference, String>
  get browserPreference => $composableBuilder(
    column: $table.browserPreference,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<
    VisitFirstUnreadSetting?,
    VisitFirstUnreadSetting,
    String
  >
  get visitFirstUnread => $composableBuilder(
    column: $table.visitFirstUnread,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<
    MarkReadOnScrollSetting?,
    MarkReadOnScrollSetting,
    String
  >
  get markReadOnScroll => $composableBuilder(
    column: $table.markReadOnScroll,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<
    LegacyUpgradeState?,
    LegacyUpgradeState,
    String
  >
  get legacyUpgradeState => $composableBuilder(
    column: $table.legacyUpgradeState,
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

  ColumnOrderings<String> get browserPreference => $composableBuilder(
    column: $table.browserPreference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get visitFirstUnread => $composableBuilder(
    column: $table.visitFirstUnread,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get markReadOnScroll => $composableBuilder(
    column: $table.markReadOnScroll,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get legacyUpgradeState => $composableBuilder(
    column: $table.legacyUpgradeState,
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

  GeneratedColumnWithTypeConverter<BrowserPreference?, String>
  get browserPreference => $composableBuilder(
    column: $table.browserPreference,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<VisitFirstUnreadSetting?, String>
  get visitFirstUnread => $composableBuilder(
    column: $table.visitFirstUnread,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<MarkReadOnScrollSetting?, String>
  get markReadOnScroll => $composableBuilder(
    column: $table.markReadOnScroll,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<LegacyUpgradeState?, String>
  get legacyUpgradeState => $composableBuilder(
    column: $table.legacyUpgradeState,
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
          createFilteringComposer: () =>
              $$GlobalSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GlobalSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GlobalSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<ThemeSetting?> themeSetting = const Value.absent(),
                Value<BrowserPreference?> browserPreference =
                    const Value.absent(),
                Value<VisitFirstUnreadSetting?> visitFirstUnread =
                    const Value.absent(),
                Value<MarkReadOnScrollSetting?> markReadOnScroll =
                    const Value.absent(),
                Value<LegacyUpgradeState?> legacyUpgradeState =
                    const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GlobalSettingsCompanion(
                themeSetting: themeSetting,
                browserPreference: browserPreference,
                visitFirstUnread: visitFirstUnread,
                markReadOnScroll: markReadOnScroll,
                legacyUpgradeState: legacyUpgradeState,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<ThemeSetting?> themeSetting = const Value.absent(),
                Value<BrowserPreference?> browserPreference =
                    const Value.absent(),
                Value<VisitFirstUnreadSetting?> visitFirstUnread =
                    const Value.absent(),
                Value<MarkReadOnScrollSetting?> markReadOnScroll =
                    const Value.absent(),
                Value<LegacyUpgradeState?> legacyUpgradeState =
                    const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GlobalSettingsCompanion.insert(
                themeSetting: themeSetting,
                browserPreference: browserPreference,
                visitFirstUnread: visitFirstUnread,
                markReadOnScroll: markReadOnScroll,
                legacyUpgradeState: legacyUpgradeState,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
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
typedef $$BoolGlobalSettingsTableCreateCompanionBuilder =
    BoolGlobalSettingsCompanion Function({
      required String name,
      required bool value,
      Value<int> rowid,
    });
typedef $$BoolGlobalSettingsTableUpdateCompanionBuilder =
    BoolGlobalSettingsCompanion Function({
      Value<String> name,
      Value<bool> value,
      Value<int> rowid,
    });

class $$BoolGlobalSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $BoolGlobalSettingsTable> {
  $$BoolGlobalSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BoolGlobalSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $BoolGlobalSettingsTable> {
  $$BoolGlobalSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BoolGlobalSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BoolGlobalSettingsTable> {
  $$BoolGlobalSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$BoolGlobalSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BoolGlobalSettingsTable,
          BoolGlobalSettingRow,
          $$BoolGlobalSettingsTableFilterComposer,
          $$BoolGlobalSettingsTableOrderingComposer,
          $$BoolGlobalSettingsTableAnnotationComposer,
          $$BoolGlobalSettingsTableCreateCompanionBuilder,
          $$BoolGlobalSettingsTableUpdateCompanionBuilder,
          (
            BoolGlobalSettingRow,
            BaseReferences<
              _$AppDatabase,
              $BoolGlobalSettingsTable,
              BoolGlobalSettingRow
            >,
          ),
          BoolGlobalSettingRow,
          PrefetchHooks Function()
        > {
  $$BoolGlobalSettingsTableTableManager(
    _$AppDatabase db,
    $BoolGlobalSettingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BoolGlobalSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BoolGlobalSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BoolGlobalSettingsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> name = const Value.absent(),
                Value<bool> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BoolGlobalSettingsCompanion(
                name: name,
                value: value,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String name,
                required bool value,
                Value<int> rowid = const Value.absent(),
              }) => BoolGlobalSettingsCompanion.insert(
                name: name,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BoolGlobalSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BoolGlobalSettingsTable,
      BoolGlobalSettingRow,
      $$BoolGlobalSettingsTableFilterComposer,
      $$BoolGlobalSettingsTableOrderingComposer,
      $$BoolGlobalSettingsTableAnnotationComposer,
      $$BoolGlobalSettingsTableCreateCompanionBuilder,
      $$BoolGlobalSettingsTableUpdateCompanionBuilder,
      (
        BoolGlobalSettingRow,
        BaseReferences<
          _$AppDatabase,
          $BoolGlobalSettingsTable,
          BoolGlobalSettingRow
        >,
      ),
      BoolGlobalSettingRow,
      PrefetchHooks Function()
    >;
typedef $$IntGlobalSettingsTableCreateCompanionBuilder =
    IntGlobalSettingsCompanion Function({
      required String name,
      required int value,
      Value<int> rowid,
    });
typedef $$IntGlobalSettingsTableUpdateCompanionBuilder =
    IntGlobalSettingsCompanion Function({
      Value<String> name,
      Value<int> value,
      Value<int> rowid,
    });

class $$IntGlobalSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $IntGlobalSettingsTable> {
  $$IntGlobalSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$IntGlobalSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $IntGlobalSettingsTable> {
  $$IntGlobalSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$IntGlobalSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $IntGlobalSettingsTable> {
  $$IntGlobalSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$IntGlobalSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IntGlobalSettingsTable,
          IntGlobalSettingRow,
          $$IntGlobalSettingsTableFilterComposer,
          $$IntGlobalSettingsTableOrderingComposer,
          $$IntGlobalSettingsTableAnnotationComposer,
          $$IntGlobalSettingsTableCreateCompanionBuilder,
          $$IntGlobalSettingsTableUpdateCompanionBuilder,
          (
            IntGlobalSettingRow,
            BaseReferences<
              _$AppDatabase,
              $IntGlobalSettingsTable,
              IntGlobalSettingRow
            >,
          ),
          IntGlobalSettingRow,
          PrefetchHooks Function()
        > {
  $$IntGlobalSettingsTableTableManager(
    _$AppDatabase db,
    $IntGlobalSettingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IntGlobalSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IntGlobalSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IntGlobalSettingsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> name = const Value.absent(),
                Value<int> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IntGlobalSettingsCompanion(
                name: name,
                value: value,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String name,
                required int value,
                Value<int> rowid = const Value.absent(),
              }) => IntGlobalSettingsCompanion.insert(
                name: name,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$IntGlobalSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IntGlobalSettingsTable,
      IntGlobalSettingRow,
      $$IntGlobalSettingsTableFilterComposer,
      $$IntGlobalSettingsTableOrderingComposer,
      $$IntGlobalSettingsTableAnnotationComposer,
      $$IntGlobalSettingsTableCreateCompanionBuilder,
      $$IntGlobalSettingsTableUpdateCompanionBuilder,
      (
        IntGlobalSettingRow,
        BaseReferences<
          _$AppDatabase,
          $IntGlobalSettingsTable,
          IntGlobalSettingRow
        >,
      ),
      IntGlobalSettingRow,
      PrefetchHooks Function()
    >;
typedef $$AccountsTableCreateCompanionBuilder =
    AccountsCompanion Function({
      Value<int> id,
      required Uri realmUrl,
      Value<String?> realmName,
      Value<Uri?> realmIcon,
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
      Value<String?> realmName,
      Value<Uri?> realmIcon,
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

  ColumnFilters<String> get realmName => $composableBuilder(
    column: $table.realmName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Uri?, Uri, String> get realmIcon =>
      $composableBuilder(
        column: $table.realmIcon,
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

  ColumnOrderings<String> get realmName => $composableBuilder(
    column: $table.realmName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get realmIcon => $composableBuilder(
    column: $table.realmIcon,
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

  GeneratedColumn<String> get realmName =>
      $composableBuilder(column: $table.realmName, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Uri?, String> get realmIcon =>
      $composableBuilder(column: $table.realmIcon, builder: (column) => column);

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
          createFilteringComposer: () =>
              $$AccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<Uri> realmUrl = const Value.absent(),
                Value<String?> realmName = const Value.absent(),
                Value<Uri?> realmIcon = const Value.absent(),
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
                realmName: realmName,
                realmIcon: realmIcon,
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
                Value<String?> realmName = const Value.absent(),
                Value<Uri?> realmIcon = const Value.absent(),
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
                realmName: realmName,
                realmIcon: realmIcon,
                userId: userId,
                email: email,
                apiKey: apiKey,
                zulipVersion: zulipVersion,
                zulipMergeBase: zulipMergeBase,
                zulipFeatureLevel: zulipFeatureLevel,
                ackedPushToken: ackedPushToken,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
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
  $$BoolGlobalSettingsTableTableManager get boolGlobalSettings =>
      $$BoolGlobalSettingsTableTableManager(_db, _db.boolGlobalSettings);
  $$IntGlobalSettingsTableTableManager get intGlobalSettings =>
      $$IntGlobalSettingsTableTableManager(_db, _db.intGlobalSettings);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db, _db.accounts);
}
