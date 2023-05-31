typedef ApiNarrow = List<ApiNarrowElement>;

/// An element in the list representing a narrow in the Zulip API.
///
/// Docs: <https://zulip.com/api/construct-narrow>
///
/// The existing list of subclasses is incomplete;
/// please add more as needed.
sealed class ApiNarrowElement {
  String get operator;
  Object get operand;
  final bool negated;

  ApiNarrowElement({this.negated = false});

  Map<String, dynamic> toJson() => {
    'operator': operator,
    'operand': operand,
    if (negated) 'negated': negated,
  };
}

class ApiNarrowStream extends ApiNarrowElement {
  @override String get operator => 'stream';

  @override final int operand;

  ApiNarrowStream(this.operand, {super.negated});

  factory ApiNarrowStream.fromJson(Map<String, dynamic> json) => ApiNarrowStream(
    json['operand'] as int,
    negated: json['negated'] as bool? ?? false,
  );
}

class ApiNarrowTopic extends ApiNarrowElement {
  @override String get operator => 'topic';

  @override final String operand;

  ApiNarrowTopic(this.operand, {super.negated});

  factory ApiNarrowTopic.fromJson(Map<String, dynamic> json) => ApiNarrowTopic(
    json['operand'] as String,
    negated: json['negated'] as bool? ?? false,
  );
}

class ApiNarrowPmWith extends ApiNarrowElement {
  @override String get operator => 'pm-with'; // TODO(server-7): use 'dm' where possible

  @override final List<int> operand;

  ApiNarrowPmWith(this.operand, {super.negated});

  factory ApiNarrowPmWith.fromJson(Map<String, dynamic> json) => ApiNarrowPmWith(
    (json['operand'] as List<dynamic>).map((e) => e as int).toList(),
    negated: json['negated'] as bool? ?? false,
  );
}
