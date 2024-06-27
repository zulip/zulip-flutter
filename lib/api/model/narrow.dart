typedef ApiNarrow = List<ApiNarrowElement>;

/// Resolve any [ApiNarrowDm] elements appropriately.
///
/// This encapsulates a server-feature check.
ApiNarrow resolveDmElements(ApiNarrow narrow, int zulipFeatureLevel) {
  if (!narrow.any((element) => element is ApiNarrowDm)) {
    return narrow;
  }
  final supportsOperatorDm = zulipFeatureLevel >= 177; // TODO(server-7)
  return narrow.map((element) => switch (element) {
    ApiNarrowDm() => element.resolve(legacy: !supportsOperatorDm),
    _             => element,
  }).toList();
}

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
  @override String get operator => 'channel';

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

/// An [ApiNarrowElement] with the 'dm', or legacy 'pm-with', operator.
///
/// An instance directly of this class must not be serialized with [jsonEncode],
/// and more generally its [operator] getter must not be called.
/// Instead, call [resolve] and use the object it returns.
///
/// If part of [ApiNarrow] use [resolveDmElements].
class ApiNarrowDm extends ApiNarrowElement {
  @override String get operator {
    assert(false,
      "The [operator] getter was called on a plain [ApiNarrowDm].  "
      "Before passing to [jsonEncode] or otherwise getting [operator], "
      "the [ApiNarrowDm] must be replaced by the result of [ApiNarrowDm.resolve]."
    );
    return "dm";
  }

  @override final List<int> operand;

  ApiNarrowDm(this.operand, {super.negated});

  factory ApiNarrowDm.fromJson(Map<String, dynamic> json) {
    var operand = (json['operand'] as List<dynamic>).map((e) => e as int).toList();
    var negated = json['negated'] as bool? ?? false;
    return (json['operator'] == 'pm-with')
      ? ApiNarrowPmWith._(operand, negated: negated)
      : ApiNarrowDmModern._(operand, negated: negated);
  }

  /// This element resolved, as either an [ApiNarrowDmModern] or an [ApiNarrowPmWith].
  ApiNarrowDm resolve({required bool legacy}) {
    return legacy ? ApiNarrowPmWith._(operand, negated: negated)
                  : ApiNarrowDmModern._(operand, negated: negated);
  }
}

/// An [ApiNarrowElement] with the 'dm' operator (and not the legacy 'pm-with').
///
/// To construct one of these, use [ApiNarrowDm.resolve].
class ApiNarrowDmModern extends ApiNarrowDm {
  @override String get operator => 'dm';

  ApiNarrowDmModern._(super.operand, {super.negated});
}

/// An [ApiNarrowElement] with the legacy 'pm-with' operator.
///
/// To construct one of these, use [ApiNarrowDm.resolve].
class ApiNarrowPmWith extends ApiNarrowDm {
  @override String get operator => 'pm-with';

  ApiNarrowPmWith._(super.operand, {super.negated});
}

// TODO: generalize into ApiNarrowIs
class ApiNarrowIsUnread extends ApiNarrowElement {
  @override String get operator => 'is';
  @override String get operand => 'unread';

  ApiNarrowIsUnread({super.negated});
}

class ApiNarrowMessageId extends ApiNarrowElement {
  @override String get operator => 'id';

  // The API requires a string, even though message IDs are ints:
  //   https://chat.zulip.org/#narrow/stream/378-api-design/topic/.60id.3A123.60.20narrow.20in.20.60GET.20.2Fmessages.60/near/1591465
  // TODO(server-future) Send ints to future servers that support them. For how
  //   to handle the migration, see [ApiNarrowDm.resolve].
  @override final String operand;

  ApiNarrowMessageId(int operand, {super.negated}) : operand = operand.toString();

  factory ApiNarrowMessageId.fromJson(Map<String, dynamic> json) => ApiNarrowMessageId(
    int.parse(json['operand'] as String, radix: 10),
    negated: json['negated'] as bool? ?? false,
  );
}
