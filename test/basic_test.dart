import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/basic.dart';

void main() {
  group('Option', () {
    test('==/hashCode', () {
      void checkEqual(Object a, Object b) {
        check(a).equals(b);
        check(a.hashCode).equals(b.hashCode);
      }

      void checkUnequal(Object a, Object b) {
        check(a).not((it) => it.equals(b));
      }

      checkEqual(OptionNone<int>(), OptionNone<int?>());
      checkEqual(OptionNone<int>(), OptionNone<String>());

      checkEqual(OptionSome<int>(3), OptionSome<int?>(3));
      checkEqual(OptionSome<int?>(null), OptionSome<String?>(null));
      checkEqual(OptionSome(OptionSome(3)), OptionSome(OptionSome(3)));

      checkUnequal(OptionNone<void>(), OptionSome<void>(null));
      checkUnequal(OptionSome(3), OptionSome(OptionSome(3)));
      checkUnequal(3, OptionSome(3));
    });

    test('or', () {
      check(OptionSome<int>(3).or(4)).equals(3);
      check(OptionSome<int?>(3).or(4)).equals(3);
      check(OptionSome<int?>(null).or(4)).equals(null);
      check(OptionNone<int?>().or(4)).equals(4);
    });

    test('orElse', () {
      check(OptionSome<int>(3).orElse(() => 4)).equals(3);
      check(OptionSome<int?>(3).orElse(() => 4)).equals(3);
      check(OptionSome<int?>(null).orElse(() => 4)).equals(null);
      check(OptionNone<int?>().orElse(() => 4)).equals(4);

      final myError = Error();
      check(OptionSome<int>(3).orElse(() => throw myError)).equals(3);
      check(() => OptionNone<int>().orElse(() => throw myError))
        .throws<Error>().identicalTo(myError);
    });
  });
}
