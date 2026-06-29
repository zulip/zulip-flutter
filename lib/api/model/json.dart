import 'package:json_annotation/json_annotation.dart';

/// A value parsed from JSON as either `null` or another value.
///
/// This can be used to represent JSON properties where absence, null,
/// and some other type are distinguished.
/// For example, with the following field definition:
/// ```dart
///   JsonNullable<String>? name;
/// ```
/// a `name` value of `null` (as a Dart value) represents
/// the `name` property being absent in JSON;
/// a value of `JsonNullable(null)` represents `'name': null` in JSON;
/// and a value of `JsonNullable("foo")` represents `'name': 'foo'` in JSON.
///
/// To use this class with [JsonSerializable]:
///  * On the field, apply [JsonKey.readValue] with a method from the
///    [readFromJson] family.
///  * On either the field or the class, apply an [IdentityJsonConverter]
///    subclass such as [NullableIntJsonConverter].
///  * Both the read method and the converter need to have a concrete type,
///    not generic in T, because of limitations in `package:json_serializable`.
///    Go ahead and add them for more concrete types whenever needed.
class JsonNullable<T extends Object> {
  const JsonNullable(this.value);

  final T? value;

  /// Reads a [JsonNullable] from a JSON map, as in [JsonKey.readValue].
  ///
  /// The method actually passed to [JsonKey.readValue] needs a concrete type;
  /// see the wrapper methods [readIntFromJson] and [readStringFromJson],
  /// and add more freely as needed.
  ///
  /// This generic version is useful when writing a custom [JsonKey.readValue]
  /// callback for other reasons, as well as for implementing those wrappers.
  ///
  /// Because the [JsonKey.readValue] return value is expected to still be
  /// a JSON-like value that needs conversion,
  /// the field (or the class) will also need to be annotated with
  /// [IdentityJsonConverter] or a subclass.
  /// The converter tells `package:json_serializable` how to convert
  /// the [JsonNullable] from JSON: namely, by doing nothing.
  static JsonNullable<T>? readFromJson<T extends Object>(
      Map<dynamic, dynamic> map, String key) {
    return map.containsKey(key) ? JsonNullable(map[key] as T?) : null;
  }

  /// Reads a [JsonNullable<int>] from a JSON map, as in [JsonKey.readValue].
  ///
  /// The field or class will need to be annotated with [NullableIntJsonConverter].
  /// See [readFromJson].
  static JsonNullable<int>? readIntFromJson(Map<dynamic, dynamic> map, String key) =>
    readFromJson<int>(map, key);

  /// Reads a [JsonNullable<String>] from a JSON map, as in [JsonKey.readValue].
  ///
  /// The field or class will need to be annotated with [NullableStringJsonConverter].
  /// See [readFromJson].
  static JsonNullable<String>? readStringFromJson(Map<dynamic, dynamic> map, String key) =>
    readFromJson<String>(map, key);

  @override
  bool operator ==(Object other) {
    if (other is! JsonNullable) return false;
    return value == other.value;
  }

  @override
  int get hashCode => Object.hash('JsonNullable', value);
}

/// "Converts" a value to and from JSON by using the value unmodified.
///
/// This is useful when e.g. a [JsonKey.readValue] callback has already
/// effectively converted the value from JSON,
/// as [JsonNullable.readFromJson] does.
///
/// The converter actually applied as an annotation needs a specific type.
/// Just writing `@IdentityJsonConverter<…>` directly as the annotation
/// doesn't work, as `package:json_serializable` gets confused;
/// instead, use a subclass like [NullableIntJsonConverter],
/// and add new such subclasses whenever needed.
// Possibly related to that issue with a generic converter:
//   https://github.com/google/json_serializable.dart/issues/1398
class IdentityJsonConverter<T> extends JsonConverter<T, T> {
  const IdentityJsonConverter();

  @override
  T fromJson(T json) => json;

  @override
  T toJson(T object) => object;
}

/// "Converts" a [JsonNullable<int>] to and from JSON by using it unmodified.
///
/// This is useful with [JsonNullable.readIntFromJson].
/// See there, and the base class [IdentityJsonConverter].
class NullableIntJsonConverter extends IdentityJsonConverter<JsonNullable<int>> {
  const NullableIntJsonConverter();
}

/// "Converts" a [JsonNullable<String>] to and from JSON by using it unmodified.
///
/// This is useful with [JsonNullable.readStringFromJson].
/// See there, and the base class [IdentityJsonConverter].
class NullableStringJsonConverter extends IdentityJsonConverter<JsonNullable<String>> {
  const NullableStringJsonConverter();
}
