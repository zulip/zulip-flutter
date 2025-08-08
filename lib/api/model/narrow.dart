import 'package:json_annotation/json_annotation.dart';

import 'model.dart';

part 'narrow.g.dart';

typedef ApiNarrow = List<ApiNarrowElement>;

/// Adapt the given narrow to be sent to the given Zulip server version.
///
/// Any elements that take a different name on old vs. new servers
/// will be resolved to the specific name to use.
/// Any elements that are unknown to old servers and can
/// reasonably be omitted will be omitted.
ApiNarrow resolveApiNarrowForServer(ApiNarrow narrow, int zulipFeatureLevel) {
  final supportsOperatorDm = zulipFeatureLevel >= 177; // TODO(server-7)
  final supportsOperatorChannel = zulipFeatureLevel >= 250; // TODO(server-9)
  final supportsOperatorWith = zulipFeatureLevel >= 271; // TODO(server-9)

  bool hasDmElement = false;
  bool hasChannelElement = false;
  bool hasWithElement = false;
  for (final element in narrow) {
    switch (element) {
      case ApiNarrowChannel(): hasChannelElement = true;
      case ApiNarrowDm():      hasDmElement = true;
      case ApiNarrowWith():    hasWithElement = true;
      default:
    }
  }
  if (!(hasChannelElement || hasDmElement || (hasWithElement && !supportsOperatorWith))) {
    return narrow;
  }

  final result = <ApiNarrowElement>[];
  for (final element in narrow) {
    switch (element) {
      case ApiNarrowChannel():
        result.add(element.resolve(legacy: !supportsOperatorChannel));
      case ApiNarrowDm():
        result.add(element.resolve(legacy: !supportsOperatorDm));
      case ApiNarrowWith() when !supportsOperatorWith:
        break; // drop unsupported element
      default:
        result.add(element);
    }
  }
  return result;
}

/// An element in the list representing a narrow in the Zulip API.
///
/// Docs: <https://zulip.com/api/construct-narrow>
///
/// The existing list of subclasses is incomplete;
/// please add more as needed.
sealed class ApiNarrowElement {
  String get operator;

  /// The operand of this narrow filter.
  ///
  /// The base-class getter [ApiNarrowElement.operand] returns `dynamic`,
  /// and its value should only be used for encoding as JSON, for use in a
  /// request to the Zulip server.
  ///
  /// For any operations that depend more specifically on the operand's type,
  /// do not use run-time type checks on the value of [operand]; instead, make
  /// a run-time type check (e.g. with `switch`) on the [ApiNarrowElement]
  /// itself, and use the [operand] getter of the specific subtype.
  ///
  /// That makes a difference because [ApiNarrowTopic.operand] has type
  /// [TopicName]; at runtime a [TopicName] is indistinguishable from [String],
  /// but an [ApiNarrowTopic] can still be distinguished from other subclasses.
  //
  // We can't just write [Object] here; if we do, the compiler rejects the
  // override in ApiNarrowTopic because TopicName can't be assigned to Object.
  // The reason that could be bad is that a caller of [ApiNarrowElement.operand]
  // could take the result and call Object members on it, like toString, even
  // though TopicName doesn't declare those members.
  //
  // In this case that's fine because the only plausible thing to do with
  // a generic [ApiNarrowElement.operand] is to encode it as JSON anyway,
  // which behaves just fine on TopicName.
  //
  // ... Even if it weren't fine, in the case of Object this protection is
  // thoroughly undermined already: code that has a TopicName can call Object
  // members on it directly.  See comments at [TopicName].
  dynamic get operand; // see justification for `dynamic` above

  final bool negated;

  ApiNarrowElement({this.negated = false});

  Map<String, dynamic> toJson() => {
    'operator': operator,
    'operand': operand,
    if (negated) 'negated': negated,
  };
}

class ApiNarrowChannel extends ApiNarrowElement {
  @override String get operator {
    assert(false,
      "The [operator] getter was called on a plain [ApiNarrowChannel].  "
      "Before passing to [jsonEncode] or otherwise getting [operator], "
      "the [ApiNarrowChannel] must be replaced by the result of [ApiNarrowChannel.resolve]."
    );
    return "channel";
  }

  @override final int operand;

  ApiNarrowChannel(this.operand, {super.negated});

  factory ApiNarrowChannel.fromJson(Map<String, dynamic> json) {
    var operand = (json['operand'] as int);
    var negated = json['negated'] as bool? ?? false;
    return json['operator'] == 'stream'
      ? ApiNarrowStream._(operand, negated: negated)
      : ApiNarrowChannelModern._(operand, negated: negated);
  }

  /// This element resolved, as either an [ApiNarrowChannelModern] or an [ApiNarrowStream].
  ApiNarrowChannel resolve({required bool legacy}) {
    return legacy ? ApiNarrowStream._(operand, negated: negated)
                  : ApiNarrowChannelModern._(operand, negated: negated);
  }
}

/// An [ApiNarrowElement] with the 'channel' operator (and not the legacy 'stream').
///
/// To construct one of these, use [ApiNarrowChannel.resolve].
class ApiNarrowChannelModern extends ApiNarrowChannel {
  @override String get operator => 'channel';

  ApiNarrowChannelModern._(super.operand, {super.negated});
}

/// An [ApiNarrowElement] with the legacy 'stream' operator.
///
/// To construct one of these, use [ApiNarrowChannel.resolve].
class ApiNarrowStream extends ApiNarrowChannel {
  @override String get operator => 'stream';

  ApiNarrowStream._(super.operand, {super.negated});
}

class ApiNarrowTopic extends ApiNarrowElement {
  @override String get operator => 'topic';

  @override final TopicName operand;

  ApiNarrowTopic(this.operand, {super.negated});

  factory ApiNarrowTopic.fromJson(Map<String, dynamic> json) => ApiNarrowTopic(
    TopicName.fromJson(json['operand'] as String),
    negated: json['negated'] as bool? ?? false,
  );
}

/// An [ApiNarrowElement] with the 'dm', or legacy 'pm-with', operator.
///
/// An instance directly of this class must not be serialized with [jsonEncode],
/// and more generally its [operator] getter must not be called.
/// Instead, call [resolve] and use the object it returns.
///
/// If part of [ApiNarrow] use [resolveApiNarrowForServer].
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

/// An [ApiNarrowElement] with the 'search' operator.
class ApiNarrowSearch extends ApiNarrowElement {
  @override String get operator => 'search';

  @override final String operand;

  ApiNarrowSearch(this.operand, {super.negated});

  factory ApiNarrowSearch.fromJson(Map<String, dynamic> json) => ApiNarrowSearch(
    json['operand'] as String,
    negated: json['negated'] as bool? ?? false,
  );
}

class ApiNarrowIs extends ApiNarrowElement {
  @override String get operator => 'is';

  @override final IsOperand operand;

  ApiNarrowIs(this.operand, {super.negated});

  factory ApiNarrowIs.fromJson(Map<String, dynamic> json) => ApiNarrowIs(
    IsOperand.fromRawString(json['operand'] as String),
    negated: json['negated'] as bool? ?? false,
  );
}

/// An operand value of "is" operator.
///
/// See also:
///   - https://zulip.com/api/construct-narrow
///   - https://zulip.com/help/search-for-messages#search-your-important-messages
///   - https://zulip.com/help/search-for-messages#search-by-message-status
@JsonEnum(alwaysCreate: true)
enum IsOperand {
  dm,        // TODO(server-7) new in FL 177
  private,   // TODO(server-7) deprecated in FL 177, equivalent to [dm].
  alerted,
  mentioned,
  starred,
  followed,  // TODO(server-9) new in FL 265
  resolved,
  unread,
  unknown;

  static IsOperand fromRawString(String raw) => $enumDecode(
    _$IsOperandEnumMap, raw, unknownValue: unknown);

  @override
  String toString() => _$IsOperandEnumMap[this]!;

  String toJson() => toString();
}

/// An [ApiNarrowElement] with the 'with' operator.
///
/// If part of [ApiNarrow] use [resolveApiNarrowForServer].
class ApiNarrowWith extends ApiNarrowElement {
  @override String get operator => 'with';

  @override final int operand;

  ApiNarrowWith(this.operand, {super.negated});

  factory ApiNarrowWith.fromJson(Map<String, dynamic> json) => ApiNarrowWith(
    json['operand'] as int,
    negated: json['negated'] as bool? ?? false,
  );
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
