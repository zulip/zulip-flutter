import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../log.dart';
import 'events.dart';

part 'submessage.g.dart';

/// Data used for Zulip "widgets" within messages, like polls and todo lists.
///
/// For docs, see:
///   https://zulip.com/api/get-messages#response (search for "submessage")
///   https://zulip.readthedocs.io/en/latest/subsystems/widgets.html
///
/// This is an underdocumented part of the Zulip Server API.
/// So in addition to docs, see other clients:
///   https://github.com/zulip/zulip-mobile/blob/2217c858e/src/api/modelTypes.js#L800-L861
///   https://github.com/zulip/zulip-mobile/blob/2217c858e/src/webview/html/message.js#L118-L192
///   https://github.com/zulip/zulip/blob/40f59a05c/web/src/submessage.ts
///   https://github.com/zulip/zulip/blob/40f59a05c/web/shared/src/poll_data.ts
@JsonSerializable(fieldRename: FieldRename.snake)
class Submessage {
  const Submessage({
    required this.senderId,
    required this.msgType,
    required this.content,
  });

  // TODO(server): should we be sorting a message's submessages by ID?  Web seems to:
  //   https://github.com/zulip/zulip/blob/40f59a05c55e0e4f26ca87d2bca646770e94bff0/web/src/submessage.ts#L88
  // final int id;  // ignored because we don't use it

  /// The sender of this submessage (not necessarily of the [Message] it's on).
  final int senderId;

  // final int messageId;  // ignored; redundant with [Message.id]

  @JsonKey(unknownEnumValue: SubmessageType.unknown)
  final SubmessageType msgType;

  /// A JSON encoding of a [SubmessageData].
  // We cannot parse the String into one of the [SubmessageData] classes because
  // information from other submessages are required. Specifically, we need:
  //   * the index of this submessage in [Message.submessages];
  //   * the parsed [WidgetType] from the first [Message.submessages].
  final String content;

  /// Parse a JSON list into a [Poll].
  // TODO: Use a generalized return type when supporting other Zulip widgets.
  static Poll? parseSubmessagesJson(List<Object?> json, {
    required int messageSenderId,
  }) {
    final submessages = json.map((e) => Submessage.fromJson(e as Map<String, Object?>)).toList();
    if (submessages.isEmpty) return null;

    assert(submessages.first.senderId == messageSenderId);

    final widgetData = WidgetData.fromJson(jsonDecode(submessages.first.content));
    switch (widgetData) {
      case PollWidgetData():
        return Poll.fromSubmessages(
          widgetData: widgetData,
          pollEventSubmessages: submessages.skip(1),
          messageSenderId: messageSenderId,
          debugSubmessages: kDebugMode ? submessages : null,
        );
      case UnsupportedWidgetData():
        assert(debugLog('Unsupported widgetData: ${widgetData.json}'));
        return null;
    }
  }

  factory Submessage.fromJson(Map<String, Object?> json) =>
    _$SubmessageFromJson(json);

  Map<String, Object?> toJson() => _$SubmessageToJson(this);
}

/// As in [Submessage.msgType].
///
/// The only type of submessage that actually exists in Zulip (as of 2024,
/// and since this "submessages" subsystem was created in 2017–2018)
/// is [SubmessageType.widget].
@JsonEnum(fieldRename: FieldRename.snake, alwaysCreate: true)
enum SubmessageType {
  widget,
  unknown;

  String toJson() => _$SubmessageTypeEnumMap[this]!;
}

/// The data encoded in a submessage at [Submessage.content].
///
/// For widgets (the only existing use of submessages), the submessages
/// on a [Message] consist of:
///  * One submessage with content [WidgetData]; then
///  * Zero or more submessages with content [PollEventSubmessage] if the
///    message is a poll (i.e. if the first submessage was a [PollWidgetData]),
///    and similarly for other types of widgets.
sealed class SubmessageData {
  Object? toJson();
}

/// The data encoded in a submessage to make the message a Zulip widget.
///
/// Expected from the first [Submessage.content] in the "submessages" field on
/// the message when there is an widget.
///
/// See https://zulip.readthedocs.io/en/latest/subsystems/widgets.html
sealed class WidgetData extends SubmessageData {
  WidgetType get widgetType;

  WidgetData();

  factory WidgetData.fromJson(Object? json) {
    final map = json as Map<String, Object?>;
    final rawWidgetType = map['widget_type'] as String;
    return switch (WidgetType.fromRawString(rawWidgetType)) {
      WidgetType.poll => PollWidgetData.fromJson(map),
      WidgetType.unknown => UnsupportedWidgetData.fromJson(map),
    };
  }

  @override
  Object? toJson();
}

/// As in [WidgetData.widgetType].
@JsonEnum(alwaysCreate: true)
enum WidgetType {
  poll,
  // todo,  // TODO(#882)
  // zform,  // This exists in web but is more a demo than a real feature.
  unknown;

  static WidgetType fromRawString(String raw) => _byRawString[raw] ?? unknown;

  static final _byRawString = _$WidgetTypeEnumMap
    .map((key, value) => MapEntry(value, key));
}

/// The data in the first submessage on a poll widget message.
///
/// Subsequent submessages on the same message will be [PollEventSubmessage].
@JsonSerializable(fieldRename: FieldRename.snake)
class PollWidgetData extends WidgetData {
  @override
  @JsonKey(includeToJson: true)
  WidgetType get widgetType => WidgetType.poll;

  /// The initial question and options on the poll.
  final PollWidgetExtraData extraData;

  PollWidgetData({required this.extraData});

  factory PollWidgetData.fromJson(Map<String, Object?> json) =>
    _$PollWidgetDataFromJson(json);

  @override
  Map<String, Object?> toJson() => _$PollWidgetDataToJson(this);
}

/// As in [PollWidgetData.extraData].
@JsonSerializable(fieldRename: FieldRename.snake)
class PollWidgetExtraData {
  // The [question] and [options] fields seem to be always present.
  // But both web and zulip-mobile accept them as optional, with default values:
  //   https://github.com/zulip/zulip-flutter/pull/823#discussion_r1697656896
  //   https://github.com/zulip/zulip/blob/40f59a05c55e0e4f26ca87d2bca646770e94bff0/web/src/poll_widget.ts#L29
  // And the server doesn't really enforce any structure on submessage data.
  // So match the web and zulip-mobile behavior.
  @JsonKey(defaultValue: "")
  final String question;
  @JsonKey(defaultValue: [])
  final List<String> options;

  const PollWidgetExtraData({required this.question, required this.options});

  factory PollWidgetExtraData.fromJson(Map<String, Object?> json) =>
    _$PollWidgetExtraDataFromJson(json);

  Map<String, Object?> toJson() => _$PollWidgetExtraDataToJson(this);
}

class UnsupportedWidgetData extends WidgetData {
  @override
  @JsonKey(includeToJson: true)
  WidgetType get widgetType => WidgetType.unknown;

  final Object? json;

  UnsupportedWidgetData.fromJson(this.json);

  @override
  Object? toJson() => json;
}

/// The data in a submessage that acts on a poll.
///
/// The first submessage on the message should be a [PollWidgetData].
sealed class PollEventSubmessage extends SubmessageData {
  PollEventSubmessageType get type;

  PollEventSubmessage();

  /// The key for identifying the [idx]'th option added by user
  /// [senderId] to a poll.
  ///
  /// For options that are a part of the initial [PollWidgetData], the
  /// [senderId] should be `null`.
  static PollOptionKey optionKey({required int? senderId, required int idx}) =>
    // "canned" is a canonical constant coined by the web client:
    //   https://github.com/zulip/zulip/blob/40f59a05c/web/shared/src/poll_data.ts#L238
    '${senderId ?? 'canned'},$idx';

  factory PollEventSubmessage.fromJson(Map<String, Object?> json) {
    final rawPollEventType = json['type'] as String;
    switch (PollEventSubmessageType.fromRawString(rawPollEventType)) {
      case PollEventSubmessageType.newOption: return PollNewOptionEventSubmessage.fromJson(json);
      case PollEventSubmessageType.question: return PollQuestionEventSubmessage.fromJson(json);
      case PollEventSubmessageType.vote: return PollVoteEventSubmessage.fromJson(json);
      case PollEventSubmessageType.unknown: return UnknownPollEventSubmessage.fromJson(json);
    }
  }

  @override
  Map<String, Object?> toJson();
}

/// As in [PollEventSubmessage.type].
@JsonEnum(fieldRename: FieldRename.snake)
enum PollEventSubmessageType {
  newOption,
  question,
  vote,
  unknown;

  static PollEventSubmessageType fromRawString(String raw) => _byRawString[raw]!;

  static final _byRawString = _$PollEventSubmessageTypeEnumMap
    .map((key, value) => MapEntry(value, key));
}

typedef PollOptionKey = String;

/// A poll event when an option is added.
///
/// See: https://github.com/zulip/zulip/blob/40f59a05c/web/shared/src/poll_data.ts#L112-L159
@JsonSerializable(fieldRename: FieldRename.snake)
class PollNewOptionEventSubmessage extends PollEventSubmessage {
  @override
  @JsonKey(includeToJson: true)
  PollEventSubmessageType get type => PollEventSubmessageType.newOption;

  final String option;
  /// A sequence number for this option, among options added to this poll
  /// by this [Submessage.senderId].
  ///
  /// See [PollEventSubmessage.optionKey].
  final int idx;

  PollNewOptionEventSubmessage({required this.option, required this.idx});

  @override
  factory PollNewOptionEventSubmessage.fromJson(Map<String, Object?> json) =>
    _$PollNewOptionEventSubmessageFromJson(json);

  @override
  Map<String, Object?> toJson() => _$PollNewOptionEventSubmessageToJson(this);
}

/// A poll event when the question has been edited.
///
/// See: https://github.com/zulip/zulip/blob/40f59a05c/web/shared/src/poll_data.ts#L161-186
@JsonSerializable(fieldRename: FieldRename.snake)
class PollQuestionEventSubmessage extends PollEventSubmessage {
  @override
  @JsonKey(includeToJson: true)
  PollEventSubmessageType get type => PollEventSubmessageType.question;

  final String question;

  PollQuestionEventSubmessage({required this.question});

  @override
  factory PollQuestionEventSubmessage.fromJson(Map<String, Object?> json) =>
    _$PollQuestionEventSubmessageFromJson(json);

  @override
  Map<String, Object?> toJson() => _$PollQuestionEventSubmessageToJson(this);
}

/// A poll event when a vote has been cast or removed.
///
/// See: https://github.com/zulip/zulip/blob/40f59a05c/web/shared/src/poll_data.ts#L188-234
@JsonSerializable(fieldRename: FieldRename.snake)
class PollVoteEventSubmessage extends PollEventSubmessage {
  @override
  @JsonKey(includeToJson: true)
  PollEventSubmessageType get type => PollEventSubmessageType.vote;

  /// The key of the affected option.
  ///
  /// See [PollEventSubmessage.optionKey].
  final PollOptionKey key;
  @JsonKey(name: 'vote', unknownEnumValue: PollVoteOp.unknown)
  final PollVoteOp op;

  PollVoteEventSubmessage({required this.key, required this.op});

  @override
  factory PollVoteEventSubmessage.fromJson(Map<String, Object?> json) {
    final result = _$PollVoteEventSubmessageFromJson(json);
    // Crunchy-shell validation
    final segments = result.key.split(',');
    final [senderId, idx] = segments;
    if (senderId != 'canned') {
      int.parse(senderId, radix: 10);
    }
    int.parse(idx, radix: 10);
    return result;
  }

  @override
  Map<String, Object?> toJson() => _$PollVoteEventSubmessageToJson(this);
}

/// As in [PollVoteEventSubmessage.op].
@JsonEnum(valueField: 'apiValue')
enum PollVoteOp {
  add(apiValue: 1),
  remove(apiValue: -1),
  unknown(apiValue: null);

  const PollVoteOp({required this.apiValue});

  final int? apiValue;

  int? toJson() => apiValue;
}

class UnknownPollEventSubmessage extends PollEventSubmessage {
  @override
  @JsonKey(includeToJson: true)
  PollEventSubmessageType get type => PollEventSubmessageType.unknown;

  final Map<String, Object?> json;

  UnknownPollEventSubmessage.fromJson(this.json);

  @override
  Map<String, Object?> toJson() => json;
}

/// States of a poll Zulip widget.
///
/// See also:
/// - https://zulip.com/help/create-a-poll
/// - https://github.com/zulip/zulip/blob/304d948416465c1a085122af5d752f03d6797003/web/shared/src/poll_data.ts
class Poll extends ChangeNotifier {
  /// Construct a poll from submessages.
  ///
  /// For a poll Zulip widget, the first submessage's content contains a
  /// [PollWidgetData], and all the following submessages' content each contains
  /// a [PollEventSubmessage].
  factory Poll.fromSubmessages({
    required PollWidgetData widgetData,
    required Iterable<Submessage> pollEventSubmessages,
    required int messageSenderId,
    required List<Submessage>? debugSubmessages,
  }) {
    final poll = Poll._(
      messageSenderId: messageSenderId,
      question: widgetData.extraData.question,
      options: widgetData.extraData.options,
      debugSubmessages: debugSubmessages,
    );

    for (final submessage in pollEventSubmessages) {
      final event = PollEventSubmessage.fromJson(jsonDecode(submessage.content) as Map<String, Object?>);
      poll._applyEvent(submessage.senderId, event);
    }
    return poll;
  }

  Poll._({
    required this.messageSenderId,
    required this.question,
    required List<String> options,
    required List<Submessage>? debugSubmessages,
  }) {
    for (int index = 0; index < options.length; index += 1) {
      // Initial poll options use a placeholder senderId.
      // See [PollEventSubmessage.optionKey] for details.
      _addOption(senderId: null, idx: index, option: options[index]);
    }
    if (kDebugMode) {
      _debugSubmessages = debugSubmessages;
    }
  }

  final int messageSenderId;
  String question;

  List<Submessage>? _debugSubmessages;

  /// The limit of options any single user can add to a poll.
  ///
  /// See https://github.com/zulip/zulip/blob/304d948416465c1a085122af5d752f03d6797003/web/shared/src/poll_data.ts#L69-L71
  static const _maxIdx = 1000;

  Iterable<PollOption> get options => _options.values;
  /// Contains the text of all options from [_options].
  final Set<String> _existingOptionTexts = {};
  final Map<PollOptionKey, PollOption> _options = {};

  void handleSubmessageEvent(SubmessageEvent event) {
    final PollEventSubmessage? pollEventSubmessage;
    try {
      pollEventSubmessage = PollEventSubmessage.fromJson(jsonDecode(event.content) as Map<String, Object?>);
    } catch (e) {
      assert(debugLog('Malformed submessage event data for poll: $e\n${jsonEncode(event)}')); // TODO(log)
      return;
    }
    _applyEvent(event.senderId, pollEventSubmessage);
    notifyListeners();

    if (kDebugMode) {
      assert(_debugSubmessages != null);
      _debugSubmessages!.add(Submessage(
        senderId: event.senderId,
        msgType: event.msgType,
        content: event.content));
    }
  }

  void _applyEvent(int senderId, PollEventSubmessage event) {
    switch (event) {
      case PollNewOptionEventSubmessage():
        _addOption(senderId: senderId, idx: event.idx, option: event.option);

      case PollQuestionEventSubmessage():
        if (senderId != messageSenderId) {
          // Only the message owner can edit the question.
          assert(debugLog('unexpected poll data: user $senderId is not allowed to edit the question')); // TODO(log)
          return;
        }

        question = event.question;

      case PollVoteEventSubmessage():
        final option = _options[event.key];
        if (option == null) {
          assert(debugLog('vote for unknown key ${event.key}')); // TODO(log)
          return;
        }

        switch (event.op) {
          case PollVoteOp.add:
            option.voters.add(senderId);
          case PollVoteOp.remove:
            option.voters.remove(senderId);
          case PollVoteOp.unknown:
            assert(debugLog('unknown vote op ${event.op}')); // TODO(log)
        }

      case UnknownPollEventSubmessage():
    }
  }

  void _addOption({required int? senderId, required int idx, required String option}) {
    if (idx > _maxIdx || idx < 0) return;

    // The web client suppresses duplicate options, which can be created through
    // the /poll command as there is no server-side validation.
    if (_existingOptionTexts.contains(option)) return;

    final key = PollEventSubmessage.optionKey(senderId: senderId, idx: idx);
    assert(!_options.containsKey(key));
    _options[key] = PollOption(key: key, text: option);
    _existingOptionTexts.add(option);
  }

  static Poll? fromJson(Object? json) {
    // [Submessage.parseSubmessagesJson] does all the heavy lifting for parsing.
    return json as Poll?;
  }

  static List<Submessage> toJson(Poll? poll) {
    List<Submessage>? result;

    if (kDebugMode) {
      // Useful for setting up a message list with a poll message, which goes
      // through this codepath (when preparing a fetch response).
      result = poll?._debugSubmessages;
    }

    // In prod, rather than maintaining a up-to-date submessages list,
    // return as if it is empty, because we are not sending the submessages
    // to the server anyway.
    return result ?? [];
  }
}

class PollOption {
  PollOption({required this.key, required this.text});

  final PollOptionKey key;
  final String text;
  final Set<int> voters = {};

  @override
  String toString() => 'PollOption(text: $text, voters: {${voters.join(', ')}})';
}
