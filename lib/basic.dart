
/// Either a value, or the absence of a value.
///
/// An `Option<T>` is either an `OptionSome` representing a `T` value,
/// or an `OptionNone` representing the absence of a value.
///
/// When `T` is non-nullable, this is the same information that is
/// normally represented as a `T?`.
/// This class is useful when T is nullable (or might be nullable).
/// In that case `null` is already a T value,
/// and so can't also be used to represent the absence of a T value,
/// but `OptionNone()` is a different value from `OptionSome(null)`.
///
/// This interface is small because members are added lazily when needed.
/// If adding another member, consider borrowing the naming from Rust:
///   https://doc.rust-lang.org/std/option/enum.Option.html
sealed class Option<T> {
  const Option();

  /// The value contained in this option, if any; else the given value.
  T or(T optb);

  /// The value contained in this option, if any;
  /// else the value returned by [fn].
  ///
  /// [fn] is called only if its return value is needed.
  T orElse(T Function() fn);
}

class OptionNone<T> extends Option<T> {
  const OptionNone();

  @override
  T or(T optb) => optb;

  @override
  T orElse(T Function() fn) => fn();

  @override
  bool operator ==(Object other) => other is OptionNone;

  @override
  int get hashCode => 'OptionNone'.hashCode;

  @override
  String toString() => 'OptionNone';
}

class OptionSome<T> extends Option<T> {
  const OptionSome(this.value);

  final T value;

  @override
  T or(T optb) => value;

  @override
  T orElse(T Function() fn) => value;

  @override
  bool operator ==(Object other) => other is OptionSome && value == other.value;

  @override
  int get hashCode => Object.hash('OptionSome', value);

  @override
  String toString() => 'OptionSome($value)';
}
