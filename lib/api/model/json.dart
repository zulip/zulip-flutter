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
class JsonNullable<T extends Object> {
  const JsonNullable(this.value);

  final T? value;

  static JsonNullable<T>? readFromJson<T extends Object>(
      Map<dynamic, dynamic> map, String key) {
    return map.containsKey(key) ? JsonNullable(map[key] as T?) : null;
  }

  static JsonNullable<int>? readIntFromJson(Map<dynamic, dynamic> map, String key) =>
    readFromJson<int>(map, key);

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

class IdentityJsonConverter<T> extends JsonConverter<T, T> {
  const IdentityJsonConverter();

  @override
  T fromJson(T json) => json;

  @override
  T toJson(T object) => object;
}

// Make similar IdentityJsonConverter<…> subclasses as needed.
// Just writing `@IdentityJsonConverter<…>` directly as the annotation
// doesn't work, as json_serializable gets confused.  Possibly related:
//   https://github.com/google/json_serializable.dart/issues/1398
class NullableIntJsonConverter extends IdentityJsonConverter<JsonNullable<int>> {
  const NullableIntJsonConverter();
}

class NullableStringJsonConverter extends IdentityJsonConverter<JsonNullable<String>> {
  const NullableStringJsonConverter();
}
