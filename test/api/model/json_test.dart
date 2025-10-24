import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/api/model/json.dart';

void main() {
  group('JsonNullable', () {
    test('value', () {
      check(const JsonNullable<int>(null)).value.isNull();
      check(const JsonNullable(3)).value.equals(3);
      check(const JsonNullable(JsonNullable(3))).value
        ..identicalTo(const JsonNullable(3))
        ..isNotNull().value.equals(3);
    });

    test('readFromJson', () {
      check(JsonNullable.readFromJson({},          'a')).isNull();
      check(JsonNullable.readFromJson({'a': null}, 'a')).equals(const JsonNullable(null));
      check(JsonNullable.readFromJson({'a': 3},    'a')).equals(const JsonNullable(3));
    });

    test('==/hashCode', () {
      // ignore: prefer_const_constructors
      check(JsonNullable<int>(null)).equals(JsonNullable(null));
      // ignore: prefer_const_constructors
      check(JsonNullable(3)).equals(JsonNullable(3));
      // ignore: prefer_const_constructors
      check(JsonNullable(JsonNullable(3))).equals(JsonNullable(JsonNullable(3)));

      const values = [JsonNullable<int>(null), JsonNullable(3), JsonNullable(4),
        JsonNullable(JsonNullable<int>(null)), JsonNullable(JsonNullable(3))];
      for (int i = 0; i < values.length; i++) {
        for (int j = i + 1; j < values.length; j++) {
          check(values[i]).not((it) => it.equals(values[j]));
          check(values[i].hashCode).not((it) => it.equals(values[j].hashCode));
        }
      }
    });
  });
}

extension JsonNullableChecks<T extends Object> on Subject<JsonNullable<T>> {
  Subject<T?> get value => has((x) => x.value, 'value');
}
